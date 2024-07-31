import 'package:flutter/material.dart';

class HomeGame extends StatefulWidget {
  static String id = 'home_game';
  const HomeGame({
    super.key,
  });

  @override
  State<HomeGame> createState() => _HomeGameState();
}

class _HomeGameState extends State<HomeGame> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Dự kiến cuối quý 4',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
