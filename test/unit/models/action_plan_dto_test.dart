// Phase B TDD — Flutter DTO, Drift Cache, and Offline Transition State
//
// Tests: B1, B5, B6
// - B1: ActionPlanDto parses allowedActions from JSON.
// - B5: Optimistic submit/verify/reject updates do not lose allowedActions.
// - B6: Offline pending entity injects default allowedActions ['view', 'edit', 'delete'].
//
// Source: implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md
// Author: Sentinel (QA)
// Status: 🔴 RED — ActionPlanDto has no allowedActions field; ActionPlan domain
//         transitions build optimistic DTOs without action payload.

import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/domain/action_plan.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal valid JSON payload matching the backend shape (Phase A contract).
Map<String, dynamic> _openPlanJson({List<String>? allowedActions}) => {
  'id': 'plan-b1-001',
  'submissionId': 'sub-001',
  'status': 'open',
  'criteriaLabel': 'Food Safety',
  'groupTitle': 'Hygiene',
  'storeName': 'Store 7',
  'storeId': 'store-001',
  'allowedActions': allowedActions ?? ['view', 'submit_evidence'],
  'createdAt': '2026-05-16T05:30:00Z',
  'updatedAt': '2026-05-16T05:30:00Z',
};

Map<String, dynamic> _pendingVerifyPlanJson() => {
  'id': 'plan-b1-002',
  'status': 'pending_verify',
  'criteriaLabel': 'Food Safety',
  'groupTitle': 'Hygiene',
  'allowedActions': ['view', 'verify_close', 'reject_evidence'],
  'createdAt': '2026-05-16T05:30:00Z',
  'updatedAt': '2026-05-16T05:30:00Z',
};

/// Creates an ActionPlanDto with allowedActions already set.
ActionPlanDto _makeDto({
  required String status,
  List<String>? allowedActions,
}) => ActionPlanDto(
  id: 'plan-test',
  status: status,
  criteriaLabel: 'Criteria A',
  groupTitle: 'Section 1',
  allowedActions: allowedActions,
  createdAt: DateTime.utc(2026, 5, 1),
  updatedAt: DateTime.utc(2026, 5, 1),
);

