import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/notifications/widgets/notification_bell.dart';
import 'package:checkly/features/notifications/manager/notification_manager.dart';
import 'package:checkly/features/notifications/services/notification_api_service.dart';
import 'package:checkly/features/notifications/model/notification_dto.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/notification_dao.dart';

class MockNotificationApiService extends Mock implements NotificationApiService {}
class MockNotificationDao extends Mock implements NotificationDao {}
class MockDatabaseService extends Mock implements DatabaseService {}
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late NotificationManager manager;
  late MockNotificationApiService api;
  late MockNotificationDao dao;

  setUp(() {
    GetIt.instance.reset();
    api = MockNotificationApiService();
    dao = MockNotificationDao();
    final databaseService = MockDatabaseService();
    final appDatabase = MockAppDatabase();
    
    // Stub DatabaseService.db to return a mock
    when(() => databaseService.db).thenReturn(appDatabase);
    GetIt.instance.registerSingleton<DatabaseService>(databaseService);
    
    // Stub the dao/api calls needed by loadNotifications
    when(() => dao.getAllNotifications()).thenAnswer((_) async => []);
    when(() => api.getNotifications(since: any(named: 'since'))).thenAnswer((_) async => <NotificationDto>[]);

    // Register a real manager so notifyListeners() actually works synchronously
    manager = NotificationManager(api: api, dao: dao);
    GetIt.instance.registerSingleton<NotificationManager>(manager);
  });

  testWidgets('NotificationBell crashes when loadNotifications is called during build of a sibling/child', (tester) async {
    // We expect this test to FAIL (Red Pillar) because loadNotifications calls notifyListeners synchronously
    // which triggers setState in the already-mounted NotificationBell while the framework is building.

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              NotificationBell(),
            ],
          ),
          body: const Center(child: Text('Home')),
        ),
      ),
    );

    // Ensure initial build is clean
    await tester.pump();

    // Now, we simulate a build that triggers manager.loadNotifications()
    // This is what happens when NotificationDrawerPage mounts.
    // In a test, we can just pump a new widget that calls it in its build or initState.
    
    final crashCausingWidget = Builder(
      builder: (context) {
        // Triggering this synchronously inside a builder is a "call during build"
        manager.loadNotifications(); 
        return const SizedBox();
      },
    );

    // This should throw: FlutterError (setState() or markNeedsBuild() called during build.)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              NotificationBell(),
            ],
          ),
          body: crashCausingWidget,
        ),
      ),
    );

    // If we reach here without exception, the test failed to reproduce the bug (or the bug is fixed)
    expect(tester.takeException(), isNull);
  });
}
