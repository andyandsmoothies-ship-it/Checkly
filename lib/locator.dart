import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '_shared/services/api_client.dart';
import '_shared/database/database_service.dart';
import '_shared/database/dao/outbox_dao.dart';
import '_shared/database/dao/action_plan_outbox_dao.dart';
import '_shared/database/dao/global_risk_dao.dart';
import '_shared/database/dao/submission_risk_outbox_dao.dart';
import '_shared/database/dao/sync_meta_dao.dart';
import '_shared/services/connectivity_service.dart';
import '_shared/services/connectivity_service_impl.dart';
import '_shared/services/gps_service.dart';
import '_shared/services/sync_engine.dart';
import '_shared/services/service_adapters.dart';
import '_shared/theme/theme_manager.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/services/secure_storage_service.dart';
import 'features/auth/services/policy_api_service.dart';
import 'features/auth/manager/auth_manager.dart';
import '_shared/database/dao/policy_dao.dart';
import '_shared/services/policy_manager.dart';
import 'features/templates/services/template_api_service.dart';
import 'features/templates/manager/template_manager.dart';
import 'features/stores/services/store_api_service.dart';
import 'features/stores/manager/store_manager.dart';
import 'features/audit/services/submission_api_service.dart';
import 'features/audit/manager/audit_manager.dart';
import 'features/audit/manager/history_manager.dart';
import 'features/audit/manager/survey_results_manager.dart';
import 'features/notifications/services/notification_api_service.dart';
import 'features/notifications/manager/notification_manager.dart';
import 'features/notifications/manager/notification_sync_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/action_plans/manager/action_plan_manager.dart';
import 'features/dashboard/manager/dashboard_manager.dart';
import 'features/admin/services/admin_api_service.dart';
import 'features/admin/manager/role_manager.dart';
import 'features/admin/manager/admin_user_manager.dart';
import 'features/admin/manager/admin_store_manager.dart';
import 'features/admin/manager/admin_area_manager.dart';
import 'features/admin/manager/admin_dashboard_manager.dart';
import 'features/admin/manager/admin_audit_manager.dart';
import 'features/admin/manager/admin_global_risk_manager.dart';
import 'features/analytics/services/analytics_api_service.dart';
import 'features/analytics/manager/analytics_manager.dart';
import 'features/stores/manager/store_dashboard_manager.dart';
import 'features/profile/manager/profile_manager.dart';
import 'features/user_groups/services/user_group_api_service.dart';
import 'features/user_groups/manager/user_group_manager.dart';

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
  di.registerLazySingleton<ActionPlanOutboxDao>(
    () => ActionPlanOutboxDao(di<DatabaseService>().db),
  );
  di.registerLazySingleton<GlobalRiskDao>(
    () => GlobalRiskDao(di<DatabaseService>().db),
  );
  di.registerLazySingleton<SubmissionRiskOutboxDao>(
    () => SubmissionRiskOutboxDao(di<DatabaseService>().db),
  );
  di.registerLazySingleton<SyncMetaDao>(
    () => SyncMetaDao(di<DatabaseService>().db),
  );
  di.registerLazySingleton<GpsService>(() => GpsService());

  // ---------- Auth (Slice 2 + PBAC Slice 4) ----------
  di.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  di.registerLazySingleton<AuthApiService>(() => AuthApiService(di<Dio>()));
  di.registerLazySingleton<PolicyApiService>(() => PolicyApiService(di<Dio>()));
  di.registerLazySingleton<PolicyDao>(
    () => PolicyDao(di<DatabaseService>().db),
  );
  di.registerLazySingleton<AuthManager>(
    () => AuthManager(
      authApi: di<AuthApiService>(),
      storage: di<SecureStorageService>(),
      apiClient: di<ApiClient>(),
      policyApi: di<PolicyApiService>(),
      policyDao: di<PolicyDao>(),
      dbService: di<DatabaseService>(),
    ),
  );
  di.registerLazySingleton<PolicyManager>(
    () => PolicyManager(auth: di<AuthManager>()),
  );

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
  di.registerLazySingleton<SurveyResultsManager>(() => SurveyResultsManager());

  // ---------- Sync Engine (Phase 3 — C1, C2) ----------
  di.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );
  di.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      connectivity: di<ConnectivityService>(),
      api: SyncApiAdapter(di<Dio>()),
      auth: AuthCheckAdapter(di<AuthManager>()),
      outboxDao: di<OutboxDao>(),
      actionPlanApi: ActionPlanApiAdapter(di<Dio>()),
      actionPlanOutboxDao: di<ActionPlanOutboxDao>(),
      globalRiskDao: di<GlobalRiskDao>(),
      submissionRiskOutboxDao: di<SubmissionRiskOutboxDao>(),
      syncMetaDao: di<SyncMetaDao>(),
    ),
  );

  // ---------- Action Plans (Slice 5 — C3) ----------
  di.registerLazySingleton<ActionPlanManager>(
    () => ActionPlanManager(
      api: ActionPlanApiAdapter(di<Dio>()),
      userRole: UserRoleAdapter(di<AuthManager>()),
      connectivity: di<ConnectivityService>(),
      outboxDao: di<ActionPlanOutboxDao>(),
      db: di<DatabaseService>().db,
    ),
  );

  // ---------- Notifications (Slice 6) ----------
  di.registerLazySingleton<NotificationApiService>(
    () => NotificationApiService(di<Dio>()),
  );
  di.registerLazySingleton<NotificationManager>(() => NotificationManager());

  // ---------- Notification V3 Sync Engine ----------
  di.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );
  di.registerLazySingleton<NotificationSyncManager>(
    () => NotificationSyncManager(
      notificationManager: di<NotificationManager>(),
      localNotifications: di<FlutterLocalNotificationsPlugin>(),
    ),
  );

  // ---------- Dashboard (Slice 7) ----------
  di.registerLazySingleton<DashboardManager>(() => DashboardManager());

  // ---------- Admin (CRUD Gaps — MS5) ----------
  di.registerLazySingleton<AdminApiService>(() => AdminApiService(di<Dio>()));

  // ---------- Admin PBAC Slice 2 — Role Management ----------
  di.registerLazySingleton<RoleManager>(
    () => RoleManager(adminApiService: di<AdminApiService>()),
    dispose: (m) => m.dispose(),
  );
  di.registerLazySingleton<AdminUserManager>(() => AdminUserManager());
  di.registerLazySingleton<AdminStoreManager>(() => AdminStoreManager());
  di.registerLazySingleton<AdminAreaManager>(() => AdminAreaManager());
  di.registerLazySingleton<AdminDashboardManager>(
    () => AdminDashboardManager(),
  );
  di.registerLazySingleton<AdminAuditManager>(() => AdminAuditManager());
  di.registerLazySingleton<AdminGlobalRiskManager>(
    () => AdminGlobalRiskManager(),
  );

  // ---------- Analytics (CRUD Gaps — MS5) ----------
  di.registerLazySingleton<AnalyticsApiService>(
    () => AnalyticsApiService(di<Dio>()),
  );
  di.registerLazySingleton<AnalyticsManager>(() => AnalyticsManager());

  // ---------- Store Dashboard ----------
  di.registerLazySingleton<StoreDashboardManager>(
    () => StoreDashboardManager(),
  );

  // ---------- Profile ----------
  di.registerLazySingleton<ProfileManager>(() => ProfileManager());

  // ---------- User Groups ----------
  di.registerLazySingleton<UserGroupApiService>(
    () => UserGroupApiService(di<Dio>()),
  );
  di.registerLazySingleton<UserGroupManager>(
    () => UserGroupManager(di<UserGroupApiService>()),
  );
}
