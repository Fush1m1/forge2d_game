import 'package:flutter/material.dart';
import 'package:forge2d_game/game/model/game_mode.dart';
import 'package:forge2d_game/game/services/passkey_account.dart';
import 'package:forge2d_game/game/suika_game.dart';

/// Passkey sign-up / sign-in, and the signed-in player's best level per
/// mode. Opens as a peek overlay from the settings menu; tapping outside
/// dismisses it back to settings.
class AccountMenu extends StatefulWidget {
  final SuikaGame game;

  const AccountMenu({super.key, required this.game});

  @override
  State<AccountMenu> createState() => _AccountMenuState();
}

class _AccountMenuState extends State<AccountMenu> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.primary,
        elevation: 8,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SizedBox(
          width: 340,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      'ACCOUNT',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: game.closeAccount,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<AccountState>(
                  valueListenable: game.account.state,
                  builder: (context, account, _) => _body(account, textTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.closeAccount,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Center(child: SingleChildScrollView(child: card)),
      ],
    );
  }

  Widget _body(AccountState account, TextTheme textTheme) {
    final labelStyle = textTheme.bodyMedium?.copyWith(color: Colors.white);
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white),
    );
    final error = account.error;

    final children = switch (account.status) {
      AccountStatus.disabled => [
        Text(
          'Passkey accounts are off in this build. Run with '
          '--dart-define=PASSKEY_SERVER_URL=https://<your server>.',
          style: labelStyle,
        ),
      ],
      AccountStatus.busy => [
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
      AccountStatus.signedIn => [
        Text(
          'Signed in as ${account.profile!.username}',
          style: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        for (final mode in GameMode.values)
          Text(
            '${_modeLabel(mode)} best: '
            '${_levelLabel(account.profile!.best[mode] ?? 0)}',
            style: labelStyle,
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: widget.game.account.signOut,
          style: buttonStyle,
          child: const Text('Sign Out'),
        ),
      ],
      AccountStatus.signedOut => [
        TextField(
          controller: _usernameController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: labelStyle,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () =>
              widget.game.account.register(_usernameController.text),
          style: buttonStyle,
          icon: const Icon(Icons.add),
          label: const Text('Create Passkey'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: widget.game.account.signIn,
          style: buttonStyle,
          icon: const Icon(Icons.key),
          label: const Text('Sign In with Passkey'),
        ),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error,
            style: textTheme.bodySmall?.copyWith(color: Colors.amberAccent),
          ),
        ],
      ],
    );
  }

  static String _modeLabel(GameMode mode) => switch (mode) {
    GameMode.normal => 'Normal',
    GameMode.easy => 'Easy',
  };

  static String _levelLabel(int level) => level == 0 ? '-' : 'Lv. $level';
}
