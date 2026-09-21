import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum JevRequestStatus { idle, loading, success, error }

/// Baked in only when built with `--dart-define=JEV_DEFAULT_API_KEY=...`,
/// so a real key never has to be typed in-app or committed to source/git
/// history. Empty when the flag isn't passed.
const String jevDefaultApiKey = String.fromEnvironment('JEV_DEFAULT_API_KEY');

/// Snapshot of the most recent request made to the Jev ("TypeSafe AI")
/// `choice` primitive.
class JevAssistantState {
  const JevAssistantState({
    required this.status,
    this.errorMessage,
    this.rawResponseBody,
  });

  static const idle = JevAssistantState(status: JevRequestStatus.idle);

  final JevRequestStatus status;
  final String? errorMessage;

  /// The raw HTTP response body from Jev, when one was actually received
  /// (success or a non-200 status) — null for network failures/timeouts
  /// where there's no response to show. Surfaced in the debug logging
  /// overlay (including in release builds) so a real reply can be
  /// inspected without a device log/proxy.
  final String? rawResponseBody;
}

/// Asks Jev's (https://jevtypesafeai.com) `decide` API to pick which lane to
/// drop the next ball into, given a text description of the current board.
/// This is a single on-demand HTTP call (not something invoked every
/// frame), since Jev's ~70-500ms round trip is only acceptable for a player
/// explicitly asking for a suggestion, not for continuous autoplay.
class JevAssistant {
  JevAssistant({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://jevtypesafeai.com/api/v1/decide';
  static const _requestTimeout = Duration(seconds: 12);

  final http.Client _client;
  final ValueNotifier<JevAssistantState> state = ValueNotifier(
    JevAssistantState.idle,
  );

  /// Sends [boardState] (a free-text description of the board) and
  /// [laneCriteria] (lane key -> description of what's currently in that
  /// lane) to Jev, and returns the chosen lane key, or `null` if the
  /// request failed (see [state] for the error message in that case).
  Future<String?> chooseLane({
    required String apiKey,
    required String boardState,
    required Map<String, String> laneCriteria,
  }) async {
    final trimmedApiKey = apiKey.trim();
    if (trimmedApiKey.isEmpty) {
      state.value = const JevAssistantState(
        status: JevRequestStatus.error,
        errorMessage:
            'Jev APIキーが未設定です。--dart-define=JEV_DEFAULT_API_KEY=... '
            'を付けてビルドしてください。',
      );
      return null;
    }

    state.value = const JevAssistantState(status: JevRequestStatus.loading);
    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $trimmedApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'state': boardState,
              'questions': {
                'lane': {
                  'type': 'choice',
                  'instructions':
                      'Pick the lane to drop the next ball into so it is '
                      'most likely to merge, or otherwise keeps the stack '
                      'as low as possible.',
                  'criteria': laneCriteria,
                },
              },
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        state.value = JevAssistantState(
          status: JevRequestStatus.error,
          errorMessage: _messageForStatus(response.statusCode, response.body),
          rawResponseBody: response.body,
        );
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final answers = body['answers'] as Map<String, dynamic>?;
      final laneAnswer = answers?['lane'] as Map<String, dynamic>?;
      final choice = laneAnswer?['choice'] as String?;
      if (choice == null) {
        state.value = JevAssistantState(
          status: JevRequestStatus.error,
          errorMessage: 'Jevから予期しない応答が返されました。',
          rawResponseBody: response.body,
        );
        return null;
      }

      state.value = JevAssistantState(
        status: JevRequestStatus.success,
        rawResponseBody: response.body,
      );
      return choice;
    } on TimeoutException {
      state.value = const JevAssistantState(
        status: JevRequestStatus.error,
        errorMessage: 'Jevの応答がタイムアウトしました。',
      );
      return null;
    } catch (_) {
      state.value = const JevAssistantState(
        status: JevRequestStatus.error,
        errorMessage: 'Jevへの接続に失敗しました。',
      );
      return null;
    }
  }

  String _messageForStatus(int statusCode, String responseBody) {
    final detail = _extractDetail(responseBody);
    final suffix = detail == null ? '' : '\n$detail';
    switch (statusCode) {
      case 401:
        return 'Jev APIキーが無効です。$suffix';
      case 402:
        return 'Jevアカウントのクレジット残高が不足しています。'
            'jevtypesafeai.comのダッシュボードでチャージしてください。$suffix';
      case 422:
        return 'Jevへのリクエストが不正でした。$suffix';
      case 429:
        return 'Jevのレート制限に達しました。少し待って再試行してください。$suffix';
      case 529:
        return 'Jevが混雑しています。少し待って再試行してください。$suffix';
      default:
        return 'Jevへのリクエストに失敗しました ($statusCode)。$suffix';
    }
  }

  /// Pulls a human-readable detail out of an error response body so the
  /// canned message above isn't the only thing shown when debugging why a
  /// key was rejected. Falls back to the raw (truncated) body when it
  /// isn't the `{"error"/"message": "..."}` shape we'd expect.
  String? _extractDetail(String responseBody) {
    if (responseBody.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error'] ?? decoded['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Not JSON — fall through to the raw body.
    }
    final truncated =
        responseBody.length > 200
            ? '${responseBody.substring(0, 200)}...'
            : responseBody;
    return truncated;
  }

  void dispose() {
    state.dispose();
    _client.close();
  }
}
