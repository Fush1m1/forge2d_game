import 'package:flutter/material.dart';
import 'package:forge2d_game/game/model/game_mode.dart';
import 'package:forge2d_game/game/suika_game.dart';

const _deepViolet = Color(0xFF3D0080);

class ModeSelectMenu extends StatelessWidget {
  final SuikaGame game;

  const ModeSelectMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Mid-play "New Game" opens this dialog on top of the current game
    // without touching it, so it can be dismissed by tapping outside. At
    // launch / after game over there is no game to return to, so it must
    // stay a mandatory choice.
    final canDismiss = game.session.isPlaying;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.primary,
        elevation: 8,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SELECT MODE',
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(3, 3)),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Normal Mode
              _ModeButton(
                label: 'NORMAL',
                icon: Icons.sports_esports,
                color: _deepViolet,
                description: 'Standard ball sizes',
                onTap: () => game.startGame(GameMode.normal),
              ),
              const SizedBox(height: 20),

              // Easy Mode
              _ModeButton(
                label: 'EASY',
                icon: Icons.sentiment_satisfied_alt,
                color: _deepViolet,
                description: 'Balls are half the size',
                onTap: () => game.startGame(GameMode.easy),
              ),
            ],
          ),
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
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
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
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      elevation: 4,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 3),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SizedBox(
            height: 60,
            width: 200,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(color: Colors.black45, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
