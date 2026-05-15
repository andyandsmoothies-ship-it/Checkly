import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/model/submission_dto.dart';

void main() {
  group('SubmissionDto', () {
    test('TC-10: withStatus() propagates allowedActions', () {
      final json = {
        'id': '123',
        'status': 'completed',
        'createdAt': '2023-01-01T00:00:00Z',
        'allowedActions': ['edit'],
      };
      final dto = SubmissionDto.fromJson(json);
      final newDto = dto.withStatus('draft');

      dynamic dynamicNewDto = newDto;

      expect(dynamicNewDto.allowedActions, isNotNull);
      expect(dynamicNewDto.allowedActions.contains('edit'), isTrue);
    });

    test('fromJson parses allowedActions', () {
      final json = {
        'id': '123',
        'status': 'completed',
        'createdAt': '2023-01-01T00:00:00Z',
        'allowedActions': ['edit', 'finalize'],
      };

      final dto = SubmissionDto.fromJson(json);

      // Cast to dynamic to access allowedActions without compiler error
      dynamic dynamicDto = dto;

      expect(dynamicDto.allowedActions, isNotNull);
      expect(dynamicDto.allowedActions.contains('edit'), isTrue);
    });
  });
}
