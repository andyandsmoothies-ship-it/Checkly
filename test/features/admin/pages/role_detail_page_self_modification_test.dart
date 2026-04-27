import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/admin/pages/role_detail_page.dart';
import 'package:checkly/features/admin/manager/role_manager.dart';
import 'package:checkly/features/admin/model/role_dto.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

class MockRoleManager extends Mock implements RoleManager {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPolicyManager extends Mock implements PolicyManager {}

void main() {
  setUp(() {
    GetIt.I.allowReassignment = true;
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets(
    'Self-modification guard disables admin:access toggle for admin role',
    (tester) async {
      // Arrange
      final roleManager = MockRoleManager();
      final connectivity = MockConnectivityService();
      final policy = MockPolicyManager();

      GetIt.I.registerSingleton<RoleManager>(roleManager);
      GetIt.I.registerSingleton<ConnectivityService>(connectivity);
      GetIt.I.registerSingleton<PolicyManager>(policy);

      when(() => connectivity.isOnline).thenReturn(true);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => Stream.value(true));
      when(() => policy.can('admin:manage_roles')).thenReturn(true);

      final catalogNotifier = ValueNotifier<List<String>>(['admin:access']);
      when(() => roleManager.catalog).thenReturn(catalogNotifier);

      when(() => roleManager.catalogMeta).thenReturn(
        ValueNotifier({
          'admin:access': const CapabilityMeta(
            label: 'Admin Console Access',
            group: 'Admin',
            description: 'Grants access to admin features',
          ),
        }),
      );

      final rolesNotifier = ValueNotifier<List<RoleDto>>([
        RoleDto(role: 'admin', capabilities: ['admin:access']),
      ]);
      when(() => roleManager.roles).thenReturn(rolesNotifier);

      final isLoadingNotifier = ValueNotifier<bool>(false);
      when(() => roleManager.isLoading).thenReturn(isLoadingNotifier);

      when(() => roleManager.loadRoles()).thenAnswer((_) async {});
      when(() => roleManager.loadCatalog()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: RoleDetailPage(role: 'admin')),
      );
      await tester.pumpAndSettle();

      // Assert
      final tileFinder = find.byType(CheckboxListTile);
      expect(tileFinder, findsOneWidget);

      final CheckboxListTile tile = tester.widget(tileFinder);

      // We expect the checkbox to be disabled (onChanged == null)
      // because we are viewing the 'admin' role and looking at the 'admin:access' capability
      expect(tile.onChanged, isNull);
    },
  );
}
