import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:bao_oan/HomeGame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════
// TRAILER FPV - GÓC NHÌN THỨ NHẤT
// Kiên mở mắt → chớp mắt → bước đi → xuyên cảnh liên tục
// Quê → Nhà Trọ → Cave → Nhiễu glitch hỗn tạp
// ════════════════════════════════════════════════════════════

class TrailerFPV extends StatefulWidget {
  static String id = 'trailer_fpv';
  const TrailerFPV({super.key});

  @override
  State<TrailerFPV> createState() => _TrailerFPVState();
}

class _TrailerFPVState extends State<TrailerFPV> with TickerProviderStateMixin {
  // Audio
  late AudioPlayer _bgMusic;
  late AudioPlayer _sfx1;
  late AudioPlayer _sfx2;
  late AudioPlayer _sfx3;

  // Timeline
  late AnimationController _masterController;
  static const double _totalDuration = 60.0;

  // Eyelids
  double _eyelidOpen = 0.0; // 0 = đóng, 1 = mở hoàn toàn
  bool _isBlinking = false;

  // Camera/Head bob
  double _headBobY = 0.0;
  double _headBobX = 0.0;
  double _breathOffset = 0.0;

  // Scene
  int _currentSceneIndex = 0;
  double _sceneTime = 0.0;
  double _parallaxX = 0.0;
  double _sceneZoom = 1.0;

  // Glitch
  double _glitchIntensity = 0.0;
  double _glitchOffsetX = 0.0;
  double _glitchOffsetY = 0.0;
  bool _showGlitch = false;
  double _colorShiftR = 0.0;
  double _colorShiftB = 0.0;

  // Rain
  bool _showRain = false;
  List<_RainDrop> _rainDrops = [];

  // Effects
  double _screenOpacity = 0.0;
  double _vignetteIntensity = 0.5;
  double _redFlash = 0.0;
  String _subtitleText = '';
  double _subtitleOpacity = 0.0;
  double _hearingRing = 0.0; // tinnitus effect

  // Text
  String _currentText = '';
  int _visibleChars = 0;
  Timer? _typewriterTimer;

  final Random _random = Random();

  // SFX flags
  bool _playedOpen = false;
  bool _playedFootsteps = false;
  bool _playedGlitch = false;
  bool _playedRain = false;
  bool _playedWhisper = false;
  bool _playedHeartbeat = false;

