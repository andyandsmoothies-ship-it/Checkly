// Test Plan: Slice 4 — Progressive CCP/Risk Disclosure (BL-1 through BL-5)
//
// Two-gate logic (mirrors criterion_editor.dart's planned implementation):
//
// Gate 1 — BLOCKLIST: modeAllows = scoringMode != 'survey' && scoringMode != 'checklist'
// Gate 2 — ALLOWLIST+exception: show = modeAllows && inputTypeScored && (globalEnabled || criterion.flag)
//
// This is an explicit BLOCKLIST — unknown/future modes DEFAULT to showing (safe, opposite of sub-section rule).
//
// Behavioral Expectations (per plan):
//   EDD-A: penalty+ccpOff+criterionFalse → false (novice clean view)
//   EDD-B: penalty+ccpOn → true (admin unlocked)
//   EDD-C: criterion.isCcp=true + globalOff → true (data preservation, Gotcha #6)
//   EDD-D: survey + ccpOn → false (BLOCKLIST)
//   EDD-E: checklist + ccpOn → false (BLOCKLIST)
//   EDD-F: null mode + ccpOn → true (null treated as non-restricted)
//   EDD-G: text/single_choice/multi_choice → false regardless (Gotcha #11)

import 'package:flutter_test/flutter_test.dart';

// ── Pure helper mirroring criterion_editor.dart's planned local logic ─────────
/// Gate 1: BLOCKLIST — survey and checklist block CCP/Risk.
/// All other modes (penalty, accumulation, null, unknown) allow.
bool modeAllows(String? scoringMode) =>
    scoringMode != 'survey' && scoringMode != 'checklist';

/// Gate 2: inputTypeScored — mirrors Gotcha #11 exclusion.
bool inputTypeScored(String inputType) =>
    inputType != 'text' &&
    inputType != 'single_choice' &&
    inputType != 'multi_choice';

/// Combined CCP visibility logic.
bool showCcp({
  required String inputType,
  required String? scoringMode,
  required bool globalCcpEnabled,
  required bool criterionIsCcp,
}) =>
    modeAllows(scoringMode) &&
    inputTypeScored(inputType) &&
    (globalCcpEnabled || criterionIsCcp);

/// Combined Risk visibility logic (mirrors CCP).
bool showRisk({
  required String inputType,
  required String? scoringMode,
  required bool globalRiskEnabled,
  required bool criterionIsRisk,
}) =>
    modeAllows(scoringMode) &&
    inputTypeScored(inputType) &&
    (globalRiskEnabled || criterionIsRisk);

/// Divider visibility — only if at least one toggle is shown.
bool showDivider({required bool ccpVisible, required bool riskVisible}) =>
    ccpVisible || riskVisible;

