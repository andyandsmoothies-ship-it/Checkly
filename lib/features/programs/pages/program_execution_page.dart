import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:go_router/go_router.dart';

import '../../programs/manager/program_manager.dart';
import '../model/program_assignment_dto.dart';
import '../model/assignment_status.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/widgets/primitives/bubbly_button.dart';

/// Full-screen page where the Store Manager submits evidence for one
/// program assignment.
///
/// Navigation contract:
/// - Called via `/programs/:assignmentId`.
/// - Routes to `/audit` on "Start Audit".
class ProgramExecutionPage extends StatefulWidget {
  final String assignmentId;

  const ProgramExecutionPage({super.key, required this.assignmentId});

  @override
  State<ProgramExecutionPage> createState() => _ProgramExecutionPageState();
}

class _ProgramExecutionPageState extends State<ProgramExecutionPage> {
  final _manager = GetIt.instance<ProgramManager>();

  ProgramAssignmentDto? _assignment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    final result = await _manager.loadAssignment(widget.assignmentId);
    if (mounted) {
      setState(() {
        _assignment = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleStartAudit() async {
    final assignment = _assignment;
    if (assignment == null || !mounted) return;

    // Get primary store via manager — pages must NOT access the DB directly.
    final storeId = await _manager.getPrimaryStoreId();

    if (!mounted) return;

    final templateId = assignment.templateId ?? '';
    final subId = assignment.activeSubmissionId;
    final programAssignmentId = assignment.id;

    // Replace the current route with the audit route so that navigating back exits the program
    String route =
        '/audit?templateId=$templateId&storeId=$storeId&programAssignmentId=$programAssignmentId';
    if (subId != null && subId.isNotEmpty) {
      route += '&submissionId=$subId';
    }

    context.replace(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _assignment?.programTitle ?? 'Program Task',
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _assignment != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Deadline: ${_formatDeadline(_assignment!.deadline)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignment == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Assignment not found or already submitted.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_assignment!.status ==
                      AssignmentStatus.needsRevision) ...[
                    StrokeCard(
                      color: AppColors.walkingFish,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.flamingo,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Needs Revision',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.flamingo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _assignment!.rejectionComment ??
                                      'Please review and resubmit.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.flamingo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    _assignment!.programTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_assignment!.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    PillChip(
                      label: _assignment!.category.toUpperCase(),
                      type: PillChipType.blue,
                    ),
                  ],
                  const SizedBox(height: 24),
                  BubblyButton(
                    onPressed: _handleStartAudit,
                    color: AppColors.featherGreen,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _assignment!.activeSubmissionId != null &&
                                  _assignment!.activeSubmissionId!.isNotEmpty
                              ? 'Resume Audit'
                              : 'Start Audit',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return 'No deadline';
    final d = deadline.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }
}
