import 'package:drift/drift.dart';

// ============================================================
// Cache Tables (mirror server entities for offline reads)
// ============================================================

/// Cached audit templates — delta synced via `?since=`.
class CachedTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get scoringLogicConfig => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached template sections (groups) — synced with parent template.
class CachedGroups extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(CachedTemplates, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get maxDeductionPoints => real().nullable()();
  RealColumn get minusPerFault => real().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()();
  TextColumn get metadata => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached audit criteria — synced with parent template.
class CachedCriteria extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(CachedGroups, #id)();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();
  TextColumn get inputType => text()();
  RealColumn get pointsWeight => real().nullable()();
  RealColumn get minusImpact => real().nullable()();
  RealColumn get maxDeductionPoints => real().nullable()();
  BoolColumn get isCcp => boolean().withDefault(const Constant(false))();
  BoolColumn get isRisk => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get metadata => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached stores — full replace on sync.
class CachedStores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();

  TextColumn get areaId => text().nullable()();
  TextColumn get areaName => text().nullable()();
  RealColumn get gpsLat => real().nullable()();
  RealColumn get gpsLng => real().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached submission history — pull from API, cache locally.
class CachedSubmissions extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().nullable()();
  TextColumn get templateTitle => text().nullable()();
  TextColumn get templateType => text().nullable()();
  TextColumn get storeId => text().nullable()();
  TextColumn get storeName => text().nullable()();
  TextColumn get auditorId => text().nullable()();
  TextColumn get auditorName => text().nullable()();
  TextColumn get status => text()();
  RealColumn get totalScore => real().nullable()();
  TextColumn get sectionScores => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get reviewStatus => text().nullable()();
  TextColumn get templateSnapshot => text().nullable()();
  IntColumn get templateVersion => integer().nullable()();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get voidedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached action plans — delta synced.
class CachedActionPlans extends Table {
  TextColumn get id => text()();
  TextColumn get submissionId => text().nullable()();
  TextColumn get answerId => text().nullable()();
  TextColumn get criteriaLabel => text()();
  TextColumn get groupTitle => text()();
  TextColumn get planDescription => text().nullable()();
  TextColumn get rootCause => text().nullable()();
  TextColumn get correctionPlan => text().nullable()();
  TextColumn get evidencePhotoUrl => text().nullable()();
  TextColumn get evidenceNote => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get storeName => text().nullable()();
  TextColumn get storeId => text().nullable()();
  TextColumn get storeManagerName => text().nullable()();
  TextColumn get verifierName => text().nullable()();
  DateTimeColumn get evidenceSubmittedAt => dateTime().nullable()();
  TextColumn get evidenceSubmittedByName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached notifications — delta synced via `?since=`.
class CachedNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get readAt => dateTime().nullable()();
  TextColumn get actionUrl => text().nullable()();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local capability cache — populated after active login from GET /api/system/capabilities.
/// Cleared on logout. Read on tryAutoLogin() to restore offline capability state.
/// Single-column PK on capability string: bounded by definition (one row per capability).
class CachedPolicies extends Table {
  /// The capability string, e.g. "templates:create", "submissions:list".
  TextColumn get capability => text()();

  @override
  Set<Column> get primaryKey => {capability};
}

/// Cached profile snapshot used for offline store-scope decisions.
/// assignedStoreOverrides stores comma-separated GUIDs for AM direct assignments.
class CachedProfiles extends Table {
  TextColumn get profileId => text()();
  TextColumn get fullName => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get role => text().nullable()();
  TextColumn get assignedStoreOverrides => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {profileId};
}

// ============================================================
// Outbox Tables (local-first writes pending sync)
// ============================================================

/// Pending audit submissions queued for sync.
/// syncStatus: 'pending', 'submission_synced', 'photos_pending', 'fully_synced', 'exhausted', 'error'.
class PendingSubmissions extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()();
  TextColumn get storeId => text()();
  RealColumn get clientScore => real()();
  TextColumn get sectionScores => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get gpsLat => real().nullable()();
  RealColumn get gpsLng => real().nullable()();
  TextColumn get idempotencyKey => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt =>
      dateTime().nullable()(); // UTC — evaluated by SyncEngine
  DateTimeColumn get createdAt => dateTime()();

  /// When non-null, this outbox row is finalizing an EXISTING server-side draft.
  /// SyncEngine routes to PUT /submissions/{id}/finalize instead of POST /submissions.
  /// Null = fresh new audit (default POST path).
  TextColumn get targetSubmissionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Answers for pending submissions.
class PendingAnswers extends Table {
  TextColumn get id => text()();
  TextColumn get pendingSubmissionId =>
      text().references(PendingSubmissions, #id)();
  TextColumn get criteriaId => text()();
  TextColumn get value => text().nullable()();
  RealColumn get numericValue => real().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  BoolColumn get isRepeatedError =>
      boolean().withDefault(const Constant(false))();
  IntColumn get repeatedFaults => integer().withDefault(const Constant(0))();
  BoolColumn get isCcp => boolean().withDefault(const Constant(false))();
  BoolColumn get isRisk => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Photo files awaiting upload after submission sync.
/// syncStatus: 'pending', 'uploaded', 'exhausted', 'error'.
class PendingPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get pendingSubmissionId =>
      text().references(PendingSubmissions, #id)();
  TextColumn get answerId => text()
      .nullable()(); // links to PendingAnswers.id for server-side patching
  TextColumn get localPath => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt =>
      dateTime().nullable()(); // UTC — evaluated by PhotoQueueService
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// Metadata Table
// ============================================================

/// Tracks last sync timestamp per entity type for delta sync.
class SyncMeta extends Table {
  TextColumn get entityType => text()();
  DateTimeColumn get lastSyncAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityType};
}

// ============================================================
// Draft Table (local auto-save for in-progress audits)
// ============================================================

/// Auto-saved audit draft answers.
/// Key: "templateId:storeId:userId". Single row per draft.
/// answersJson: JSON-serialized `Map<criterionId, AuditAnswer>`.
class DraftAnswers extends Table {
  TextColumn get draftKey => text()();
  TextColumn get answersJson => text()();
  TextColumn get notesJson => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {draftKey};
}

// ============================================================
// Action Plan Outbox (offline evidence submission queue)
// ============================================================

/// Queued evidence submissions for action plans — written offline,
/// drained by SyncEngine when connectivity is restored.
///
/// syncStatus: 'pending' | 'exhausted' | 'error'.
class PendingActionPlanUpdates extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get actionPlanId => text()(); // links CachedActionPlans.id
  TextColumn get correctionPlan => text()();
  TextColumn get evidenceNote => text()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// Global Risks Tables (Slice 4)
// ============================================================

/// Cached global risks — delta synced via `GET /api/global-risks?since=`.
/// Active risks only (is_active = true) are shown to auditors in the UI.
class CachedGlobalRisks extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending submission risk triggers — written offline when auditor triggers
/// a global risk, drained by SyncEngine when connectivity is restored.
class SubmissionRiskOutboxEntries extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get submissionId => text()(); // server-side submission UUID
  TextColumn get globalRiskId => text()(); // server-side global risk UUID
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// Programs Module Tables (Slice 2B)
// ============================================================

/// Cached program assignments for the calling Store Manager.
/// Full-replace on sync: all rows deleted and reinserted each cycle.
/// Mirrors AssignmentSummaryDto from GET /api/programs/assignments/my.
class CachedProgramAssignments extends Table {
  TextColumn get id => text()(); // server UUID
  TextColumn get programId => text()();
  TextColumn get programTitle => text()();
  TextColumn get category => text()();
  DateTimeColumn get deadline => dateTime()();

  /// Values: 'pending' | 'overdue' | 'submitted' | 'needs_revision'
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get rejectionComment => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox for offline program evidence submissions.
/// Written immediately when SM submits evidence offline.
/// Drained by SyncEngine to POST /api/programs/assignments/{id}/submit.
/// syncStatus: 'pending' | 'exhausted'
class PendingProgramSubmissions extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get assignmentId => text()(); // links CachedProgramAssignments.id
  /// JSON-encoded List<{criteriaId, value, photoLocalKey?}>.
  TextColumn get evidenceItemsJson => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Photo upload queue linked to a PendingProgramSubmissions row.
/// Uploaded AFTER the evidence submit is confirmed by the server.
/// Drain logic is in Slice C (requires UI photo path structure).
/// syncStatus: 'pending' | 'uploaded' | 'exhausted'
class PendingProgramPhotos extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get pendingProgramSubmissionId =>
      text().references(PendingProgramSubmissions, #id)();
  TextColumn get criteriaId => text()();
  TextColumn get localPath => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
