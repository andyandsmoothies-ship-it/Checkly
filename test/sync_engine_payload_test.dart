import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/services/core_audit_sync_module.dart';

/// A simple stub representing a database row (e.g. PendingAnswer)
/// Since `buildAnswerPayload` uses `dynamic`, we can pass any object
/// with the matching property getters.
class _StubAnswer {
  final String criteriaId = 'test-id';
  final String? value = 'conform';
  final double? numericValue = null;
  final String? note = null;
  final String? photoUrl = null;
  final bool isRepeatedError = false;
  final int repeatedFaults = 0;
  final bool isCcp;
  final bool isRisk;

  _StubAnswer({required this.isCcp, required this.isRisk});
}

void main() {
  group('CoreAuditSyncModule Answer Payload Builder', () {
    test(
      'SE1: buildAnswerPayload with isCcp=true includes isCcp key mapping',
      () {
        final stub = _StubAnswer(isCcp: true, isRisk: false);
        final jsonMap = CoreAuditSyncModule.buildAnswerPayload(stub);

        expect(
          jsonMap.containsKey('isCcp'),
          isTrue,
          reason: 'Payload MUST include isCcp key',
        );
        expect(
          jsonMap['isCcp'],
          isTrue,
          reason: 'isCcp value MUST be mapped correctly',
        );
      },
    );

    test(
      'SE2: buildAnswerPayload with isRisk=true includes isRisk key mapping',
      () {
        final stub = _StubAnswer(isCcp: false, isRisk: true);
        final jsonMap = CoreAuditSyncModule.buildAnswerPayload(stub);

        expect(
          jsonMap.containsKey('isRisk'),
          isTrue,
          reason: 'Payload MUST include isRisk key',
        );
        expect(
          jsonMap['isRisk'],
          isTrue,
          reason: 'isRisk value MUST be mapped correctly',
        );
      },
    );

    test(
      'SE3: buildAnswerPayload with false values serializes them explicitly',
      () {
        final stub = _StubAnswer(isCcp: false, isRisk: false);
        final jsonMap = CoreAuditSyncModule.buildAnswerPayload(stub);

        expect(
          jsonMap.containsKey('isCcp'),
          isTrue,
          reason: 'Payload MUST explicitly serialize false isCcp',
        );
        expect(
          jsonMap['isCcp'],
          isFalse,
          reason: 'Explicit negative flag mapping',
        );

        expect(
          jsonMap.containsKey('isRisk'),
          isTrue,
          reason: 'Payload MUST explicitly serialize false isRisk',
        );
        expect(
          jsonMap['isRisk'],
          isFalse,
          reason: 'Explicit negative flag mapping',
        );
      },
    );
  });
}
