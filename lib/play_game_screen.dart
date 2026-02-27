import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:bao_oan/HomeGame.dart';
import 'package:bao_oan/dialog_widget.dart';
import 'package:bao_oan/game_controller.dart';
import 'package:bao_oan/puzzle_mandala_widget.dart';
import 'package:bao_oan/puzzle_torn_paper_widget.dart';
import 'package:bao_oan/puzzle_betel_tray_widget.dart';
import 'package:bao_oan/puzzle_khmer_charm_widget.dart';
import 'package:bao_oan/puzzle_offering_ritual_widget.dart';
import 'package:bao_oan/puzzle_ghost_riddle_widget.dart';
import 'package:bao_oan/puzzle_diary_decode_widget.dart';
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
  late AudioPlayer _chantingPlayer;
  late AudioPlayer _cryPlayer;
  late AudioPlayer _heartbeatPlayer;
  late AudioPlayer _envSfxPlayer;
  late AudioPlayer _whisperPlayer;
  bool _musicStarted = false;
  bool _isHeartbeatPlaying = false;

  // Puzzles state
  bool _showMandala = false;
  bool _showTornPaper = false;
  bool _showBetelTray = false;
  bool _showOfferingRitual = false;
  bool _showDiaryDecode = false;
  bool _showGhostRiddle = false;
  bool _showKhmerCharm = false;

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
  bool _showFuneralIllusions = false;
  bool _showDiaryContent = false;
  bool _ghostsVisible = false; // Bóng ma đã xuất hiện chưa
  int _ghostFlickerCount = 0; // Số lần nhấp nháy
  Timer? _ghostFlickerTimer;
  double _jumpscareHeadY = -1.0; // Vị trí đầu người rơi (-1 = trên đỉnh, 0.3 = giữa mặt)

  // Scene-specific
  bool _doorOpening = false;

  // Sprite images (loaded via dart:ui for frame clipping)
  ui.Image? _normalSpriteImage;
  ui.Image? _flashlightSpriteImage;
  ui.Image? _baHuyenSpriteImage;
  static const int _spriteColumns = 8;
  static const int _spriteRows = 8;
  int _currentRow = 0; // 0=idle, 1=walk, 5=look around
  bool _flashlightOn = false;

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
    _chantingPlayer = AudioPlayer();
    _cryPlayer = AudioPlayer();
    _heartbeatPlayer = AudioPlayer();
    _envSfxPlayer = AudioPlayer();
    _whisperPlayer = AudioPlayer();
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
        await _bgMusic.setVolume(0.3); // Giảm âm lượng nhạc nền xuống chút xíu
        await _bgMusic.setReleaseMode(ReleaseMode.loop);
        await _bgMusic.play(AssetSource('horror_music_main.mp3'));
        debugPrint('BG Music started successfully');
      } catch (e) {
        debugPrint('Error playing bg music: $e');
      }

      // Phát thêm tiếng gió rít nếu ở ngoài
      if (_game.currentScene == GameScene.outside) {
        _envSfxPlayer.setReleaseMode(ReleaseMode.loop);
        _envSfxPlayer.play(AssetSource('wind_howl.mp3'));
        _envSfxPlayer.setVolume(0.5);
      }
    }
  }

  void _checkHeartbeat() {
    if (_game.sanityLevel <= 0.6) {
      if (!_isHeartbeatPlaying) {
        _isHeartbeatPlaying = true;
        _heartbeatPlayer.setReleaseMode(ReleaseMode.loop);
        _heartbeatPlayer.play(AssetSource('heartbeat.mp3'));
        _heartbeatPlayer.setVolume(1.0);
      }
    } else {
      if (_isHeartbeatPlaying) {
        _isHeartbeatPlaying = false;
        _heartbeatPlayer.stop();
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

    // Xử lý nhạc nền (Ambient) theo Scene
    if (scene == GameScene.outside) {
      _envSfxPlayer.setReleaseMode(ReleaseMode.loop);
      _envSfxPlayer.play(AssetSource('wind_howl.mp3'));
      _envSfxPlayer.setVolume(0.5);
    } else if (scene == GameScene.attic) {
      _envSfxPlayer.setReleaseMode(ReleaseMode.loop);
      _envSfxPlayer.play(AssetSource('creaking_light.mp3'));
      _envSfxPlayer.setVolume(0.2);
    } else {
      _envSfxPlayer.stop();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _isTransitioning = false;

    // Auto-trigger events
    _triggerSceneEvent(scene);
  }

  void _triggerSceneEvent(GameScene scene) {
    if (_game.isPowerOff && scene == GameScene.inside) {
      _bgMusic.stop(); // Tắt nhạc nền cũ
      if (_chantingPlayer.state != PlayerState.playing) {
        _chantingPlayer.setReleaseMode(ReleaseMode.loop);
        _chantingPlayer.play(AssetSource('chanting_nam_mo.mp3'));
        _chantingPlayer.setVolume(0.5);
      }
      if (_cryPlayer.state != PlayerState.playing) {
        _cryPlayer.setReleaseMode(ReleaseMode.loop);
        _cryPlayer.play(AssetSource('funeral_cry_hollow.mp3'));
        _cryPlayer.setVolume(0.5);
      }
      _lightsOff = true;
      _flashlightOn = true;
      _showFuneralIllusions = true;
    } else if (scene != GameScene.inside || !_game.isPowerOff) {
      _chantingPlayer.stop();
      _cryPlayer.stop();
      _showFuneralIllusions = false;
    }

    switch (scene) {
      case GameScene.inside:
        if (!_game.wentToSleep) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _game.getDialogsForScene().isNotEmpty) {
              setState(() {
                _game.isDialogActive = true;
                _game.dialogIndex = 0;
              });
            }
          });
        } else if (!_game.heardNoise1 && _game.foundOldItems) {
          // Trigger noise after a delay
          _noiseTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) {
              _sfxPlayer.play(AssetSource('scratching.mp3'));
              _sfxPlayer.setVolume(0.6);
              setState(() {
                _game.heardNoise1 = true;
                _shakeX = 2;
                _shakeY = 1;
                _showNoiseHint = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted)
                  setState(() {
                    _shakeX = 0;
                    _shakeY = 0;
                  });
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
        if (_game.visitedAtticFirstTime && !_game.heardNoise2) {
          // Lần đầu lên kiếm chuột (vẫn còn điện, chỉ thấy vết ố)
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _game.getDialogsForScene().isNotEmpty) {
              setState(() {
                _game.isDialogActive = true;
                _game.dialogIndex = 0;
              });
            }
          });
        } else if (!_game.wentToAttic && _game.heardNoise2) {
          // Lần 2 lên mới thực sự gặp ma và bị nhốt (cúp điện)
          _game.wentToAttic = true;
          _lightsOff = true;
          _sfxPlayer.play(AssetSource('light_flicker.mp3'));
          _sfxPlayer.setVolume(0.5);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _game.isPowerOff = true;
                if (_game.getDialogsForScene().isNotEmpty) {
                  _game.isDialogActive = true;
                  _game.dialogIndex = 0;
                }
              });
            }
          });
        } else {
          // Trở lại gác mái các lần sau
          _lightsOff = _game.isPowerOff;
        }
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
      case GameScene.inside:
        if (!_game.wentToSleep) {
          _game.wentToSleep = true;
          _startSleepingEvent();
        } else if (_game.wentToSleep &&
            _game.isPowerOff &&
            !_game.lookedInMirror) {
          // Xong thoại giật mình 3h15 sáng -> đợi người chơi điều khiển đi soi gương
        } else if (_game.lookedInMirror && !_game.morningArrived) {
          _game.morningArrived = true;
          // Kéo bọc rác ra ngoài đụng Bà Năm
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted)
              setState(() {
                _game.isDialogActive = true;
                _game.dialogIndex = 0;
              });
          });
        } else if (_game.morningArrived && !_game.metBaNam) {
          setState(() {
            _game.metBaNam = true;
          });
          // Bà Năm nói cúng kiến → Bắt buộc làm nghi thức cúng
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !_game.solvedOffering) {
              setState(() => _showOfferingRitual = true);
            }
          });
        } else if (_game.foundOldItems && !_game.heardNoise1) {
          // Sau khi nhặt được mớ đồ cũ -> Trigger tiếng chuột lần 1
          _noiseTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              try {
                _sfxPlayer.play(AssetSource('scratching.mp3'));
                _sfxPlayer.setVolume(0.4);
              } catch (_) {}
              setState(() {
                _game.heardNoise1 = true;
                _showNoiseHint = true;
              });
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted)
                  setState(() {
                    _game.isDialogActive = true;
                    _game.dialogIndex = 0;
                  });
              });
            }
          });
        } else if (_game.visitedAtticFirstTime && !_game.heardNoise2) {
          // Sau khi lên gác bị lừa, xuống Sofa lại -> Tiếng động 2 dồn dập
          _noiseTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              try {
                _sfxPlayer.play(AssetSource('scratching.mp3'));
                _sfxPlayer.setVolume(1.0);
              } catch (_) {} // Dồn dập
              setState(() {
                _game.heardNoise2 = true;
                _shakeX = 5;
                _shakeY = 3;
                _showNoiseHint = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted)
                  setState(() {
                    _shakeX = 0;
                    _shakeY = 0;
                  });
              });
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted)
                  setState(() {
                    _game.isDialogActive = true;
                    _game.dialogIndex = 0;
                  });
              });
            }
          });
        }
        break;
      case GameScene.attic:
      if (!_game.foundDiary && !_game.solvedMandala && _game.wentToAttic) {
        // Bước 1: Câu đố ma xuất hiện khi vào gác mái
        if (!_game.solvedGhostRiddle) {
          setState(() => _showGhostRiddle = true);
        } else {
          // Bước 2: Giải đố ma xong → Mandala
          setState(() {
            _game.foundDiary = true;
            _showMandala = true;
          });
        }
      }
      break;
      default:
        break;
    }
  }

  void _onMandalaSolved() {
    setState(() {
      _showMandala = false;
      _game.solvedMandala = true;
    });
    _sfxPlayer.play(AssetSource('paper_rustle.mp3'));

    // Sau mandala → Bùa Khơ Me bắt buộc
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_game.solvedKhmerCharm) {
        setState(() => _showKhmerCharm = true);
      } else {
        setState(() => _showDiaryContent = true);
      }
    });
  }

  void _onTornPaperSolved() {
    setState(() {
      _showTornPaper = false;
      _game.solvedTornPaper = true;
    });
    // Giải xong bùa rách vào buổi sáng -> Thức dậy buổi sáng
    _wakeUpMorningEvent();
  }

  void _startSleepingEvent() async {
    setState(() => _isTransitioning = true);
    setState(() => _fadeOpacity = 1.0);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    _envSfxPlayer.setReleaseMode(ReleaseMode.loop);
    _envSfxPlayer.play(AssetSource('wind_howl.mp3'));

    await Future.delayed(const Duration(seconds: 3)); // Ngủ 3 giây

    // Tỉnh dậy 3h15 AM - Cúp điện
    _bgMusic.stop();
    setState(() {
      _game.isPowerOff = true;
      _lightsOff = true;
      _flashlightOn = true;
      _showFuneralIllusions = true; // Hiện quan tài trước
      _ghostsVisible = false; // Bóng ma chưa hiện
    });

    setState(() => _fadeOpacity = 0.0);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isTransitioning = false);

    // --- Kiên giật mình thấy quan tài ---
    setState(() { _shakeX = 15; _shakeY = 10; });
    try { _sfxPlayer.play(AssetSource('jumpscare_mirror.mp3')); _sfxPlayer.setVolume(0.6); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() { _shakeX = 0; _shakeY = 0; });

    // --- Bắt đầu nhấp nháy bóng ma + tiếng xì xào nhỏ ---
    try {
      _whisperPlayer.setReleaseMode(ReleaseMode.loop);
      _whisperPlayer.play(AssetSource('whisper_crowd.mp3'));
      _whisperPlayer.setVolume(0.15); // Nhỏ nhỏ lúc đầu
    } catch (_) {}
    _ghostFlickerCount = 0;
    _ghostFlickerTimer?.cancel();
    _ghostFlickerTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) { timer.cancel(); return; }
      _ghostFlickerCount++;
      setState(() => _ghostsVisible = !_ghostsVisible);
      if (_ghostFlickerCount >= 8) {
        // Sau 8 lần nhấp nháy (khoảng 2.4 giây) -> Hiện cố định
        timer.cancel();
        setState(() => _ghostsVisible = true);
        // Tăng tiếng xì xào và bật nhạc đám tang
        try { _whisperPlayer.setVolume(0.5); } catch (_) {}
        _chantingPlayer.setReleaseMode(ReleaseMode.loop);
        _chantingPlayer.play(AssetSource('chanting_nam_mo.mp3'));
        _chantingPlayer.setVolume(0.5);
        _cryPlayer.setReleaseMode(ReleaseMode.loop);
        _cryPlayer.play(AssetSource('funeral_cry_hollow.mp3'));
        _cryPlayer.setVolume(0.5);
        // Bật thoại Kiên hoảng loạn
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() {
            _game.isDialogActive = true;
            _game.dialogIndex = 0;
          });
        });
      }
    });
  }

  void _wakeUpMorningEvent() async {
    setState(() => _isTransitioning = true);
    setState(() => _fadeOpacity = 1.0);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    _chantingPlayer.stop();
    _cryPlayer.stop();
    _whisperPlayer.stop();
    _bgMusic.play(AssetSource('horror_music_main.mp3'));

    setState(() {
      _game.isPowerOff = false;
      _lightsOff = false;
      _flashlightOn = false;
      _showFuneralIllusions = false;
    });

    setState(() => _fadeOpacity = 0.0);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isTransitioning = false);

    if (mounted && _game.getDialogsForScene().isNotEmpty) {
      setState(() {
        _game.isDialogActive = true;
        _game.dialogIndex = 0;
      });
    }
  }

  void _onBetelTraySolved() {
    setState(() {
      _showBetelTray = false;
      _game.solvedBetelTray = true;
    });
    _transitionToScene(GameScene.endDemo);
  }

  // ═══ NEW PUZZLE HANDLERS ═══
  void _onOfferingRitualSolved() {
    setState(() {
      _showOfferingRitual = false;
      _game.solvedOffering = true;
    });
    _sfxPlayer.play(AssetSource('wind_howl.mp3'));
    _sfxPlayer.setVolume(0.3);
  }

  void _onDiaryDecodeSolved() {
    setState(() {
      _showDiaryDecode = false;
      _game.solvedDiaryDecode = true;
      _showDiaryContent = true;
    });
    _sfxPlayer.play(AssetSource('paper_rustle.mp3'));
  }

  void _onGhostRiddleSolved() {
    setState(() {
      _showGhostRiddle = false;
      _game.solvedGhostRiddle = true;
    });
    _sfxPlayer.play(AssetSource('scratching.mp3'));
    _sfxPlayer.setVolume(0.4);

    // Giải đố ma xong → Mandala tiếp
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _game.foundDiary = true;
          _showMandala = true;
        });
      }
    });
  }

  void _onKhmerCharmSolved() {
    setState(() {
      _showKhmerCharm = false;
      _game.solvedKhmerCharm = true;
      _showDiaryContent = true; // Hiện thư con ma sau khi giải bùa
    });
    _sfxPlayer.play(AssetSource('chanting_nam_mo.mp3'));
    _sfxPlayer.setVolume(0.4);
  }

  // ═══ BẮT BUỘC LÀM LẠI PUZZLE KHI BỎ QUA ═══
  // Kiên tự nói chuyện với chính mình rồi buộc làm lại
  void _forceRetryPuzzle(String selfDialog, VoidCallback reshow, VoidCallback hide) {
    // Ẩn puzzle tạm
    hide();

    // Hiện self-dialog kiểu Kiên tự nhủ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('💭 ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                selfDialog,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1a0500),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red[900]!.withOpacity(0.5)),
        ),
      ),
    );

    // Sau 3 giây → re-show puzzle bắt buộc
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        reshow();
      }
    });
  }

  void _triggerGhostFlash() async {
    _sfxPlayer.play(AssetSource('jumpscare_mirror.mp3'));
    _sfxPlayer.setVolume(1.0);
    _envSfxPlayer.play(AssetSource('glitch_sound.mp3'));
    _envSfxPlayer.setVolume(0.5);

    // Bắt đầu: đầu ở trên đỉnh
    setState(() {
      _showGhostFlash = true;
      _jumpscareHeadY = -1.0;
      _shakeX = 0;
      _shakeY = 0;
    });

    // Animation rơi xuống trong 300ms (10 bước)
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() {
        _jumpscareHeadY = -1.0 + (1.3 * i / 10); // Từ -1.0 đến 0.3
      });
    }

    // Đập vào mặt! Shake cực mạnh + máu loang
    setState(() {
      _shakeX = 40;
      _shakeY = 40;
      _game.sanityLevel -= 0.3;
      _checkHeartbeat();
    });

    // Nhấp nháy vài lần
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _shakeX = (i % 2 == 0) ? 35 : -35;
        _shakeY = (i % 2 == 0) ? 25 : -25;
      });
    }

    // Kết thúc jumpscare
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _showGhostFlash = false;
        _shakeX = 0;
        _shakeY = 0;
        _jumpscareHeadY = -1.0;
      });
    }
  }

  void _startMoving(bool left) {
    if (_game.isDialogActive ||
        _isTransitioning ||
        _showMandala ||
        _showTornPaper ||
        _showBetelTray) return;
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
    if (_game.isDialogActive ||
        _isTransitioning ||
        _showMandala ||
        _showTornPaper ||
        _showBetelTray ||
        _showOfferingRitual ||
        _showDiaryDecode ||
        _showGhostRiddle ||
        _showKhmerCharm) return;

    if (_game.currentScene == GameScene.outside &&
        _game.isNearDoor() &&
        _game.gotKey) {
      _sfxPlayer.play(AssetSource('creak_door.mp3'));
      _game.enteredHouse = true;
      _transitionToScene(GameScene.inside);
    } else if (_game.currentScene == GameScene.inside &&
        _game.isNearSofa() &&
        _game.metBaNam &&
        !_game.foundOldItems) {
      _game.foundOldItems = true;
      _game.isDialogActive = true;
      _game.dialogIndex = 0;
      setState(() {});
      // Sau dialog nhặt đồ cũ → Hiện puzzle giải mã nhật ký
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_game.solvedDiaryDecode) {
          setState(() => _showDiaryDecode = true);
        }
      });
    } else if (_game.currentScene == GameScene.inside &&
        _game.isNearStairs() &&
        _game.heardNoise1 &&
        !_game.visitedAtticFirstTime) {
      _sfxPlayer.play(AssetSource('footsteps_gravel.mp3'));
      _game.visitedAtticFirstTime = true;
      _transitionToScene(GameScene.attic);
    } else if (_game.currentScene == GameScene.inside &&
        _game.isNearStairs() &&
        _game.heardNoise2 &&
        !_game.wentToAttic) {
      _sfxPlayer.play(AssetSource('footsteps_gravel.mp3'));
      _transitionToScene(GameScene.attic);
    } else if (_game.currentScene == GameScene.attic && _game.playerX < 0.2) {
      // Xuống nhà
      _sfxPlayer.play(AssetSource('footsteps_gravel.mp3'));

      // Nếu là đang xuống nhà Lần 1 sau vụ bóng ố vàng
      if (_game.visitedAtticFirstTime && !_game.heardNoise2) {
        _game.isDialogActive = true;
        _game.dialogIndex = 0;
      }

      _transitionToScene(GameScene.inside);
    } else if (_game.currentScene == GameScene.inside &&
        _game.isPowerOff &&
        _game.isNearMirror() &&
        !_game.lookedInMirror) {
      _triggerGhostFlash();
      _game.lookedInMirror = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showTornPaper = true);
      });
    } else if (_game.currentScene == GameScene.inside &&
        _game.solvedTornPaper &&
        _game.isNearSofa() &&
        !_game.solvedBetelTray) {
      setState(() => _showBetelTray = true);
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _ghostController.dispose();
    _moveTimer?.cancel();
    _walkAnimTimer?.cancel();
    _noiseTimer?.cancel();
    _ghostFlickerTimer?.cancel();
    _npcAnimTimer?.cancel();
    _whisperPlayer.stop();
    _whisperPlayer.dispose();
    _bgMusic.stop();
    _bgMusic.dispose();
    _sfxPlayer.stop();
    _sfxPlayer.dispose();
    _sfxPlayer2.stop();
    _sfxPlayer2.dispose();
    _chantingPlayer.stop();
    _chantingPlayer.dispose();
    _cryPlayer.stop();
    _cryPlayer.dispose();

    _heartbeatPlayer.stop();
    _heartbeatPlayer.dispose();
    _envSfxPlayer.stop();
    _envSfxPlayer.dispose();
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

            // Funeral Illusions (Ghosts)
            if (_showFuneralIllusions) _buildFuneralIllusions(size),

            // Interaction hints
            _buildInteractionHints(size),

            // Ghost flash
            if (_showGhostFlash) _buildGhostFlash(size),

            // Vignette
            _buildVignette(),

            // Dialog
            if (_game.isDialogActive) _buildDialog(),

            // Puzzles Overlay class components
            if (_showMandala)
              Positioned.fill(
                child: PuzzleMandalaWidget(
                  onSolved: _onMandalaSolved,
                  onClose: () => setState(() => _showMandala = false),
                ),
              ),
            if (_showDiaryContent)
              Positioned.fill(
                child: _buildDiaryContent(),
              ),
            if (_showTornPaper)
              Positioned.fill(
                child: PuzzleTornPaperWidget(
                  onSolved: _onTornPaperSolved,
                  onClose: () => setState(() => _showTornPaper = false),
                ),
              ),
            if (_showBetelTray)
              Positioned.fill(
                child: PuzzleBetelTrayWidget(
                  onSolved: _onBetelTraySolved,
                  onClose: () => setState(() => _showBetelTray = false),
                ),
              ),

            // ═══ NEW PUZZLES ═══
            if (_showOfferingRitual)
              Positioned.fill(
                child: PuzzleOfferingRitualWidget(
                  onSolved: _onOfferingRitualSolved,
                  onClose: () => _forceRetryPuzzle(
                    'Không được... bà Năm nói phải cúng kiến mới yên. Mình phải làm lại!',
                    () => setState(() => _showOfferingRitual = true),
                    () => setState(() => _showOfferingRitual = false),
                  ),
                ),
              ),
            if (_showDiaryDecode)
              Positioned.fill(
                child: PuzzleDiaryDecodeWidget(
                  onSolved: _onDiaryDecodeSolved,
                  onClose: () => _forceRetryPuzzle(
                    'Cuốn nhật ký này... có gì đó bất thường. Mình phải đọc cho hết!',
                    () => setState(() => _showDiaryDecode = true),
                    () => setState(() => _showDiaryDecode = false),
                  ),
                ),
              ),
            if (_showGhostRiddle)
              Positioned.fill(
                child: PuzzleGhostRiddleWidget(
                  onSolved: _onGhostRiddleSolved,
                  onClose: () => _forceRetryPuzzle(
                    'Tiếng thì thào vẫn vang vọng... Mình không thể bỏ qua được!',
                    () => setState(() => _showGhostRiddle = true),
                    () => setState(() => _showGhostRiddle = false),
                  ),
                ),
              ),
            if (_showKhmerCharm)
              Positioned.fill(
                child: PuzzleKhmerCharmWidget(
                  onSolved: _onKhmerCharmSolved,
                  onClose: () => _forceRetryPuzzle(
                    'Lá bùa này đang phát ra ánh sáng lạ... Mình phải giải trừ nó!',
                    () => setState(() => _showKhmerCharm = true),
                    () => setState(() => _showKhmerCharm = false),
                  ),
                ),
              ),

            // Controls
            if (!_game.isDialogActive &&
                !_showMandala &&
                !_showTornPaper &&
                !_showBetelTray &&
                !_showOfferingRitual &&
                !_showDiaryDecode &&
                !_showGhostRiddle &&
                !_showKhmerCharm)
              _buildControls(size),

            // Sanity Bar
            if (_game.currentScene != GameScene.outside)
              Positioned(
                top: 16,
                left: 100,
                child: _buildSanityBar(),
              ),

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Text('Thoát',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildSanityBar() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tinh Thần',
              style: TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _game.sanityLevel.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
              minHeight: 8,
            ),
          ),
        ],
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
    _normalSpriteImage =
        await _loadImage('images/character/png sheet/normal.png');
    _flashlightSpriteImage =
        await _loadImage('images/character/png sheet/with_flashlight.png');
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
    final spriteImage = (_game.currentScene == GameScene.attic && _flashlightOn)
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

    // Bà Năm - inside scene, chỉ xuất hiện Ngày 2 (sau khi morningArrived)
    if (_game.currentScene == GameScene.inside && _game.morningArrived && !_game.metBaNam) {
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
        size,
        0.48,
        '🚪 Nhấn [E] để mở cửa',
        Colors.amber,
      ));
    }

    // Bà Năm interaction (chỉ Ngày 2)
    if (_game.currentScene == GameScene.inside &&
        _game.morningArrived &&
        _game.isNearBaNam() &&
        !_game.metBaNam) {
      hints.add(_buildHintBubble(
        size,
        _game.baNamX,
        '[E] Nói chuyện',
        Colors.blue,
      ));
    }

    // Sofa interaction (Nhặt thẻ Sinh viên)
    if (_game.currentScene == GameScene.inside &&
        _game.metBaNam &&
        !_game.foundOldItems &&
        _game.isNearSofa()) {
      hints.add(_buildHintBubble(
        size,
        0.25,
        '🔍 Nhấn [E] để xem đồ cũ',
        Colors.yellow,
      ));
    }

    // Stairs interaction
    if (_game.currentScene == GameScene.inside &&
        _game.heardNoise1 &&
        _game.isNearStairs()) {
      hints.add(_buildHintBubble(
        size,
        0.72,
        '⬆️ Nhấn [E] lên gác mái',
        Colors.red,
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
    // Tính scale: càng gần mặt càng to (phóng to từ 0.5 lên 3.0)
    double progress = ((_jumpscareHeadY + 1.0) / 1.3).clamp(0.0, 1.0);
    double headScale = 0.5 + progress * 2.5;
    double bloodOpacity = (progress * 0.7).clamp(0.0, 0.7);

    return Positioned.fill(
      child: Stack(
        children: [
          // Màn máu đỏ loang dần
          Container(
            color: Colors.red.withOpacity(bloodOpacity),
          ),
          // Đầu người rơi xuống
          Positioned(
            top: size.height * _jumpscareHeadY,
            left: (size.width - size.width * 0.5) / 2,
            child: Transform.scale(
              scale: headScale,
              child: SizedBox(
                width: size.width * 0.5,
                height: size.width * 0.5,
                child: Image.asset(
                  'assets/jumpscare_head.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Vết máu bắn tung toé khi chạm mặt
          if (progress > 0.9)
            Positioned.fill(
              child: CustomPaint(
                painter: _BloodSplatterPainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVignette() {
    double intensity = 0.4;
    if (_game.currentScene == GameScene.attic) {
      intensity =
          _flashlightOn ? 0.7 : 0.95; // Almost pitch black without flashlight
    } else if (_game.currentScene == GameScene.inside && _lightsOff) {
      intensity = 0.8;
    }
    final double o1 = intensity.clamp(0.0, 1.0).toDouble();
    final double o2 = (intensity + 0.3).clamp(0.0, 1.0).toDouble();
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(o1),
                Colors.black.withOpacity(o2),
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
            child: Row(
              children: [
                // Flashlight toggle button (only in attic)
                if (_game.currentScene == GameScene.attic)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _flashlightOn = !_flashlightOn;
                      });
                      _sfxPlayer
                          .play(AssetSource('switch.mp3')); // generic sound
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _flashlightOn
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _flashlightOn
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white.withOpacity(0.15)),
                      ),
                      child: Icon(
                        _flashlightOn
                            ? Icons.highlight
                            : Icons.highlight_outlined,
                        color: _flashlightOn
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        size: 32,
                      ),
                    ),
                  ),

                // Interact / Action button
                GestureDetector(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canInteract() {
    if (_game.currentScene == GameScene.outside &&
        _game.gotKey &&
        _game.isNearDoor()) return true;
    if (_game.currentScene == GameScene.inside &&
        _game.metBaNam &&
        !_game.foundOldItems &&
        _game.isNearSofa()) return true;
    if (_game.currentScene == GameScene.inside &&
        _game.heardNoise1 &&
        _game.isNearStairs()) return true;
    if (_game.currentScene == GameScene.attic && _game.playerX < 0.2)
      return true; // Cầu thang xuống
    if (_game.currentScene == GameScene.inside &&
        _game.isPowerOff &&
        _game.isNearMirror() &&
        !_game.lookedInMirror) return true;
    if (_game.currentScene == GameScene.inside &&
        _game.solvedTornPaper &&
        _game.isNearSofa() &&
        !_game.solvedBetelTray) return true;
    if (_game.currentScene == GameScene.outside &&
        _game.isNearBaHuyen() &&
        !_game.metBaHuyen) return true;
    if (_game.currentScene == GameScene.inside &&
        _game.morningArrived &&
        _game.isNearBaNam() &&
        !_game.metBaNam) return true;
    if (_game.currentScene == GameScene.attic &&
        _game.isNearDiary() &&
        !_game.foundDiary &&
        _game.wentToAttic) return true;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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

  Widget _buildDiaryContent() {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            border: Border.all(color: Colors.brown[800]!, width: 4),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Trang cuối...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mưa dột nhiều ngày liền...\nBà chủ đòi tăng tiền phòng...\nCăn nhà 403 này thật ngột ngạt.\nTôi muốn thoát khỏi đây...\nNhưng có ai đó đang giam giữ tôi ở sau mảng tường này...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                  fontFamily: 'HorrorText',
                  color: Colors.red, // Viết bằng máu
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showDiaryContent = false;
                  });
                },
                child: const Text(
                  '[Đóng sổ]',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuneralIllusions(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Lớp sương mù đỏ bao phủ
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, 0.3),
                    radius: 0.8,
                    colors: [
                      Colors.red.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // === QUAN TÀI (Dùng hình PNG thật) ===
            Positioned(
              left: size.width * 0.25,
              bottom: size.height * 0.18,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.15),
                      blurRadius: 60,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/coffin_funeral.png',
                  width: size.width * 0.35,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.85),
                ),
              ),
            ),

            // === BÁT NHANG + 3 CÂY NHANG ===
            Positioned(
              left: size.width * 0.38,
              bottom: size.height * 0.36,
              child: Column(
                children: [
                  // Khói nhang mờ ảo
                  Container(
                    width: 20,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Bát nhang
                  Container(
                    width: 32,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.orange[900],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (_) => Container(
                        width: 2,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          boxShadow: [
                            BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 6, spreadRadius: 1),
                          ],
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),

            // === ẢNH THỜ ===
            Positioned(
              left: size.width * 0.39,
              bottom: size.height * 0.42,
              child: Container(
                width: 28,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  color: Colors.white12,
                  boxShadow: [
                    BoxShadow(color: Colors.yellow.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: Icon(Icons.person, color: Colors.black.withOpacity(0.4), size: 20),
              ),
            ),

            // === 2 CÂY NẾN 2 BÊN ===
            _buildCandle(size, 0.22, 0.30),
            _buildCandle(size, 0.55, 0.30),

            // === BÓNG MA (CHỈ HIỆN KHI _ghostsVisible) ===
            if (_ghostsVisible) ...[
              // Ảnh nhóm 6 người phía sau quan tài (hoạt ảnh chính)
              Positioned(
                left: size.width * 0.10,
                bottom: size.height * 0.20,
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    'assets/ghost_silhouette.png',
                    width: size.width * 0.65,
                    fit: BoxFit.contain,
                    color: Colors.black.withOpacity(0.8),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
              ),
              // Bóng đơn lẻ rải thêm 2 bên tạo chiều sâu
              _buildGhostSilhouette(size, 0.0, 0.16, 100, 0.4),
              _buildGhostSilhouette(size, 0.78, 0.18, 90, 0.5, flip: true),
              _buildGhostSilhouette(size, 0.88, 0.14, 70, 0.25),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCandle(Size size, double xPercent, double bottomPercent) {
    return Positioned(
      left: size.width * xPercent,
      bottom: size.height * bottomPercent,
      child: Column(
        children: [
          // Ngọn lửa
          Container(
            width: 6,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(color: Colors.yellow.withOpacity(0.6), blurRadius: 12, spreadRadius: 4),
                BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20, spreadRadius: 6),
              ],
            ),
          ),
          // Thân nến
          Container(
            width: 4,
            height: 20,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildGhostSilhouette(Size size, double xPercent, double bottomPercent, double heightSize, double opacity, {bool flip = false}) {
    return Positioned(
      left: size.width * xPercent,
      bottom: size.height * bottomPercent,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(flip ? -1.0 : 1.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 25, spreadRadius: 5),
              ],
            ),
            child: Image.asset(
              'assets/ghost_single.png',
              height: heightSize,
              fit: BoxFit.contain,
              color: Colors.black.withOpacity(0.85),
              colorBlendMode: BlendMode.srcATop,
            ),
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
    if (columns <= 0 || rows <= 0 || image.width <= 0 || image.height <= 0)
      return;
    if (size.width <= 0 || size.height <= 0) return;

    final int safeColumns = columns <= 0 ? 1 : columns;
    final int safeRows = rows <= 0 ? 1 : rows;

    final double frameW = image.width / safeColumns;
    final double frameH = image.height / safeRows;

    int safeCol = col;
    int safeRow = row;
    if (safeCol < 0) safeCol = 0;
    if (safeRow < 0) safeRow = 0;
    if (safeCol >= safeColumns) safeCol = safeColumns - 1;
    if (safeRow >= safeRows) safeRow = safeRows - 1;

    double srcX = safeCol * frameW;
    double srcY = safeRow * frameH;

    // Clamp X and Y to not exceed image dimensions
    if (srcX < 0) srcX = 0;
    if (srcY < 0) srcY = 0;
    if (srcX >= image.width)
      srcX = (image.width - frameW).clamp(0.0, image.width.toDouble());
    if (srcY >= image.height)
      srcY = (image.height - frameH).clamp(0.0, image.height.toDouble());

    // Adjust width and height so we never read out of bounds (floating point imprecision)
    double srcW = frameW;
    double srcH = frameH;
    if (srcX + srcW > image.width) srcW = image.width - srcX;
    if (srcY + srcH > image.height) srcH = image.height - srcY;

    if (srcW <= 0 || srcH <= 0) return;

    final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (srcRect.isEmpty ||
        !srcRect.isFinite ||
        dstRect.isEmpty ||
        !dstRect.isFinite) return;

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _GameSpritePainter oldDelegate) {
    return col != oldDelegate.col ||
        row != oldDelegate.row ||
        image != oldDelegate.image;
  }
}

// Vẽ vết máu bắn tung toé khi đầu đập vào mặt
class _BloodSplatterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Seed cố định cho vệt máu không nhảy lung tung

    // Vẽ 15 vệt máu bắn random
    for (int i = 0; i < 15; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = 5 + random.nextDouble() * 25;

      paint.color = Colors.red.withOpacity(0.4 + random.nextDouble() * 0.5);
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Vệt máu chảy dài xuống
      final drip = Path()
        ..moveTo(x - radius * 0.3, y)
        ..lineTo(x + radius * 0.3, y)
        ..lineTo(x + radius * 0.1, y + radius * 2 + random.nextDouble() * 40)
        ..lineTo(x - radius * 0.1, y + radius * 2 + random.nextDouble() * 40)
        ..close();
      canvas.drawPath(drip, paint);
    }

    // Vệt máu lớn ở giữa (nơi đầu đập vào)
    paint.color = Colors.red.withOpacity(0.6);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35), 60, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
