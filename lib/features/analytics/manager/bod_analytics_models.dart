class BodStorePerformanceEntry {
  final String storeId;
  final String storeName;
  final double avgScore;
  final int auditCount;
  final DateTime? lastSyncedAt;

  BodStorePerformanceEntry({
    required this.storeId,
    required this.storeName,
    required this.avgScore,
    required this.auditCount,
    this.lastSyncedAt,
  });

  factory BodStorePerformanceEntry.fromJson(Map<String, dynamic> json) {
    return BodStorePerformanceEntry(
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
      lastSyncedAt: json['lastSyncedAt'] != null && json['lastSyncedAt'] != ''
          ? DateTime.tryParse(json['lastSyncedAt'])
          : null,
    );
  }
}

class BodApAging {
  final int bucket0to7;
  final int bucket8to30;
  final int bucket31to90;
  final int bucket90Plus;

  const BodApAging({
    required this.bucket0to7,
    required this.bucket8to30,
    required this.bucket31to90,
    required this.bucket90Plus,
  });

  factory BodApAging.fromJson(Map<String, dynamic> json) {
    return BodApAging(
      bucket0to7: json['bucket0to7'] ?? json['bucket0to30'] ?? 0,
      bucket8to30: json['bucket8to30'] ?? json['bucket31to60'] ?? 0,
      bucket31to90: json['bucket31to90'] ?? json['bucket61to90'] ?? 0,
      bucket90Plus: json['bucket90Plus'] ?? 0,
    );
  }

  /// Handles both server shapes:
  ///   List: [{"range":"0-7d","count":5}, ...]
  ///   Map:  {"bucket0to7": 5, ...}
  static BodApAging fromDynamic(dynamic raw) {
    if (raw == null) {
      return const BodApAging(
        bucket0to7: 0,
        bucket8to30: 0,
        bucket31to90: 0,
        bucket90Plus: 0,
      );
    }
    if (raw is Map) {
      return BodApAging.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is List) {
      int b0to7 = 0, b8to30 = 0, b31to90 = 0, b90Plus = 0;
      for (final item in raw) {
        if (item is! Map) continue;
        final range = (item['range'] ?? item['bucket'] ?? '')
            .toString()
            .toLowerCase();
        final count = (item['count'] ?? item['value'] ?? 0) as int;
        if (range.contains('0-7')) {
          b0to7 = count;
        } else if (range.contains('8-30')) {
          b8to30 = count;
        } else if (range.contains('31-90')) {
          b31to90 = count;
        } else if (range.contains('90') || range.contains('+')) {
          b90Plus = count;
        }
      }
      return BodApAging(
        bucket0to7: b0to7,
        bucket8to30: b8to30,
        bucket31to90: b31to90,
        bucket90Plus: b90Plus,
      );
    }
    return const BodApAging(
      bucket0to7: 0,
      bucket8to30: 0,
      bucket31to90: 0,
      bucket90Plus: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0-7': bucket0to7,
      '8-30': bucket8to30,
      '31-90': bucket31to90,
      '90+': bucket90Plus,
    };
  }
}

class BodGoldenStore {
  final String storeName;
  final double avgScore;
  final String province;

  BodGoldenStore({
    required this.storeName,
    required this.avgScore,
    required this.province,
  });

  factory BodGoldenStore.fromJson(Map<String, dynamic> json) {
    return BodGoldenStore(
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      province: json['province'] ?? '',
    );
  }
}

class ApDetailEntry {
  final String id;
  final String criteriaLabel;
  final String storeName;
  final String managerName;
  final int ageInDays;

  ApDetailEntry({
    required this.id,
    required this.criteriaLabel,
    required this.storeName,
    required this.managerName,
    required this.ageInDays,
  });

  factory ApDetailEntry.fromJson(Map<String, dynamic> json) {
    return ApDetailEntry(
      id: json['id'] ?? '',
      criteriaLabel: json['criteriaLabel'] ?? '',
      storeName: json['storeName'] ?? '',
      managerName: json['managerName'] ?? '',
      ageInDays: json['ageInDays'] ?? json['overdueDays'] ?? 0,
    );
  }
}

class RecentAuditEntry {
  final String date;
  final double score;
  final String auditorName;

  RecentAuditEntry({
    required this.date,
    required this.score,
    required this.auditorName,
  });

