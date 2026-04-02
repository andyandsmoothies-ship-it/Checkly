import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '_shared/services/api_client.dart';
import '_shared/database/database_service.dart';
import '_shared/database/dao/outbox_dao.dart';
import '_shared/services/connectivity_service.dart';
import '_shared/services/connectivity_service_impl.dart';
import '_shared/services/gps_service.dart';
import '_shared/services/sync_engine.dart';
import '_shared/services/service_adapters.dart';
import '_shared/theme/theme_manager.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/services/secure_storage_service.dart';
import 'features/auth/manager/auth_manager.dart';
import 'features/templates/services/template_api_service.dart';
import 'features/templates/manager/template_manager.dart';
import 'features/stores/services/store_api_service.dart';
import 'features/stores/manager/store_manager.dart';
import 'features/audit/services/submission_api_service.dart';
import 'features/audit/manager/audit_manager.dart';
import 'features/audit/manager/history_manager.dart';
import 'features/notifications/services/notification_api_service.dart';
import 'features/notifications/manager/notification_manager.dart';
import 'features/action_plans/manager/action_plan_manager.dart';
import 'features/dashboard/manager/dashboard_manager.dart';
import 'features/admin/services/admin_api_service.dart';
import 'features/analytics/services/analytics_api_service.dart';

final di = GetIt.instance;

/// Registers all services and managers with get_it.
/// Called once in main() before runApp().
void configureDependencies() {
  // ---------- Shared Services ----------
  di.registerLazySingleton<DatabaseService>(() => DatabaseService());
  di.registerLazySingleton<Dio>(() => createDio());
  di.registerLazySingleton<ApiClient>(() => ApiClient(di<Dio>()));
  di.registerLazySingleton<ThemeManager>(() => ThemeManager());
  di.registerLazySingleton<OutboxDao>(
    () => OutboxDao(di<DatabaseService>().db),
  );
  di.registerLazySingleton<GpsService>(() => GpsService());

  // ---------- Auth (Slice 2) ----------
  di.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  di.registerLazySingleton<AuthApiService>(() => AuthApiService(di<Dio>()));
  di.registerLazySingleton<AuthManager>(() => AuthManager());

  // ---------- Templates (Slice 3) ----------
  di.registerLazySingleton<TemplateApiService>(
    () => TemplateApiService(di<Dio>()),
  );
  di.registerLazySingleton<TemplateManager>(() => TemplateManager());

  // ---------- Stores (Slice 3) ----------
  di.registerLazySingleton<StoreApiService>(() => StoreApiService(di<Dio>()));
  di.registerLazySingleton<StoreManager>(() => StoreManager());

  // ---------- Audit (Slices 4-5) ----------
  di.registerLazySingleton<SubmissionApiService>(
    () => SubmissionApiService(di<Dio>()),
  );
  di.registerLazySingleton<AuditManager>(() => AuditManager());
  di.registerLazySingleton<HistoryManager>(() => HistoryManager());

  // ---------- Sync Engine (Phase 3 — C1, C2) ----------
  di.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );
  di.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      connectivity: di<ConnectivityService>(),
      api: SyncApiAdapter(di<Dio>()),
      outbox: OutboxAdapter(di<OutboxDao>()),
      auth: AuthCheckAdapter(di<AuthManager>()),
      outboxDao: di<OutboxDao>(),
    ),
  );

  // ---------- Action Plans (Slice 5 — C3) ----------
  di.registerLazySingleton<ActionPlanManager>(
    () => ActionPlanManager(
      api: ActionPlanApiAdapter(di<Dio>()),
      userRole: UserRoleAdapter(di<AuthManager>()),
    ),
  );

  // ---------- Notifications (Slice 6) ----------
  di.registerLazySingleton<NotificationApiService>(
    () => NotificationApiService(di<Dio>()),
  );
  di.registerLazySingleton<NotificationManager>(() => NotificationManager());

  // ---------- Dashboard (Slice 7) ----------
  di.registerLazySingleton<DashboardManager>(() => DashboardManager());

  // ---------- Admin (CRUD Gaps — MS5) ----------
  di.registerLazySingleton<AdminApiService>(() => AdminApiService(di<Dio>()));

  // ---------- Analytics (CRUD Gaps — MS5) ----------
  di.registerLazySingleton<AnalyticsApiService>(
    () => AnalyticsApiService(di<Dio>()),
  );
}
