import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SubmissionApiService service;

  late String dummyFile;

  setUpAll(() {
    registerFallbackValue(FormData.fromMap({}));
  });

  setUp(() {
    mockDio = MockDio();
    service = SubmissionApiService(mockDio);
    final file = File('dummy_test.jpg');
    file.writeAsStringSync('dummy');
    dummyFile = file.path;
  });

  tearDown(() {
    final file = File('dummy_test.jpg');
    if (file.existsSync()) file.deleteSync();
  });

  test('AC3: SubmissionApiService_UploadPhoto_UsesPathSegmentRoute', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {'url': 'https://cdn.example.com/photo.jpg'},
      ),
    );

    await service.uploadPhoto('sub-123', dummyFile);

    final captured = verify(
      () => mockDio.post(captureAny(), data: any(named: 'data')),
    ).captured;
    final path = captured.first as String;

    expect(path, '/photos/upload/sub-123'); // MUST not contain ?submissionId=
  });

  test(
    'AC4: SubmissionApiService_UploadPhoto_IncludesAnswerIdWhenProvided',
    () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'url': 'https://cdn.example.com/photo.jpg'},
        ),
      );

      await service.uploadPhoto('sub-123', dummyFile, answerId: 'ans-456');

      final captured = verify(
        () => mockDio.post(captureAny(), data: any(named: 'data')),
      ).captured;
      final path = captured.first as String;

      expect(path, '/photos/upload/sub-123?answerId=ans-456');
    },
  );
}
