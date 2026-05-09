import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../model/program_assignment_dto.dart';
import '../../programs/manager/program_manager.dart';
import 'widgets/program_evidence_form.dart';

/// Full-screen page where the Store Manager submits evidence for one
/// program assignment.
///
/// Navigation contract:
/// - Called via `/programs/:assignmentId`.
/// - On success: SnackBar + `context.pop()`.
/// - On dirty form + back: handled by [PopScope].
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
  bool _isDirty = false;

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

  Future<void> _handleSubmit(String note, {String? photoPath}) async {
    try {
      await _manager.submitEvidence(
        widget.assignmentId,
        note,
        photoPath: photoPath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit queued — will sync when online'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Clear dirty so PopScope allows pop, then pop.
        setState(() => _isDirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isDirty) {
          showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text(
                'Your note will be lost. Are you sure you want to go back?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep editing'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                    Navigator.pop(context);
                  },
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
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
                      onPressed: () => Navigator.pop(context),
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
                    if (_assignment!.status == 'needs_revision') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Needs Revision',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _assignment!.rejectionComment ??
                                        'Please review and resubmit.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
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
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(_assignment!.category),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ProgramEvidenceForm(
                      assignmentTitle: _assignment!.programTitle,
                      onSubmit: (note, {photoPath}) {
                        setState(() => _isDirty = true);
                        return _handleSubmit(note, photoPath: photoPath);
                      },
                    ),
                  ],
                ),
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