void main() {
  // ===========================================================================
  // B1 — ActionPlanDto parses allowedActions from JSON
  // ===========================================================================
  group('B1: ActionPlanDto.fromJson parses allowedActions', () {
    test('B1a: Parses submit_evidence actions for an open plan', () {
      // Arrange
      final json = _openPlanJson();

      // Act
      final dto = ActionPlanDto.fromJson(json);

      // Assert
      expect(
        dto.allowedActions,
        isNotNull,
        reason: 'allowedActions must be parsed from JSON; field is missing.',
      );
      expect(
        dto.allowedActions,
        containsAll(['view', 'submit_evidence']),
        reason: 'An open plan should allow view and submit_evidence actions.',
      );
      expect(
        dto.allowedActions,
        isNot(contains('verify_close')),
        reason: 'An open plan should NOT allow verify_close.',
      );
    });

    test('B1b: Parses verify actions for a pending_verify plan', () {
      final dto = ActionPlanDto.fromJson(_pendingVerifyPlanJson());

      expect(dto.allowedActions, isNotNull);
      expect(
        dto.allowedActions,
        containsAll(['view', 'verify_close', 'reject_evidence']),
      );
      expect(dto.allowedActions, isNot(contains('submit_evidence')));
    });

    test(
      'B1c: allowedActions is null when server omits the field (safe fallback)',
      () {
        // Arrange: JSON without allowedActions key (older API or different role)
        final json = {
          'id': 'plan-null',
          'status': 'open',
          'criteriaLabel': 'Criteria',
          'groupTitle': 'Group',
          'createdAt': '2026-05-16T05:30:00Z',
          'updatedAt': '2026-05-16T05:30:00Z',
        };

        // Act
        final dto = ActionPlanDto.fromJson(json);

        // Assert — must not throw; field is nullable
        expect(
          dto.allowedActions,
          isNull,
          reason:
              'allowedActions should be null when absent from JSON, '
              'not an empty list or an error.',
        );
      },
    );

    test(
      'B1d: allowedActions preserves the full list from JSON without truncation',
      () {
        final json = _openPlanJson(
          allowedActions: ['view', 'submit_evidence', 'delete'],
        );

        final dto = ActionPlanDto.fromJson(json);

        expect(dto.allowedActions, hasLength(3));
        expect(dto.allowedActions, contains('delete'));
      },
    );
  });

  // ===========================================================================
  // B5 — Optimistic transitions preserve allowedActions
  // ===========================================================================
  group('B5: Optimistic transitions do not lose allowedActions', () {
    test('B5a: submitEvidence resets allowedActions to pending_verify set', () {
      // Arrange: open plan with submit_evidence permission
      final plan = ActionPlan(
        _makeDto(status: 'open', allowedActions: ['view', 'submit_evidence']),
      );

      // Act: optimistic transition
      final updated = plan.submitEvidence(
        role: 'store_manager',
        correctionPlan: 'Fix the seal',
        currentUserName: 'manager@store.com',
      );

      // Assert: allowedActions is NOT null after transition
      expect(
        updated.dto.allowedActions,
        isNotNull,
        reason:
            'submitEvidence must set optimistic allowedActions; '
            'it must not null them out.',
      );
      // After submit → pending_verify: submit_evidence should be gone
      expect(
        updated.dto.allowedActions,
        isNot(contains('submit_evidence')),
        reason:
            'Once in pending_verify, the submitter can no longer submit '
            'evidence again.',
      );
      expect(updated.dto.status, 'pending_verify');
    });

    test('B5b: closePlan sets allowedActions to view-only', () {
      // Arrange: pending_verify plan auditor can close
      final plan = ActionPlan(
        _makeDto(
          status: 'pending_verify',
          allowedActions: ['view', 'verify_close', 'reject_evidence'],
        ),
      );

      final updated = plan.closePlan(
        role: 'auditor',
        verifierName: 'auditor@co.com',
      );

      expect(updated.dto.allowedActions, isNotNull);
      // Closed plan: no mutation actions remain
      expect(updated.dto.allowedActions, isNot(contains('verify_close')));
      expect(updated.dto.allowedActions, isNot(contains('reject_evidence')));
      expect(updated.dto.status, 'closed');
    });

    test('B5c: rejectEvidence resets allowedActions back to open set', () {
      // Arrange: pending_verify plan auditor can reject
      final plan = ActionPlan(
        _makeDto(
          status: 'pending_verify',
          allowedActions: ['view', 'verify_close', 'reject_evidence'],
        ),
      );

      final updated = plan.rejectEvidence(
        role: 'auditor',
        reason: 'Photo unclear',
      );

      expect(updated.dto.allowedActions, isNotNull);
      // Back to open: store manager can submit again
      expect(updated.dto.allowedActions, contains('submit_evidence'));
      expect(updated.dto.allowedActions, isNot(contains('verify_close')));
      expect(updated.dto.status, 'open');
    });

    test(
      'B5d: Transition from a plan with null allowedActions still produces valid payload',
      () {
        // Edge case: plan arrived from an older server response without allowedActions.
        // The transition must not crash and must produce a valid (non-null) action list.
        final plan = ActionPlan(_makeDto(status: 'open', allowedActions: null));

        final updated = plan.submitEvidence(
          role: 'store_manager',
          correctionPlan: 'Fix',
          currentUserName: 'sm@store.com',
        );

        // The result must be a valid DTO (no crash). Action list should not be null.
        expect(updated.dto.status, 'pending_verify');
        expect(
          updated.dto.allowedActions,
          isNotNull,
          reason:
              'Even when input allowedActions is null, the output must still '
              'produce a safe default action set for the new state.',
        );
      },
    );
  });

  // ===========================================================================
  // B6 — Offline pending entities inject default allowedActions
  // ===========================================================================
  group('B6: Offline pending entity has default allowedActions', () {
    test('B6a: ActionPlanDto.offline constructor injects default actions', () {
      // Arrange: create an offline-pending plan (syncStatus = pending).
      // The Builder must expose a factory or named constructor for offline creation.
      final offline = ActionPlanDto.offline(
        id: 'local-uuid-001',
        criteriaLabel: 'Hygiene Check',
        groupTitle: 'Section A',
      );

      // Assert
      expect(
        offline.allowedActions,
        isNotNull,
        reason:
            'Offline-created plans must have default allowedActions injected '
            'immediately, not wait for server sync.',
      );
      expect(
        offline.allowedActions,
        containsAll(['view', 'edit', 'delete']),
        reason:
            'Default offline actions are view, edit, delete per the plan spec.',
      );
      expect(
        offline.syncStatus,
        'pending',
        reason: 'Offline plans must have syncStatus = pending.',
      );
    });

    test(
      'B6b: Standard fromJson-parsed DTO does not expose a syncStatus field',
      () {
        // The syncStatus field should only exist on offline-created DTOs,
        // not on server-originated DTOs. This verifies there is no accidental leakage.
        final dto = ActionPlanDto.fromJson(_openPlanJson());

        // syncStatus for server-originated plans is null (not applicable)
        expect(
          dto.syncStatus,
          isNull,
          reason:
              'Server-originated plans do not carry a syncStatus; '
              'that field is reserved for offline-created plans.',
        );
      },
    );
  });
}
