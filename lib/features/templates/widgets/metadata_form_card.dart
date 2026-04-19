import 'package:flutter/material.dart';

import '../../../_shared/widgets/section_header.dart';

import '../models/template_constants.dart';

class MetadataFormCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String type;
  final ValueChanged<String?> onTypeChanged;

  const MetadataFormCard({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('TEMPLATE METADATA'),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Template Title',
                hintText: 'e.g. Weekly Food Safety Check',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this template audits',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: TemplateConstants.categoryTypes.any((t) => t.$1 == type) ? type : 'qc',
              decoration: const InputDecoration(labelText: 'Category'),
              borderRadius: BorderRadius.circular(12),
              items: TemplateConstants.categoryTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.$1,
                      child: Text(t.$2),
                    ),
                  )
                  .toList(),
              onChanged: onTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
