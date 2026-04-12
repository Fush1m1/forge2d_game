import 'package:flutter/material.dart';
import 'package:forge2d_game/game.dart';

class CongratulationsMenu extends StatelessWidget {
  final SuikaGame game;

  const CongratulationsMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDE7).withValues(alpha: 0.9), // Soft Yellow
          borderRadius: BorderRadius.circular(40.0),
          border: Border.all(
            color: const Color(0xFFFFE082), // Amber
            width: 6.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations!',
              style: TextStyle(
                color: Color(0xFFF9A825), // Golden Yellow
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.white,
                    offset: Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: game.resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCA28), // Amber Yellow
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('New Game'),
            ),
          ],
        ),
      ),
    );
  }
}
