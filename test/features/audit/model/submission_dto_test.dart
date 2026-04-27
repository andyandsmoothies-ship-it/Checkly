import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/model/submission_dto.dart';

void main() {
  group('SubmissionDto Void Status', () {
    test('SubmissionDto parses voidReason and voidedAt correctly', () {
      final json = {
        'id': 'sub-1',
        'status': 'voided',
        'createdAt': '2026-04-01T10:00:00.000Z',
        'voidReason': 'Duplicate audit',
        'voidedAt': '2026-04-01T11:00:00.000Z',
      };

      final dto = SubmissionDto.fromJson(json);

      expect(dto.status, 'voided');

      // The following lines will cause compile-time errors in the RED state ATDD phase.
      // The Builder must add `isVoided`, `voidReason`, and `voidedAt` to SubmissionDto.
      expect(dto.isVoided, isTrue);
      expect(dto.voidReason, 'Duplicate audit');
      expect(dto.voidedAt?.toIso8601String(), '2026-04-01T11:00:00.000Z');
    });
  });
}
