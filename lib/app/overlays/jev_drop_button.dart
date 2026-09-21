import 'package:flutter/material.dart';
import 'package:forge2d_game/game/services/jev_assistant.dart';
import 'package:forge2d_game/game/suika_game.dart';

const _jevPassword = '20260922';

/// Button that asks Jev (https://typesafe.ai) to pick a lane for the next
/// ball and drops it there (issue #48). Gated behind a password prompt (to
/// avoid burning through Jev credits by accident); once entered correctly
/// it's remembered in [AppSettings] for the rest of that calendar day, then
/// asked again, since the password is meant to rotate daily. Shows a
/// spinner while the request is in flight and a SnackBar if it fails (e.g.
/// missing/invalid API key).
class JevDropButton extends StatelessWidget {
  final SuikaGame game;

  const JevDropButton({super.key, required this.game});

  Future<void> _onPressed(BuildContext context) async {
    if (!game.appSettings.state.value.isJevAuthenticatedToday) {
      final authenticated = await showDialog<bool>(
        context: context,
        builder: (_) => const _JevPasswordDialog(),
      );
      if (authenticated != true) return;
      await game.appSettings.markJevAuthenticatedToday();
      if (!context.mounted) return;
    }

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

class _JevPasswordDialog extends StatefulWidget {
  const _JevPasswordDialog();

  @override
  State<_JevPasswordDialog> createState() => _JevPasswordDialogState();
}

class _JevPasswordDialogState extends State<_JevPasswordDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  void _submit() {
    if (_controller.text == _jevPassword) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorText = 'パスワードが違います');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jevを使用'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'パスワード', errorText: _errorText),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
