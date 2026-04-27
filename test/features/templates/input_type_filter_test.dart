// Test Plan: Slice 3 — Input Type Filtering (BL-1 through BL-6)
//
// Rule: _isDisabledForMode(inputType, scoringMode) is an ALLOWLIST:
//   survey    → BLOCKS: pass_fail, numeric, scale
//   checklist → BLOCKS: numeric, scale
//   penalty / accumulation / null / unknown → BLOCKS nothing (all 6 allowed)
//
// Mirrors the pure-Dart pattern from wizard_payload_test.dart and
// section_editor_scoring_test.dart — extract logic, test without widgets.
//
// State Matrix (from plan):
//   EDD-A (survey  → pass_fail disabled)
//   EDD-B (survey  → single_choice enabled)
//   EDD-C (checklist → numeric disabled)
//   EDD-D (checklist → pass_fail enabled)
//   EDD-E (penalty → all enabled)
//   EDD-F (null mode → all enabled, backward compat)
//   EDD-G (unknown mode → all enabled, safe default)

import 'package:flutter_test/flutter_test.dart';

// ── Pure helper mirroring InputTypeBottomSheet._isDisabledForMode ─────────────
bool isDisabledForMode(String inputType, String? scoringMode) {
  return switch (scoringMode) {
    'survey' =>
      inputType == 'pass_fail' ||
          inputType == 'numeric' ||
          inputType == 'scale',
    'checklist' => inputType == 'numeric' || inputType == 'scale',
    _ => false,
  };
}

// ── Pure helper mirroring InputTypeBottomSheet._modeLabel ─────────────────────
String modeLabel(String? scoringMode) => switch (scoringMode) {
  'survey' => 'Survey',
  'checklist' => 'Checklist',
  _ => '',
};

// All 6 input types as a constant list
const allTypes = [
  'pass_fail',
  'numeric',
  'scale',
  'single_choice',
  'multi_choice',
  'text',
];

void main() {
  // ── BL-1: Survey ALLOWLIST ────────────────────────────────────────────────
  group('isDisabledForMode: survey mode (BL-1)', () {
    test('survey → pass_fail is DISABLED', () {
      expect(isDisabledForMode('pass_fail', 'survey'), isTrue);
    });

    test('survey → numeric is DISABLED', () {
      expect(isDisabledForMode('numeric', 'survey'), isTrue);
    });

    test('survey → scale is DISABLED', () {
      expect(isDisabledForMode('scale', 'survey'), isTrue);
    });

    test('survey → single_choice is ENABLED', () {
      expect(isDisabledForMode('single_choice', 'survey'), isFalse);
    });

    test('survey → multi_choice is ENABLED', () {
      expect(isDisabledForMode('multi_choice', 'survey'), isFalse);
    });

    test('survey → text is ENABLED', () {
      expect(isDisabledForMode('text', 'survey'), isFalse);
    });
  });

  // ── BL-2: Checklist ALLOWLIST ───────────────────────────────────────────────
  group('isDisabledForMode: checklist mode (BL-2)', () {
    test('checklist → numeric is DISABLED', () {
      expect(isDisabledForMode('numeric', 'checklist'), isTrue);
    });

    test('checklist → scale is DISABLED', () {
      expect(isDisabledForMode('scale', 'checklist'), isTrue);
    });

    test('checklist → pass_fail is ENABLED (EDD-D)', () {
      expect(isDisabledForMode('pass_fail', 'checklist'), isFalse);
    });

    test('checklist → single_choice is ENABLED', () {
      expect(isDisabledForMode('single_choice', 'checklist'), isFalse);
    });

    test('checklist → multi_choice is ENABLED', () {
      expect(isDisabledForMode('multi_choice', 'checklist'), isFalse);
    });

    test('checklist → text is ENABLED', () {
      expect(isDisabledForMode('text', 'checklist'), isFalse);
    });
  });

  // ── BL-3: Penalty — all types allowed (EDD-E) ───────────────────────────────
  group('isDisabledForMode: penalty mode (BL-3)', () {
    for (final type in allTypes) {
      test("penalty → '$type' is ENABLED", () {
        expect(isDisabledForMode(type, 'penalty'), isFalse);
      });
    }
  });

  // ── BL-4: Accumulation — all types allowed ───────────────────────────────────
  group('isDisabledForMode: accumulation mode (BL-4)', () {
    for (final type in allTypes) {
      test("accumulation → '$type' is ENABLED", () {
        expect(isDisabledForMode(type, 'accumulation'), isFalse);
      });
    }
  });

  // ── BL-5: null mode — backward compat, all types allowed (EDD-F) ─────────────
  group('isDisabledForMode: null mode (BL-5 – backward compat)', () {
    for (final type in allTypes) {
      test("null → '$type' is ENABLED", () {
        expect(isDisabledForMode(type, null), isFalse);
      });
    }
  });

  // ── BL-6: Unknown mode — safe default, all types allowed (EDD-G) ─────────────
  group('isDisabledForMode: unknown mode (BL-6 – safe default)', () {
    for (final type in allTypes) {
      test("unknown 'qc' → '$type' is ENABLED", () {
        expect(isDisabledForMode(type, 'qc'), isFalse);
      });
    }
  });

  // ── modeLabel correctness ──────────────────────────────────────────────────
  group('modeLabel helper', () {
    test("'survey' → 'Survey'", () {
      expect(modeLabel('survey'), equals('Survey'));
    });

    test("'checklist' → 'Checklist'", () {
      expect(modeLabel('checklist'), equals('Checklist'));
    });

    test('null → empty string', () {
      expect(modeLabel(null), equals(''));
    });

    test("'penalty' → empty string (no label needed)", () {
      expect(modeLabel('penalty'), equals(''));
    });
  });
}
