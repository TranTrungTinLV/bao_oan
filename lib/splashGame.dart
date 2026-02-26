import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:bao_oan/HomeGame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// Cinematic Trailer - BÁO OAN
// ============================================================
// Kịch bản: Kiên đi vào khu rừng tối, khung cảnh cave parallax,
// text kịch tính, hiệu ứng horror, jump scare.
// ============================================================

class SplashGame extends StatefulWidget {
  static String id = 'splash_game';

  const SplashGame({super.key});

  @override
  State<SplashGame> createState() => _SplashGameState();
}

class _SplashGameState extends State<SplashGame> with TickerProviderStateMixin {
  // ── Audio ──
  late AudioPlayer _bgMusicPlayer;
  late AudioPlayer _sfxPlayer1; // wind, creak, scream, heartbeat
  late AudioPlayer _sfxPlayer2; // footsteps (loop)
  late AudioPlayer _sfxPlayer3; // flicker, scratching

  // ── Preloaded sprite images ──
  ui.Image? _normalSpriteImage;
  ui.Image? _flashlightSpriteImage;

  // ── SFX triggers (phát 1 lần) ──
  bool _playedWind = false;
  bool _playedFootsteps = false;
  bool _playedSpeechSfx = false;
  bool _playedSlam = false;
  bool _playedBulbMusic = false;

  // ── Master timeline ──
  late AnimationController _masterController;
  static const double _totalDuration = 90.0;

  // ── Character animation ──
  late AnimationController _spriteController;
  int _currentFrame = 0;
  static const int _spriteColumns = 8;
  static const int _spriteRows = 8;

  // ── Parallax ──
  double _parallaxOffset = 0.0;

  // ── Scene state ──
  int _currentScene = 0;
  double _sceneTime = 0.0;

  // ── Effects ──
  double _screenOpacity = 0.0;
  double _flickerOpacity = 1.0;
  double _redFlashOpacity = 0.0;
  double _shakeX = 0.0;
  double _shakeY = 0.0;
  bool _showTitle = false;
  bool _showStoryText = false;
  bool _showEnding = false;
  bool _showSpeechBubble = false;
  bool _characterVisible = false;
  bool _showYoungKien = false;
  bool _showParents = false;
  bool _isWalking = false;
  bool _isLookingAround = false;
  bool _useFlashlight = false;
  double _characterX = -0.15;
  double _youngKienX = -0.15;
  double _parentsX = 0.6;
  double _titleGlowIntensity = 0.0;
  String _currentStoryText = '';
  int _visibleChars = 0;
  Timer? _typewriterTimer;
  double _vignetteIntensity = 0.3;
  String _currentBackground = 'countryside';

  // ── Swinging bulb ──
  bool _showSwingingBulb = false;
  double _bulbSwingAngle = 0.0;

  // ── Speech bubble ──
  String _speechFullText = 'Đây là đâu?';
  int _speechBubbleChars = 0;
  Timer? _speechBubbleTimer;

  final Random _random = Random();

  // SFX triggers

  bool _playedSchoolSfx = false;
  bool _playedRainSfx = false;

  // Scene definitions:
  // 0: 0-3s     Fade in
  // 1: 3-12s    Đồng lúa quê nhà - Kiên nhỏ đi bộ
  // 2: 12-22s   Nhà gia đình - Cha mẹ + Kiên
  // 3: 22-32s   Trường học - Speech bubble
  // 4: 32-38s   Lên thành phố - Fade đen
  // 5: 38-50s   Khu phố tối - Đi bộ trong mưa
  // 6: 50-55s   Slam đen + Jumpscare
  // 7: 55-90s   Đèn đung đưa + Title

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _bgMusicPlayer = AudioPlayer();
    _sfxPlayer1 = AudioPlayer();
    _sfxPlayer2 = AudioPlayer();
    _sfxPlayer3 = AudioPlayer();

