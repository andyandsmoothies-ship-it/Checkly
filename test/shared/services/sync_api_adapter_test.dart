import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/_shared/services/service_adapters.dart';
import 'package:checkly/_shared/services/sync_interfaces.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SyncApiAdapter adapter;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    adapter = SyncApiAdapter(mockDio);
  });

  test('AC1: LocalPhotoPath_StrippedBeforePost - Local path inside payload is nulled', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'success': true},
            ));

    final payload = {
      'answers': [
        {'photoUrl': '/data/user/0/photo.jpg'},
        {'photoUrl': 'file:///app/flutter/photo2.jpg'},
      ],
    };

    final submission = PendingSubmission(
      idempotencyKey: 'key',
      createdAt: DateTime.now(),
      payload: jsonEncode(payload),
    );

    await adapter.pushSubmission(submission);

    final captured = verify(() => mockDio.post(any(), data: captureAny(named: 'data'), options: any(named: 'options'))).captured;
    final capturedData = captured.first as Map<String, dynamic>;

    final answers = capturedData['answers'] as List;
    expect(answers[0]['photoUrl'], isNull);
    expect(answers[1]['photoUrl'], isNull);
  });

  test('AC2: CdnPhotoUrl_PreservedBeforePost - Remote CDN URL is not stripped', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'success': true},
            ));

    final payload = {
      'answers': [
        {'photoUrl': 'https://cdn.example.com/photo.jpg'},
      ],
    };

    final submission = PendingSubmission(
      idempotencyKey: 'key',
      createdAt: DateTime.now(),
      payload: jsonEncode(payload),
    );

    await adapter.pushSubmission(submission);

    final captured = verify(() => mockDio.post(any(), data: captureAny(named: 'data'), options: any(named: 'options'))).captured;
    final capturedData = captured.first as Map<String, dynamic>;

    final answers = capturedData['answers'] as List;
    expect(answers[0]['photoUrl'], 'https://cdn.example.com/photo.jpg');
  });

  test('AC10: NullPhotoUrl_NotMangled - Null photoUrl passes through safely', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: {'success': true},
            ));

    final payload = {
      'answers': [
        {'photoUrl': null},
      ],
    };

    final submission = PendingSubmission(
      idempotencyKey: 'key',
      createdAt: DateTime.now(),
      payload: jsonEncode(payload),
    );

    await adapter.pushSubmission(submission);

    final captured = verify(() => mockDio.post(any(), data: captureAny(named: 'data'), options: any(named: 'options'))).captured;
    final capturedData = captured.first as Map<String, dynamic>;

    final answers = capturedData['answers'] as List;
    expect(answers[0]['photoUrl'], isNull);
  });
}
