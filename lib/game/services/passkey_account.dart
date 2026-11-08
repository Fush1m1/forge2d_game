import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/game_mode.dart';
import 'passkey_api.dart';

enum AccountStatus {
  /// No `PASSKEY_SERVER_URL` was given at build time.
  disabled,
  signedOut,
  busy,
  signedIn,
}

/// Snapshot of the player's passkey account.
class AccountState {
  const AccountState(this.status, {this.profile, this.error});

  final AccountStatus status;

  /// Set while [AccountStatus.signedIn].
  final AccountProfile? profile;

  /// Message from the last failed action, shown until the next one starts.
  final String? error;
}

/// Passkey sign-up/sign-in against the server in `server/`, plus syncing
/// the player's best level per mode while signed in. The session token is
/// persisted via [SharedPreferences] so a restart stays signed in.
class PasskeyAccount {
  PasskeyAccount({
    PasskeyApi? api,
    PasskeyAuthenticatorInterface? authenticator,
  }) : _api = api ?? _defaultApi(),
       _authenticator = authenticator ?? PasskeyAuthenticator(),
       state = ValueNotifier(const AccountState(AccountStatus.signedOut)) {
    if (_api == null) {
      state.value = const AccountState(AccountStatus.disabled);
      ready = Future.value();
    } else {
      ready = _restore(_api);
    }
  }

  static const _keyToken = 'account.token';

  final PasskeyApi? _api;
  final PasskeyAuthenticatorInterface _authenticator;
  final ValueNotifier<AccountState> state;

  /// Resolves once a persisted session (if any) has been restored.
  late final Future<void> ready;

  String? _token;

  bool get isSignedIn => state.value.status == AccountStatus.signedIn;

  static PasskeyApi? _defaultApi() => PasskeyApi.configuredUrl.isEmpty
      ? null
      : PasskeyApi(baseUrl: Uri.parse(PasskeyApi.configuredUrl));

  Future<void> _restore(PasskeyApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return;
    state.value = const AccountState(AccountStatus.busy);
    try {
      final profile = await api.me(token);
      _token = token;
      state.value = AccountState(AccountStatus.signedIn, profile: profile);
    } on PasskeyApiException catch (e) {
      if (e.isUnauthorized) await prefs.remove(_keyToken);
      state.value = AccountState(AccountStatus.signedOut, error: e.message);
    } catch (e) {
      // Offline etc.: keep the token so the next launch can retry.
      state.value = AccountState(
        AccountStatus.signedOut,
        error: 'Could not reach the server: $e',
      );
    }
  }

  /// Creates a new account named [username] with a fresh passkey.
  Future<void> register(String username) => _run((api) async {
    final request = await api.registerOptions(username.trim());
    final response = await _authenticator.register(request);
    return api.registerVerify(username.trim(), response);
  });

  /// Signs in with any passkey the device offers for this server.
  Future<void> signIn() => _run((api) async {
    final request = await api.loginOptions();
    final response = await _authenticator.authenticate(request);
    return api.loginVerify(response);
  });

  Future<void> signOut() async {
    final token = _token;
    _token = null;
    state.value = const AccountState(AccountStatus.signedOut);
    (await SharedPreferences.getInstance()).remove(_keyToken);
    if (token == null) return;
    try {
      await _api?.logout(token);
    } catch (_) {
      // Already signed out locally; a stale server session is harmless.
    }
  }

  /// Reports the highest level reached in a finished round. No-op unless
  /// signed in; failures are swallowed since this runs fire-and-forget.
  Future<void> submitLevel(GameMode mode, int level) async {
    final api = _api;
    final token = _token;
    final profile = state.value.profile;
    if (api == null || token == null || profile == null || level < 1) return;
    try {
      final best = await api.submitLevel(token, mode, level);
      if (_token != token) return; // Signed out meanwhile.
      state.value = AccountState(
        AccountStatus.signedIn,
        profile: profile.copyWith(best: best),
      );
    } catch (e) {
      debugPrint('Failed to submit best level: $e');
    }
  }

  Future<void> _run(
    Future<(String, AccountProfile)> Function(PasskeyApi api) action,
  ) async {
    final api = _api;
    if (api == null || state.value.status == AccountStatus.busy) return;
    state.value = const AccountState(AccountStatus.busy);
    try {
      final (token, profile) = await action(api);
      _token = token;
      (await SharedPreferences.getInstance()).setString(_keyToken, token);
      state.value = AccountState(AccountStatus.signedIn, profile: profile);
    } on PasskeyAuthCancelledException {
      state.value = const AccountState(AccountStatus.signedOut);
    } on DomainNotAssociatedException catch (e) {
      state.value = AccountState(
        AccountStatus.signedOut,
        error: 'This app is not associated with the server domain. $e',
      );
    } on NoCredentialsAvailableException {
      state.value = const AccountState(
        AccountStatus.signedOut,
        error: 'No passkey found on this device. Create one first.',
      );
    } catch (e) {
      state.value = AccountState(AccountStatus.signedOut, error: '$e');
    }
  }

  void dispose() {
    state.dispose();
    _api?.close();
  }
}
