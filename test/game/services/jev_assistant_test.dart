import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/services/jev_assistant.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns null and an error when the API key is empty', () async {
    final assistant = JevAssistant(
      client: MockClient((request) async => http.Response('', 500)),
    );
    addTearDown(assistant.dispose);

    final choice = await assistant.chooseLane(
      apiKey: '',
      boardState: 'board',
      laneCriteria: const {'center': 'empty'},
    );

    expect(choice, isNull);
    expect(assistant.state.value.status, JevRequestStatus.error);
  });

  test('returns the chosen lane on a successful response', () async {
    final assistant = JevAssistant(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://api.typesafe.ai/v1/systemone');
        expect(request.headers['Authorization'], 'Bearer test-key');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'jev-latest');
        expect(body['questions']['lane']['type'], 'choice');

        return http.Response(
          jsonEncode({
            'model': 'jev-1.0.0',
            'answers': {
              'lane': {
                'type': 'choice',
                'choice': 'center',
                'probabilities': {'center': 0.9},
                'confidence': 0.9,
              },
            },
            'usage': {'input_tokens': 1, 'output_tokens': 1},
          }),
          200,
        );
      }),
    );
    addTearDown(assistant.dispose);

    final choice = await assistant.chooseLane(
      apiKey: 'test-key',
      boardState: 'board',
      laneCriteria: const {'center': 'empty'},
    );

    expect(choice, 'center');
    expect(assistant.state.value.status, JevRequestStatus.success);
  });

  test('surfaces a friendly message on a 401 response', () async {
    final assistant = JevAssistant(
      client: MockClient((request) async => http.Response('', 401)),
    );
    addTearDown(assistant.dispose);

    final choice = await assistant.chooseLane(
      apiKey: 'bad-key',
      boardState: 'board',
      laneCriteria: const {'center': 'empty'},
    );

    expect(choice, isNull);
    expect(assistant.state.value.status, JevRequestStatus.error);
    expect(assistant.state.value.errorMessage, contains('無効'));
  });
}
