import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../model/submission_dto.dart';
import '../services/submission_api_service.dart';
import '../widgets/read_only_criterion_row.dart';

/// Read-only slide-up sheet showing the full detail of a completed or voided audit.
/// Fetches [SubmissionDetailDto] from the server on open.
/// Must NOT import AuditManager or AuditCriterionCard.
class AuditPreviewSheet extends StatefulWidget {
  final String submissionId;

  const AuditPreviewSheet({super.key, required this.submissionId});

  @override
  State<AuditPreviewSheet> createState() => _AuditPreviewSheetState();
}

class _AuditPreviewSheetState extends State<AuditPreviewSheet> {
  SubmissionDetailDto? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final detail = await GetIt.instance<SubmissionApiService>()
          .getSubmission(widget.submissionId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _error = 'Requires an internet connection.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load audit (${e.response?.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Audit Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            // Body
            Expanded(
              child: _buildBody(context, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_outlined, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetch();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Header card
        _HeaderCard(detail: detail),
        const SizedBox(height: 16),

        // Legacy guard
        if (detail.templateSnapshot == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Legacy audit — section details unavailable.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Answers
        if (detail.answers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No answers recorded for this audit.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...detail.answers.map(
            (answer) => ReadOnlyCriterionRow(answer: answer),
          ),
      ],
    );
  }
}

/// Header card: template, store, auditor, date, score.
class _HeaderCard extends StatelessWidget {
  final SubmissionDetailDto detail;

  const _HeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVoided = detail.status == 'voided';
    final scoreColor = _scoreColor(detail.totalScore, theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template title + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    detail.templateTitle ?? 'Audit',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(theme, isVoided),
              ],
            ),
            const SizedBox(height: 10),

            // Meta rows
            _MetaRow(
              icon: Icons.store_outlined,
              label: detail.storeName ?? '—',
            ),
            _MetaRow(
              icon: Icons.person_outline,
              label: detail.auditorName ?? '—',
            ),
            _MetaRow(
              icon: Icons.calendar_today_outlined,
              label: isVoided
                  ? 'Voided ${_fmt(detail.voidedAt)}'
                  : 'Completed ${_fmt(detail.completedAt)}',
            ),

            // Void reason
            if (isVoided && detail.voidReason != null) ...[
              const SizedBox(height: 6),
              _MetaRow(
                icon: Icons.info_outline,
                label: 'Reason: ${detail.voidReason}',
                color: theme.colorScheme.error,
              ),
            ],

            // Score
            if (!isVoided && detail.totalScore != null) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${detail.totalScore!.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ThemeData theme, bool isVoided) {
    final String label;
    final Color bg;
    final Color fg;

    if (isVoided) {
      label = 'VOIDED';
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurfaceVariant;
    } else {
      label = 'COMPLETED';
      bg = Colors.green.withAlpha(30);
      fg = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Color _scoreColor(double? score, ThemeData theme) {
    if (score == null) return theme.colorScheme.onSurface;
    if (score >= 90) return Colors.green.shade700;
    if (score >= 70) return Colors.orange.shade700;
    return theme.colorScheme.error;
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy HH:mm').format(dt.toLocal());
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: effectiveColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
