import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/admin/pages/role_list_page.dart';
import 'package:checkly/features/admin/pages/role_detail_page.dart';
import 'package:checkly/features/admin/manager/role_manager.dart';
import 'package:checkly/features/admin/model/role_dto.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';

// ── Fakes & Mocks ──────────────────────────────────────────────────────────

/// Controllable connectivity fake — drives the stream to test dynamic drops.
class _FakeConnectivity implements ConnectivityService {
  bool _online;
  final _controller = StreamController<bool>.broadcast();

  _FakeConnectivity({bool online = true}) : _online = online;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void goOffline() {
    _online = false;
    _controller.add(false);
  }

  void dispose() => _controller.close();
}

class MockAdminApiService extends Mock implements AdminApiService {}

class MockAuthManager extends Mock implements AuthManager {}

// ── Helpers ────────────────────────────────────────────────────────────────

final _di = GetIt.instance;

Widget _pump(Widget child) => MaterialApp(home: child);

final _mockRoles = [
  RoleDto(role: 'auditor', capabilities: ['submissions:list']),
];

final _catalog = ['submissions:list', 'templates:create'];

void main() {
  group('ATDD — PBAC Admin Dashboard Flow', () {
    late _FakeConnectivity connectivity;
    late MockAdminApiService mockApi;
    late RoleManager manager;
    late PolicyManager policy;
    late MockAuthManager mockAuth;

    setUp(() {
      connectivity = _FakeConnectivity(online: true);
      mockApi = MockAdminApiService();
      mockAuth = MockAuthManager();

      // Default capability stub: has admin:manage_roles
      when(() => mockAuth.capabilities)
          .thenReturn(ValueNotifier({'admin:manage_roles', 'admin:access'}));

      policy = PolicyManager(auth: mockAuth);
      manager = RoleManager(adminApiService: mockApi);

      // Default API stubs
      when(() => mockApi.getRoles()).thenAnswer((_) async => _mockRoles);
      when(() => mockApi.getCapabilityCatalog())
          .thenAnswer((_) async => _catalog);

      _di.pushNewScope(init: (g) {
        g.registerSingleton<ConnectivityService>(connectivity);
        g.registerSingleton<RoleManager>(manager);
        g.registerSingleton<PolicyManager>(policy);
      });
    });

    tearDown(() async {
      await _di.popScope();
      connectivity.dispose();
      manager.dispose();
    });

    // ── AT-01 ───────────────────────────────────────────────────────────────
    testWidgets(
      'AT-01: RoleListPage_WhenOffline_ShowsOfflineLock',
      (tester) async {
        // Arrange: rebuild scope with offline connectivity
        await _di.popScope();
        connectivity.dispose();
        connectivity = _FakeConnectivity(online: false);
        _di.pushNewScope(init: (g) {
          g.registerSingleton<ConnectivityService>(connectivity);
          g.registerSingleton<RoleManager>(manager);
          g.registerSingleton<PolicyManager>(policy);
        });

        // Act
        await tester.pumpWidget(_pump(const RoleListPage()));
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.textContaining('Stable Internet Connection'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
        verifyNever(() => mockApi.getRoles());
      },
    );

    // ── AT-02 ───────────────────────────────────────────────────────────────
    testWidgets(
      'AT-02: RoleDetailPage_WhenConnectionDrops_HidesCheckboxes',
      (tester) async {
        // Arrange: online, roles and catalog loaded
        await tester.pumpWidget(_pump(const RoleDetailPage(role: 'auditor')));
        await manager.loadRoles();
        await manager.loadCatalog();
        await tester.pumpAndSettle();

        // Verify checkboxes visible while online
        expect(find.byType(CheckboxListTile), findsWidgets);
        expect(find.byIcon(Icons.wifi_off), findsNothing);

        // Act: drop connection
        connectivity.goOffline();
        await tester.pumpAndSettle();

        // Assert: lock screen replaces checkboxes
        expect(find.byType(CheckboxListTile), findsNothing);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      },
    );

    // ── AT-03 ───────────────────────────────────────────────────────────────
    testWidgets(
      'AT-03: RoleDetailPage_WhenNoCapability_CheckboxesDisabled',
      (tester) async {
        // Arrange: user lacks admin:manage_roles
        when(() => mockAuth.capabilities)
            .thenReturn(ValueNotifier({'admin:access'})); // no manage_roles

        await tester.pumpWidget(_pump(const RoleDetailPage(role: 'auditor')));
        await manager.loadRoles();
        await manager.loadCatalog();
        await tester.pumpAndSettle();

        // Assert: checkboxes rendered but all disabled
        final checkboxes = tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .toList();
        expect(checkboxes, isNotEmpty);
        for (final cb in checkboxes) {
          expect(cb.enabled, isFalse,
              reason: 'Checkbox for ${cb.title} must be disabled without manage_roles');
        }
      },
    );

    // ── AT-04 ───────────────────────────────────────────────────────────────
    testWidgets(
      'AT-04: RoleDetailPage_GrantRevoke_FiresServiceAndReloads',
      (tester) async {
        // Arrange: auditor starts without templates:create
        // grantCapability succeeds
        when(() => mockApi.grantCapability(
              role: 'auditor',
              capability: 'templates:create',
            )).thenAnswer((_) async {});

        // getRoles: first call returns base list, subsequent returns updated list
        // Use a flag controlled by grantCapability being called
        var granted = false;
        when(() => mockApi.grantCapability(
              role: any(named: 'role'),
              capability: any(named: 'capability'),
            )).thenAnswer((_) async { granted = true; });
        when(() => mockApi.getRoles()).thenAnswer((_) async {
          if (granted) {
            return [
              RoleDto(role: 'auditor',
                  capabilities: ['submissions:list', 'templates:create']),
            ];
          }
          return _mockRoles; // submissions:list only
        });

        await tester.pumpWidget(_pump(const RoleDetailPage(role: 'auditor')));
        await manager.loadRoles();
        await manager.loadCatalog();
        await tester.pumpAndSettle();

        // Verify templates:create appears as unchecked
        final uncheckedTile = find.widgetWithText(CheckboxListTile, 'templates:create');
        expect(uncheckedTile, findsOneWidget);
        final tileBefore = tester.widget<CheckboxListTile>(uncheckedTile);
        expect(tileBefore.value, isFalse, reason: 'templates:create should start unchecked');

        // Act: tap the unchecked capability
        await tester.tap(uncheckedTile);
        await tester.pumpAndSettle();

        // Assert: grantCapability fired, roles reloaded with updated list
        expect(granted, isTrue);
        verify(() => mockApi.getRoles()).called(greaterThanOrEqualTo(2));
        expect(
          manager.roles.value!.first.capabilities,
          contains('templates:create'),
        );
      },
    );

    // ── AT-05 ───────────────────────────────────────────────────────────────
    testWidgets(
      'AT-05: RoleDetailPage_AtomicFailure_SnackBar',
      (tester) async {
        // Arrange: grant throws 403
        when(() => mockApi.grantCapability(
              role: 'auditor',
              capability: any(named: 'capability'),
            )).thenThrow(Exception('403 Forbidden'));

        await tester.pumpWidget(_pump(const RoleDetailPage(role: 'auditor')));
        await manager.loadRoles();
        await manager.loadCatalog();
        await tester.pumpAndSettle();

        // Capture roles before tap
        final rolesBefore = List.from(manager.roles.value!.first.capabilities);

        // Act: tap an unassigned capability
        final uncheckedTile =
            find.widgetWithText(CheckboxListTile, 'templates:create');
        await tester.tap(uncheckedTile);
        await tester.pumpAndSettle();

        // Assert: SnackBar shown
        expect(find.byType(SnackBar), findsOneWidget);
        // Local state unchanged — truth is remote
        expect(manager.roles.value!.first.capabilities, equals(rolesBefore));
      },
    );
  });
}
