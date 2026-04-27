import 'package:flutter/material.dart';
import '../manager/analytics_manager.dart';

class AnalyticsFilterSheet extends StatelessWidget {
  final AnalyticsManager manager;

  const AnalyticsFilterSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: manager.selectedArea,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Areas')),
                  ...(manager.data?.areaNames ?? []).map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  manager.selectedArea = v;
                  manager.selectedStore = null; // cascade reset
                  Navigator.pop(context);
                  manager.load();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: manager.selectedStore,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Store',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Stores'),
                  ),
                  ...(manager.data?.storeNames ?? []).map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  manager.selectedStore = v;
                  Navigator.pop(context);
                  manager.load();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: manager.selectedType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Audit Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...(manager.data?.templateTypes ?? []).map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  manager.selectedType = v;
                  Navigator.pop(context);
                  manager.load();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: manager.selectedAuditor,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Auditor',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Auditors'),
                  ),
                  ...(manager.data?.auditorNames ?? []).map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  manager.selectedAuditor = v;
                  Navigator.pop(context);
                  manager.load();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: manager.selectedStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                ],
                onChanged: (v) {
                  manager.selectedStatus = v;
                  Navigator.pop(context);
                  manager.load();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: manager.selectedReviewStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Review Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All Review Statuses'),
                  ),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                ],
                onChanged: (v) {
                  manager.selectedReviewStatus = v;
                  Navigator.pop(context);
                  manager.load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
