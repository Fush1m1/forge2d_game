import 'package:flutter/material.dart';
import 'package:forge2d_game/game/services/jev_assistant.dart';
import 'package:forge2d_game/game/suika_game.dart';

/// Today's Jev password. Given today as YYYYmmDD, this is
/// `${DD-1}${YYYY+2026}${mm+10}` — e.g. 2026-09-22 -> day 21, year 4052,
/// month 19 -> '21405219'. Derived from the device clock rather than
/// stored anywhere, so there's nothing secret to leak — the generation
/// rule itself is documented right here in source. This is just friction
/// against an accidental tap burning through Jev credits, not a real
/// access control.
// MEMO(fushimi): パスワード生成ロジックが露出していますが、これは単なるおもしろ機能のため、よしとしています。
String _todaysJevPassword() {
  final now = DateTime.now();
  final day = (now.day - 1).toString().padLeft(2, '0');
  final year = (now.year + 2026).toString().padLeft(4, '0');
  final month = (now.month + 10).toString().padLeft(2, '0');
  return '$day$year$month';
}

/// Button that asks Jev (https://typesafe.ai) to pick a lane for the next
/// ball and drops it there (issue #48). Gated behind a password prompt (to
/// avoid burning through Jev credits by accident); once entered correctly
/// it's remembered in [AppSettings] for the rest of that calendar day, then
/// asked again, since [_todaysJevPassword] changes every day. Shows a
/// spinner while the request is in flight and a SnackBar if it fails (e.g.
/// missing/invalid API key).
class JevDropButton extends StatelessWidget {
  final SuikaGame game;

  const JevDropButton({super.key, required this.game});

  Future<void> _onPressed(BuildContext context) async {
    if (!game.appSettings.state.value.isJevAuthenticatedToday) {
      final controller = TextEditingController();
      final authenticated = await showDialog<bool>(
        context: context,
        builder: (_) => _JevPasswordDialog(controller: controller),
      );
      controller.dispose();
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

/// Stateless by design: the controller is owned by the caller (so it can be
/// disposed alongside the showDialog await), and the inline error text is
/// held via [StatefulBuilder] instead of a dedicated StatefulWidget/State
/// pair — the closure below is only ever rebuilt by that StatefulBuilder's
/// own setState, so `errorText` safely persists across those rebuilds.
class _JevPasswordDialog extends StatelessWidget {
  const _JevPasswordDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    String? errorText;

    return StatefulBuilder(
      builder: (context, setState) {
        void submit() {
          if (controller.text == _todaysJevPassword()) {
            Navigator.of(context).pop(true);
          } else {
            setState(() => errorText = 'パスワードが違います');
          }
        }

        return AlertDialog(
          title: const Text('Jevを使用'),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'パスワード',
              errorText: errorText,
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(onPressed: submit, child: const Text('OK')),
          ],
        );
      },
    );
  }
}
