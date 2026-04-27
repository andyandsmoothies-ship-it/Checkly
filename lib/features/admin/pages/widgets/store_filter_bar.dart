import 'package:flutter/material.dart';

class StoreFilterBar extends StatelessWidget {
  final List<Map<String, dynamic>> areas;
  final String? selectedAreaId;
  final ValueChanged<String?> onChanged;

  const StoreFilterBar({
    super.key,
    required this.areas,
    this.selectedAreaId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DropdownButtonFormField<String?>(
        initialValue: selectedAreaId,
        decoration: const InputDecoration(
          labelText: 'Filter by Area',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Areas')),
          ...areas.map(
            (a) => DropdownMenuItem(
              value: a['id'] as String,
              child: Text(a['name'] as String),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
