import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/utils/audit_snapshot_parser.dart';

void main() {
  group('AuditSnapshotParser.parseSnapshot (Slice 3 Redesign)', () {
    test('TC-08: New JSON keys (none, false) -> survey string', () {
      final snapshot = {
        'scoringLogicConfig': {
          'scoreDirection': 'none',
          'isWeighted': false,
        }
      };
      final result = AuditSnapshotParser.parseSnapshot(jsonEncode(snapshot));
      expect(result.scoringMode, 'survey');
    });

    test('TC-08b: New down + true -> penalty string', () {
      final snapshot = {
        'scoringLogicConfig': {
          'scoreDirection': 'down',
          'isWeighted': true,
        }
      };
      final result = AuditSnapshotParser.parseSnapshot(jsonEncode(snapshot));
      expect(result.scoringMode, 'penalty');
    });

    test('TC-08c: New up + false -> accumulation string', () {
      final snapshot = {
        'scoringLogicConfig': {
          'scoreDirection': 'up',
          'isWeighted': false,
        }
      };
      final result = AuditSnapshotParser.parseSnapshot(jsonEncode(snapshot));
      expect(result.scoringMode, 'accumulation');
    });

    test('TC-08d: Legacy key (checklist) still works', () {
      final snapshot = {
        'scoringLogicConfig': {
          'scoringMode': 'checklist',
        }
      };
      final result = AuditSnapshotParser.parseSnapshot(jsonEncode(snapshot));
      expect(result.scoringMode, 'checklist');
    });

    test('New JSON keys (down, false) -> checklist string', () {
      final snapshot = {
        'scoringLogicConfig': {
          'scoreDirection': 'down',
          'isWeighted': false,
        }
      };
      final result = AuditSnapshotParser.parseSnapshot(jsonEncode(snapshot));
      expect(result.scoringMode, 'checklist');
    });
  });
}
