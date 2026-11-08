import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/model/game_mode.dart';
import 'package:forge2d_game/game/services/passkey_account.dart';
import 'package:forge2d_game/game/services/passkey_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:passkeys/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthenticator implements PasskeyAuthenticatorInterface {
  Object? error;
  RegisterRequestType? lastRegister;
  AuthenticateRequestType? lastAuthenticate;

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    lastRegister = request;
    if (error != null) throw error!;
    return const RegisterResponseType(
      id: 'cred-1',
      rawId: 'cred-1',
      clientDataJSON: 'cdj',
      attestationObject: 'att',
      transports: ['internal'],
    );
  }

  @override
  Future<AuthenticateResponseType> authenticate(
    AuthenticateRequestType request,
  ) async {
    lastAuthenticate = request;
    if (error != null) throw error!;
    return const AuthenticateResponseType(
      id: 'cred-1',
      rawId: 'cred-1',
      clientDataJSON: 'cdj',
      authenticatorData: 'ad',
      signature: 'sig',
      userHandle: 'uh',
    );
  }

  @override
  Future<void> signalUnknownCredential(
    SignalUnknownCredentialRequestType request,
  ) async {}

  @override
  Future<void> signalAllAcceptedCredentials(
    SignalAllAcceptedCredentialsRequestType request,
  ) async {}
}

/// Minimal in-memory stand-in for the routes `server/` exposes.
class _FakeServer {
  final requests = <http.Request>[];
  int scoresStatus = 200;
  Map<String, int> best = {'normal': 0, 'easy': 0};

  late final client = MockClient((request) async {
    requests.add(request);
    final body = request.body.isEmpty ? null : jsonDecode(request.body);
    final authorized = request.headers['authorization'] == 'Bearer token-1';
    http.Response json(Object value, [int status = 200]) =>
        http.Response(jsonEncode(value), status);
    final signedIn = {'token': 'token-1', 'username': 'alice', 'best': best};

    switch (request.url.path) {
      case '/auth/register/options':
        if (body['username'] == 'taken') {
          return json({'error': 'Username already taken'}, 409);
        }
        return json({
          'challenge': 'Y2hhbGxlbmdl',
          'rp': {'id': 'game.example.com', 'name': 'Forge2D Game'},
          'user': {
            'id': 'dXNlcg',
            'name': body['username'],
            'displayName': body['username'],
          },
          'pubKeyCredParams': [
            {'alg': -7, 'type': 'public-key'},
          ],
          'authenticatorSelection': {'residentKey': 'required'},
          'excludeCredentials': [],
        });
      case '/auth/login/options':
        return json({
          'challenge': 'Y2hhbGxlbmdl',
          'rpId': 'game.example.com',
          'allowCredentials': [],
        });
      case '/auth/register/verify':
      case '/auth/login/verify':
        return json(signedIn);
      case '/me':
        return authorized
            ? json({'username': 'alice', 'best': best})
            : json({'error': 'Not signed in'}, 401);
      case '/scores':
        if (scoresStatus != 200) return json({'error': 'boom'}, scoresStatus);
        final mode = body['mode'] as String;
        if (body['level'] > best[mode]!) best[mode] = body['level'] as int;
        return json({'best': best});
      case '/auth/logout':
        return http.Response('', 204);
    }
    return json({'error': 'not found'}, 404);
  });

  List<String> get paths => [for (final r in requests) r.url.path];
}

void main() {
  late _FakeServer server;
  late _FakeAuthenticator authenticator;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = _FakeServer();
    authenticator = _FakeAuthenticator();
  });

  PasskeyAccount newAccount() {
    final account = PasskeyAccount(
      api: PasskeyApi(
        baseUrl: Uri.parse('https://game.example.com'),
        client: server.client,
      ),
      authenticator: authenticator,
    );
    addTearDown(account.dispose);
    return account;
  }

  test('is disabled when no server is configured', () {
    final account = PasskeyAccount(authenticator: authenticator);
    addTearDown(account.dispose);
    expect(account.state.value.status, AccountStatus.disabled);
  });

  test('register creates a passkey and signs in', () async {
    final account = newAccount();
    await account.ready;

    await account.register(' alice ');

    expect(account.state.value.status, AccountStatus.signedIn);
    expect(account.state.value.profile!.username, 'alice');
    expect(authenticator.lastRegister!.relyingParty.id, 'game.example.com');
    expect(authenticator.lastRegister!.user.name, 'alice');
    final verify = server.requests.last;
    expect(verify.url.path, '/auth/register/verify');
    expect(jsonDecode(verify.body)['response']['id'], 'cred-1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('account.token'), 'token-1');
  });

  test('signIn authenticates with a discoverable passkey', () async {
    final account = newAccount();
    await account.ready;

    await account.signIn();

    expect(account.state.value.status, AccountStatus.signedIn);
    expect(authenticator.lastAuthenticate!.relyingPartyId, 'game.example.com');
    expect(authenticator.lastAuthenticate!.allowCredentials, isNull);
    expect(server.paths, ['/auth/login/options', '/auth/login/verify']);
  });

  test('restores a persisted session on startup', () async {
    SharedPreferences.setMockInitialValues({'account.token': 'token-1'});
    server.best = {'normal': 7, 'easy': 3};

    final account = newAccount();
    await account.ready;

    expect(account.state.value.status, AccountStatus.signedIn);
    expect(account.state.value.profile!.best, {
      GameMode.normal: 7,
      GameMode.easy: 3,
    });
  });

  test('drops a persisted token the server rejects', () async {
    SharedPreferences.setMockInitialValues({'account.token': 'stale'});

    final account = newAccount();
    await account.ready;

    expect(account.state.value.status, AccountStatus.signedOut);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('account.token'), isFalse);
  });

  test('cancelling the passkey prompt returns to signed out quietly', () async {
    authenticator.error = PasskeyAuthCancelledException();
    final account = newAccount();
    await account.ready;

    await account.signIn();

    expect(account.state.value.status, AccountStatus.signedOut);
    expect(account.state.value.error, isNull);
  });

  test('server errors are surfaced as the error message', () async {
    final account = newAccount();
    await account.ready;

    await account.register('taken');

    expect(account.state.value.status, AccountStatus.signedOut);
    expect(account.state.value.error, 'Username already taken');
    expect(authenticator.lastRegister, isNull);
  });

  test('submitLevel updates the best levels while signed in', () async {
    final account = newAccount();
    await account.ready;
    await account.signIn();

    await account.submitLevel(GameMode.normal, 6);

    expect(account.state.value.profile!.best[GameMode.normal], 6);
    expect(jsonDecode(server.requests.last.body), {
      'mode': 'normal',
      'level': 6,
    });
  });

  test('submitLevel is a no-op when signed out', () async {
    final account = newAccount();
    await account.ready;

    await account.submitLevel(GameMode.normal, 6);

    expect(server.paths, isNot(contains('/scores')));
  });

  test('submitLevel failures keep the account signed in', () async {
    final account = newAccount();
    await account.ready;
    await account.signIn();
    server.scoresStatus = 500;

    await account.submitLevel(GameMode.easy, 4);

    expect(account.state.value.status, AccountStatus.signedIn);
    expect(account.state.value.profile!.best[GameMode.easy], 0);
  });

  test('signOut clears the session locally and on the server', () async {
    final account = newAccount();
    await account.ready;
    await account.signIn();

    await account.signOut();

    expect(account.state.value.status, AccountStatus.signedOut);
    expect(server.paths.last, '/auth/logout');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('account.token'), isFalse);
  });
}