  factory RecentAuditEntry.fromJson(Map<String, dynamic> json) {
    return RecentAuditEntry(
      date: json['date'] ?? '',
      score: (json['score'] ?? 0.0) is int
          ? (json['score'] as int).toDouble()
          : (json['score'] ?? 0.0).toDouble(),
      auditorName: json['auditorName'] ?? '',
    );
  }
}

class CategoryScoreEntry {
  final String categoryName;
  final double avgScore;

  CategoryScoreEntry({required this.categoryName, required this.avgScore});

  factory CategoryScoreEntry.fromJson(Map<String, dynamic> json) {
    return CategoryScoreEntry(
      categoryName: json['categoryName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
    );
  }
}

class SlaOverdueSegment {
  final String bucket;
  final int count;

  SlaOverdueSegment({required this.bucket, required this.count});

  factory SlaOverdueSegment.fromJson(Map<String, dynamic> json) {
    return SlaOverdueSegment(
      bucket: json['bucket'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'bucket': bucket, 'count': count};
  }
}

class CategoryStoreEntry {
  final String storeName;
  final double avgScore;
  final int auditCount;
  final int failureCount;

  CategoryStoreEntry({
    required this.storeName,
    required this.avgScore,
    required this.auditCount,
    required this.failureCount,
  });

  factory CategoryStoreEntry.fromJson(Map<String, dynamic> json) {
    return CategoryStoreEntry(
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
    );
  }
}

class BodAuditorEntry {
  final String auditorId;
  final String auditorName;
  final int completedAudits;
  final double avgScore;

  const BodAuditorEntry({
    required this.auditorId,
    required this.auditorName,
    required this.completedAudits,
    required this.avgScore,
  });

  factory BodAuditorEntry.fromJson(Map<String, dynamic> json) {
    return BodAuditorEntry(
      auditorId: json['auditorId'] ?? json['id'] ?? '',
      auditorName: json['auditorName'] ?? json['name'] ?? '',
      completedAudits:
          json['completedAudits'] ??
          json['completedCount'] ??
          json['count'] ??
          json['audits'] ??
          0,
      avgScore: (json['avgScore'] ?? json['score'] ?? 0.0) is int
          ? (json['avgScore'] ?? json['score'] as int).toDouble()
          : (json['avgScore'] ?? json['score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'auditorId': auditorId,
    'auditorName': auditorName,
    'completedAudits': completedAudits,
    'avgScore': avgScore,
  };
}

/// Represents the strongly typed aging buckets for overdue Action Plans.
enum BodAgingBucket {
  sevenDays,
  thirtyDays,
  ninetyDays,
  overdue,
  all;

  /// Returns the matching request parameter key for the backend API.
  String toApiKey() {
    switch (this) {
      case BodAgingBucket.sevenDays:
        return '0-7d';
      case BodAgingBucket.thirtyDays:
        return '8-30d';
      case BodAgingBucket.ninetyDays:
        return '31-90d';
      case BodAgingBucket.overdue:
        return '90d+';
      case BodAgingBucket.all:
        return 'all';
    }
  }

  /// Returns the human-readable display name for the UI.
  String get displayName {
    switch (this) {
      case BodAgingBucket.sevenDays:
        return '0-7 Days';
      case BodAgingBucket.thirtyDays:
        return '8-30 Days';
      case BodAgingBucket.ninetyDays:
        return '31-90 Days';
      case BodAgingBucket.overdue:
        return '90+ Days';
      case BodAgingBucket.all:
        return 'All';
    }
  }

  /// Resolves raw string parameters safely to their enum representation.
  static BodAgingBucket fromName(String name) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'all' || trimmed == 'open') {
      return BodAgingBucket.all;
    }
    if (trimmed.contains('0-7') || trimmed.contains('0-7d')) {
      return BodAgingBucket.sevenDays;
    }
    if (trimmed.contains('8-30') ||
        trimmed.contains('8-30d') ||
        trimmed.contains('0-30')) {
      return BodAgingBucket.thirtyDays;
    }
    if (trimmed.contains('31-90') ||
        trimmed.contains('31-90d') ||
        trimmed.contains('31-60') ||
        trimmed.contains('61-90')) {
      return BodAgingBucket.ninetyDays;
    }
    if (trimmed.contains('90+') || trimmed.contains('90d')) {
      return BodAgingBucket.overdue;
    }
    return BodAgingBucket.all;
  }
}
