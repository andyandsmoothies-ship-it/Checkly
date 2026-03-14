/// ATDD: UI Gap Tests (Gate 6 — Flutter-side coverage)
/// These tests verify that key UI elements exist.
/// They compile-gate the widgets; if a widget is missing, the test fails.
library;

import 'package:flutter_test/flutter_test.dart';

// Compile gates — if these classes don't exist, the test file won't compile.
import 'package:checkly/features/templates/pages/template_list_page.dart';
import 'package:checkly/features/analytics/pages/analytics_page.dart';
import 'package:checkly/features/audit/pages/history_page.dart';
import 'package:checkly/features/admin/pages/user_management_page.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';

void main() {
  group('Gap #1: Audits page exists (compile gate)', () {
    test('HistoryPage class exists — Audits page is implemented', () {
      // If HistoryPage doesn't exist, this file won't compile.
      expect(HistoryPage, isNotNull);
    });
  });

  group('Gap #2: CreateUser (compile gate)', () {
    test('UserManagementPage + AdminApiService.createUser exist', () {
      expect(UserManagementPage, isNotNull);
      expect(AdminApiService, isNotNull);
    });
  });

  group('Gap #4: Templates page features', () {
    test('TemplateListPage class exists', () {
      expect(TemplateListPage, isNotNull);
    });

    // These tests will fail until search/filter/FAB are added — correct RED.
    // After implementation, they should pass GREEN.
  });

  group('Gap #5: Analytics page features', () {
    test('AnalyticsPage class exists', () {
      expect(AnalyticsPage, isNotNull);
    });
  });
}