void main() {
  // ── Gate 1: modeAllows BLOCKLIST ─────────────────────────────────────────
  group('modeAllows: BLOCKLIST gate (BL-1)', () {
    test('survey → modeAllows is FALSE', () {
      expect(modeAllows('survey'), isFalse);
    });

    test('checklist → modeAllows is FALSE', () {
      expect(modeAllows('checklist'), isFalse);
    });

    test('penalty → modeAllows is TRUE', () {
      expect(modeAllows('penalty'), isTrue);
    });

    test('accumulation → modeAllows is TRUE', () {
      expect(modeAllows('accumulation'), isTrue);
    });

    test('null → modeAllows is TRUE (EDD-F backward compat)', () {
      expect(modeAllows(null), isTrue);
    });

    test("unknown 'qc' → modeAllows is TRUE (safe default)", () {
      expect(modeAllows('qc'), isTrue);
    });
  });

  // ── Gate 2: inputTypeScored (Gotcha #11 extension) ────────────────────────
  group('inputTypeScored: Gotcha #11 gate (BL-2)', () {
    test('pass_fail → scored', () {
      expect(inputTypeScored('pass_fail'), isTrue);
    });

    test('numeric → scored', () {
      expect(inputTypeScored('numeric'), isTrue);
    });

    test('scale → scored', () {
      expect(inputTypeScored('scale'), isTrue);
    });

    test('text → NOT scored (EDD-G)', () {
      expect(inputTypeScored('text'), isFalse);
    });

    test('single_choice → NOT scored (EDD-G)', () {
      expect(inputTypeScored('single_choice'), isFalse);
    });

    test('multi_choice → NOT scored (EDD-G)', () {
      expect(inputTypeScored('multi_choice'), isFalse);
    });
  });

  // ── BL-3: showCcp combined logic ──────────────────────────────────────────
  group('showCcp combined gate (BL-3)', () {
    // EDD-A: novice clean view
    test('EDD-A: penalty + ccpOff + criterionFalse → hidden', () {
      expect(
        showCcp(
          inputType: 'pass_fail',
          scoringMode: 'penalty',
          globalCcpEnabled: false,
          criterionIsCcp: false,
        ),
        isFalse,
      );
    });

    // EDD-B: admin unlocked
    test('EDD-B: penalty + globalCcpEnabled=true → shown', () {
      expect(
        showCcp(
          inputType: 'pass_fail',
          scoringMode: 'penalty',
          globalCcpEnabled: true,
          criterionIsCcp: false,
        ),
        isTrue,
      );
    });

    // EDD-C: DATA PRESERVATION — Gotcha #6
    test(
      'EDD-C: criterion.isCcp=true + globalOff → shown (data preservation)',
      () {
        expect(
          showCcp(
            inputType: 'pass_fail',
            scoringMode: 'penalty',
            globalCcpEnabled: false,
            criterionIsCcp: true,
          ),
          isTrue,
        );
      },
    );

    // EDD-D: BLOCKLIST — survey blocks regardless of global flag
    test('EDD-D: survey + globalCcpEnabled=true → hidden', () {
      expect(
        showCcp(
          inputType: 'pass_fail',
          scoringMode: 'survey',
          globalCcpEnabled: true,
          criterionIsCcp: true,
        ),
        isFalse,
      );
    });

    // EDD-E: BLOCKLIST — checklist blocks
    test('EDD-E: checklist + globalCcpEnabled=true → hidden', () {
      expect(
        showCcp(
          inputType: 'pass_fail',
          scoringMode: 'checklist',
          globalCcpEnabled: true,
          criterionIsCcp: true,
        ),
        isFalse,
      );
    });

    // EDD-F: null mode → non-restricted
    test('EDD-F: null mode + globalCcpEnabled=true → shown', () {
      expect(
        showCcp(
          inputType: 'pass_fail',
          scoringMode: null,
          globalCcpEnabled: true,
          criterionIsCcp: false,
        ),
        isTrue,
      );
    });

    // EDD-G: non-scored inputType blocks regardless
    test(
      'EDD-G: penalty + globalOn + inputType=text → hidden (Gotcha #11)',
      () {
        expect(
          showCcp(
            inputType: 'text',
            scoringMode: 'penalty',
            globalCcpEnabled: true,
            criterionIsCcp: false,
          ),
          isFalse,
        );
      },
    );

    test('EDD-G: penalty + globalOn + inputType=single_choice → hidden', () {
      expect(
        showCcp(
          inputType: 'single_choice',
          scoringMode: 'penalty',
          globalCcpEnabled: true,
          criterionIsCcp: false,
        ),
        isFalse,
      );
    });

    test('EDD-G: penalty + globalOn + inputType=multi_choice → hidden', () {
      expect(
        showCcp(
          inputType: 'multi_choice',
          scoringMode: 'penalty',
          globalCcpEnabled: true,
          criterionIsCcp: false,
        ),
        isFalse,
      );
    });
  });

  // ── BL-4: showRisk mirrors CCP logic ──────────────────────────────────────
  group('showRisk mirrors CCP gate (BL-4)', () {
    test('penalty + riskOff + criterionFalse → hidden', () {
      expect(
        showRisk(
          inputType: 'pass_fail',
          scoringMode: 'penalty',
          globalRiskEnabled: false,
          criterionIsRisk: false,
        ),
        isFalse,
      );
    });

    test('penalty + globalRiskEnabled=true → shown', () {
      expect(
        showRisk(
          inputType: 'pass_fail',
          scoringMode: 'penalty',
          globalRiskEnabled: true,
          criterionIsRisk: false,
        ),
        isTrue,
      );
    });

    test('criterion.isRisk=true + globalOff → shown (data preservation)', () {
      expect(
        showRisk(
          inputType: 'pass_fail',
          scoringMode: 'penalty',
          globalRiskEnabled: false,
          criterionIsRisk: true,
        ),
        isTrue,
      );
    });

    test('survey + globalRiskEnabled=true → hidden (BLOCKLIST)', () {
      expect(
        showRisk(
          inputType: 'pass_fail',
          scoringMode: 'survey',
          globalRiskEnabled: true,
          criterionIsRisk: true,
        ),
        isFalse,
      );
    });

    test('text inputType + globalRiskEnabled=true → hidden', () {
      expect(
        showRisk(
          inputType: 'text',
          scoringMode: 'penalty',
          globalRiskEnabled: true,
          criterionIsRisk: false,
        ),
        isFalse,
      );
    });
  });

  // ── BL-5: Divider gate ────────────────────────────────────────────────────
  group('showDivider: only renders if at least one toggle shows (BL-5)', () {
    test('both hidden → no divider', () {
      expect(showDivider(ccpVisible: false, riskVisible: false), isFalse);
    });

    test('ccp shown only → divider', () {
      expect(showDivider(ccpVisible: true, riskVisible: false), isTrue);
    });

    test('risk shown only → divider', () {
      expect(showDivider(ccpVisible: false, riskVisible: true), isTrue);
    });

    test('both shown → divider', () {
      expect(showDivider(ccpVisible: true, riskVisible: true), isTrue);
    });
  });
}
