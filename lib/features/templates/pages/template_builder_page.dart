import 'package:flutter/material.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:get_it/get_it.dart';

/// 6C: Template Builder — metadata form + scoring rule toggles + section/criteria list (read-only).
class TemplateBuilderPage extends StatefulWidget {
  final String templateId;
  const TemplateBuilderPage({super.key, required this.templateId});

  @override
  State<TemplateBuilderPage> createState() => _TemplateBuilderPageState();
}

class _TemplateBuilderPageState extends State<TemplateBuilderPage> {
  late final AppDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = GetIt.I<DatabaseService>().db;
    _loadData();
  }

  bool _loading = true;

  CachedTemplate? _template;
  List<_SectionData> _sections = [];

  // Scoring rule toggles
  bool _progressiveRepeatPenalty = false;

  Future<void> _loadData() async {
    final templates = await _db.select(_db.cachedTemplates).get();
    _template = templates.where((t) => t.id == widget.templateId).firstOrNull;

    // Build section list from cached submissions' section scores
    // (Template sections aren't cached separately — show metadata only)
    _sections = [];

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_template?.title ?? 'Template Builder')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Metadata Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Template Metadata',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _MetadataRow(
                          label: 'Title',
                          value: _template?.title ?? '—',
                        ),
                        _MetadataRow(
                          label: 'Type',
                          value: _template?.type ?? '—',
                        ),
                        _MetadataRow(
                          label: 'Description',
                          value: _template?.description ?? '—',
                        ),
                        _MetadataRow(
                          label: 'Version',
                          value: _template?.version.toString() ?? '1',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Scoring Rules Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scoring Rules',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Progressive Repeat Penalty'),
                          subtitle: const Text(
                            'n² escalation for repeated faults (display only — requires server sync)',
                          ),
                          value: _progressiveRepeatPenalty,
                          onChanged: (v) =>
                              setState(() => _progressiveRepeatPenalty = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sections placeholder
                Text('Sections', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),

                if (_sections.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Section/criteria editing is available when connected to the server.\n'
                        'Sections are managed from the admin dashboard.',
                      ),
                    ),
                  )
                else
                  ..._sections.map(
                    (s) => Card(
                      child: ListTile(
                        title: Text(s.title),
                        subtitle: Text(
                          '${s.criteriaCount} criteria • Weight: ${s.weight}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  final String title;
  final int criteriaCount;
  final double weight;
  _SectionData({
    required this.title,
    required this.criteriaCount,
    required this.weight,
  });
}
