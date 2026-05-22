/// Target: shellActiveIndexFromLocation (visible tab index mapping)
///
/// Observable contract: The bottom nav's active tab index must correctly
/// reflect the current router location, relative to the VISIBLE tab list
/// (which varies by the user's capabilities).
///
/// After removing TEMPLATES from ShellTab.all, visible tabs for full caps:
///   HOME(0) | ACTIVITY(1) | PLANS(2) | PROFILE(3) | INBOX(4)
///
/// /templates and /admin/* have no shell tab.
/// The router fallback anchors both on the PROFILE tab.
///
/// Contracts tested:
///   - Full caps: /activity → 1, /plans → 2, /profile → 3, /inbox → 4
///   - /templates and /admin/* → PROFILE index (fallback)
///   - No submissionsList cap: /plans → 1 (ACTIVITY tab hidden, shifts left)
///   - /home → always 0 (Home is always first and always visible)
///   - /inbox → last visible tab (always visible)

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/router/shell_tab.dart';
import 'package:checkly/_shared/constants/app_capabilities.dart';

/// Full caps set: user has all optional tab capabilities.
const _fullCaps = {
  AppCapabilities.submissionsList,
  AppCapabilities.programsList,
  AppCapabilities.templatesCreate,
};

void main() {
  group('shellActiveIndexFromLocation — full caps (all tabs visible)', () {
    test('/home → visual index 0 (Home tab)', () {
      expect(shellActiveIndexFromLocation('/home', _fullCaps), equals(0));
    });

    test('/activity → visual index 1 (Activity tab)', () {
      expect(shellActiveIndexFromLocation('/activity', _fullCaps), equals(1));
    });

    test('/plans → visual index 2 (Plans tab)', () {
      expect(shellActiveIndexFromLocation('/plans', _fullCaps), equals(2));
    });

    test(
      '/templates → visual index 3 (fallback: no Templates tab, anchors PROFILE)',
      () {
        expect(
          shellActiveIndexFromLocation('/templates', _fullCaps),
          equals(3),
        );
      },
    );

    test('/profile → visual index 3 (Profile tab)', () {
      expect(shellActiveIndexFromLocation('/profile', _fullCaps), equals(3));
    });

    test('/inbox → visual index 4 (Inbox tab)', () {
      expect(shellActiveIndexFromLocation('/inbox', _fullCaps), equals(4));
    });

    // /admin/* has no shell tab — anchors on PROFILE tab via fallback.
    test(
      '/admin/* → visual index 3 (PROFILE tab — anchored by router fallback)',
      () {
        expect(
          shellActiveIndexFromLocation('/admin/dashboard', _fullCaps),
          equals(3),
          reason:
              '/admin/* routes have no shell tab; router fallback anchors '
              'user on PROFILE tab (index 3) to preserve navigation context',
        );
      },
    );
  });

  group(
    'shellActiveIndexFromLocation — no submissionsList cap (Activity hidden)',
    () {
      const caps = {
        AppCapabilities.programsList,
        AppCapabilities.templatesCreate,
      };

      // Visible tabs: Home(0) Plans(1) Profile(2) Inbox(3)
      test('/home → 0', () {
        expect(shellActiveIndexFromLocation('/home', caps), equals(0));
      });

      test('/plans → 1 (Activity tab hidden, Plans shifts left)', () {
        expect(shellActiveIndexFromLocation('/plans', caps), equals(1));
      });

      test('/templates → 2 (fallback to PROFILE; no Templates tab)', () {
        expect(shellActiveIndexFromLocation('/templates', caps), equals(2));
      });
    },
  );

  group(
    'shellActiveIndexFromLocation — only Home/Plans/Profile/Inbox visible',
    () {
      const caps = <String>{}; // no optional caps

      // Visible tabs: Home(0) Plans(1) Profile(2) Inbox(3)
      test('/home → 0', () {
        expect(shellActiveIndexFromLocation('/home', caps), equals(0));
      });

      test('/profile → 2', () {
        expect(shellActiveIndexFromLocation('/profile', caps), equals(2));
      });

      test('/inbox → 3', () {
        expect(shellActiveIndexFromLocation('/inbox', caps), equals(3));
      });

      // /activity is hidden — location matches no visible tab → clamp to 0.
      test('/activity → 0 when Activity tab is hidden (clamp to Home)', () {
        expect(
          shellActiveIndexFromLocation('/activity', caps),
          equals(0),
          reason:
              'When Activity tab is hidden, navigating to /activity must '
              'not produce a wrong index — clamped to 0 (Home)',
        );
      });
    },
  );
}
