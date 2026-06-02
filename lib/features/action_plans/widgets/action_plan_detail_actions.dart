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
      builder: (ctx) => _VerifyDialog(
        plan: plan,
        manager: manager,
        currentUserName: currentUserName,
        setBusy: setBusy,
        onConfirm: ({required rootCause, required correctionPlan}) async {
          await _callManager(
            context: context,
            manager: manager,
            setBusy: setBusy,
            fn: () => manager.closePlan(
              plan,
              verifierName: currentUserName,
              rootCause: rootCause,
              correctionPlan: correctionPlan,
            ),
            successMsg: 'Action plan closed',
          );
        },
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

class _VerifyDialog extends StatefulWidget {
  final ActionPlanDto plan;
  final ActionPlanManager manager;
  final String currentUserName;
  final Function(bool) setBusy;
  final Future<void> Function({
    required String rootCause,
    required String correctionPlan,
  }) onConfirm;

  const _VerifyDialog({
    required this.plan,
    required this.manager,
    required this.currentUserName,
    required this.setBusy,
    required this.onConfirm,
  });

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  late final TextEditingController _rootCauseCtrl;
  late final TextEditingController _correctionPlanCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _rootCauseCtrl = TextEditingController(text: widget.plan.rootCause);
    _correctionPlanCtrl = TextEditingController(text: widget.plan.correctionPlan);
  }

  @override
  void dispose() {
    _rootCauseCtrl.dispose();
    _correctionPlanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify & Close'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Review and refine the verified root cause and correction plan before closing.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rootCauseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Verified Root Cause',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please describe the verified root cause.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correctionPlanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Verified Correction Plan',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please describe the verified correction plan.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybePop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final rootCause = _rootCauseCtrl.text.trim();
            final correctionPlan = _correctionPlanCtrl.text.trim();
            Navigator.maybePop(context);
            await widget.onConfirm(
              rootCause: rootCause,
              correctionPlan: correctionPlan,
            );
          },
          child: const Text('Verify & Close'),
        ),
      ],
    );
  }
}
