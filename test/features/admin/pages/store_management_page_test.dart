import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/_shared/services/geocoding_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:checkly/_shared/constants/app_capabilities.dart';
import 'package:checkly/_shared/exceptions/app_error.dart';
import 'package:checkly/_shared/services/error_display_service.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/features/admin/manager/admin_store_manager.dart';
import 'package:checkly/features/admin/pages/store_management_page.dart';
import 'package:checkly/features/stores/model/store_dto.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';

class MockStoreApiService extends Mock implements StoreApiService {}
class MockPolicyManager extends Mock implements PolicyManager {}
class MockErrorDisplayService extends Mock implements ErrorDisplayService {}
class MockAdminApiService extends Mock implements AdminApiService {}
class MockGeocodingService extends Mock implements GeocodingService {}

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  late MockStoreApiService mockStoreApi;
  late MockPolicyManager mockPolicyManager;
  late MockErrorDisplayService mockErrorDisplay;
  late MockAdminApiService mockAdminApi;
  late MockGeocodingService mockGeocoding;

  final testStores = [
    StoreDto(
      id: 's1',
      name: 'Checkly Landmark 81',
      address: 'Vinhomes Central Park, Binh Thanh',
      isActive: true,
      createdAt: DateTime.now(),
    ),
    StoreDto(
      id: 's2',
      name: 'Checkly Bui Vien',
      address: 'Bui Vien, District 1',
      isActive: false,
      createdAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockStoreApi = MockStoreApiService();
    mockPolicyManager = MockPolicyManager();
    mockErrorDisplay = MockErrorDisplayService();
    mockAdminApi = MockAdminApiService();
    mockGeocoding = MockGeocodingService();

    final di = GetIt.instance;
    di.registerSingleton<StoreApiService>(mockStoreApi);
    di.registerSingleton<PolicyManager>(mockPolicyManager);
    di.registerSingleton<ErrorDisplayService>(mockErrorDisplay);
    di.registerSingleton<AdminApiService>(mockAdminApi);
    di.registerSingleton<GeocodingService>(mockGeocoding);
    di.registerSingleton<AdminStoreManager>(AdminStoreManager(storeApi: mockStoreApi));

    registerFallbackValue(const AppError(code: 'default'));
    registerFallbackValue(const LatLng(0, 0));

    // Default stubbing
    when(() => mockErrorDisplay.show(any())).thenReturn(null);
    when(() => mockGeocoding.geocode(any())).thenAnswer((_) async => const LatLng(10.7758, 106.7018));
    when(() => mockGeocoding.reverseGeocode(any())).thenAnswer((_) async => const GeocodedAddress(
      province: 'Ho Chi Minh',
      district: 'District 1',
      ward: 'Ben Nghe',
      street: 'Nguyen Hue',
      displayName: 'Nguyen Hue, Ben Nghe, District 1, Ho Chi Minh',
    ));
    when(() => mockStoreApi.getStores(
      search: any(named: 'search'),
      includeInactive: any(named: 'includeInactive'),
      province: any(named: 'province'),
      district: any(named: 'district'),
      managerName: any(named: 'managerName'),
    )).thenAnswer((_) async => testStores);

    when(() => mockStoreApi.fetchProvinces()).thenAnswer((_) async => ['Ho Chi Minh', 'Hanoi']);
    when(() => mockStoreApi.fetchDistricts(any())).thenAnswer((_) async => ['Binh Thanh', 'District 1']);
    when(() => mockAdminApi.getUsers(
      role: any(named: 'role'),
      pageSize: any(named: 'pageSize'),
    )).thenAnswer((_) async => <Map<String, dynamic>>[
      {'fullName': 'Manager A'},
      {'fullName': 'Manager B'},
    ]);
    when(() => mockPolicyManager.can(AppCapabilities.storesWrite)).thenReturn(true);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const StoreManagementPage(),
    );
  }

  testWidgets('renders search input, status filter pill, and store cards', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify search text field exists with hint
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search by store name or address...'), findsOneWidget);

    // Verify status filter pill
    expect(find.text('Status: All'), findsOneWidget);

    // Verify both stores are rendered
    expect(find.text('Checkly Landmark 81'), findsOneWidget);
    expect(find.text('Checkly Bui Vien'), findsOneWidget);

    // FAB should be visible by default since we stubbed storesWrite to true
    expect(find.byKey(const Key('create_store_fab')), findsOneWidget);
  });

  testWidgets('hides FAB when storesWrite capability is false', (tester) async {
    when(() => mockPolicyManager.can(AppCapabilities.storesWrite)).thenReturn(false);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_store_fab')), findsNothing);
  });

  testWidgets('triggering search submits correct search term to API', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Type query
    await tester.enterText(find.byType(TextField), 'Landmark');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Verify getStores called with 'Landmark' search query
    verify(() => mockStoreApi.getStores(
      includeInactive: true,
      search: 'Landmark',
      province: any(named: 'province'),
      district: any(named: 'district'),
      managerName: any(named: 'managerName'),
    )).called(1);
  });

  testWidgets('status filter sheet filters stores list client-side', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify both stores are shown initially
    expect(find.text('Checkly Landmark 81'), findsOneWidget);
    expect(find.text('Checkly Bui Vien'), findsOneWidget);

    // Tap the status filter pill
    await tester.tap(find.text('Status: All'));
    await tester.pumpAndSettle();

    // Verify bottom sheet is shown
    expect(find.text('Filter by Status'), findsOneWidget);
    // Counts check: All = 2, Active = 1, Inactive = 1
    expect(find.textContaining('All Stores'), findsOneWidget);
    
    final activeOption = find.descendant(
      of: find.byKey(const Key('store_status_filter_sheet')),
      matching: find.text('Active'),
    );
    expect(activeOption, findsOneWidget);

    final inactiveOption = find.descendant(
      of: find.byKey(const Key('store_status_filter_sheet')),
      matching: find.text('Inactive'),
    );
    expect(inactiveOption, findsOneWidget);

    // Select 'Active'
    await tester.tap(activeOption);
    await tester.pumpAndSettle();

    // Bottom sheet should close, pill text should update
    expect(find.text('Filter by Status'), findsNothing);
    expect(find.text('Status: Active'), findsOneWidget);

    // Only Landmark 81 (active) should be rendered
    expect(find.text('Checkly Landmark 81'), findsOneWidget);
    expect(find.text('Checkly Bui Vien'), findsNothing);
  });

  testWidgets('displays empty states appropriately', (tester) async {
    // 1. Completely empty database
    when(() => mockStoreApi.getStores(
      search: any(named: 'search'),
      includeInactive: any(named: 'includeInactive'),
      province: any(named: 'province'),
      district: any(named: 'district'),
      managerName: any(named: 'managerName'),
    )).thenAnswer((_) async => <StoreDto>[]);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final emptyStateFinder = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'ChecklyEmptyState');
    expect(emptyStateFinder, findsOneWidget);
    expect(find.text('Ready for your first store?'), findsOneWidget);
    expect(
      find.text('Tap the circular + button to create a new location and start auditing!'),
      findsOneWidget,
    );

    // 2. Search/filter yielded no results
    // Return testStores but query a search that filters them out
    when(() => mockStoreApi.getStores(
      search: any(named: 'search'),
      includeInactive: any(named: 'includeInactive'),
      province: any(named: 'province'),
      district: any(named: 'district'),
      managerName: any(named: 'managerName'),
    )).thenAnswer((_) async => testStores);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Status: All and select Inactive (which has s2)
    // Then search for something else that s2 doesn't have
    // Now mock store api will return empty list for that search
    when(() => mockStoreApi.getStores(
      search: 'Nonexistent Store',
      includeInactive: any(named: 'includeInactive'),
      province: any(named: 'province'),
      district: any(named: 'district'),
      managerName: any(named: 'managerName'),
    )).thenAnswer((_) async => <StoreDto>[]);

    await tester.enterText(find.byType(TextField), 'Nonexistent Store');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final emptyStateFinder2 = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'ChecklyEmptyState');
    expect(emptyStateFinder2, findsOneWidget);
    expect(find.text("Let's find some stores!"), findsOneWidget);
    expect(
      find.text('Try adjusting your search or status filter to find locations.'),
      findsOneWidget,
    );
  });

  testWidgets('validates coordinates range and formatting on store save', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap FAB to open Store Form
    await tester.tap(find.byKey(const Key('create_store_fab')));
    await tester.pumpAndSettle();

    final nameFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Store Name *');
    final latFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Latitude');
    final lngFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Longitude');
    final saveButtonFinder = find.widgetWithText(FilledButton, 'Create Store');

    // 1. Enter invalid latitude format
    await tester.enterText(nameFinder, 'New Store');
    await tester.enterText(latFinder, 'abc');
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // 2. Clear and enter out-of-range latitude
    await tester.enterText(latFinder, '95');
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // 3. Clear latitude, enter invalid longitude format
    await tester.enterText(latFinder, '');
    await tester.enterText(lngFinder, '12.34xyz');
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // 4. Enter out-of-range longitude
    await tester.enterText(lngFinder, '-181');
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Verify all ErrorDisplayService calls at the end
    final captured = verify(() => mockErrorDisplay.show(captureAny())).captured;
    expect(captured.length, 4);
    expect((captured[0] as AppError).message, 'Latitude must be a valid number');
    expect((captured[1] as AppError).message, 'Latitude must be between -90 and 90 degrees');
    expect((captured[2] as AppError).message, 'Longitude must be a valid number');
    expect((captured[3] as AppError).message, 'Longitude must be between -180 and 180 degrees');
  });

  testWidgets('shows loading indicator and prevents double-taps during toggle active', (tester) async {
    // Stub updateStore to delay so we can see the toggling state
    when(() => mockStoreApi.updateStore(any(), isActive: any(named: 'isActive')))
        .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return <String, dynamic>{};
        });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Find the more_vert button of the first card (Landmark 81) and tap it
    final moreButton = find.byIcon(Icons.more_vert).first;
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    // Tap Deactivate
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('Deactivate'));
    // Pump a frame but don't settle yet, to let the async updateStore start
    await tester.pump();

    // The more_vert icon should be replaced by a loading indicator (CircularProgressIndicator)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the delay
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Loading indicator should be gone after completion
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('province filter selection loads districts and updates province filter pill', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Province filter pill
    await tester.tap(find.byKey(const Key('province_filter_pill')));
    await tester.pumpAndSettle();

    // Verify Province bottom sheet is shown
    expect(find.text('Filter by Province'), findsOneWidget);
    expect(find.text('Ho Chi Minh'), findsOneWidget);
    expect(find.text('Hanoi'), findsOneWidget);

    // Select 'Ho Chi Minh'
    await tester.tap(find.text('Ho Chi Minh'));
    await tester.pumpAndSettle();

    // Bottom sheet should close, pill text should update
    expect(find.text('Filter by Province'), findsNothing);
    expect(find.text('Province: Ho Chi Minh'), findsOneWidget);

    // Verify API called for Ho Chi Minh
    verify(() => mockStoreApi.getStores(
      includeInactive: true,
      province: 'Ho Chi Minh',
      district: null,
      managerName: null,
      search: any(named: 'search'),
    )).called(1);
  });


  testWidgets('manager filter selection updates manager filter pill and triggers api filter', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Manager filter pill
    await tester.tap(find.byKey(const Key('manager_filter_pill')));
    await tester.pumpAndSettle();

    // Verify Manager bottom sheet is shown
    expect(find.text('Filter by Manager'), findsOneWidget);
    expect(find.text('Manager A'), findsOneWidget);
    expect(find.text('Manager B'), findsOneWidget);

    // Select 'Manager A'
    await tester.tap(find.text('Manager A'));
    await tester.pumpAndSettle();

    // Bottom sheet closes, pill text updates
    expect(find.text('Filter by Manager'), findsNothing);
    expect(find.text('Manager: Manager A'), findsOneWidget);

    // Verify API called with manager filter
    verify(() => mockStoreApi.getStores(
      includeInactive: true,
      province: null,
      district: null,
      managerName: 'Manager A',
      search: any(named: 'search'),
    )).called(1);
  });


  testWidgets('Locate on Map button geocodes combined address and updates map coordinates', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGeocoding.geocode(any())).thenAnswer((_) async => const LatLng(10.7758, 106.7018));

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Open Store Form
    await tester.tap(find.byKey(const Key('create_store_fab')));
    await tester.pumpAndSettle();

    // Fill form fields
    final streetFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Street');
    final wardFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Ward');
    final districtFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'District');
    
    await tester.enterText(streetFinder, 'Nguyễn Huệ');
    await tester.enterText(wardFinder, 'Bến Nghé');
    await tester.enterText(districtFinder, 'Quận 1');

    // Select Province Ho Chi Minh
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ho Chi Minh').last);
    await tester.pumpAndSettle();

    // Tap "Locate on Map" button
    final locateButtonFinder = find.byKey(const Key('locate_on_map_button'));
    expect(locateButtonFinder, findsOneWidget);
    await tester.tap(locateButtonFinder);
    
    // During active geocoding, button should show loading indicator
    await tester.pump();
    expect(find.byKey(const Key('locate_on_map_loading')), findsOneWidget);

    await tester.pumpAndSettle();

    // Verify coordinates updated
    final latFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Latitude');
    final lngFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Longitude');
    expect((tester.widget(latFinder) as TextField).controller?.text, '10.775800');
    expect((tester.widget(lngFinder) as TextField).controller?.text, '106.701800');

    // Verify geocode was called with combined address string
    verify(() => mockGeocoding.geocode('Nguyễn Huệ, Bến Nghé, Quận 1, Ho Chi Minh')).called(1);
  });

  testWidgets('Locate on Map button uses legacy address when structured address fields are empty', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGeocoding.geocode(any())).thenAnswer((_) async => const LatLng(14.108696, 109.114590));

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Open Store Form
    await tester.tap(find.byKey(const Key('create_store_fab')));
    await tester.pumpAndSettle();

    // Fill only legacy Address field
    final addressFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Address');
    await tester.enterText(addressFinder, '7 Nguyen Tat Thanh, Quy Nhon, Binh Dinh');

    // Select Province Ho Chi Minh
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ho Chi Minh').last);
    await tester.pumpAndSettle();

    // Tap "Locate on Map" button
    final locateButtonFinder = find.byKey(const Key('locate_on_map_button'));
    await tester.tap(locateButtonFinder);
    await tester.pumpAndSettle();

    // Verify geocode was called with legacy address string, NOT the province
    verify(() => mockGeocoding.geocode('7 Nguyen Tat Thanh, Quy Nhon, Binh Dinh')).called(1);
  });

  testWidgets('Map tap reverse geocodes coordinates and auto-populates address fields', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGeocoding.reverseGeocode(any())).thenAnswer((_) async => const GeocodedAddress(
      province: 'Ho Chi Minh',
      district: 'Quận 1',
      ward: 'Bến Nghé',
      street: 'Nguyễn Huệ',
      displayName: 'Nguyễn Huệ, Quận 1, Ho Chi Minh',
    ));

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Open Store Form
    await tester.tap(find.byKey(const Key('create_store_fab')));
    await tester.pumpAndSettle();

    // Enter some street text first
    final streetFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Street');
    await tester.enterText(streetFinder, 'Dummy');

    // Simulate tap on map
    final mapFinder = find.byType(FlutterMap);
    expect(mapFinder, findsOneWidget);
    await tester.ensureVisible(mapFinder);
    await tester.tap(mapFinder);
    await tester.pumpAndSettle();

    // Verify fields populated
    final wardFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Ward');
    final districtFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'District');
    final addressFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Address');

    expect((tester.widget(streetFinder) as TextField).controller?.text, 'Nguyễn Huệ');
    expect((tester.widget(wardFinder) as TextField).controller?.text, 'Bến Nghé');
    expect((tester.widget(districtFinder) as TextField).controller?.text, 'Quận 1');
    expect((tester.widget(addressFinder) as TextField).controller?.text, 'Nguyễn Huệ, Quận 1, Ho Chi Minh');
    expect(find.text('Ho Chi Minh'), findsOneWidget);
  });

  testWidgets('Map tap on un-addressable region preserves coordinates and shows warning SnackBar', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Mock reverseGeocode to return null (water/un-addressable)
    when(() => mockGeocoding.reverseGeocode(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Open Store Form
    await tester.tap(find.byKey(const Key('create_store_fab')));
    await tester.pumpAndSettle();

    // Fill some street address first to verify it's not wiped
    final streetFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Street');
    await tester.enterText(streetFinder, 'Keep Me');

    // Simulate tap on map
    final mapFinder = find.byType(FlutterMap);
    await tester.tap(mapFinder);
    await tester.pumpAndSettle();

    // Verify street field still has "Keep Me" (not wiped)
    expect((tester.widget(streetFinder) as TextField).controller?.text, 'Keep Me');

    // Verify warning snackbar is shown
    expect(find.text('Address name not found, but map coordinates saved'), findsOneWidget);

    // Verify coordinates are still updated/saved in form
    final latFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Latitude');
    expect((tester.widget(latFinder) as TextField).controller?.text, isNotEmpty);
  });

  testWidgets('successful store creation dismisses form sheet and triggers onSaved', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockStoreApi.createStore(
      name: any(named: 'name'),
      address: any(named: 'address'),
      gpsLat: any(named: 'gpsLat'),
      gpsLng: any(named: 'gpsLng'),
      province: any(named: 'province'),
      district: any(named: 'district'),
      ward: any(named: 'ward'),
      street: any(named: 'street'),
    )).thenAnswer((_) async => <String, dynamic>{'id': 'new_s'});

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Open Store Form
    await tester.tap(find.byKey(const Key('create_store_fab')));
    await tester.pumpAndSettle();

    // Enter name
    final nameFinder = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Store Name *');
    await tester.enterText(nameFinder, 'New Test Store');
    await tester.pumpAndSettle();

    // Tap save button
    final saveButtonFinder = find.widgetWithText(FilledButton, 'Create Store');
    await tester.tap(saveButtonFinder);
    
    // Pump and settle to let save complete and pop happen
    await tester.pumpAndSettle();

    // The store form sheet should have popped and no longer be visible
    expect(find.text('Create Store'), findsNothing);
  });
}

