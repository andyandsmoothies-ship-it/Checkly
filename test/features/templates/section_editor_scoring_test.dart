// Test Plan:
// Tests the _allowSubSections business logic rule (Slice 2, BL-1..BL-4).
//
// Rule: allowSubSections = scoringMode == null
//                        || scoringMode == 'penalty'
//                        || scoringMode == 'accumulation'
//
// Mirrors the pure-Dart pattern used by wizard_payload_test.dart —
// extract the logic, test it without widgets for speed and reliability.
//
// State Matrix:
//   EDD-A: null mode  → allowed  (backward compat, Builder default)
//   EDD-B: 'penalty'  → allowed
//   EDD-C: 'accumulation' → allowed
//   EDD-D: 'survey'   → NOT allowed → SnackBar path
//   EDD-E: 'checklist' → NOT allowed → SnackBar path
//   EDD-F: unknown string → NOT allowed (allowlist model, not blocklist)

import 'package:flutter_test/flutter_test.dart';

// ── Pure helper mirroring SectionEditor._allowSubSections getter ──────────────
bool allowSubSections(String? scoringMode) =>
    scoringMode == null ||
    scoringMode == 'penalty' ||
    scoringMode == 'accumulation';

void main() {
  group('allowSubSections business logic rule (Slice 2 / BL-1)', () {
    // ── EDD-A: null → allowed (backward compat) ──────────────────────────────
    test(
      'null scoringMode → allowed (backward compat for Builder default)',
      () {
        expect(allowSubSections(null), isTrue);
      },
    );

    // ── EDD-B: penalty → allowed ──────────────────────────────────────────────
    test("scoringMode 'penalty' → sub-sections allowed", () {
      expect(allowSubSections('penalty'), isTrue);
    });

    // ── EDD-C: accumulation → allowed ─────────────────────────────────────────
    test("scoringMode 'accumulation' → sub-sections allowed", () {
      expect(allowSubSections('accumulation'), isTrue);
    });

    // ── EDD-D: survey → NOT allowed ───────────────────────────────────────────
    test("scoringMode 'survey' → sub-sections NOT allowed", () {
      expect(allowSubSections('survey'), isFalse);
    });

    // ── EDD-E: checklist → NOT allowed ────────────────────────────────────────
    test("scoringMode 'checklist' → sub-sections NOT allowed", () {
      expect(allowSubSections('checklist'), isFalse);
    });

    // ── EDD-F: unknown value → allowed (safe default) ─────────────────────────
    test(
      "unknown non-empty scoringMode 'qc' → NOT allowed (allowlist model)",
      () {
        // The getter is an explicit ALLOWLIST: only null/penalty/accumulation pass.
        // Any other string, including 'qc', returns false.
        expect(allowSubSections('qc'), isFalse);
      },
    );

    test(
      "empty string scoringMode → NOT allowed (not null, not in allowlist)",
      () {
        expect(allowSubSections(''), isFalse);
      },
    );
  });

  group(
    'allowSubSections: condition logic for button visibility (Slice 2 / BL-2)',
    () {
      // GhostAddButton condition: section.criteria.isEmpty || !allowSubSections(mode)
      // Validates that in restricted modes the button is ALWAYS visible (EDD-6 in plan)
      bool buttonVisible({
        required bool criteriaEmpty,
        required String? mode,
      }) => criteriaEmpty || !allowSubSections(mode);

      test(
        'survey + no criteria → button visible (restricted mode + no criteria)',
        () {
          expect(buttonVisible(criteriaEmpty: true, mode: 'survey'), isTrue);
        },
      );

      test(
        'survey + has criteria → button STILL visible (restricted mode overrides)',
        () {
          expect(buttonVisible(criteriaEmpty: false, mode: 'survey'), isTrue);
        },
      );

      test('penalty + no criteria → button visible (allowed mode + empty)', () {
        expect(buttonVisible(criteriaEmpty: true, mode: 'penalty'), isTrue);
      });

      test(
        'penalty + has criteria → button HIDDEN (original behaviour preserved)',
        () {
          expect(buttonVisible(criteriaEmpty: false, mode: 'penalty'), isFalse);
        },
      );

      test('null mode + has criteria → button HIDDEN (backward compat)', () {
        expect(buttonVisible(criteriaEmpty: false, mode: null), isFalse);
      });
    },
  );
}
