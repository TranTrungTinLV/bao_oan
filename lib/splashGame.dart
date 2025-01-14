import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bao_oan/HomeGame.dart';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashGame extends StatefulWidget {
  static String id = 'splash_game';

  SplashGame({super.key});

  @override
  State<SplashGame> createState() => _SplashGameState();
}

class _SplashGameState extends State<SplashGame> {
  late AudioPlayer _audioPlayer;
  late VideoPlayerController _videoPlayerController;
  bool _showSkipButton = false;
  late Timer _timer;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _audioPlayer = AudioPlayer();
    _videoPlayerController =
        VideoPlayerController.asset('assets/horro_intro.mp4');
    _playBackgroundMusic();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _playBackgroundMusic() async {
    await _audioPlayer.play(AssetSource('horror_music.mp3'));

    Duration audioDuration = (await _audioPlayer.getDuration())!;

    Future.delayed(audioDuration, _playVideo);
  }

  void _playVideo() async {
    await _videoPlayerController.initialize();
    _videoPlayerController.play();
    _videoPlayerController.setLooping(false);

    _videoPlayerController.addListener(() {
      if (!_videoPlayerController.value.isPlaying &&
          _videoPlayerController.value.isInitialized) {
        // Chuyển sang màn hình tiếp theo sau khi video kết thúc
        Navigator.pushReplacementNamed(context, HomeGame.id);
      }
    });

    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (_videoPlayerController.value.isInitialized) {
        final position = _videoPlayerController.value.position;
        if (position.inSeconds >= 10 && !_showSkipButton) {
          setState(() {
            _showSkipButton = true;
          });
        }
      }
    });

    setState(() {});
  }

  void _skipVideo() {
    _videoPlayerController.pause();
    Navigator.pushReplacementNamed(context, HomeGame.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('images/background.jpg'))),
            child: Center(
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText('Báo oán',
                      duration: Duration(milliseconds: 5000),
                      textStyle: TextStyle(
                          fontFamily: 'HorrorText',
                          fontSize: 60,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              offset: Offset(3, 3),
                            )
                          ],
                          color: Color(0xff03211c))),
                  ScaleAnimatedText("By Levi",
                      duration: Duration(milliseconds: 4000),
                      textStyle: TextStyle(fontSize: 30))
                ],
              ),
            ),
          ),
          if (_videoPlayerController.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              ),
            ),
          if (_showSkipButton)
            Positioned(
              bottom: 10,
              right: 90,
              child: ElevatedButton(
                onPressed: _skipVideo,
                child: Text('Bỏ qua'),
              ),
            )
        ],
      ),
    );
  }
}
