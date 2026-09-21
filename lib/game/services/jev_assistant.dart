import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum JevRequestStatus { idle, loading, success, error }

/// Snapshot of the most recent request made to the Jev ("TypeSafe AI")
/// `choice` primitive.
class JevAssistantState {
  const JevAssistantState({required this.status, this.errorMessage});

  static const idle = JevAssistantState(status: JevRequestStatus.idle);

  final JevRequestStatus status;
  final String? errorMessage;
}

/// Asks Jev's hosted `systemone` API (https://docs.typesafe.ai) to pick
/// which lane to drop the next ball into, given a text description of the
/// current board. This is a single on-demand HTTP call (not something
/// invoked every frame), since Jev's ~100-500ms round trip is only
/// acceptable for a player explicitly asking for a suggestion, not for
/// continuous autoplay.
class JevAssistant {
  JevAssistant({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://api.typesafe.ai/v1/systemone';
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
    if (apiKey.trim().isEmpty) {
      state.value = const JevAssistantState(
        status: JevRequestStatus.error,
        errorMessage: 'Jev APIキーが未設定です。設定画面で入力してください。',
      );
      return null;
    }

    state.value = const JevAssistantState(status: JevRequestStatus.loading);
    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'state': boardState,
              'model': 'jev-latest',
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
          errorMessage: _messageForStatus(response.statusCode),
        );
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final answers = body['answers'] as Map<String, dynamic>?;
      final laneAnswer = answers?['lane'] as Map<String, dynamic>?;
      final choice = laneAnswer?['choice'] as String?;
      if (choice == null) {
        state.value = const JevAssistantState(
          status: JevRequestStatus.error,
          errorMessage: 'Jevから予期しない応答が返されました。',
        );
        return null;
      }

      state.value = const JevAssistantState(status: JevRequestStatus.success);
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

  String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Jev APIキーが無効です。設定画面で確認してください。';
      case 422:
        return 'Jevへのリクエストが不正でした。';
      case 429:
        return 'Jevのレート制限に達しました。少し待って再試行してください。';
      case 529:
        return 'Jevが混雑しています。少し待って再試行してください。';
      default:
        return 'Jevへのリクエストに失敗しました ($statusCode)。';
    }
  }

  void dispose() {
    state.dispose();
    _client.close();
  }
}
