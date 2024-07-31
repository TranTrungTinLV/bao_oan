import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bao_oan/HomeGame.dart';

import 'package:flutter/material.dart';

class SplashGame extends StatefulWidget {
  static String id = 'splash_game';

  SplashGame({super.key});

  @override
  State<SplashGame> createState() => _SplashGameState();
}

class _SplashGameState extends State<SplashGame> {
  late AudioPlayer _audioPlayer;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playBackgroundMusic() async {
    // Sử dụng tệp âm thanh cục bộ, đặt file âm thanh trong thư mục assets và định nghĩa trong pubspec.yaml
    await _audioPlayer.play(AssetSource('horror_music.mp3'));

    Duration audioDuration = (await _audioPlayer.getDuration())!;

    Future.delayed(audioDuration, () {
      Navigator.pushReplacementNamed(context, HomeGame.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        // mainAxisAlignment: MainAxisAlignment.center,
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
          )
        ],
      ),
    );
  }
}
