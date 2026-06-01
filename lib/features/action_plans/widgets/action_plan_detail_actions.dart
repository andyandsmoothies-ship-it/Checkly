import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:checkly/_shared/exceptions/app_error.dart';
import 'package:checkly/_shared/services/error_display_service.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/widgets/submit_evidence_sheet.dart';

import 'package:get_it/get_it.dart';

class ActionPlanDetailActions {
  static void showSubmitEvidenceSheet(
    BuildContext context,
    ActionPlanDto plan,
    ActionPlanManager manager,
    String currentUserName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubmitEvidenceSheet(
        plan: plan,
        manager: manager,
        currentUserName: currentUserName,
      ),
    );
  }

  static void showVerifyDialog({
    required BuildContext context,
    required ActionPlanDto plan,
    required ActionPlanManager manager,
    required String currentUserName,
    required Function(bool) setBusy,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify & Close'),
        content: const Text(
          'Mark this action plan as resolved? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.maybePop(ctx);
              await _callManager(
                context: context,
                manager: manager,
                setBusy: setBusy,
                fn: () =>
                    manager.closePlan(plan, verifierName: currentUserName),
                successMsg: 'Action plan closed',
              );
            },
            child: const Text('Verify & Close'),
          ),
        ],
      ),
    );
  }

  static void showRejectDialog({
    required BuildContext context,
    required ActionPlanDto plan,
    required ActionPlanManager manager,
    required Function(bool) setBusy,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Evidence'),
        content: const Text(
          'Return this plan to open status? The store manager will '
          'need to resubmit evidence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.maybePop(ctx);
              await _callManager(
                context: context,
                manager: manager,
                setBusy: setBusy,
                fn: () => manager.rejectEvidence(plan),
                successMsg: 'Evidence rejected — plan reopened',
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  static Future<void> _callManager({
    required BuildContext context,
    required ActionPlanManager manager,
    required Function(bool) setBusy,
    required Future<ActionPlanDto> Function() fn,
    required String successMsg,
  }) async {
    setBusy(true);
    try {
      await fn();
      await manager.loadActionPlans();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } on RoleGuardException catch (_) {
      if (context.mounted) {
        GetIt.instance<ErrorDisplayService>().show(
          const AppError(
            code: 'forbidden',
            message:
                'This action requires higher permissions. Please contact your workspace administrator.',
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        GetIt.instance<ErrorDisplayService>().show(
          AppError.fromDioException(e),
        );
      }
    } catch (e) {
      if (context.mounted) {
        GetIt.instance<ErrorDisplayService>().show(
          const AppError(code: 'unknown'),
        );
      }
    } finally {
      setBusy(false);
    }
  }
}
