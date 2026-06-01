import 'dart:io';

void main() {
  final files = [
    'lib/features/action_plans/widgets/action_plan_detail_actions.dart',
    'lib/features/admin/pages/user_management_page.dart',
    'lib/features/admin/pages/widgets/audit_review_sheet.dart',
    'lib/features/admin/pages/widgets/risk_form_sheet.dart',
    'lib/features/admin/pages/widgets/store_form_sheet.dart',
    'lib/features/admin/widgets/dropdown_card.dart',
    'lib/features/analytics/pages/analytics_page.dart',
    'lib/features/analytics/pages/area_bod_analytics_page.dart',
    'lib/features/analytics/pages/bod_analytics_page.dart',
    'lib/features/analytics/widgets/area_bod_ap_aging_funnel.dart',
    'lib/features/analytics/widgets/area_bod_kpi_grid.dart',
    'lib/features/analytics/widgets/bod_ap_aging_funnel.dart',
    'lib/features/analytics/widgets/bod_auditor_scatter.dart',
    'lib/features/analytics/widgets/bod_category_weakness.dart',
    'lib/features/analytics/widgets/bod_kpi_grid.dart',
    'lib/features/analytics/widgets/bod_store_leaderboard.dart',
    'lib/features/audit/pages/audit_form_page.dart',
    'lib/features/audit/pages/widgets/history_list_view.dart',
    'lib/features/audit/pages/widgets/schedule_audit_sheet.dart',
    'lib/features/audit/widgets/audit_criterion_sheet.dart',
    'lib/features/audit/widgets/audit_photo_section.dart',
    'lib/features/audit/widgets/risks_panel.dart',
    'lib/features/dashboard/pages/dashboard_page.dart',
    'lib/features/dashboard/pages/widgets/submission_row.dart',
    'lib/features/dashboard/widgets/tactical_history_drawer.dart',
    'lib/features/programs/pages/program_create_wizard_page.dart',
    'lib/features/stores/pages/store_selector_page.dart',
    'lib/features/templates/widgets/criterion_editor.dart',
    'lib/features/templates/widgets/criterion_editor_drawer.dart',
    'lib/features/templates/widgets/wizard_step_sections.dart',
    'lib/features/user_groups/pages/user_group_list_page.dart',
  ];

  for (final path in files) {
    var p = path.replaceAll('\\', '/');
    final file = File(p);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    if (!content.contains('Icons.close_rounded')) {
      stdout.writeln('MISSING CLOSE ICON: $p');
    }
    if (!content.contains('Navigator.maybePop(')) {
      stdout.writeln('MISSING MAYBE_POP: $p');
    }
  }
}
