/// Test Plan (Sentinel — Detroit Style)
/// ======================================
/// Target: _MainShell._indexFromLocation (private static helper)
///
/// Observable contract: The bottom nav's active index must correctly reflect
/// the current router location. We test this by extracting the mapping logic
/// from the public behavior — the nav item that renders as "active" — rather
/// than calling the private static method directly.
///
/// Since _indexFromLocation is private, we validate the INDEX CONTRACT by
/// importing the app_router.dart and extracting the function signature
/// through a @visibleForTesting exposure or by wrapping the logic.
///
/// Strategy: These tests use a pure unit approach by mirroring the exact
/// mapping logic from app_router.dart and asserting the expected indices.
/// This is intentionally a spec-test that will FAIL until the production
/// code is updated to handle /admin/* → 4 (Profile index).
///
/// Contracts from test_contracts_admin_ui_fixes.md:
///   - /admin/dashboard → 4
///   - /admin/users     → 4
///   - /profile         → 4
///   - /home            → 0

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/router/app_router.dart';

void main() {
  group('Router — shellIndexFromLocation', () {
    test(
      '_indexFromLocation_AdminRoute_ReturnsProfileIndex — /admin/dashboard maps to tab 4',
      () {
        // VALID RED: Fails because production code has no `/admin` branch.
        // Current production returns 0. Expected: 4.
        expect(shellIndexFromLocation('/admin/dashboard'), equals(4));
      },
    );

    test(
      '_indexFromLocation_AdminSubRoute_ReturnsProfileIndex — /admin/users maps to tab 4',
      () {
        // VALID RED: Fails for same reason — no /admin branch in production.
        expect(shellIndexFromLocation('/admin/users'), equals(4));
      },
    );

    test(
      '_indexFromLocation_ProfileRoute_ReturnsProfileIndex — /profile maps to tab 4',
      () {
        // HAPPY PATH: Already passes in production code.
        expect(shellIndexFromLocation('/profile'), equals(4));
      },
    );

    test('_indexFromLocation_HomeRoute_ReturnsZero — /home maps to tab 0', () {
      // HAPPY PATH: Already passes in production code.
      expect(shellIndexFromLocation('/home'), equals(0));
    });

    // TC1.2a: /inbox → index 5
    test('_inbox_Route_ExistsInShell — /inbox maps to tab 5', () {
      expect(shellIndexFromLocation('/inbox'), equals(5));
    });
  });
}
