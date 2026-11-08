import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:passkeys/types.dart';

import '../model/game_mode.dart';

/// Best ball level reached per mode, as stored on the passkey server.
typedef BestLevels = Map<GameMode, int>;

class AccountProfile {
  const AccountProfile({required this.username, required this.best});

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    username: json['username'] as String,
    best: _bestFromJson(json['best'] as Map<String, dynamic>),
  );

  final String username;
  final BestLevels best;

  AccountProfile copyWith({BestLevels? best}) =>
      AccountProfile(username: username, best: best ?? this.best);
}

BestLevels _bestFromJson(Map<String, dynamic> json) => {
  for (final mode in GameMode.values) mode: (json[mode.name] as int?) ?? 0,
};

class PasskeyApiException implements Exception {
  const PasskeyApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin client for the relying-party server in `server/`. The server speaks
/// standard WebAuthn JSON, which the passkeys package parses/produces
/// directly, so this only adds the HTTP plumbing and session token.
class PasskeyApi {
  PasskeyApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Set with `--dart-define=PASSKEY_SERVER_URL=https://...`. Empty disables
  /// passkey accounts entirely.
  static const configuredUrl = String.fromEnvironment('PASSKEY_SERVER_URL');

  final Uri baseUrl;
  final http.Client _client;

  Future<RegisterRequestType> registerOptions(String username) async =>
      RegisterRequestType.fromJson(
        await _post('/auth/register/options', {'username': username}),
      );

  Future<(String, AccountProfile)> registerVerify(
    String username,
    RegisterResponseType response,
  ) async => _signedIn(
    await _post('/auth/register/verify', {
      'username': username,
      'response': response.toJson(),
    }),
  );

  Future<AuthenticateRequestType> loginOptions() async =>
      AuthenticateRequestType.fromJson(
        await _post('/auth/login/options', {}),
        // Let the OS offer passkeys from other devices (QR / hybrid) too.
        preferImmediatelyAvailableCredentials: false,
      );

  Future<(String, AccountProfile)> loginVerify(
    AuthenticateResponseType response,
  ) async => _signedIn(
    await _post('/auth/login/verify', {'response': response.toJson()}),
  );

  Future<void> logout(String token) => _post('/auth/logout', {}, token: token);

  Future<AccountProfile> me(String token) async =>
      AccountProfile.fromJson(await _get('/me', token: token));

  Future<BestLevels> submitLevel(String token, GameMode mode, int level) async {
    final json = await _post('/scores', {
      'mode': mode.name,
      'level': level,
    }, token: token);
    return _bestFromJson(json['best'] as Map<String, dynamic>);
  }

  void close() => _client.close();

  (String, AccountProfile) _signedIn(Map<String, dynamic> json) =>
      (json['token'] as String, AccountProfile.fromJson(json));

  Future<Map<String, dynamic>> _get(String path, {String? token}) async =>
      _decode(await _client.get(_uri(path), headers: _headers(token)));

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async => _decode(
    await _client.post(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body),
    ),
  );

  Uri _uri(String path) => baseUrl.resolve(path);

  Map<String, String> _headers(String? token) => {
    'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = body is Map<String, dynamic> && body['error'] is String
          ? body['error'] as String
          : 'Server error (${response.statusCode})';
      throw PasskeyApiException(response.statusCode, message);
    }
    return body as Map<String, dynamic>;
  }
}
