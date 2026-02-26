import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:bao_oan/HomeGame.dart';
import 'package:bao_oan/dialog_widget.dart';
import 'package:bao_oan/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayGameScreen extends StatefulWidget {
  static String id = 'play_game';
  const PlayGameScreen({super.key});

  @override
  State<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen>
    with TickerProviderStateMixin {
  final GameController _game = GameController();

  // Audio
  late AudioPlayer _bgMusic;
  late AudioPlayer _sfxPlayer;
  late AudioPlayer _sfxPlayer2;
  bool _musicStarted = false;

  // Animation
  late AnimationController _flickerController;
  late AnimationController _ghostController;
  double _flickerOpacity = 1.0;
  final Random _random = Random();

  // Player movement
  bool _movingLeft = false;
  bool _movingRight = false;
  Timer? _moveTimer;
  int _walkFrame = 0;
  Timer? _walkAnimTimer;

  // Scene transition
  double _fadeOpacity = 1.0; // 1 = black, 0 = visible
  bool _isTransitioning = false;

  // Horror effects
  bool _showGhostFlash = false;
  double _shakeX = 0;
  double _shakeY = 0;
  bool _lightsOff = false;
  Timer? _noiseTimer;
  bool _showNoiseHint = false;

  // Scene-specific
  bool _doorOpening = false;

  // Sprite images (loaded via dart:ui for frame clipping)
  ui.Image? _normalSpriteImage;
  ui.Image? _flashlightSpriteImage;
  ui.Image? _baHuyenSpriteImage;
  static const int _spriteColumns = 8;
  static const int _spriteRows = 8;
  int _currentRow = 0; // 0=idle, 1=walk, 5=look around

  // NPC animation
  int _npcFrame = 0;
  Timer? _npcAnimTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _bgMusic = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _sfxPlayer2 = AudioPlayer();
    _loadSpriteImages();

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_onFlicker);

    _ghostController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Start with fade in
    _fadeInScene();
    _startBgMusic();
    _startFlicker();

    // Auto-start dialog for outside scene
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _game.isDialogActive = true;
          _game.dialogIndex = 0;
        });
      }
    });
  }

  void _startBgMusic() async {
    if (!_musicStarted) {
      _musicStarted = true;
      try {
        await _bgMusic.setVolume(0.5);
        await _bgMusic.setReleaseMode(ReleaseMode.loop);
        await _bgMusic.play(AssetSource('horror_music_main.mp3'));
        debugPrint('BG Music started successfully');
      } catch (e) {
        debugPrint('Error playing bg music: $e');
      }
    }
  }

  void _startFlicker() {
    _flickerController.repeat();
  }

  void _onFlicker() {
    if (_game.currentScene == GameScene.attic ||
        (_game.currentScene == GameScene.inside && _lightsOff)) {
      setState(() {
        _flickerOpacity = 0.7 + _random.nextDouble() * 0.3;
        if (_random.nextInt(30) == 0) {
          _shakeX = (_random.nextDouble() - 0.5) * 2;
          _shakeY = (_random.nextDouble() - 0.5) * 1;
        } else {
          _shakeX = 0;
          _shakeY = 0;
        }
      });
    }
  }

  void _fadeInScene() {
    _isTransitioning = true;
    _fadeOpacity = 1.0;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _fadeOpacity = 0.0;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          _isTransitioning = false;
        });
      }
    });
  }

  void _transitionToScene(GameScene scene) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // Fade out
    setState(() => _fadeOpacity = 1.0);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Change scene
    setState(() {
      _game.currentScene = scene;
      _game.playerX = 0.15;
      _game.isDialogActive = false;
      _game.resetDialogIndex();
    });

    // Fade in
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _fadeOpacity = 0.0);

    await Future.delayed(const Duration(milliseconds: 500));
    _isTransitioning = false;

    // Auto-trigger events
    _triggerSceneEvent(scene);
  }

  void _triggerSceneEvent(GameScene scene) {
    switch (scene) {
      case GameScene.inside:
        if (!_game.metBaNam) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _game.isDialogActive = true;
                _game.dialogIndex = 0;
              });
            }
          });
        } else if (!_game.heardNoise) {
          // Trigger noise after a delay
          _noiseTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) {
              _sfxPlayer.play(AssetSource('scratching.mp3'));
              _sfxPlayer.setVolume(0.6);
              setState(() {
                _game.heardNoise = true;
                _shakeX = 2;
                _shakeY = 1;
                _showNoiseHint = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() { _shakeX = 0; _shakeY = 0; });
              });
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _game.isDialogActive = true;
                    _game.dialogIndex = 0;
                  });
                }
              });
            }
          });
        }
        break;
      case GameScene.attic:
        _game.wentToAttic = true;
        _lightsOff = true;
        _sfxPlayer.play(AssetSource('light_flicker.mp3'));
        _sfxPlayer.setVolume(0.5);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _game.isDialogActive = true;
              _game.dialogIndex = 0;
            });
          }
        });
        break;
      default:
        break;
    }
  }

  void _advanceDialog() {
    final dialogs = _game.getDialogsForScene();
    if (_game.dialogIndex < dialogs.length - 1) {
      setState(() {
        _game.dialogIndex++;
      });
    } else {
      // Dialog finished
      setState(() {
        _game.isDialogActive = false;
      });
      _onDialogComplete();
    }
  }

  void _onDialogComplete() {
    switch (_game.currentScene) {
      case GameScene.outside:
        if (!_game.metBaHuyen) {
          setState(() {
            _game.metBaHuyen = true;
            _game.gotKey = true;
          });
          _sfxPlayer.play(AssetSource('creak_door.mp3'));
          _sfxPlayer.setVolume(0.4);
        }
        break;
      case GameScene.inside:
        if (!_game.metBaNam) {
          setState(() {
            _game.metBaNam = true;
          });
          // Sau khi gặp Bà Năm → trigger tiếng động gác mái
          _noiseTimer = Timer(const Duration(seconds: 4), () {
            if (mounted && !_game.heardNoise) {
              try {
                _sfxPlayer.play(AssetSource('scratching.mp3'));
                _sfxPlayer.setVolume(0.6);
              } catch (_) {}
              setState(() {
                _game.heardNoise = true;
                _shakeX = 3;
                _shakeY = 2;
                _showNoiseHint = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() { _shakeX = 0; _shakeY = 0; });
              });
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _game.isDialogActive = true;
                    _game.dialogIndex = 0;
                  });
                }
              });
            }
          });
        }
        break;
      case GameScene.attic:
        if (!_game.foundDiary) {
          setState(() {
            _game.foundDiary = true;
          });
          // Ghost flash!
          _triggerGhostFlash();
          Future.delayed(const Duration(seconds: 3), () {
            _transitionToScene(GameScene.endDemo);
          });
        }
        break;
      default:
        break;
    }
  }

  void _triggerGhostFlash() async {
    _sfxPlayer.play(AssetSource('jumpscare_scream.mp3'));
    _sfxPlayer.setVolume(0.7);
    setState(() {
      _showGhostFlash = true;
      _shakeX = 5;
      _shakeY = 3;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showGhostFlash = false;
        _shakeX = 0;
        _shakeY = 0;
      });
    }
  }

  void _startMoving(bool left) {
    if (_game.isDialogActive || _isTransitioning) return;
    _movingLeft = left;
    _movingRight = !left;
    _moveTimer?.cancel();
    _walkAnimTimer?.cancel();

    setState(() {
      _game.playerFacingRight = !left;
      _currentRow = 1; // switch to walk row
    });

    // Tiếng bước chân
    _sfxPlayer2.setReleaseMode(ReleaseMode.loop);
    _sfxPlayer2.play(AssetSource('footsteps_gravel.mp3'));
    _sfxPlayer2.setVolume(0.4);

    _moveTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {
        if (_movingLeft) {
          _game.playerX = (_game.playerX - 0.008).clamp(0.02, 0.85);
        } else if (_movingRight) {
          _game.playerX = (_game.playerX + 0.008).clamp(0.02, 0.85);
        }
      });
    });

    _walkAnimTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      setState(() {
        _walkFrame = (_walkFrame + 1) % 7;
      });
    });
  }

  void _stopMoving() {
    _movingLeft = false;
    _movingRight = false;
    _moveTimer?.cancel();
    _walkAnimTimer?.cancel();
    _sfxPlayer2.stop(); // Dừng tiếng bước chân
    setState(() {
      _walkFrame = 0;
      _currentRow = 0; // back to idle row
    });
  }

  void _handleInteract() {
    if (_game.isDialogActive || _isTransitioning) return;

    if (_game.currentScene == GameScene.outside && _game.isNearDoor() && _game.gotKey) {
      _sfxPlayer.play(AssetSource('creak_door.mp3'));
      _game.enteredHouse = true;
      _transitionToScene(GameScene.inside);
    } else if (_game.currentScene == GameScene.inside && _game.isNearStairs() && _game.heardNoise) {
      _sfxPlayer.play(AssetSource('footsteps_gravel.mp3'));
      _transitionToScene(GameScene.attic);
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _ghostController.dispose();
    _moveTimer?.cancel();
    _walkAnimTimer?.cancel();
    _noiseTimer?.cancel();
    _npcAnimTimer?.cancel();
    _bgMusic.stop();
    _bgMusic.dispose();
    _sfxPlayer.stop();
    _sfxPlayer.dispose();
    _sfxPlayer2.stop();
    _sfxPlayer2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_game.currentScene == GameScene.endDemo) {
      return _buildEndDemo(size);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Transform.translate(
        offset: Offset(_shakeX, _shakeY),
        child: Stack(
          children: [
            // Background
            _buildBackground(size),

            // Flicker overlay
            Opacity(
              opacity: (1.0 - _flickerOpacity).clamp(0.0, 0.4),
              child: Container(color: Colors.black),
            ),

            // NPCs
            _buildNPCs(size),

            // Player character
            _buildPlayer(size),

            // Interaction hints
            _buildInteractionHints(size),

            // Ghost flash
            if (_showGhostFlash) _buildGhostFlash(size),

            // Vignette
            _buildVignette(),

            // Dialog
            if (_game.isDialogActive) _buildDialog(),

            // Controls
            if (!_game.isDialogActive) _buildControls(size),

            // Scene fade transition
            AnimatedOpacity(
              opacity: _fadeOpacity,
              duration: const Duration(milliseconds: 500),
              child: IgnorePointer(
                child: Container(color: Colors.black),
              ),
            ),

            // Back button
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: () {
                  _bgMusic.stop();
                  Navigator.pushReplacementNamed(context, HomeGame.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white38, size: 16),
                      SizedBox(width: 4),
                      Text('Thoát', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

            // Scene indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getSceneName(),
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSceneName() {
    switch (_game.currentScene) {
      case GameScene.outside:
        return 'NGOÀI NHÀ TRỌ 403';
      case GameScene.inside:
        return 'TẦNG TRỆT';
      case GameScene.attic:
        return 'GÁC MÁI';
      default:
        return '';
    }
  }

  Widget _buildBackground(Size size) {
    String bgAsset;
    switch (_game.currentScene) {
      case GameScene.outside:
        bgAsset = 'images/backgrounds/outside_house.png';
        break;
      case GameScene.inside:
        bgAsset = 'images/backgrounds/room_interior.png';
        break;
      case GameScene.attic:
        bgAsset = 'images/backgrounds/attic_room.png';
        break;
      default:
        bgAsset = 'images/backgrounds/room_interior.png';
    }

    return Positioned.fill(
      child: Opacity(
        opacity: _flickerOpacity.clamp(0.5, 1.0),
        child: Image.asset(
          bgAsset,
          fit: BoxFit.cover,
          color: _lightsOff ? Colors.black.withOpacity(0.5) : null,
          colorBlendMode: BlendMode.darken,
        ),
      ),
    );
  }

  // Load sprite sheet images
  Future<void> _loadSpriteImages() async {
    _normalSpriteImage = await _loadImage('images/character/png sheet/normal.png');
    _flashlightSpriteImage = await _loadImage('images/character/png sheet/with_flashlight.png');
    _baHuyenSpriteImage = await _loadImage('images/npc/ba_huyen.png');
    if (mounted) setState(() {});
    // Start NPC idle animation
    _npcAnimTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) {
        setState(() {
          _npcFrame = (_npcFrame + 1) % 4;
        });
      }
    });
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Widget _buildPlayer(Size size) {
    final spriteImage = (_game.currentScene == GameScene.attic ||
            _game.currentScene == GameScene.inside)
        ? _flashlightSpriteImage
        : _normalSpriteImage;
    if (spriteImage == null) return const SizedBox.shrink();

    double charScale = size.height * 0.35;
    double groundY = size.height * 0.95 - charScale;

    int col = _walkFrame.clamp(0, _spriteColumns - 1);
    int row = _currentRow;

    return Positioned(
      left: size.width * _game.playerX,
      top: groundY,
      child: Transform.flip(
        flipX: !_game.playerFacingRight,
        child: SizedBox(
          width: charScale,
          height: charScale,
          child: CustomPaint(
            painter: _GameSpritePainter(
              image: spriteImage,
              col: col,
              row: row,
              columns: _spriteColumns,
              rows: _spriteRows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNPCs(Size size) {
    double npcScale = size.height * 0.30;
    double groundY = size.height * 0.95 - npcScale;

    List<Widget> npcs = [];

    // Bà Huyền - outside scene (sprite sheet 4x4)
    if (_game.currentScene == GameScene.outside && !_game.enteredHouse) {
      if (_baHuyenSpriteImage != null) {
        npcs.add(Positioned(
          left: size.width * _game.baHuyenX,
          top: groundY,
          child: Opacity(
            opacity: _game.metBaHuyen ? 0.5 : 1.0,
            child: SizedBox(
              width: npcScale,
              height: npcScale,
              child: CustomPaint(
                painter: _GameSpritePainter(
                  image: _baHuyenSpriteImage!,
                  col: _npcFrame,
                  row: 0, // idle row
                  columns: 4,
                  rows: 4,
                ),
              ),
            ),
          ),
        ));
      }
    }

    // Bà Năm - inside scene, before meeting
    if (_game.currentScene == GameScene.inside && !_game.metBaNam) {
      npcs.add(Positioned(
        left: size.width * 0.05,
        top: groundY,
        child: SizedBox(
          width: npcScale,
          height: npcScale,
          child: Image.asset('images/npc/ba_nam.png', fit: BoxFit.contain),
        ),
      ));
    }

    return Stack(children: npcs);
  }

  Widget _buildInteractionHints(Size size) {
    List<Widget> hints = [];

    // Door interaction
    if (_game.currentScene == GameScene.outside &&
        _game.gotKey &&
        _game.isNearDoor()) {
      hints.add(_buildHintBubble(
        size, 0.48, '🚪 Nhấn [E] để mở cửa', Colors.amber,
      ));
    }

    // Stairs interaction
    if (_game.currentScene == GameScene.inside &&
        _game.heardNoise &&
        _game.isNearStairs()) {
      hints.add(_buildHintBubble(
        size, 0.72, '⬆️ Nhấn [E] lên gác mái', Colors.red,
      ));
    }

    // Noise hint
    if (_showNoiseHint && _game.currentScene == GameScene.inside) {
      hints.add(Positioned(
        top: 40,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: const Text(
              '🔊 *tiếng loạt soạt từ gác mái*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ));
    }

    return Stack(children: hints);
  }

  Widget _buildHintBubble(Size size, double x, String text, Color color) {
    return Positioned(
      bottom: size.height * 0.35,
      left: size.width * x - 60,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildGhostFlash(Size size) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Opacity(
            opacity: 0.8,
            child: Image.asset(
              'images/npc/ghost.png',
              width: size.height * 0.6,
              height: size.height * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVignette() {
    double intensity = _game.currentScene == GameScene.attic ? 0.7 : 0.4;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(intensity),
                Colors.black.withOpacity(intensity + 0.3),
              ],
              stops: const [0.3, 0.75, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialog() {
    final dialogs = _game.getDialogsForScene();
    if (dialogs.isEmpty || _game.dialogIndex >= dialogs.length) {
      return const SizedBox.shrink();
    }
    final dialog = dialogs[_game.dialogIndex];

    return DialogWidget(
      key: ValueKey('${_game.currentScene}_${_game.dialogIndex}'),
      speaker: dialog.speaker,
      text: dialog.text,
      isNPC: dialog.isNPC,
      onComplete: () {},
      onTap: _advanceDialog,
    );
  }

  Widget _buildControls(Size size) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // D-pad (left side)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                // Left button
                GestureDetector(
                  onTapDown: (_) => _startMoving(true),
                  onTapUp: (_) => _stopMoving(),
                  onTapCancel: _stopMoving,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Icon(Icons.arrow_left,
                        color: Colors.white.withOpacity(0.4), size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                // Right button
                GestureDetector(
                  onTapDown: (_) => _startMoving(false),
                  onTapUp: (_) => _stopMoving(),
                  onTapCancel: _stopMoving,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Icon(Icons.arrow_right,
                        color: Colors.white.withOpacity(0.4), size: 32),
                  ),
                ),
              ],
            ),
          ),

          // Action button (right side)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: _handleInteract,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _canInteract()
                      ? Colors.amber.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _canInteract()
                        ? Colors.amber.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                    width: _canInteract() ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'E',
                    style: TextStyle(
                      color: _canInteract()
                          ? Colors.amber
                          : Colors.white.withOpacity(0.3),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canInteract() {
    if (_game.currentScene == GameScene.outside && _game.gotKey && _game.isNearDoor()) return true;
    if (_game.currentScene == GameScene.inside && _game.heardNoise && _game.isNearStairs()) return true;
    return false;
  }

  Widget _buildEndDemo(Size size) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _bgMusic.stop();
          Navigator.pushReplacementNamed(context, HomeGame.id);
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Diary icon
              const Text('📓', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 20),
              const Text(
                'Cuốn nhật ký bí ẩn...',
                style: TextStyle(
                  fontFamily: 'HorrorText',
                  fontSize: 28,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(blurRadius: 20, color: Color(0xFFcc0000)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"Ai đó đã sống ở đây... và chưa bao giờ rời đi..."',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HẾT DEMO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '[ Chạm để quay về ]',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sprite sheet painter - vẽ đúng 1 frame từ sprite sheet
class _GameSpritePainter extends CustomPainter {
  final ui.Image image;
  final int col;
  final int row;
  final int columns;
  final int rows;

  _GameSpritePainter({
    required this.image,
    required this.col,
    required this.row,
    required this.columns,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameW = image.width / columns;
    final frameH = image.height / rows;

    final srcRect = Rect.fromLTWH(
      col * frameW,
      row * frameH,
      frameW,
      frameH,
    );

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _GameSpritePainter oldDelegate) {
    return col != oldDelegate.col ||
        row != oldDelegate.row ||
        image != oldDelegate.image;
  }
}
