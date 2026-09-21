import 'package:flutter/material.dart';
import 'package:forge2d_game/game/model/game_mode.dart';
import 'package:forge2d_game/game/model/stage.dart';
import 'package:forge2d_game/game/suika_game.dart';

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

    // Kept outside the StatefulBuilder below so it survives its rebuilds
    // (the same pattern as _JevPasswordDialog's errorText) without needing
    // a dedicated StatefulWidget/State pair just for this one selection.
    var selectedStage = Stage.classic;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.primary,
        elevation: 8,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SELECT MODE',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'STAGE',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final stage in Stage.values)
                        ChoiceChip(
                          label: Text(stage.label),
                          selected: selectedStage == stage,
                          selectedColor: colorScheme.primaryContainer,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color:
                                selectedStage == stage
                                    ? colorScheme.onPrimaryContainer
                                    : Colors.white,
                          ),
                          onSelected: (_) {
                            setState(() => selectedStage = stage);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Normal Mode
                  _ModeButton(
                    label: 'NORMAL',
                    icon: Icons.sports_esports,
                    color: colorScheme.primaryContainer,
                    onColor: colorScheme.onPrimaryContainer,
                    description: 'Standard ball sizes',
                    onTap: () => game.startGame(GameMode.normal, selectedStage),
                  ),
                  const SizedBox(height: 20),

                  // Easy Mode
                  _ModeButton(
                    label: 'EASY',
                    icon: Icons.sentiment_satisfied_alt,
                    color: colorScheme.primaryContainer,
                    onColor: colorScheme.onPrimaryContainer,
                    description: 'Balls are half the size',
                    onTap: () => game.startGame(GameMode.easy, selectedStage),
                  ),
                ],
              );
            },
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
  final Color onColor;
  final String description;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: color,
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
                Icon(icon, color: onColor, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(color: onColor),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: onColor.withValues(alpha: 0.7),
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
