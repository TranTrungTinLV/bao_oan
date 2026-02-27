import 'package:bao_oan/HomeGame.dart';
import 'package:bao_oan/play_game_screen.dart';
import 'package:bao_oan/splashGame.dart';
import 'package:bao_oan/trailer_fpv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Báo Oán',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SplashGame(),
      routes: {
        SplashGame.id: (context) => const SplashGame(),
        HomeGame.id: (context) => const HomeGame(),
        PlayGameScreen.id: (context) => const PlayGameScreen(),
        TrailerFPV.id: (context) => const TrailerFPV(),
      },
    );
  }
}
