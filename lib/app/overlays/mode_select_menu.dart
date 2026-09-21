import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/model/game_mode.dart';
import 'package:forge2d_game/game/suika_game.dart';

class ModeSelectMenu extends StatelessWidget {
  final SuikaGame game;

  const ModeSelectMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Mid-play "New Game" opens this dialog on top of the current game
    // without touching it, so it can be dismissed by tapping outside. At
    // launch / after game over there is no game to return to, so it must
    // stay a mandatory choice.
    final canDismiss = game.session.isPlaying;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        decoration: BoxDecoration(
          color: AppTheme.overlayBackground.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: AppTheme.overlayBorder,
            width: AppTheme.borderWidth / 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Mode',
              style: TextStyle(
                color: AppTheme.titleText,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 36),

            // Normal Mode
            _ModeButton(
              label: 'Normal',
              icon: Icons.sports_esports,
              color: AppTheme.normalMode,
              description: 'Standard ball sizes',
              onTap: () => game.startGame(GameMode.normal),
            ),
            const SizedBox(height: 20),

            // Easy Mode
            _ModeButton(
              label: 'Easy',
              icon: Icons.sentiment_satisfied_alt,
              color: AppTheme.easyMode,
              description: 'Balls are half the size',
              onTap: () => game.startGame(GameMode.easy),
            ),
          ],
        ),
      ),
    );

    if (!canDismiss) {
      return Center(child: card);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.closeModeSelect,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Center(child: card),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: SizedBox(
              height: 60,
              width: 200,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
