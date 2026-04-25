import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture: Oversized UI Split Verification', () {
    
    test('Audit Approval Page should be split into widgets', () {
      final widgetsDir = Directory('lib/features/admin/pages/widgets');
      expect(widgetsDir.existsSync(), isTrue, reason: 'Widgets directory must be created for Admin pages.');
      
      final files = widgetsDir.listSync().map((e) => e.path).toList();
      final hasApprovalWidgets = files.any((path) => path.contains('approval'));
      expect(hasApprovalWidgets, isTrue, reason: 'audit_approval_page.dart must be decomposed into approval widgets.');
    });

    test('Store Management Page should be split into widgets', () {
      final widgetsDir = Directory('lib/features/admin/pages/widgets');
      expect(widgetsDir.existsSync(), isTrue, reason: 'Widgets directory must be created for Admin pages.');
      
      final files = widgetsDir.listSync().map((e) => e.path).toList();
      final hasStoreWidgets = files.any((path) => path.contains('store'));
      expect(hasStoreWidgets, isTrue, reason: 'store_management_page.dart must be decomposed into store widgets.');
    });

    test('History Page should be split into widgets', () {
      final widgetsDir = Directory('lib/features/audit/pages/widgets');
      expect(widgetsDir.existsSync(), isTrue, reason: 'Widgets directory must be created for Audit pages.');
      
      final files = widgetsDir.listSync().map((e) => e.path).toList();
      final hasHistoryWidgets = files.any((path) => path.contains('history'));
      expect(hasHistoryWidgets, isTrue, reason: 'history_page.dart must be decomposed into history widgets.');
    });

    test('Audit Form Page should be split into widgets', () {
      final widgetsDir = Directory('lib/features/audit/pages/widgets');
      expect(widgetsDir.existsSync(), isTrue, reason: 'Widgets directory must be created for Audit pages.');
      
      final files = widgetsDir.listSync().map((e) => e.path).toList();
      final hasFormWidgets = files.any((path) => path.contains('form') || path.contains('section'));
      expect(hasFormWidgets, isTrue, reason: 'audit_form_page.dart must be decomposed into form widgets.');
    });
  });
}
