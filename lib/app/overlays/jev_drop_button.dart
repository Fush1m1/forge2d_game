import 'package:flutter/material.dart';
import 'package:forge2d_game/game/services/jev_assistant.dart';
import 'package:forge2d_game/game/suika_game.dart';

/// Button that asks Jev (https://typesafe.ai) to pick a lane for the next
/// ball and drops it there (issue #48). Shows a spinner while the request
/// is in flight and a SnackBar if it fails (e.g. missing/invalid API key).
class JevDropButton extends StatelessWidget {
  final SuikaGame game;

  const JevDropButton({super.key, required this.game});

  Future<void> _onPressed(BuildContext context) async {
    await game.requestJevDrop();
    if (!context.mounted) return;
    final result = game.jevAssistant.state.value;
    if (result.status == JevRequestStatus.error &&
        result.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<JevAssistantState>(
      valueListenable: game.jevAssistant.state,
      builder: (context, jevState, _) {
        final isLoading = jevState.status == JevRequestStatus.loading;
        return IconButton.filled(
          onPressed: isLoading ? null : () => _onPressed(context),
          icon:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.auto_awesome, size: 20),
          style: IconButton.styleFrom(elevation: 4, shadowColor: Colors.black),
        );
      },
    );
  }
}