    // Master timeline controller
    _masterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalDuration * 1000).toInt()),
    );

    // Sprite animation controller (6 FPS for pixel art feel)
    _spriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _spriteController.reset();
          _spriteController.forward();
          setState(() {
            _advanceSpriteFrame();
          });
        }
      });

    _masterController.addListener(_onTimelineUpdate);

    // Load sprite images
    _loadSpriteImages();

    // Start
    _startTrailer();
  }

  @override
  void dispose() {
    _masterController.dispose();
    _spriteController.dispose();
    _typewriterTimer?.cancel();
    _speechBubbleTimer?.cancel();
    _bgMusicPlayer.stop();
    _bgMusicPlayer.dispose();
    _sfxPlayer1.stop();
    _sfxPlayer1.dispose();
    _sfxPlayer2.stop();
    _sfxPlayer2.dispose();
    _sfxPlayer3.stop();
    _sfxPlayer3.dispose();
    super.dispose();
  }

  void _startTrailer() async {
    // Phát nhạc nền horror
    // 🔊 ÂM THANH: horror_music.mp3 - nhạc nền horror xuyên suốt trailer
    await _bgMusicPlayer.play(AssetSource('horror_music_main.mp3'));
    await _bgMusicPlayer.setVolume(0.7);

    _masterController.forward();
    _spriteController.forward();
  }

  void _onTimelineUpdate() {
    final progress = _masterController.value;
    final time = progress * _totalDuration;
    _sceneTime = time;

    setState(() {
      // ══════ SCENE 0: Fade In (0-3s) ══════
      if (time < 3.0) {
        _currentScene = 0;
        _screenOpacity = (time / 3.0).clamp(0.0, 1.0);
        _currentBackground = 'countryside';
        _vignetteIntensity = 0.3;
      }
      // ══════ SCENE 1: Đồng Lúa Quê (3-12s) ══════
      else if (time < 12.0) {
        _currentScene = 1;
        _screenOpacity = 1.0;
        _currentBackground = 'countryside';
        _showYoungKien = true;
        _showParents = false;
        _characterVisible = false;
        _vignetteIntensity = 0.2;

        double walkP = ((time - 3.0) / 9.0).clamp(0.0, 1.0);
        _youngKienX = -0.1 + walkP * 0.5;
        _parallaxOffset = walkP * 200;

        if (!_showStoryText) {
          _showStoryText = true;
          _startTypewriter('Trương Thành Kiên\nsinh ra ở một vùng quê nhỏ...');
        }

        if (!_playedWind) {
          _playedWind = true;
          _sfxPlayer1.play(AssetSource('wind_howl.mp3'));
          _sfxPlayer1.setVolume(0.3);
        }
      }
      // ══════ SCENE 2: Nhà Gia Đình (12-22s) ══════
      else if (time < 22.0) {
        _currentScene = 2;
        _currentBackground = 'family';
        _showYoungKien = true;
        _showParents = true;
        _characterVisible = false;
        _vignetteIntensity = 0.2;
        _parallaxOffset = 0;

        double walkP = ((time - 12.0) / 10.0).clamp(0.0, 1.0);
        _youngKienX = -0.1 + walkP * 0.35;
        _parentsX = 0.55;

        if (time >= 12.0 && time < 12.5) {
          _showStoryText = false;
        }
        if (time >= 13.0 && !_showStoryText) {
          _showStoryText = true;
          _startTypewriter('Nổi tiếng gan lì từ nhỏ\nchuyện tâm linh cậu ít khi quan tâm');
        }
      }
      // ══════ SCENE 3: Trường Học (22-32s) ══════
      else if (time < 32.0) {
        _currentScene = 3;
        _currentBackground = 'school';
        _showYoungKien = false;
        _showParents = false;
        _characterVisible = true;
        _isWalking = time < 27.0;
        _isLookingAround = time >= 27.0;
        _useFlashlight = false;
        _vignetteIntensity = 0.2;
        _parallaxOffset = 0;

        double walkP = ((time - 22.0) / 5.0).clamp(0.0, 1.0);
        _characterX = -0.1 + walkP * 0.35;

        if (time >= 22.0 && time < 22.5) {
          _showStoryText = false;
        }

        // Speech bubble "Ba nói tìm được chỗ trọ tốt rồi"
        if (time >= 27.0) {
          _isWalking = false;
          _showSpeechBubble = true;
          if (!_playedSpeechSfx) {
            _playedSpeechSfx = true;
            _speechFullText = 'Ba nói tìm được chỗ trọ tốt rồi!';
            _speechBubbleChars = 0;
            _sfxPlayer3.setReleaseMode(ReleaseMode.loop);
            _sfxPlayer3.play(AssetSource('speak-in-game.mp3'));
            _sfxPlayer3.setVolume(0.2);
            _speechBubbleTimer = Timer.periodic(
              const Duration(milliseconds: 100),
              (timer) {
                setState(() {
                  _speechBubbleChars++;
                  if (_speechBubbleChars >= _speechFullText.length) {
                    timer.cancel();
                    _sfxPlayer3.stop();
                  }
                });
              },
            );
          }
        }

        if (!_playedSchoolSfx) {
          _playedSchoolSfx = true;
          _sfxPlayer1.stop();
          _sfxPlayer2.setReleaseMode(ReleaseMode.loop);
          _sfxPlayer2.play(AssetSource('footsteps_gravel.mp3'));
          _sfxPlayer2.setVolume(0.3);
        }
      }
      // ══════ SCENE 4: Lên Thành Phố (32-38s) ══════
      else if (time < 38.0) {
        _currentScene = 4;
        _showSpeechBubble = false;
        _showYoungKien = false;
        _showParents = false;
        _characterVisible = false;
        _speechBubbleTimer?.cancel();
        _sfxPlayer2.stop();
        _sfxPlayer3.stop();

        double fadeP = ((time - 32.0) / 1.5).clamp(0.0, 1.0);
        _screenOpacity = 1.0 - fadeP; // Fade to black

        if (time >= 33.5) {
          _screenOpacity = 0.0;
          if (!_showStoryText) {
            _showStoryText = true;
            _startTypewriter('Rời quê lên Thành Phố...\nmột mình bước vào bóng tối');
          }
        }

        if (!_playedRainSfx) {
          _playedRainSfx = true;
          _sfxPlayer1.play(AssetSource('rain_night.mp3'));
          _sfxPlayer1.setVolume(0.6);
        }
      }
      // ══════ SCENE 5: Khu Phố Tối (38-50s) ══════
      else if (time < 50.0) {
        _currentScene = 5;
        _currentBackground = 'cave';
        _showStoryText = false;
        _characterVisible = true;
        _isWalking = true;
        _isLookingAround = false;
        _useFlashlight = true;
        _showYoungKien = false;
        _showParents = false;

        double fadeIn = ((time - 38.0) / 2.0).clamp(0.0, 1.0);
        _screenOpacity = fadeIn;

        double walkP = ((time - 38.0) / 12.0).clamp(0.0, 1.0);
        _characterX = -0.15 + walkP * 0.55;
        _parallaxOffset = walkP * 500;

        _vignetteIntensity = 0.5 + walkP * 0.2;

        if ((time * 3).floor() % 7 == 0) {
          _flickerOpacity = 0.7 + _random.nextDouble() * 0.3;
        } else {
          _flickerOpacity = 1.0;
        }

        if (!_playedFootsteps) {
          _playedFootsteps = true;
          _bgMusicPlayer.setVolume(0.9);
          _sfxPlayer2.setReleaseMode(ReleaseMode.loop);
          _sfxPlayer2.play(AssetSource('footsteps_gravel.mp3'));
          _sfxPlayer2.setVolume(0.4);
        }
      }
      // ══════ SCENE 6: Slam Đen (50-55s) ══════
      else if (time < 55.0) {
        _currentScene = 6;
        _characterVisible = false;
        _showEnding = false;
        _showSwingingBulb = false;

        if (!_playedSlam) {
          _playedSlam = true;
          _bgMusicPlayer.stop();
          _sfxPlayer1.stop();
          _sfxPlayer2.stop();
          _sfxPlayer1.play(AssetSource('slam_shut.mp3'));
          _sfxPlayer1.setVolume(0.9);
        }

        _screenOpacity = 0.0;

        // Jumpscare nhanh ở giây 52
        if (time >= 52.0 && time < 52.5) {
          _redFlashOpacity = 0.8;
          _shakeX = (_random.nextDouble() - 0.5) * 40;
          _shakeY = (_random.nextDouble() - 0.5) * 30;
        } else {
          _redFlashOpacity = 0.0;
          _shakeX = 0;
          _shakeY = 0;
        }
      }
      // ══════ SCENE 7: Đèn đung đưa + Title (55-90s) ══════
      else {
        _currentScene = 7;
        _showSwingingBulb = true;
        _showEnding = true;
        _characterVisible = false;
        _showYoungKien = false;
        _showParents = false;

        if (!_playedBulbMusic) {
          _playedBulbMusic = true;
          _sfxPlayer1.stop();
          _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
          _bgMusicPlayer.play(AssetSource('kiepnaodoyeunhau.wav'));
          _bgMusicPlayer.setVolume(0.6);
          _sfxPlayer2.setReleaseMode(ReleaseMode.loop);
          _sfxPlayer2.play(AssetSource('creaking_light.mp3'));
          _sfxPlayer2.setVolume(0.4);
        }

        double bulbTime = time - 55.0;
        _bulbSwingAngle = sin(bulbTime * 1.8) * 0.4;
        _flickerOpacity = 0.85 + sin(bulbTime * 5.0) * 0.15;

        double fadeIn = (bulbTime / 2.0).clamp(0.0, 1.0);
        _screenOpacity = fadeIn;
        _titleGlowIntensity = 0.5 + sin(bulbTime * 1.5) * 0.5;
      }
    });
  }

  void _advanceSpriteFrame() {
    if (_isWalking) {
      // Walk animation: row 1, 7 frames (columns 0-6)
      _currentFrame = (_currentFrame + 1) % 7;
    } else if (_isLookingAround) {
      // Look around: row 5, 8 frames
      _currentFrame = (_currentFrame + 1) % 8;
    } else {
      // Idle: row 0, 2 frames
      _currentFrame = (_currentFrame + 1) % 2;
    }
  }

  int get _currentRow {
    if (_isWalking) return 1;
    if (_isLookingAround) return 5;
    return 0; // idle
  }

  int get _totalFramesInRow {
    if (_isWalking) return 7;
    if (_isLookingAround) return 8;
    return 2;
  }

  void _startTypewriter(String text) {
    _currentStoryText = text;
    _visibleChars = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (_visibleChars < text.length) {
        setState(() {
          _visibleChars++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _skipTrailer() {
    _masterController.stop();
    _bgMusicPlayer.stop();
    _typewriterTimer?.cancel();
    Navigator.pushReplacementNamed(context, HomeGame.id);
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
        onTap: _currentScene >= 6 ? _skipTrailer : null,
        child: Transform.translate(
          offset: Offset(_shakeX, _shakeY),
          child: Stack(
            children: [
              // ── Parallax Background Layers ──
              _buildParallaxBackground(size),

              // ── Vignette overlay (tối viền) ──
              _buildVignette(size),

              // ── Flicker effect ──
              Opacity(
                opacity: (1.0 - _flickerOpacity).clamp(0.0, 0.5),
                child: Container(color: Colors.black),
              ),

              // ── Character (teenager sprite sheet) ──
              if (_characterVisible) _buildCharacter(size),

              // ── Young Kien (static image) ──
              if (_showYoungKien) _buildYoungKien(size),

              // ── Parents NPC ──
              if (_showParents) _buildParentsNPC(size),

              // ── Speech Bubble ──
              if (_showSpeechBubble) _buildSpeechBubble(size),

              // ── Flashlight darkness ──
              if (_characterVisible && _useFlashlight)
                _buildFlashlightDarkness(size),

              // ── Red Flash (jump scare) ──
              if (_redFlashOpacity > 0)
                Opacity(
                  opacity: _redFlashOpacity.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('images/background.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              // ── Fade in/out black overlay ──
              if (_screenOpacity < 1.0)
                Opacity(
                  opacity: (1.0 - _screenOpacity).clamp(0.0, 1.0),
                  child: Container(color: Colors.black),
                ),

              // ── Title "BÁO OÁN" ──
              if (_showTitle) _buildTitle(size),

              // ── Story Text ──
              if (_showStoryText)
                _buildStoryText(size),

              // ── Swinging Light Bulb (background layer) ──
              if (_showSwingingBulb) _buildSwingingBulb(size),

              // ── Ending (text on top) ──
              if (_showEnding) _buildEnding(size),

              // ── Skip button ──
              if (_sceneTime > 5.0 && !_showEnding)
                Positioned(
                  bottom: 20,
                  right: 30,
                  child: GestureDetector(
                    onTap: _skipTrailer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Text(
                        'Bỏ qua ▸▸',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // PARALLAX BACKGROUND
  // ════════════════════════════════════════
  Widget _buildParallaxBackground(Size size) {
    // Chuyển background theo scene
    if (_currentBackground == 'countryside' || _currentBackground == 'family' || _currentBackground == 'school') {
      // Dùng background tĩnh cho các cảnh quê/gia đình/trường học
      String bgPath;
      switch (_currentBackground) {
        case 'family':
          bgPath = 'images/backgrounds/bg_family_home.png';
          break;
        case 'school':
          bgPath = 'images/backgrounds/bg_school.png';
          break;
        default:
          bgPath = 'images/backgrounds/bg_countryside.png';
      }
      return Opacity(
        opacity: _screenOpacity.clamp(0.0, 1.0),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(-_parallaxOffset * 0.1, 0),
                child: Image.asset(
                  bgPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cảnh cave/khu phố tối - dùng parallax layers
    final layers = [
      _ParallaxLayer('images/BackGround Layers/00.png', 0.02), // sky
      _ParallaxLayer('images/BackGround Layers/6.png', 0.05), // fog/light xa
      _ParallaxLayer('images/BackGround Layers/5.png', 0.10), // cave walls xa
      _ParallaxLayer('images/BackGround Layers/4.png', 0.15), // ceiling rocks
      _ParallaxLayer('images/BackGround Layers/3.png', 0.20), // cave ceiling
      _ParallaxLayer('images/BackGround Layers/1.png', 0.30), // stalactites
      _ParallaxLayer('images/BackGround Layers/2.png', 0.40), // cave arch
    ];

    return Opacity(
      opacity: _screenOpacity.clamp(0.0, 1.0),
      child: Stack(
        children: [
          // Base dark background
          Container(color: const Color(0xFF0a0a12)),

          // Parallax layers (chỉ Scene 5 - khu phố tối)
          if (_currentScene >= 5)
          ...layers.map((layer) {
            return Positioned.fill(
              child: Transform.translate(
                offset: Offset(-_parallaxOffset * layer.speed, 0),
                child: Image.asset(
                  layer.assetPath,
                  fit: BoxFit.cover,
                  width: size.width * 1.5,
                  alignment: Alignment.centerLeft,
                  color:
                      _currentScene >= 6 ? Colors.black.withOpacity(0.3) : null,
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            );
          }),

          // Light rays overlay
          if (_currentScene == 5)
            Positioned.fill(
              child: Opacity(
                opacity: (_flickerOpacity * 0.3).clamp(0.0, 0.4),
                child: Transform.translate(
                  offset: Offset(-_parallaxOffset * 0.05, 0),
                  child: Image.asset(
                    'images/BackGround Layers/BlueLight.png',
                    fit: BoxFit.cover,
                    color: Colors.blue.withOpacity(0.15),
                    colorBlendMode: BlendMode.screen,
                  ),
                ),
              ),
            ),

          // Foreground layer (closest)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(-_parallaxOffset * 0.55, 0),
              child: Image.asset(
                'images/BackGround Layers/7ForeGround.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),

          // Ground/platform layer at bottom
          Positioned(
            bottom: 0,
            left: -_parallaxOffset * 0.45,
            child: SizedBox(
              width: size.width * 2,
              height: size.height * 0.18,
              child: Image.asset(
                'images/long-platforms.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeatX,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // VIGNETTE (tối viền tạo chiều sâu)
  // ════════════════════════════════════════
  Widget _buildVignette(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(_vignetteIntensity),
                Colors.black.withOpacity(_vignetteIntensity + 0.3),
              ],
              stops: const [0.3, 0.75, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // LOAD SPRITE IMAGES
  // ════════════════════════════════════════
  Future<void> _loadSpriteImages() async {
    _normalSpriteImage =
        await _loadImage('images/character/png sheet/normal.png');
    _flashlightSpriteImage =
        await _loadImage('images/character/png sheet/with_flashlight.png');
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ════════════════════════════════════════
  // YOUNG KIEN (static image - tuổi thơ)
  // ════════════════════════════════════════
  Widget _buildYoungKien(Size size) {
    double charScale = size.height * 0.25;
    double groundY = size.height * 0.88 - charScale;

    return Positioned(
      left: size.width * _youngKienX,
      top: groundY,
      child: SizedBox(
        width: charScale,
        height: charScale,
        child: Image.asset(
          'images/npc/kien_young.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // PARENTS NPC (static image)
  // ════════════════════════════════════════
  Widget _buildParentsNPC(Size size) {
    double npcScale = size.height * 0.30;
    double groundY = size.height * 0.88 - npcScale;

    return Positioned(
      left: size.width * _parentsX,
      top: groundY,
      child: SizedBox(
        width: npcScale * 1.4,
        height: npcScale,
        child: Image.asset(
          'images/npc/parents.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // CHARACTER
  // ════════════════════════════════════════
  Widget _buildCharacter(Size size) {
    final spriteImage =
        _useFlashlight ? _flashlightSpriteImage : _normalSpriteImage;
    if (spriteImage == null) return const SizedBox.shrink();

    int row = _currentRow;
    int col = _currentFrame.clamp(0, _totalFramesInRow - 1);

    // ✅ TĂNG scale để nhân vật lớn hơn
    double charScale = size.height * 0.35; // ✅ Tăng từ 0.22 → 0.35

    // ✅ Tính Y position dựa trên ground level
    double groundY =
        size.height * 0.84; // ✅ Vị trí mặt đất (80-85% chiều cao màn hình)
    double charY = groundY - charScale; // ✅ Đặt nhân vật đứng trên đất

    return Positioned(
      left: size.width * _characterX,
      top: charY,
      child: SizedBox(
        width: charScale,
        height: charScale,
        child: CustomPaint(
          painter: _SpritePainter(
            image: spriteImage,
            col: col,
            row: row,
            columns: _spriteColumns,
            rows: _spriteRows,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // SPEECH BUBBLE ("Đây là đâu?")
  // ════════════════════════════════════════
  Widget _buildSpeechBubble(Size size) {
    double charScale = size.height * 0.35;
    double groundY = size.height * 1.0;
    double charY = groundY - charScale;

    // Bubble nằm phía trên đầu nhân vật
    double bubbleWidth = 160;
    double bubbleHeight = 50;
    double bubbleX = size.width * _characterX + charScale * 0.2;
    double bubbleY = charY - bubbleHeight - 15;

    return Positioned(
      left: bubbleX,
      top: bubbleY,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bubble box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _speechFullText.substring(
                0,
                _speechBubbleChars.clamp(0, _speechFullText.length),
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Triangle pointer
          CustomPaint(
            size: const Size(16, 10),
            painter: _BubbleTrianglePainter(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // TITLE
  // ════════════════════════════════════════
  Widget _buildTitle(Size size) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing "BÁO OAN" text
          Text(
            'BÁO OAN',
            style: TextStyle(
              fontFamily: 'HorrorText',
              fontSize: 72,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 20.0 * _titleGlowIntensity,
                  color:
                      const Color(0xFFcc0000).withOpacity(_titleGlowIntensity),
                  offset: const Offset(0, 0),
                ),
                Shadow(
                  blurRadius: 40.0 * _titleGlowIntensity,
                  color: Colors.red.withOpacity(_titleGlowIntensity * 0.5),
                  offset: const Offset(0, 5),
                ),
                const Shadow(
                  blurRadius: 8.0,
                  color: Colors.black,
                  offset: Offset(3, 3),
                ),
              ],
              letterSpacing: 12,
            ),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: (_titleGlowIntensity * 0.7).clamp(0.0, 1.0),
            child: Text(
              '— CÂU CHUYỆN KINH HOÀNG —',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.red.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // STORY TEXT (Typewriter)
  // ════════════════════════════════════════
  Widget _buildStoryText(Size size) {
    String displayText = _currentStoryText.length > _visibleChars
        ? _currentStoryText.substring(0, _visibleChars)
        : _currentStoryText;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'HorrorText',
            fontSize: 26,
            color: Colors.white.withOpacity(0.9),
            height: 1.8,
            letterSpacing: 2,
            shadows: [
              Shadow(
                blurRadius: 15,
                color: Colors.red.withOpacity(0.4),
                offset: const Offset(0, 2),
              ),
              const Shadow(
                blurRadius: 5,
                color: Colors.black,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // ENDING
  // ════════════════════════════════════════
  Widget _buildEnding(Size size) {
    return Container(
      color: _showSwingingBulb
          ? Colors.transparent
          : Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "BÁO OAN" với glow đỏ
            Text(
              'BÁO OAN',
              style: TextStyle(
                fontFamily: 'HorrorText',
                fontSize: 80,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 30.0 * _titleGlowIntensity,
                    color: const Color(0xFFff0000)
                        .withOpacity(_titleGlowIntensity),
                  ),
                  Shadow(
                    blurRadius: 60.0 * _titleGlowIntensity,
                    color: Colors.red.withOpacity(_titleGlowIntensity * 0.4),
                  ),
                  const Shadow(
                    blurRadius: 5,
                    color: Colors.black,
                    offset: Offset(3, 3),
                  ),
                ],
                letterSpacing: 15,
              ),
            ),
            const SizedBox(height: 30),
            // "Coming Soon"
            Opacity(
              opacity: _titleGlowIntensity.clamp(0.0, 1.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withOpacity(_titleGlowIntensity * 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'COMING SOON',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: _titleGlowIntensity.clamp(0.0, 1.0),
              child: const Text(
                '[ Chạm để tiếp tục ]',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 13,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // SWINGING LIGHT BULB (bóng đèn đung đưa ma mị)
  // ════════════════════════════════════════
  Widget _buildSwingingBulb(Size size) {
    return Positioned.fill(
      child: Stack(
        children: [
          // ── Nền đen với ánh sáng nhấp nháy ──
          Container(
            color: Colors.black.withOpacity(0.95),
          ),

          // ── Ánh sáng hắt từ bóng đèn (cone light) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: _bulbSwingAngle,
              alignment: Alignment.topCenter,
              child: CustomPaint(
                painter: _LightConePainter(
                  opacity: _flickerOpacity.clamp(0.0, 1.0),
                ),
              ),
            ),
          ),

          // ── Dây treo + bóng đèn ──
          Positioned(
            top: 0,
            left: size.width / 2 - 30,
            child: Transform.rotate(
              angle: _bulbSwingAngle,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  // Dây treo
                  Container(
                    width: 2,
                    height: size.height * 0.18,
                    color: Colors.grey.withOpacity(0.6),
                  ),
                  // Bóng đèn
                  Container(
                    width: 20,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFe8dcc8)
                              .withOpacity(_flickerOpacity * 0.9),
                          const Color(0xFFc4a882)
                              .withOpacity(_flickerOpacity * 0.5),
                          const Color(0xFF8a7560)
                              .withOpacity(_flickerOpacity * 0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFe8dcc8)
                              .withOpacity(_flickerOpacity * 0.4),
                          blurRadius: 25,
                          spreadRadius: 12,
                        ),
                        BoxShadow(
                          color: const Color(0xFF8a7560)
                              .withOpacity(_flickerOpacity * 0.2),
                          blurRadius: 50,
                          spreadRadius: 25,
                        ),
                      ],
                    ),
                  ),
                  // Đuôi đèn (đui)
                  Container(
                    width: 12,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // FLASHLIGHT DARKNESS OVERLAY
  // ════════════════════════════════════════
  Widget _buildFlashlightDarkness(Size size) {
    double charScale = size.height * 0.35; // ✅ Phải khớp với _buildCharacter
    double groundY = size.height * 1.0; // ✅ Khớp với ground level
    double charY = groundY - charScale;

    // ✅ Vị trí tâm đèn pin = tâm nhân vật + offset
    double lightX =
        size.width * _characterX + charScale * 0.5; // ✅ Giữa nhân vật
    double lightY = charY + charScale * 0.4; // ✅ Ở tầm ngực nhân vật

    // Bán kính spotlight
    double baseRadius = size.width * 0.25; // ✅ Tăng từ 0.18 → 0.25
    double flickerRadius = baseRadius * (_flickerOpacity * 0.3 + 0.7);

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _FlashlightPainter(
            lightCenter: Offset(lightX, lightY),
            lightRadius: flickerRadius,
            darkness: _currentScene == 5 ? 0.92 : 0.85,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
// FLASHLIGHT PAINTER
// ════════════════════════════════════════
class _FlashlightPainter extends CustomPainter {
  final Offset lightCenter;
  final double lightRadius;
  final double darkness;

  _FlashlightPainter({
    required this.lightCenter,
    required this.lightRadius,
    required this.darkness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Tạo gradient: trong suốt ở tâm → đen ở ngoài
    paint.shader = RadialGradient(
      center: Alignment(
        (lightCenter.dx / size.width) * 2 - 1,
        (lightCenter.dy / size.height) * 2 - 1,
      ),
      radius: lightRadius / size.shortestSide,
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withOpacity(darkness * 0.3),
        Colors.black.withOpacity(darkness * 0.7),
        Colors.black.withOpacity(darkness),
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlashlightPainter oldDelegate) {
    return lightCenter != oldDelegate.lightCenter ||
        lightRadius != oldDelegate.lightRadius ||
        darkness != oldDelegate.darkness;
  }
}

// Sprite sheet painter - vẽ đúng 1 frame từ sprite sheet
class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int col;
  final int row;
  final int columns;
  final int rows;

  _SpritePainter({
    required this.image,
    required this.col,
    required this.row,
    required this.columns,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || rows <= 0 || image.width <= 0 || image.height <= 0) return;

    final double frameW = image.width / columns;
    final double frameH = image.height / rows;

    double srcX = col * frameW;
    double srcY = row * frameH;

    if (srcX < 0) srcX = 0;
    if (srcY < 0) srcY = 0;
    if (srcX >= image.width) srcX = (image.width - frameW).clamp(0.0, image.width.toDouble());
    if (srcY >= image.height) srcY = (image.height - frameH).clamp(0.0, image.height.toDouble());

    double srcW = frameW;
    double srcH = frameH;
    if (srcX + srcW > image.width) srcW = image.width - srcX;
    if (srcY + srcH > image.height) srcH = image.height - srcY;

    final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return col != oldDelegate.col ||
        row != oldDelegate.row ||
        image != oldDelegate.image;
  }
}

// Speech bubble triangle pointer
class _BubbleTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Light cone painter (ánh sáng hình nón từ bóng đèn)
class _LightConePainter extends CustomPainter {
  final double opacity;

  _LightConePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Vị trí bóng đèn (đầu cone)
    final bulbY = size.height * 0.22;
    // Đáy cone (sàn)
    final floorY = size.height;
    // Độ rộng cone ở đáy
    final coneHalfWidth = size.width * 0.35;

    final path = Path()
      ..moveTo(centerX, bulbY)
      ..lineTo(centerX - coneHalfWidth, floorY)
      ..lineTo(centerX + coneHalfWidth, floorY)
      ..close();

    // Gradient từ sáng → mờ dần
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX, bulbY),
        Offset(centerX, floorY),
        [
          const Color(0xFFe8dcc8).withOpacity(opacity * 0.10),
          const Color(0xFF8a7560).withOpacity(opacity * 0.05),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LightConePainter oldDelegate) {
    return opacity != oldDelegate.opacity;
  }
}

// Helper class
class _ParallaxLayer {
  final String assetPath;
  final double speed;

  _ParallaxLayer(this.assetPath, this.speed);
}
