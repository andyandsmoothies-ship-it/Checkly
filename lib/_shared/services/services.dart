/// Barrel export for lib/_shared/services.
///
/// SC-7: Centralises all shared service imports so feature modules
/// import one path instead of individual file paths.
library;

export 'accumulation_calculator.dart';
export 'answer_input.dart';
export 'api_client.dart';
export 'app_lifecycle_manager.dart';
export 'auth_check.dart';
export 'auth_check_adapter.dart';
export 'checklist_calculator.dart';
export 'connectivity_service.dart';
export 'connectivity_service_impl.dart';
export 'criterion_input.dart';
export 'delta_pull_result.dart';
export 'drain_result.dart';
export 'error_display_service.dart';
export 'gps_service.dart';
export 'outbox.dart';
export 'penalty_calculator.dart';
export 'pending_submission.dart';
export 'pending_submission_risk.dart';
export 'photo_api.dart';
export 'photo_queue_service.dart';
export 'policy_manager.dart';
export 'scoring_engine.dart';
export 'scoring_helpers.dart';
export 'scoring_input.dart';
export 'scoring_mode.dart';
export 'scoring_result.dart';
export 'section_input.dart';
export 'section_score.dart';
export 'service_adapters.dart';
export 'subsection_input.dart';
export 'sync_api.dart';
export 'sync_api_adapter.dart';
export 'sync_engine.dart';
export 'sync_module.dart';
export 'sync_state.dart';
export 'user_role_adapter.dart';
export 'user_role_provider.dart';
