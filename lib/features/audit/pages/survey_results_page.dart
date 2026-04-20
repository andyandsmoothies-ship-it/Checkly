import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../manager/survey_results_manager.dart';
import '../widgets/survey_question_card.dart';

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
  late final SurveyResultsManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<SurveyResultsManager>();
    _manager.load(widget.templateId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Survey Results')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_manager.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(_manager.error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => _manager.load(widget.templateId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (_manager.results.isEmpty) {
            return Center(
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
            );
          }
          return RefreshIndicator(
            onRefresh: () => _manager.load(widget.templateId),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _manager.results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  SurveyQuestionCard(result: _manager.results[index]),
            ),
          );
        },
      ),
    );
  }
}
