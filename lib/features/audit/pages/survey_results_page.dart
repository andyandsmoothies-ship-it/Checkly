import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/submission_api_service.dart';

final _di = GetIt.instance;

/// Displays aggregated survey results for a template —
/// horizontal bar charts per question showing option distribution.
class SurveyResultsPage extends StatefulWidget {
  final String templateId;
  const SurveyResultsPage({super.key, required this.templateId});

  @override
  State<SurveyResultsPage> createState() => _SurveyResultsPageState();
}

class _SurveyResultsPageState extends State<SurveyResultsPage> {
  bool _loading = true;
  String? _error;
  List<SurveyQuestionResult> _results = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _di<SubmissionApiService>().getSurveyResults(
        widget.templateId,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load survey results: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Survey Results')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(_error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.poll_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No survey responses yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete some audits to see results here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _QuestionCard(result: _results[index]),
              ),
            ),
    );
  }
}

// ── Question Card ──

class _QuestionCard extends StatelessWidget {
  final SurveyQuestionResult result;
  const _QuestionCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question label
            Text(
              result.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.totalResponses} response${result.totalResponses == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Option bars
            ...result.options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionBar(
                  label: opt.value,
                  count: opt.count,
                  percentage: opt.percentage,
                  maxPercentage: result.options.isNotEmpty
                      ? result.options.first.percentage
                      : 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Option Bar ──

class _OptionBar extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final double maxPercentage;

  const _OptionBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.maxPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barFraction = maxPercentage > 0 ? percentage / maxPercentage : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: barFraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withAlpha(100),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

// ── Model classes ──

class SurveyQuestionResult {
  final String? criterionId;
  final String label;
  final int totalResponses;
  final List<SurveyOptionCount> options;

  const SurveyQuestionResult({
    this.criterionId,
    required this.label,
    required this.totalResponses,
    required this.options,
  });

  factory SurveyQuestionResult.fromJson(Map<String, dynamic> json) =>
      SurveyQuestionResult(
        criterionId: json['criterionId'] as String?,
        label: json['label'] as String? ?? 'Unknown',
        totalResponses: json['totalResponses'] as int? ?? 0,
        options:
            (json['options'] as List<dynamic>?)
                ?.map(
                  (o) => SurveyOptionCount.fromJson(o as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

class SurveyOptionCount {
  final String value;
  final int count;
  final double percentage;

  const SurveyOptionCount({
    required this.value,
    required this.count,
    required this.percentage,
  });

  factory SurveyOptionCount.fromJson(Map<String, dynamic> json) =>
      SurveyOptionCount(
        value: json['value'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}