  // Backgrounds to cycle through
  final List<_FPVScene> _scenes = [
    _FPVScene('images/backgrounds/bg_countryside.png', 'countryside', 10.0),
    _FPVScene('images/backgrounds/room_interior.png', 'room', 8.0),
    _FPVScene('images/BackGround Layers/5.png', 'cave1', 6.0),
    _FPVScene('images/backgrounds/bg_family_home.png', 'home', 7.0),
    _FPVScene('images/BackGround Layers/3.png', 'cave2', 5.0),
    _FPVScene('images/backgrounds/outside_house.png', 'outside', 6.0),
    _FPVScene('images/BackGround Layers/2.png', 'cave3', 5.0),
    _FPVScene('images/backgrounds/attic_room.png', 'attic', 5.0),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _bgMusic = AudioPlayer();
    _sfx1 = AudioPlayer();
    _sfx2 = AudioPlayer();
    _sfx3 = AudioPlayer();

    // Generate rain drops
    _rainDrops = List.generate(80, (_) => _RainDrop(_random));

    _masterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalDuration * 1000).toInt()),
    );

    _masterController.addListener(_onUpdate);
    _startTrailer();
  }

  @override
  void dispose() {
    _masterController.dispose();
    _typewriterTimer?.cancel();
    _bgMusic.stop();
    _bgMusic.dispose();
    _sfx1.stop();
    _sfx1.dispose();
    _sfx2.stop();
    _sfx2.dispose();
    _sfx3.stop();
    _sfx3.dispose();
    super.dispose();
  }

  void _startTrailer() async {
    // Nhạc horror ambient
    await _bgMusic.play(AssetSource('horror_music_main.mp3'));
    await _bgMusic.setVolume(0.4);
    _masterController.forward();
  }

  void _skipTrailer() {
    _masterController.stop();
    _bgMusic.stop();
    _sfx1.stop();
    _sfx2.stop();
    _sfx3.stop();
    _typewriterTimer?.cancel();
    Navigator.pushReplacementNamed(context, HomeGame.id);
  }

  void _startTypewriter(String text) {
    _currentText = text;
    _visibleChars = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (_visibleChars < text.length) {
        setState(() => _visibleChars++);
      } else {
        timer.cancel();
      }
    });
  }

  // ════════════════════════════════════════
  // TIMELINE UPDATE
  // ════════════════════════════════════════
  void _onUpdate() {
    final time = _masterController.value * _totalDuration;
    _sceneTime = time;

    setState(() {
      // ═══ PHASE 1: Mở mắt (0-5s) ═══
      if (time < 5.0) {
        _screenOpacity = 1.0;
        _eyelidOpen = (time / 4.0).clamp(0.0, 1.0); // Mở dần dần
        _vignetteIntensity = 0.8 - _eyelidOpen * 0.3;
        _currentSceneIndex = 0; // Countryside
        _showRain = false;

        // Tiếng thở + mở mắt
        if (!_playedOpen) {
          _playedOpen = true;
          _sfx1.play(AssetSource('wind_howl.mp3'));
          _sfx1.setVolume(0.3);
        }

        // Head bob nhẹ (thở)
        _breathOffset = sin(time * 2.0) * 3.0;
        _headBobY = _breathOffset;

        // Subtitle
        if (time > 2.0) {
          _subtitleText = '...';
          _subtitleOpacity = ((time - 2.0) / 1.0).clamp(0.0, 1.0);
        }
      }
      // ═══ PHASE 2: Đi bộ cảnh quê (5-12s) ═══
      else if (time < 12.0) {
        _eyelidOpen = 1.0;
        _screenOpacity = 1.0;
        _currentSceneIndex = 0;
        double walkP = (time - 5.0) / 7.0;

        // Head bob khi đi bộ
        _headBobY = sin(time * 6.0) * 8.0;
        _headBobX = cos(time * 3.0) * 3.0;
        _parallaxX = walkP * 200;
        _sceneZoom = 1.0 + walkP * 0.05;

        // Footsteps
        if (!_playedFootsteps) {
          _playedFootsteps = true;
          _sfx2.setReleaseMode(ReleaseMode.loop);
          _sfx2.play(AssetSource('footsteps_gravel.mp3'));
          _sfx2.setVolume(0.5);
        }

        _subtitleText = '';
        _subtitleOpacity = 0;

        // Chớp mắt tự nhiên
        if ((time * 10).floor() % 40 == 0) {
          _triggerBlink();
        }
      }
      // ═══ GLITCH TRANSITION 1 (12-13s) ═══
      else if (time < 13.0) {
        _showGlitch = true;
        _glitchIntensity = 1.0;
        _glitchOffsetX = (_random.nextDouble() - 0.5) * 30;
        _glitchOffsetY = (_random.nextDouble() - 0.5) * 20;
        _colorShiftR = (_random.nextDouble() - 0.5) * 10;
        _colorShiftB = (_random.nextDouble() - 0.5) * 10;
        _redFlash = _random.nextDouble() * 0.3;

        if (!_playedGlitch) {
          _playedGlitch = true;
          _sfx3.play(AssetSource('glitch_sound.mp3'));
          _sfx3.setVolume(0.8);
        }
      }
      // ═══ PHASE 3: Phòng trọ (13-20s) ═══
      else if (time < 20.0) {
        _showGlitch = false;
        _glitchIntensity = 0;
        _redFlash = 0;
        _currentSceneIndex = 1; // room_interior
        _showRain = false;
        double walkP = (time - 13.0) / 7.0;

        _headBobY = sin(time * 5.0) * 6.0;
        _headBobX = cos(time * 2.5) * 4.0;
        _parallaxX = walkP * 150;
        _sceneZoom = 1.0 + sin(time * 0.5) * 0.03;

        _vignetteIntensity = 0.5 + sin(time * 3.0) * 0.1;

        // Chớp mắt hoảng
        if ((time * 10).floor() % 25 == 0) {
          _triggerBlink();
        }
      }
      // ═══ GLITCH TRANSITION 2 (20-21s) ═══
      else if (time < 21.0) {
        _showGlitch = true;
        _glitchIntensity = 1.0;
        _glitchOffsetX = (_random.nextDouble() - 0.5) * 50;
        _glitchOffsetY = (_random.nextDouble() - 0.5) * 30;
        _colorShiftR = (_random.nextDouble() - 0.5) * 15;
        _colorShiftB = (_random.nextDouble() - 0.5) * 15;
        _redFlash = _random.nextDouble() * 0.5;
        _playedGlitch = false;

        _sfx3.play(AssetSource('scratching.mp3'));
        _sfx3.setVolume(0.6);
      }
      // ═══ PHASE 4: Cave tối (21-28s) ═══
      else if (time < 28.0) {
        _showGlitch = false;
        _glitchIntensity = 0;
        _redFlash = 0;
        _currentSceneIndex = 2; // cave1
        _showRain = true;
        double walkP = (time - 21.0) / 7.0;

        _headBobY = sin(time * 7.0) * 10.0; // Chạy nhanh hơn
        _headBobX = cos(time * 3.5) * 6.0;
        _parallaxX = walkP * 300;
        _sceneZoom = 1.0 + walkP * 0.1;
        _vignetteIntensity = 0.7;

        // Mưa trong cave
        if (!_playedRain) {
          _playedRain = true;
          _sfx1.stop();
          _sfx1.setReleaseMode(ReleaseMode.loop);
          _sfx1.play(AssetSource('rain_night.mp3'));
          _sfx1.setVolume(0.5);
        }

        // Tiếng thì thầm
        if (!_playedWhisper) {
          _playedWhisper = true;
          _sfx3.stop();
          _sfx3.setReleaseMode(ReleaseMode.loop);
          _sfx3.play(AssetSource('whisper_crowd.mp3'));
          _sfx3.setVolume(0.4);
        }

        // Chớp mắt nhanh
        if ((time * 10).floor() % 15 == 0) {
          _triggerBlink();
        }
      }
      // ═══ GLITCH TRANSITION 3 (28-29s) ═══
      else if (time < 29.0) {
        _showGlitch = true;
        _glitchIntensity = 1.0;
        _glitchOffsetX = (_random.nextDouble() - 0.5) * 60;
        _glitchOffsetY = (_random.nextDouble() - 0.5) * 40;
        _redFlash = 0.4 + _random.nextDouble() * 0.3;
      }
      // ═══ PHASE 5: Nhà quê flashback (29-35s) ═══
      else if (time < 35.0) {
        _showGlitch = false;
        _redFlash = 0;
        _currentSceneIndex = 3; // family home
        double walkP = (time - 29.0) / 6.0;

        _headBobY = sin(time * 5.0) * 5.0;
        _headBobX = cos(time * 2.0) * 3.0;
        _parallaxX = walkP * 100;
        _sceneZoom = 1.0;
        _vignetteIntensity = 0.3;

        // Ngưng tiếng mưa, chỉ còn gió
        _sfx1.setVolume(0.2);
      }
      // ═══ RAPID GLITCH MONTAGE (35-45s) ═══
      else if (time < 45.0) {
        // Chuyển cảnh liên tục cực nhanh
        double montageTime = time - 35.0;
        int sceneSwitch = (montageTime * 2).floor(); // Đổi cảnh mỗi 0.5s
        _currentSceneIndex = (4 + sceneSwitch) % _scenes.length;

        _showGlitch = montageTime.floor() % 2 == 0;
        _showRain = true; // Mưa visual chaos
        _glitchIntensity = 0.5 + _random.nextDouble() * 0.5;
        _glitchOffsetX = (_random.nextDouble() - 0.5) * 40;
        _glitchOffsetY = (_random.nextDouble() - 0.5) * 30;
        _colorShiftR = (_random.nextDouble() - 0.5) * 20;
        _colorShiftB = (_random.nextDouble() - 0.5) * 20;
        _redFlash = _random.nextDouble() * 0.3;

        _headBobY = (_random.nextDouble() - 0.5) * 30;
        _headBobX = (_random.nextDouble() - 0.5) * 20;
        _sceneZoom = 1.0 + _random.nextDouble() * 0.3;
        _vignetteIntensity = 0.6 + _random.nextDouble() * 0.3;

        _parallaxX = _random.nextDouble() * 300;

        // ── ÂM THANH HỖN TẠP ──
        if (!_playedHeartbeat) {
          _playedHeartbeat = true;
          // Heartbeat dồn dập
          _sfx2.stop();
          _sfx2.setReleaseMode(ReleaseMode.loop);
          _sfx2.play(AssetSource('heartbeat.mp3'));
          _sfx2.setVolume(0.8);

          // Tiếng khóc tang lễ
          _sfx1.stop();
          _sfx1.setReleaseMode(ReleaseMode.loop);
          _sfx1.play(AssetSource('funeral_cry_hollow.mp3'));
          _sfx1.setVolume(0.5);

          // Tiếng thì thầm + nam mô chồng lên
          _sfx3.stop();
          _sfx3.setReleaseMode(ReleaseMode.loop);
          _sfx3.play(AssetSource('chanting_nam_mo.mp3'));
          _sfx3.setVolume(0.4);

          // Nhạc nền tăng volume
          _bgMusic.setVolume(0.9);
        }

        // Xen kẽ volume ngẫu nhiên - tạo hiệu ứng nhiễu âm thanh
        double chaosVolume = 0.3 + _random.nextDouble() * 0.7;
        _sfx1.setVolume(chaosVolume * 0.6); // Khóc nhấp nhô
        _sfx3.setVolume(chaosVolume * 0.5); // Nam mô nhấp nhô

        // Chớp mắt cực nhanh
        _eyelidOpen = 0.5 + _random.nextDouble() * 0.5;
      }
      // ═══ PHASE 6: Đen sập (45-48s) ═══
      else if (time < 48.0) {
        _showGlitch = false;
        _redFlash = 0;
        _eyelidOpen = 0.0; // Nhắm mắt
        _screenOpacity = 0.0;
        _sfx1.stop();
        _sfx2.stop();
        _sfx3.stop();
        _bgMusic.setVolume(0.3);

        if (time > 46.0) {
          _subtitleText = 'BÁO OAN';
          _subtitleOpacity = ((time - 46.0) / 1.0).clamp(0.0, 1.0);
        }
      }
      // ═══ PHASE 7: Title + Coming Soon (48-60s) ═══
      else {
        _showGlitch = false;
        _showRain = false;
        _redFlash = 0;
        _eyelidOpen = 0;
        _screenOpacity = 0.0;
        _subtitleText = 'BÁO OAN';
        _subtitleOpacity = 1.0;
        _hearingRing = sin(time * 2.0) * 0.3;

        // Flicker nhẹ cho title
        if ((time * 10).floor() % 30 == 0) {
          _redFlash = 0.15;
        }
      }

      // Update rain
      if (_showRain) {
        for (var drop in _rainDrops) {
          drop.update();
        }
      }
    });
  }

  void _triggerBlink() {
    if (_isBlinking) return;
    _isBlinking = true;
    _eyelidOpen = 0.3;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() {
        _eyelidOpen = 1.0;
        _isBlinking = false;
      });
    });
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _sceneTime > 45.0 ? _skipTrailer : null,
        child: Stack(
          children: [
            // ── Background Scene ──
            if (_screenOpacity > 0)
              Transform.translate(
                offset: Offset(_headBobX + _glitchOffsetX, _headBobY + _glitchOffsetY),
                child: Transform.scale(
                  scale: _sceneZoom,
                  child: Opacity(
                    opacity: _screenOpacity.clamp(0.0, 1.0),
                    child: _buildCurrentScene(size),
                  ),
                ),
              ),

            // ── Color shift (RGB glitch) ──
            if (_showGlitch) ...[
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(_colorShiftR, 0),
                  child: Opacity(
                    opacity: 0.3,
                    child: Container(color: Colors.red.withOpacity(0.2)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(_colorShiftB, 0),
                  child: Opacity(
                    opacity: 0.3,
                    child: Container(color: Colors.blue.withOpacity(0.2)),
                  ),
                ),
              ),
            ],

            // ── Rain overlay ──
            if (_showRain)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RainPainter(_rainDrops),
                ),
              ),

            // ── Vignette ──
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(_vignetteIntensity.clamp(0.0, 1.0)),
                        Colors.black.withOpacity((_vignetteIntensity + 0.2).clamp(0.0, 1.0)),
                      ],
                      stops: const [0.2, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Red flash ──
            if (_redFlash > 0)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withOpacity(_redFlash.clamp(0.0, 0.7)),
                ),
              ),

            // ── EYELIDS (góc nhìn thứ nhất) ──
            _buildEyelids(size),

            // ── Glitch scan lines ──
            if (_showGlitch)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanLinePainter(_glitchIntensity),
                ),
              ),

            // ── Subtitle text ──
            if (_subtitleOpacity > 0) _buildSubtitle(size),

            // ── ENDING SCREEN HORROR ──
            if (_sceneTime > 48.0)
              Positioned.fill(
                child: _buildHorrorEnding(size),
              ),

            // ── Skip button ──
            if (_sceneTime > 3.0 && _sceneTime < 45.0)
              Positioned(
                bottom: 15,
                right: 25,
                child: GestureDetector(
                  onTap: _skipTrailer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'Bỏ qua ▸▸',
                      style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // CURRENT SCENE BACKGROUND
  // ════════════════════════════════════════
  Widget _buildCurrentScene(Size size) {
    final scene = _scenes[_currentSceneIndex.clamp(0, _scenes.length - 1)];
    bool isCave = scene.name.startsWith('cave');

    if (isCave) {
      // ═══ CAVE IMMERSIVE 3D ═══
      // Cảm giác đang bước đi bên trong hang rừng
      // Perspective giả: nền đất cuộn, vách hang 2 bên, trần trên đầu
      double scrollX = _parallaxX;

      return SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ━━━ NỀN TRỜI / SƯƠNG MÙ XA ━━━
            Container(color: const Color(0xFF070a14)),
            Transform.translate(
              offset: Offset(-scrollX * 0.02, 0),
              child: Opacity(
                opacity: 0.8,
                child: Image.asset('images/BackGround Layers/00.png', fit: BoxFit.cover),
              ),
            ),

            // ━━━ SƯƠNG XANH MỜ ẢO (bát ngát) ━━━
            Transform.translate(
              offset: Offset(-scrollX * 0.04, 0),
              child: Opacity(
                opacity: 0.5,
                child: Image.asset('images/BackGround Layers/6.png', fit: BoxFit.cover),
              ),
            ),

            // ━━━ VÁCH ĐÁ XA (layer depth) ━━━
            Transform.translate(
              offset: Offset(-scrollX * 0.08, 0),
              child: Image.asset('images/BackGround Layers/5.png', fit: BoxFit.cover),
            ),

            // ━━━ VÒM HANG GIỮA ━━━
            Transform.translate(
              offset: Offset(-scrollX * 0.12, 0),
              child: Image.asset('images/BackGround Layers/4.png', fit: BoxFit.cover),
            ),

            // ━━━ NHŨ ĐÁ TREO ━━━
            Transform.translate(
              offset: Offset(-scrollX * 0.18, 0),
              child: Image.asset('images/BackGround Layers/3.png', fit: BoxFit.cover),
            ),

            // ━━━ ÁNH SÁNG XANH MỜ ẢO ━━━
            Opacity(
              opacity: 0.20,
              child: Transform.translate(
                offset: Offset(-scrollX * 0.05, 0),
                child: Image.asset('images/BackGround Layers/BlueLight.png',
                  fit: BoxFit.cover,
                  color: Colors.blue.withOpacity(0.12),
                  colorBlendMode: BlendMode.screen,
                ),
              ),
            ),

            // ━━━ VÁCH HANG GẦN (2 bên) ━━━
            Transform.translate(
              offset: Offset(-scrollX * 0.25, 0),
              child: Image.asset('images/BackGround Layers/1.png', fit: BoxFit.cover),
            ),
            Transform.translate(
              offset: Offset(-scrollX * 0.35, 0),
              child: Image.asset('images/BackGround Layers/2.png', fit: BoxFit.cover),
            ),

            // ━━━ TRẦN HANG (Tiles - hàng trên) ━━━
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.12,
              child: Transform.translate(
                offset: Offset(-scrollX * 0.40, 0),
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    'images/Tiles128x128.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    repeat: ImageRepeat.repeatX,
                  ),
                ),
              ),
            ),

            // ━━━ NỀN ĐẤT PERSPECTIVE (nhìn xuống) ━━━
            Positioned(
              bottom: 0,
              left: -size.width * 0.3,
              right: -size.width * 0.3,
              height: size.height * 0.35,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // perspective
                  ..rotateX(0.3), // nghiêng nhìn xuống
                child: Transform.translate(
                  offset: Offset(-(scrollX * 0.6) % (size.width * 0.8), 0),
                  child: Image.asset(
                    'images/long-platforms.png',
                    fit: BoxFit.cover,
                    width: size.width * 3,
                    repeat: ImageRepeat.repeatX,
                  ),
                ),
              ),
            ),

            // ━━━ CỎ BỤI RẢI RÁC 2 BÊN ━━━
            // Bên trái
            Positioned(
              bottom: size.height * 0.20,
              left: 20 - (scrollX * 0.5) % size.width,
              child: Opacity(
                opacity: 0.6,
                child: SizedBox(
                  height: size.height * 0.12,
                  child: Image.asset('images/props.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
            // Bên phải
            Positioned(
              bottom: size.height * 0.22,
              right: 30 - (scrollX * 0.45) % (size.width * 0.5),
              child: Transform.flip(
                flipX: true,
                child: Opacity(
                  opacity: 0.5,
                  child: SizedBox(
                    height: size.height * 0.10,
                    child: Image.asset('images/props.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // ━━━ FOREGROUND SÁT MẶT ━━━
            Transform.translate(
              offset: Offset(-scrollX * 0.55, 0),
              child: Opacity(
                opacity: 0.85,
                child: Image.asset('images/BackGround Layers/7ForeGround.png', fit: BoxFit.cover),
              ),
            ),

            // ━━━ VÁCH TILES 2 BÊN (gần nhất) ━━━
            // Vách trái
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: size.width * 0.08,
              child: Transform.translate(
                offset: Offset(0, -(scrollX * 0.3) % 128),
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset('images/Tiles128x128.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              ),
            ),
            // Vách phải
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: size.width * 0.08,
              child: Transform.translate(
                offset: Offset(0, -(scrollX * 0.25) % 128),
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset('images/Tiles128x128.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              ),
            ),

            // ━━━ SƯƠNG MÙ GẦN (cô đơn, bát ngát) ━━━
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1a2030).withOpacity(0.3),
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFF0a0a14).withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // ━━━ ÁNH SÁNG TỐI XUNG QUANH ━━━
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.2),
                    radius: 0.6,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cảnh thường - 1 ảnh background
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Transform.translate(
        offset: Offset(-_parallaxX * 0.15, 0),
        child: Image.asset(
          scene.bgPath,
          fit: BoxFit.cover,
          width: size.width * 1.3,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // EYELIDS (mí mắt trên + dưới)
  // ════════════════════════════════════════
  Widget _buildEyelids(Size size) {
    double closedHeight = size.height * 0.5 * (1.0 - _eyelidOpen);

    return Stack(
      children: [
        // Mí trên
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: closedHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1a0a05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(200),
                bottomRight: Radius.circular(200),
              ),
            ),
          ),
        ),
        // Mí dưới
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: closedHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1a0a05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(200),
                topRight: Radius.circular(200),
              ),
            ),
          ),
        ),
        // Lông mi trên (khi đang mở)
        if (_eyelidOpen > 0.2 && _eyelidOpen < 0.95)
          Positioned(
            top: closedHeight - 3,
            left: size.width * 0.1,
            right: size.width * 0.1,
            height: 6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════
  // SUBTITLE (for non-ending scenes)
  // ════════════════════════════════════════
  Widget _buildSubtitle(Size size) {
    if (_subtitleText == 'BÁO OAN') return const SizedBox.shrink();

    return Center(
      child: Opacity(
        opacity: _subtitleOpacity.clamp(0.0, 1.0),
        child: Text(
          _subtitleText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // HORROR ENDING SCREEN
  // ════════════════════════════════════════
  Widget _buildHorrorEnding(Size size) {
    double fadeP = ((_sceneTime - 48.0) / 2.0).clamp(0.0, 1.0);
    double creditFade = ((_sceneTime - 52.0) / 2.0).clamp(0.0, 1.0);
    double touchFade = (sin(_sceneTime * 2) * 0.5 + 0.5).clamp(0.0, 1.0);
    double glowPulse = 0.5 + sin(_sceneTime * 1.5) * 0.5;

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Blood drip từ trên xuống
          CustomPaint(
            size: size,
            painter: _BloodDripEndingPainter(
              progress: fadeP,
              time: _sceneTime,
            ),
          ),

          // Vignette đỏ sâu
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1a0000).withOpacity(0.5 * fadeP),
                  const Color(0xFF0a0000).withOpacity(0.8 * fadeP),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Title "BÁO OAN"
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: fadeP,
                  child: Text(
                    'BÁO OAN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HorrorText',
                      fontSize: 80,
                      color: Colors.white,
                      letterSpacing: 15,
                      shadows: [
                        Shadow(
                          blurRadius: 40.0 * glowPulse,
                          color: const Color(0xFFcc0000).withOpacity(glowPulse),
                        ),
                        Shadow(
                          blurRadius: 80.0 * glowPulse,
                          color: Colors.red.withOpacity(glowPulse * 0.5),
                        ),
                        const Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // COMING SOON
                Opacity(
                  opacity: creditFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3 * creditFade),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'COMING SOON',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Credits
                Opacity(
                  opacity: creditFade,
                  child: Column(
                    children: [
                      // Cốt truyện
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cốt truyện  ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Hồng Đào',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.7),
                              fontSize: 14,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Dev
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Game Dev  ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Levi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Touch to continue
          if (_sceneTime > 54.0)
            Positioned(
              bottom: size.height * 0.08,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: touchFade * creditFade,
                child: const Text(
                  '[ Chạm để tiếp tục ]',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
// RAIN SYSTEM
// ════════════════════════════════════════
class _RainDrop {
  double x, y, speed, length;
  final Random random;

  _RainDrop(this.random)
      : x = 0,
        y = 0,
        speed = 0,
        length = 0 {
    reset();
  }

  void reset() {
    x = random.nextDouble();
    y = random.nextDouble() * -0.5;
    speed = 0.02 + random.nextDouble() * 0.03;
    length = 10 + random.nextDouble() * 20;
  }

  void update() {
    y += speed;
    x -= speed * 0.1; // Mưa xiên
    if (y > 1.2) reset();
  }
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  _RainPainter(this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var drop in drops) {
      double startX = drop.x * size.width;
      double startY = drop.y * size.height;
      double endX = startX - 3;
      double endY = startY + drop.length;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ════════════════════════════════════════
// SCAN LINE GLITCH
// ════════════════════════════════════════
class _ScanLinePainter extends CustomPainter {
  final double intensity;
  _ScanLinePainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(intensity * 0.15)
      ..style = PaintingStyle.fill;

    // Horizontal scan lines
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        paint,
      );
    }

    // Random glitch blocks
    final random = Random(DateTime.now().millisecond);
    for (int i = 0; i < (intensity * 8).round(); i++) {
      double blockY = random.nextDouble() * size.height;
      double blockH = 2 + random.nextDouble() * 6;
      double blockX = random.nextDouble() * size.width * 0.5;
      double blockW = size.width * 0.3 + random.nextDouble() * size.width * 0.4;

      canvas.drawRect(
        Rect.fromLTWH(blockX, blockY, blockW, blockH),
        Paint()..color = Colors.white.withOpacity(intensity * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) => true;
}

// Helper
class _FPVScene {
  final String bgPath;
  final String name;
  final double duration;
  _FPVScene(this.bgPath, this.name, this.duration);
}

// Blood drip painter cho ending screen
class _BloodDripEndingPainter extends CustomPainter {
  final double progress;
  final double time;

  _BloodDripEndingPainter({required this.progress, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final random = Random(42); // Fixed seed cho consistent drips

    // Vẽ nhiều giọt máu chảy từ trên xuống
    for (int i = 0; i < 12; i++) {
      double x = random.nextDouble() * size.width;
      double dripSpeed = 0.3 + random.nextDouble() * 0.7;
      double dripWidth = 2 + random.nextDouble() * 4;
      double maxLength = size.height * (0.1 + random.nextDouble() * 0.4);
      double currentLength = maxLength * progress * dripSpeed;

      // Gradient máu: đỏ đậm → đỏ nhạt → trong suốt
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B0000).withOpacity(0.8 * progress),
            const Color(0xFFCC0000).withOpacity(0.5 * progress),
            const Color(0xFF660000).withOpacity(0.2 * progress),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(x, 0, dripWidth, currentLength));

      // Dải máu chính
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, dripWidth, currentLength),
          const Radius.circular(2),
        ),
        paint,
      );

      // Giọt tròn ở đầu
      if (currentLength > 10) {
        canvas.drawCircle(
          Offset(x + dripWidth / 2, currentLength),
          dripWidth * 0.8,
          Paint()..color = const Color(0xFFAA0000).withOpacity(0.6 * progress),
        );
      }
    }

    // Viền máu ở mép trên
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5a0000).withOpacity(0.6 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 30 * progress));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 30 * progress),
      topPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BloodDripEndingPainter oldDelegate) {
    return progress != oldDelegate.progress || time != oldDelegate.time;
  }
}
