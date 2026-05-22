import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/router/shell_tab.dart';
import 'package:checkly/_shared/constants/app_capabilities.dart';

void main() {
  group('ShellTab Visibility', () {
    test('TEMPLATES is no longer in ShellTab.all', () {
      final hasTemplatesTab = ShellTab.all.any(
        (tab) => tab.route == '/templates',
      );
      expect(
        hasTemplatesTab,
        isFalse,
        reason: 'TEMPLATES tab should be relocated to Profile',
      );
    });

    test(
      'User with templatesCreate cap sees exactly 5 tabs (if they also have submissionsList)',
      () {
        final caps = {
          AppCapabilities.templatesCreate,
          AppCapabilities.submissionsList,
        };

        final visibleTabs = ShellTab.all.where((tab) {
          return tab.requiredCapability == null ||
              caps.contains(tab.requiredCapability);
        }).toList();

        expect(
          visibleTabs.length,
          5,
          reason: 'HOME, ACTIVITY, PLANS, PROFILE, INBOX',
        );
      },
    );

    test(
      'shellActiveIndexFromLocation falls back to PROFILE for /templates route',
      () {
        final caps = {
          AppCapabilities.templatesCreate,
          AppCapabilities.submissionsList,
        };
        // PROFILE is index 3 in the visible list (0: HOME, 1: ACTIVITY, 2: PLANS, 3: PROFILE, 4: INBOX)
        final index = shellActiveIndexFromLocation('/templates', caps);
        expect(index, 3);
      },
    );

    test(
      'shellActiveIndexFromLocation falls back to PROFILE for /admin routes',
      () {
        final caps = {AppCapabilities.submissionsList};
        // PROFILE is index 3
        final index = shellActiveIndexFromLocation('/admin/dashboard', caps);
        expect(index, 3);
      },
    );
  });
}
