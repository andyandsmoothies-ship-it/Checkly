// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedTemplatesTable extends CachedTemplates
    with TableInfo<$CachedTemplatesTable, CachedTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _scoringLogicConfigMeta =
      const VerificationMeta('scoringLogicConfig');
  @override
  late final GeneratedColumn<String> scoringLogicConfig =
      GeneratedColumn<String>(
        'scoring_logic_config',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    type,
    version,
    isActive,
    scoringLogicConfig,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('scoring_logic_config')) {
      context.handle(
        _scoringLogicConfigMeta,
        scoringLogicConfig.isAcceptableOrUnknown(
          data['scoring_logic_config']!,
          _scoringLogicConfigMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      scoringLogicConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_logic_config'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedTemplatesTable createAlias(String alias) {
    return $CachedTemplatesTable(attachedDatabase, alias);
  }
}

class CachedTemplate extends DataClass implements Insertable<CachedTemplate> {
  final String id;
  final String title;
  final String? description;
  final String type;
  final int version;
  final bool isActive;
  final String? scoringLogicConfig;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedTemplate({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.version,
    required this.isActive,
    this.scoringLogicConfig,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['type'] = Variable<String>(type);
    map['version'] = Variable<int>(version);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || scoringLogicConfig != null) {
      map['scoring_logic_config'] = Variable<String>(scoringLogicConfig);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedTemplatesCompanion toCompanion(bool nullToAbsent) {
    return CachedTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      version: Value(version),
      isActive: Value(isActive),
      scoringLogicConfig: scoringLogicConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(scoringLogicConfig),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTemplate(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      version: serializer.fromJson<int>(json['version']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      scoringLogicConfig: serializer.fromJson<String?>(
        json['scoringLogicConfig'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<String>(type),
      'version': serializer.toJson<int>(version),
      'isActive': serializer.toJson<bool>(isActive),
      'scoringLogicConfig': serializer.toJson<String?>(scoringLogicConfig),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedTemplate copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? type,
    int? version,
    bool? isActive,
    Value<String?> scoringLogicConfig = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedTemplate(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    type: type ?? this.type,
    version: version ?? this.version,
    isActive: isActive ?? this.isActive,
    scoringLogicConfig: scoringLogicConfig.present
        ? scoringLogicConfig.value
        : this.scoringLogicConfig,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedTemplate copyWithCompanion(CachedTemplatesCompanion data) {
    return CachedTemplate(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      version: data.version.present ? data.version.value : this.version,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      scoringLogicConfig: data.scoringLogicConfig.present
          ? data.scoringLogicConfig.value
          : this.scoringLogicConfig,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTemplate(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('isActive: $isActive, ')
          ..write('scoringLogicConfig: $scoringLogicConfig, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    type,
    version,
    isActive,
    scoringLogicConfig,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTemplate &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.version == this.version &&
          other.isActive == this.isActive &&
          other.scoringLogicConfig == this.scoringLogicConfig &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedTemplatesCompanion extends UpdateCompanion<CachedTemplate> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> type;
  final Value<int> version;
  final Value<bool> isActive;
  final Value<String?> scoringLogicConfig;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.version = const Value.absent(),
    this.isActive = const Value.absent(),
    this.scoringLogicConfig = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedTemplatesCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String type,
    this.version = const Value.absent(),
    this.isActive = const Value.absent(),
    this.scoringLogicConfig = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedTemplate> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<int>? version,
    Expression<bool>? isActive,
    Expression<String>? scoringLogicConfig,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (version != null) 'version': version,
      if (isActive != null) 'is_active': isActive,
      if (scoringLogicConfig != null)
        'scoring_logic_config': scoringLogicConfig,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? type,
    Value<int>? version,
    Value<bool>? isActive,
    Value<String?>? scoringLogicConfig,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
      scoringLogicConfig: scoringLogicConfig ?? this.scoringLogicConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (scoringLogicConfig.present) {
      map['scoring_logic_config'] = Variable<String>(scoringLogicConfig.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('isActive: $isActive, ')
          ..write('scoringLogicConfig: $scoringLogicConfig, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedGroupsTable extends CachedGroups
    with TableInfo<$CachedGroupsTable, CachedGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_templates (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxDeductionPointsMeta =
      const VerificationMeta('maxDeductionPoints');
  @override
  late final GeneratedColumn<double> maxDeductionPoints =
      GeneratedColumn<double>(
        'max_deduction_points',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _minusPerFaultMeta = const VerificationMeta(
    'minusPerFault',
  );
  @override
  late final GeneratedColumn<double> minusPerFault = GeneratedColumn<double>(
    'minus_per_fault',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    title,
    description,
    weight,
    maxDeductionPoints,
    minusPerFault,
    orderIndex,
    parentId,
    metadata,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('max_deduction_points')) {
      context.handle(
        _maxDeductionPointsMeta,
        maxDeductionPoints.isAcceptableOrUnknown(
          data['max_deduction_points']!,
          _maxDeductionPointsMeta,
        ),
      );
    }
    if (data.containsKey('minus_per_fault')) {
      context.handle(
        _minusPerFaultMeta,
        minusPerFault.isAcceptableOrUnknown(
          data['minus_per_fault']!,
          _minusPerFaultMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      maxDeductionPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_deduction_points'],
      ),
      minusPerFault: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minus_per_fault'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedGroupsTable createAlias(String alias) {
    return $CachedGroupsTable(attachedDatabase, alias);
  }
}

class CachedGroup extends DataClass implements Insertable<CachedGroup> {
  final String id;
  final String templateId;
  final String title;
  final String? description;
  final double? weight;
  final double? maxDeductionPoints;
  final double? minusPerFault;
  final int orderIndex;
  final String? parentId;
  final String? metadata;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedGroup({
    required this.id,
    required this.templateId,
    required this.title,
    this.description,
    this.weight,
    this.maxDeductionPoints,
    this.minusPerFault,
    required this.orderIndex,
    this.parentId,
    this.metadata,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || maxDeductionPoints != null) {
      map['max_deduction_points'] = Variable<double>(maxDeductionPoints);
    }
    if (!nullToAbsent || minusPerFault != null) {
      map['minus_per_fault'] = Variable<double>(minusPerFault);
    }
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedGroupsCompanion toCompanion(bool nullToAbsent) {
    return CachedGroupsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      maxDeductionPoints: maxDeductionPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(maxDeductionPoints),
      minusPerFault: minusPerFault == null && nullToAbsent
          ? const Value.absent()
          : Value(minusPerFault),
      orderIndex: Value(orderIndex),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedGroup(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      weight: serializer.fromJson<double?>(json['weight']),
      maxDeductionPoints: serializer.fromJson<double?>(
        json['maxDeductionPoints'],
      ),
      minusPerFault: serializer.fromJson<double?>(json['minusPerFault']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'weight': serializer.toJson<double?>(weight),
      'maxDeductionPoints': serializer.toJson<double?>(maxDeductionPoints),
      'minusPerFault': serializer.toJson<double?>(minusPerFault),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'parentId': serializer.toJson<String?>(parentId),
      'metadata': serializer.toJson<String?>(metadata),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedGroup copyWith({
    String? id,
    String? templateId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<double?> maxDeductionPoints = const Value.absent(),
    Value<double?> minusPerFault = const Value.absent(),
    int? orderIndex,
    Value<String?> parentId = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedGroup(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    weight: weight.present ? weight.value : this.weight,
    maxDeductionPoints: maxDeductionPoints.present
        ? maxDeductionPoints.value
        : this.maxDeductionPoints,
    minusPerFault: minusPerFault.present
        ? minusPerFault.value
        : this.minusPerFault,
    orderIndex: orderIndex ?? this.orderIndex,
    parentId: parentId.present ? parentId.value : this.parentId,
    metadata: metadata.present ? metadata.value : this.metadata,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedGroup copyWithCompanion(CachedGroupsCompanion data) {
    return CachedGroup(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      weight: data.weight.present ? data.weight.value : this.weight,
      maxDeductionPoints: data.maxDeductionPoints.present
          ? data.maxDeductionPoints.value
          : this.maxDeductionPoints,
      minusPerFault: data.minusPerFault.present
          ? data.minusPerFault.value
          : this.minusPerFault,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedGroup(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('weight: $weight, ')
          ..write('maxDeductionPoints: $maxDeductionPoints, ')
          ..write('minusPerFault: $minusPerFault, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('parentId: $parentId, ')
          ..write('metadata: $metadata, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    title,
    description,
    weight,
    maxDeductionPoints,
    minusPerFault,
    orderIndex,
    parentId,
    metadata,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedGroup &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.description == this.description &&
          other.weight == this.weight &&
          other.maxDeductionPoints == this.maxDeductionPoints &&
          other.minusPerFault == this.minusPerFault &&
          other.orderIndex == this.orderIndex &&
          other.parentId == this.parentId &&
          other.metadata == this.metadata &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedGroupsCompanion extends UpdateCompanion<CachedGroup> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> title;
  final Value<String?> description;
  final Value<double?> weight;
  final Value<double?> maxDeductionPoints;
  final Value<double?> minusPerFault;
  final Value<int> orderIndex;
  final Value<String?> parentId;
  final Value<String?> metadata;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedGroupsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.weight = const Value.absent(),
    this.maxDeductionPoints = const Value.absent(),
    this.minusPerFault = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.parentId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedGroupsCompanion.insert({
    required String id,
    required String templateId,
    required String title,
    this.description = const Value.absent(),
    this.weight = const Value.absent(),
    this.maxDeductionPoints = const Value.absent(),
    this.minusPerFault = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.parentId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedGroup> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? weight,
    Expression<double>? maxDeductionPoints,
    Expression<double>? minusPerFault,
    Expression<int>? orderIndex,
    Expression<String>? parentId,
    Expression<String>? metadata,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (weight != null) 'weight': weight,
      if (maxDeductionPoints != null)
        'max_deduction_points': maxDeductionPoints,
      if (minusPerFault != null) 'minus_per_fault': minusPerFault,
      if (orderIndex != null) 'order_index': orderIndex,
      if (parentId != null) 'parent_id': parentId,
      if (metadata != null) 'metadata': metadata,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? title,
    Value<String?>? description,
    Value<double?>? weight,
    Value<double?>? maxDeductionPoints,
    Value<double?>? minusPerFault,
    Value<int>? orderIndex,
    Value<String?>? parentId,
    Value<String?>? metadata,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedGroupsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      maxDeductionPoints: maxDeductionPoints ?? this.maxDeductionPoints,
      minusPerFault: minusPerFault ?? this.minusPerFault,
      orderIndex: orderIndex ?? this.orderIndex,
      parentId: parentId ?? this.parentId,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (maxDeductionPoints.present) {
      map['max_deduction_points'] = Variable<double>(maxDeductionPoints.value);
    }
    if (minusPerFault.present) {
      map['minus_per_fault'] = Variable<double>(minusPerFault.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedGroupsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('weight: $weight, ')
          ..write('maxDeductionPoints: $maxDeductionPoints, ')
          ..write('minusPerFault: $minusPerFault, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('parentId: $parentId, ')
          ..write('metadata: $metadata, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCriteriaTable extends CachedCriteria
    with TableInfo<$CachedCriteriaTable, CachedCriteriaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCriteriaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_groups (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputTypeMeta = const VerificationMeta(
    'inputType',
  );
  @override
  late final GeneratedColumn<String> inputType = GeneratedColumn<String>(
    'input_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsWeightMeta = const VerificationMeta(
    'pointsWeight',
  );
  @override
  late final GeneratedColumn<double> pointsWeight = GeneratedColumn<double>(
    'points_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCcpMeta = const VerificationMeta('isCcp');
  @override
  late final GeneratedColumn<bool> isCcp = GeneratedColumn<bool>(
    'is_ccp',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ccp" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isRiskMeta = const VerificationMeta('isRisk');
  @override
  late final GeneratedColumn<bool> isRisk = GeneratedColumn<bool>(
    'is_risk',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_risk" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    label,
    description,
    inputType,
    pointsWeight,
    isCcp,
    isRisk,
    orderIndex,
    metadata,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_criteria';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCriteriaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('input_type')) {
      context.handle(
        _inputTypeMeta,
        inputType.isAcceptableOrUnknown(data['input_type']!, _inputTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_inputTypeMeta);
    }
    if (data.containsKey('points_weight')) {
      context.handle(
        _pointsWeightMeta,
        pointsWeight.isAcceptableOrUnknown(
          data['points_weight']!,
          _pointsWeightMeta,
        ),
      );
    }
    if (data.containsKey('is_ccp')) {
      context.handle(
        _isCcpMeta,
        isCcp.isAcceptableOrUnknown(data['is_ccp']!, _isCcpMeta),
      );
    }
    if (data.containsKey('is_risk')) {
      context.handle(
        _isRiskMeta,
        isRisk.isAcceptableOrUnknown(data['is_risk']!, _isRiskMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCriteriaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCriteriaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      inputType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_type'],
      )!,
      pointsWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}points_weight'],
      ),
      isCcp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ccp'],
      )!,
      isRisk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_risk'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedCriteriaTable createAlias(String alias) {
    return $CachedCriteriaTable(attachedDatabase, alias);
  }
}

class CachedCriteriaData extends DataClass
    implements Insertable<CachedCriteriaData> {
  final String id;
  final String groupId;
  final String label;
  final String? description;
  final String inputType;
  final double? pointsWeight;
  final bool isCcp;
  final bool isRisk;
  final int orderIndex;
  final String? metadata;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedCriteriaData({
    required this.id,
    required this.groupId,
    required this.label,
    this.description,
    required this.inputType,
    this.pointsWeight,
    required this.isCcp,
    required this.isRisk,
    required this.orderIndex,
    this.metadata,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['input_type'] = Variable<String>(inputType);
    if (!nullToAbsent || pointsWeight != null) {
      map['points_weight'] = Variable<double>(pointsWeight);
    }
    map['is_ccp'] = Variable<bool>(isCcp);
    map['is_risk'] = Variable<bool>(isRisk);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedCriteriaCompanion toCompanion(bool nullToAbsent) {
    return CachedCriteriaCompanion(
      id: Value(id),
      groupId: Value(groupId),
      label: Value(label),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      inputType: Value(inputType),
      pointsWeight: pointsWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(pointsWeight),
      isCcp: Value(isCcp),
      isRisk: Value(isRisk),
      orderIndex: Value(orderIndex),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedCriteriaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCriteriaData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      label: serializer.fromJson<String>(json['label']),
      description: serializer.fromJson<String?>(json['description']),
      inputType: serializer.fromJson<String>(json['inputType']),
      pointsWeight: serializer.fromJson<double?>(json['pointsWeight']),
      isCcp: serializer.fromJson<bool>(json['isCcp']),
      isRisk: serializer.fromJson<bool>(json['isRisk']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'label': serializer.toJson<String>(label),
      'description': serializer.toJson<String?>(description),
      'inputType': serializer.toJson<String>(inputType),
      'pointsWeight': serializer.toJson<double?>(pointsWeight),
      'isCcp': serializer.toJson<bool>(isCcp),
      'isRisk': serializer.toJson<bool>(isRisk),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'metadata': serializer.toJson<String?>(metadata),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedCriteriaData copyWith({
    String? id,
    String? groupId,
    String? label,
    Value<String?> description = const Value.absent(),
    String? inputType,
    Value<double?> pointsWeight = const Value.absent(),
    bool? isCcp,
    bool? isRisk,
    int? orderIndex,
    Value<String?> metadata = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedCriteriaData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    label: label ?? this.label,
    description: description.present ? description.value : this.description,
    inputType: inputType ?? this.inputType,
    pointsWeight: pointsWeight.present ? pointsWeight.value : this.pointsWeight,
    isCcp: isCcp ?? this.isCcp,
    isRisk: isRisk ?? this.isRisk,
    orderIndex: orderIndex ?? this.orderIndex,
    metadata: metadata.present ? metadata.value : this.metadata,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedCriteriaData copyWithCompanion(CachedCriteriaCompanion data) {
    return CachedCriteriaData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      label: data.label.present ? data.label.value : this.label,
      description: data.description.present
          ? data.description.value
          : this.description,
      inputType: data.inputType.present ? data.inputType.value : this.inputType,
      pointsWeight: data.pointsWeight.present
          ? data.pointsWeight.value
          : this.pointsWeight,
      isCcp: data.isCcp.present ? data.isCcp.value : this.isCcp,
      isRisk: data.isRisk.present ? data.isRisk.value : this.isRisk,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCriteriaData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('inputType: $inputType, ')
          ..write('pointsWeight: $pointsWeight, ')
          ..write('isCcp: $isCcp, ')
          ..write('isRisk: $isRisk, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('metadata: $metadata, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    label,
    description,
    inputType,
    pointsWeight,
    isCcp,
    isRisk,
    orderIndex,
    metadata,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCriteriaData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.label == this.label &&
          other.description == this.description &&
          other.inputType == this.inputType &&
          other.pointsWeight == this.pointsWeight &&
          other.isCcp == this.isCcp &&
          other.isRisk == this.isRisk &&
          other.orderIndex == this.orderIndex &&
          other.metadata == this.metadata &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedCriteriaCompanion extends UpdateCompanion<CachedCriteriaData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> label;
  final Value<String?> description;
  final Value<String> inputType;
  final Value<double?> pointsWeight;
  final Value<bool> isCcp;
  final Value<bool> isRisk;
  final Value<int> orderIndex;
  final Value<String?> metadata;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedCriteriaCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.label = const Value.absent(),
    this.description = const Value.absent(),
    this.inputType = const Value.absent(),
    this.pointsWeight = const Value.absent(),
    this.isCcp = const Value.absent(),
    this.isRisk = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.metadata = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCriteriaCompanion.insert({
    required String id,
    required String groupId,
    required String label,
    this.description = const Value.absent(),
    required String inputType,
    this.pointsWeight = const Value.absent(),
    this.isCcp = const Value.absent(),
    this.isRisk = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.metadata = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       label = Value(label),
       inputType = Value(inputType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedCriteriaData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? label,
    Expression<String>? description,
    Expression<String>? inputType,
    Expression<double>? pointsWeight,
    Expression<bool>? isCcp,
    Expression<bool>? isRisk,
    Expression<int>? orderIndex,
    Expression<String>? metadata,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (inputType != null) 'input_type': inputType,
      if (pointsWeight != null) 'points_weight': pointsWeight,
      if (isCcp != null) 'is_ccp': isCcp,
      if (isRisk != null) 'is_risk': isRisk,
      if (orderIndex != null) 'order_index': orderIndex,
      if (metadata != null) 'metadata': metadata,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCriteriaCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? label,
    Value<String?>? description,
    Value<String>? inputType,
    Value<double?>? pointsWeight,
    Value<bool>? isCcp,
    Value<bool>? isRisk,
    Value<int>? orderIndex,
    Value<String?>? metadata,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedCriteriaCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      label: label ?? this.label,
      description: description ?? this.description,
      inputType: inputType ?? this.inputType,
      pointsWeight: pointsWeight ?? this.pointsWeight,
      isCcp: isCcp ?? this.isCcp,
      isRisk: isRisk ?? this.isRisk,
      orderIndex: orderIndex ?? this.orderIndex,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (inputType.present) {
      map['input_type'] = Variable<String>(inputType.value);
    }
    if (pointsWeight.present) {
      map['points_weight'] = Variable<double>(pointsWeight.value);
    }
    if (isCcp.present) {
      map['is_ccp'] = Variable<bool>(isCcp.value);
    }
    if (isRisk.present) {
      map['is_risk'] = Variable<bool>(isRisk.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCriteriaCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('inputType: $inputType, ')
          ..write('pointsWeight: $pointsWeight, ')
          ..write('isCcp: $isCcp, ')
          ..write('isRisk: $isRisk, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('metadata: $metadata, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStoresTable extends CachedStores
    with TableInfo<$CachedStoresTable, CachedStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaNameMeta = const VerificationMeta(
    'areaName',
  );
  @override
  late final GeneratedColumn<String> areaName = GeneratedColumn<String>(
    'area_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLatMeta = const VerificationMeta('gpsLat');
  @override
  late final GeneratedColumn<double> gpsLat = GeneratedColumn<double>(
    'gps_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLngMeta = const VerificationMeta('gpsLng');
  @override
  late final GeneratedColumn<double> gpsLng = GeneratedColumn<double>(
    'gps_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    areaId,
    areaName,
    gpsLat,
    gpsLng,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    }
    if (data.containsKey('area_name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['area_name']!, _areaNameMeta),
      );
    }
    if (data.containsKey('gps_lat')) {
      context.handle(
        _gpsLatMeta,
        gpsLat.isAcceptableOrUnknown(data['gps_lat']!, _gpsLatMeta),
      );
    }
    if (data.containsKey('gps_lng')) {
      context.handle(
        _gpsLngMeta,
        gpsLng.isAcceptableOrUnknown(data['gps_lng']!, _gpsLngMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_id'],
      ),
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_name'],
      ),
      gpsLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lat'],
      ),
      gpsLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lng'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedStoresTable createAlias(String alias) {
    return $CachedStoresTable(attachedDatabase, alias);
  }
}

class CachedStore extends DataClass implements Insertable<CachedStore> {
  final String id;
  final String name;
  final String? address;
  final String? areaId;
  final String? areaName;
  final double? gpsLat;
  final double? gpsLng;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedStore({
    required this.id,
    required this.name,
    this.address,
    this.areaId,
    this.areaName,
    this.gpsLat,
    this.gpsLng,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || areaId != null) {
      map['area_id'] = Variable<String>(areaId);
    }
    if (!nullToAbsent || areaName != null) {
      map['area_name'] = Variable<String>(areaName);
    }
    if (!nullToAbsent || gpsLat != null) {
      map['gps_lat'] = Variable<double>(gpsLat);
    }
    if (!nullToAbsent || gpsLng != null) {
      map['gps_lng'] = Variable<double>(gpsLng);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedStoresCompanion toCompanion(bool nullToAbsent) {
    return CachedStoresCompanion(
      id: Value(id),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      areaId: areaId == null && nullToAbsent
          ? const Value.absent()
          : Value(areaId),
      areaName: areaName == null && nullToAbsent
          ? const Value.absent()
          : Value(areaName),
      gpsLat: gpsLat == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLat),
      gpsLng: gpsLng == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLng),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStore(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      areaId: serializer.fromJson<String?>(json['areaId']),
      areaName: serializer.fromJson<String?>(json['areaName']),
      gpsLat: serializer.fromJson<double?>(json['gpsLat']),
      gpsLng: serializer.fromJson<double?>(json['gpsLng']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'areaId': serializer.toJson<String?>(areaId),
      'areaName': serializer.toJson<String?>(areaName),
      'gpsLat': serializer.toJson<double?>(gpsLat),
      'gpsLng': serializer.toJson<double?>(gpsLng),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedStore copyWith({
    String? id,
    String? name,
    Value<String?> address = const Value.absent(),
    Value<String?> areaId = const Value.absent(),
    Value<String?> areaName = const Value.absent(),
    Value<double?> gpsLat = const Value.absent(),
    Value<double?> gpsLng = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedStore(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    areaId: areaId.present ? areaId.value : this.areaId,
    areaName: areaName.present ? areaName.value : this.areaName,
    gpsLat: gpsLat.present ? gpsLat.value : this.gpsLat,
    gpsLng: gpsLng.present ? gpsLng.value : this.gpsLng,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedStore copyWithCompanion(CachedStoresCompanion data) {
    return CachedStore(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      areaName: data.areaName.present ? data.areaName.value : this.areaName,
      gpsLat: data.gpsLat.present ? data.gpsLat.value : this.gpsLat,
      gpsLng: data.gpsLng.present ? data.gpsLng.value : this.gpsLng,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStore(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLng: $gpsLng, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    areaId,
    areaName,
    gpsLat,
    gpsLng,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStore &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.areaId == this.areaId &&
          other.areaName == this.areaName &&
          other.gpsLat == this.gpsLat &&
          other.gpsLng == this.gpsLng &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedStoresCompanion extends UpdateCompanion<CachedStore> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> address;
  final Value<String?> areaId;
  final Value<String?> areaName;
  final Value<double?> gpsLat;
  final Value<double?> gpsLng;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedStoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLng = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStoresCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLng = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedStore> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? areaId,
    Expression<String>? areaName,
    Expression<double>? gpsLat,
    Expression<double>? gpsLng,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (areaId != null) 'area_id': areaId,
      if (areaName != null) 'area_name': areaName,
      if (gpsLat != null) 'gps_lat': gpsLat,
      if (gpsLng != null) 'gps_lng': gpsLng,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStoresCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? address,
    Value<String?>? areaId,
    Value<String?>? areaName,
    Value<double?>? gpsLat,
    Value<double?>? gpsLng,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedStoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (areaName.present) {
      map['area_name'] = Variable<String>(areaName.value);
    }
    if (gpsLat.present) {
      map['gps_lat'] = Variable<double>(gpsLat.value);
    }
    if (gpsLng.present) {
      map['gps_lng'] = Variable<double>(gpsLng.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLng: $gpsLng, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSubmissionsTable extends CachedSubmissions
    with TableInfo<$CachedSubmissionsTable, CachedSubmission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSubmissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateTitleMeta = const VerificationMeta(
    'templateTitle',
  );
  @override
  late final GeneratedColumn<String> templateTitle = GeneratedColumn<String>(
    'template_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _auditorIdMeta = const VerificationMeta(
    'auditorId',
  );
  @override
  late final GeneratedColumn<String> auditorId = GeneratedColumn<String>(
    'auditor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _auditorNameMeta = const VerificationMeta(
    'auditorName',
  );
  @override
  late final GeneratedColumn<String> auditorName = GeneratedColumn<String>(
    'auditor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<double> totalScore = GeneratedColumn<double>(
    'total_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionScoresMeta = const VerificationMeta(
    'sectionScores',
  );
  @override
  late final GeneratedColumn<String> sectionScores = GeneratedColumn<String>(
    'section_scores',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewStatusMeta = const VerificationMeta(
    'reviewStatus',
  );
  @override
  late final GeneratedColumn<String> reviewStatus = GeneratedColumn<String>(
    'review_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateSnapshotMeta = const VerificationMeta(
    'templateSnapshot',
  );
  @override
  late final GeneratedColumn<String> templateSnapshot = GeneratedColumn<String>(
    'template_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateVersionMeta = const VerificationMeta(
    'templateVersion',
  );
  @override
  late final GeneratedColumn<int> templateVersion = GeneratedColumn<int>(
    'template_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    templateTitle,
    storeId,
    storeName,
    auditorId,
    auditorName,
    status,
    totalScore,
    sectionScores,
    notes,
    createdAt,
    completedAt,
    reviewStatus,
    templateSnapshot,
    templateVersion,
    voidReason,
    voidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_submissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSubmission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('template_title')) {
      context.handle(
        _templateTitleMeta,
        templateTitle.isAcceptableOrUnknown(
          data['template_title']!,
          _templateTitleMeta,
        ),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('auditor_id')) {
      context.handle(
        _auditorIdMeta,
        auditorId.isAcceptableOrUnknown(data['auditor_id']!, _auditorIdMeta),
      );
    }
    if (data.containsKey('auditor_name')) {
      context.handle(
        _auditorNameMeta,
        auditorName.isAcceptableOrUnknown(
          data['auditor_name']!,
          _auditorNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    }
    if (data.containsKey('section_scores')) {
      context.handle(
        _sectionScoresMeta,
        sectionScores.isAcceptableOrUnknown(
          data['section_scores']!,
          _sectionScoresMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('review_status')) {
      context.handle(
        _reviewStatusMeta,
        reviewStatus.isAcceptableOrUnknown(
          data['review_status']!,
          _reviewStatusMeta,
        ),
      );
    }
    if (data.containsKey('template_snapshot')) {
      context.handle(
        _templateSnapshotMeta,
        templateSnapshot.isAcceptableOrUnknown(
          data['template_snapshot']!,
          _templateSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('template_version')) {
      context.handle(
        _templateVersionMeta,
        templateVersion.isAcceptableOrUnknown(
          data['template_version']!,
          _templateVersionMeta,
        ),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSubmission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSubmission(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      templateTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_title'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      auditorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auditor_id'],
      ),
      auditorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auditor_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_score'],
      ),
      sectionScores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_scores'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      reviewStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_status'],
      ),
      templateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_snapshot'],
      ),
      templateVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_version'],
      ),
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
    );
  }

  @override
  $CachedSubmissionsTable createAlias(String alias) {
    return $CachedSubmissionsTable(attachedDatabase, alias);
  }
}

class CachedSubmission extends DataClass
    implements Insertable<CachedSubmission> {
  final String id;
  final String? templateId;
  final String? templateTitle;
  final String? storeId;
  final String? storeName;
  final String? auditorId;
  final String? auditorName;
  final String status;
  final double? totalScore;
  final String? sectionScores;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? reviewStatus;
  final String? templateSnapshot;
  final int? templateVersion;
  final String? voidReason;
  final DateTime? voidedAt;
  const CachedSubmission({
    required this.id,
    this.templateId,
    this.templateTitle,
    this.storeId,
    this.storeName,
    this.auditorId,
    this.auditorName,
    required this.status,
    this.totalScore,
    this.sectionScores,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.reviewStatus,
    this.templateSnapshot,
    this.templateVersion,
    this.voidReason,
    this.voidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    if (!nullToAbsent || templateTitle != null) {
      map['template_title'] = Variable<String>(templateTitle);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || auditorId != null) {
      map['auditor_id'] = Variable<String>(auditorId);
    }
    if (!nullToAbsent || auditorName != null) {
      map['auditor_name'] = Variable<String>(auditorName);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || totalScore != null) {
      map['total_score'] = Variable<double>(totalScore);
    }
    if (!nullToAbsent || sectionScores != null) {
      map['section_scores'] = Variable<String>(sectionScores);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || reviewStatus != null) {
      map['review_status'] = Variable<String>(reviewStatus);
    }
    if (!nullToAbsent || templateSnapshot != null) {
      map['template_snapshot'] = Variable<String>(templateSnapshot);
    }
    if (!nullToAbsent || templateVersion != null) {
      map['template_version'] = Variable<int>(templateVersion);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    return map;
  }

  CachedSubmissionsCompanion toCompanion(bool nullToAbsent) {
    return CachedSubmissionsCompanion(
      id: Value(id),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      templateTitle: templateTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(templateTitle),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      auditorId: auditorId == null && nullToAbsent
          ? const Value.absent()
          : Value(auditorId),
      auditorName: auditorName == null && nullToAbsent
          ? const Value.absent()
          : Value(auditorName),
      status: Value(status),
      totalScore: totalScore == null && nullToAbsent
          ? const Value.absent()
          : Value(totalScore),
      sectionScores: sectionScores == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionScores),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      reviewStatus: reviewStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewStatus),
      templateSnapshot: templateSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(templateSnapshot),
      templateVersion: templateVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(templateVersion),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
    );
  }

  factory CachedSubmission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSubmission(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      templateTitle: serializer.fromJson<String?>(json['templateTitle']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      auditorId: serializer.fromJson<String?>(json['auditorId']),
      auditorName: serializer.fromJson<String?>(json['auditorName']),
      status: serializer.fromJson<String>(json['status']),
      totalScore: serializer.fromJson<double?>(json['totalScore']),
      sectionScores: serializer.fromJson<String?>(json['sectionScores']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      reviewStatus: serializer.fromJson<String?>(json['reviewStatus']),
      templateSnapshot: serializer.fromJson<String?>(json['templateSnapshot']),
      templateVersion: serializer.fromJson<int?>(json['templateVersion']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String?>(templateId),
      'templateTitle': serializer.toJson<String?>(templateTitle),
      'storeId': serializer.toJson<String?>(storeId),
      'storeName': serializer.toJson<String?>(storeName),
      'auditorId': serializer.toJson<String?>(auditorId),
      'auditorName': serializer.toJson<String?>(auditorName),
      'status': serializer.toJson<String>(status),
      'totalScore': serializer.toJson<double?>(totalScore),
      'sectionScores': serializer.toJson<String?>(sectionScores),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'reviewStatus': serializer.toJson<String?>(reviewStatus),
      'templateSnapshot': serializer.toJson<String?>(templateSnapshot),
      'templateVersion': serializer.toJson<int?>(templateVersion),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
    };
  }

  CachedSubmission copyWith({
    String? id,
    Value<String?> templateId = const Value.absent(),
    Value<String?> templateTitle = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    Value<String?> storeName = const Value.absent(),
    Value<String?> auditorId = const Value.absent(),
    Value<String?> auditorName = const Value.absent(),
    String? status,
    Value<double?> totalScore = const Value.absent(),
    Value<String?> sectionScores = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> reviewStatus = const Value.absent(),
    Value<String?> templateSnapshot = const Value.absent(),
    Value<int?> templateVersion = const Value.absent(),
    Value<String?> voidReason = const Value.absent(),
    Value<DateTime?> voidedAt = const Value.absent(),
  }) => CachedSubmission(
    id: id ?? this.id,
    templateId: templateId.present ? templateId.value : this.templateId,
    templateTitle: templateTitle.present
        ? templateTitle.value
        : this.templateTitle,
    storeId: storeId.present ? storeId.value : this.storeId,
    storeName: storeName.present ? storeName.value : this.storeName,
    auditorId: auditorId.present ? auditorId.value : this.auditorId,
    auditorName: auditorName.present ? auditorName.value : this.auditorName,
    status: status ?? this.status,
    totalScore: totalScore.present ? totalScore.value : this.totalScore,
    sectionScores: sectionScores.present
        ? sectionScores.value
        : this.sectionScores,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    reviewStatus: reviewStatus.present ? reviewStatus.value : this.reviewStatus,
    templateSnapshot: templateSnapshot.present
        ? templateSnapshot.value
        : this.templateSnapshot,
    templateVersion: templateVersion.present
        ? templateVersion.value
        : this.templateVersion,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
  );
  CachedSubmission copyWithCompanion(CachedSubmissionsCompanion data) {
    return CachedSubmission(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateTitle: data.templateTitle.present
          ? data.templateTitle.value
          : this.templateTitle,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      auditorId: data.auditorId.present ? data.auditorId.value : this.auditorId,
      auditorName: data.auditorName.present
          ? data.auditorName.value
          : this.auditorName,
      status: data.status.present ? data.status.value : this.status,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      sectionScores: data.sectionScores.present
          ? data.sectionScores.value
          : this.sectionScores,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      reviewStatus: data.reviewStatus.present
          ? data.reviewStatus.value
          : this.reviewStatus,
      templateSnapshot: data.templateSnapshot.present
          ? data.templateSnapshot.value
          : this.templateSnapshot,
      templateVersion: data.templateVersion.present
          ? data.templateVersion.value
          : this.templateVersion,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSubmission(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('templateTitle: $templateTitle, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('auditorId: $auditorId, ')
          ..write('auditorName: $auditorName, ')
          ..write('status: $status, ')
          ..write('totalScore: $totalScore, ')
          ..write('sectionScores: $sectionScores, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('templateSnapshot: $templateSnapshot, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedAt: $voidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    templateTitle,
    storeId,
    storeName,
    auditorId,
    auditorName,
    status,
    totalScore,
    sectionScores,
    notes,
    createdAt,
    completedAt,
    reviewStatus,
    templateSnapshot,
    templateVersion,
    voidReason,
    voidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSubmission &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.templateTitle == this.templateTitle &&
          other.storeId == this.storeId &&
          other.storeName == this.storeName &&
          other.auditorId == this.auditorId &&
          other.auditorName == this.auditorName &&
          other.status == this.status &&
          other.totalScore == this.totalScore &&
          other.sectionScores == this.sectionScores &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.reviewStatus == this.reviewStatus &&
          other.templateSnapshot == this.templateSnapshot &&
          other.templateVersion == this.templateVersion &&
          other.voidReason == this.voidReason &&
          other.voidedAt == this.voidedAt);
}

class CachedSubmissionsCompanion extends UpdateCompanion<CachedSubmission> {
  final Value<String> id;
  final Value<String?> templateId;
  final Value<String?> templateTitle;
  final Value<String?> storeId;
  final Value<String?> storeName;
  final Value<String?> auditorId;
  final Value<String?> auditorName;
  final Value<String> status;
  final Value<double?> totalScore;
  final Value<String?> sectionScores;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<String?> reviewStatus;
  final Value<String?> templateSnapshot;
  final Value<int?> templateVersion;
  final Value<String?> voidReason;
  final Value<DateTime?> voidedAt;
  final Value<int> rowid;
  const CachedSubmissionsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateTitle = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.auditorId = const Value.absent(),
    this.auditorName = const Value.absent(),
    this.status = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.sectionScores = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.templateSnapshot = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSubmissionsCompanion.insert({
    required String id,
    this.templateId = const Value.absent(),
    this.templateTitle = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.auditorId = const Value.absent(),
    this.auditorName = const Value.absent(),
    required String status,
    this.totalScore = const Value.absent(),
    this.sectionScores = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.templateSnapshot = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<CachedSubmission> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? templateTitle,
    Expression<String>? storeId,
    Expression<String>? storeName,
    Expression<String>? auditorId,
    Expression<String>? auditorName,
    Expression<String>? status,
    Expression<double>? totalScore,
    Expression<String>? sectionScores,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<String>? reviewStatus,
    Expression<String>? templateSnapshot,
    Expression<int>? templateVersion,
    Expression<String>? voidReason,
    Expression<DateTime>? voidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (templateTitle != null) 'template_title': templateTitle,
      if (storeId != null) 'store_id': storeId,
      if (storeName != null) 'store_name': storeName,
      if (auditorId != null) 'auditor_id': auditorId,
      if (auditorName != null) 'auditor_name': auditorName,
      if (status != null) 'status': status,
      if (totalScore != null) 'total_score': totalScore,
      if (sectionScores != null) 'section_scores': sectionScores,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (reviewStatus != null) 'review_status': reviewStatus,
      if (templateSnapshot != null) 'template_snapshot': templateSnapshot,
      if (templateVersion != null) 'template_version': templateVersion,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSubmissionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? templateId,
    Value<String?>? templateTitle,
    Value<String?>? storeId,
    Value<String?>? storeName,
    Value<String?>? auditorId,
    Value<String?>? auditorName,
    Value<String>? status,
    Value<double?>? totalScore,
    Value<String?>? sectionScores,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<String?>? reviewStatus,
    Value<String?>? templateSnapshot,
    Value<int?>? templateVersion,
    Value<String?>? voidReason,
    Value<DateTime?>? voidedAt,
    Value<int>? rowid,
  }) {
    return CachedSubmissionsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateTitle: templateTitle ?? this.templateTitle,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      auditorId: auditorId ?? this.auditorId,
      auditorName: auditorName ?? this.auditorName,
      status: status ?? this.status,
      totalScore: totalScore ?? this.totalScore,
      sectionScores: sectionScores ?? this.sectionScores,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      templateSnapshot: templateSnapshot ?? this.templateSnapshot,
      templateVersion: templateVersion ?? this.templateVersion,
      voidReason: voidReason ?? this.voidReason,
      voidedAt: voidedAt ?? this.voidedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateTitle.present) {
      map['template_title'] = Variable<String>(templateTitle.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (auditorId.present) {
      map['auditor_id'] = Variable<String>(auditorId.value);
    }
    if (auditorName.present) {
      map['auditor_name'] = Variable<String>(auditorName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<double>(totalScore.value);
    }
    if (sectionScores.present) {
      map['section_scores'] = Variable<String>(sectionScores.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (reviewStatus.present) {
      map['review_status'] = Variable<String>(reviewStatus.value);
    }
    if (templateSnapshot.present) {
      map['template_snapshot'] = Variable<String>(templateSnapshot.value);
    }
    if (templateVersion.present) {
      map['template_version'] = Variable<int>(templateVersion.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSubmissionsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('templateTitle: $templateTitle, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('auditorId: $auditorId, ')
          ..write('auditorName: $auditorName, ')
          ..write('status: $status, ')
          ..write('totalScore: $totalScore, ')
          ..write('sectionScores: $sectionScores, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('templateSnapshot: $templateSnapshot, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedActionPlansTable extends CachedActionPlans
    with TableInfo<$CachedActionPlansTable, CachedActionPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedActionPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submissionIdMeta = const VerificationMeta(
    'submissionId',
  );
  @override
  late final GeneratedColumn<String> submissionId = GeneratedColumn<String>(
    'submission_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerIdMeta = const VerificationMeta(
    'answerId',
  );
  @override
  late final GeneratedColumn<String> answerId = GeneratedColumn<String>(
    'answer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criteriaLabelMeta = const VerificationMeta(
    'criteriaLabel',
  );
  @override
  late final GeneratedColumn<String> criteriaLabel = GeneratedColumn<String>(
    'criteria_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupTitleMeta = const VerificationMeta(
    'groupTitle',
  );
  @override
  late final GeneratedColumn<String> groupTitle = GeneratedColumn<String>(
    'group_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planDescriptionMeta = const VerificationMeta(
    'planDescription',
  );
  @override
  late final GeneratedColumn<String> planDescription = GeneratedColumn<String>(
    'plan_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootCauseMeta = const VerificationMeta(
    'rootCause',
  );
  @override
  late final GeneratedColumn<String> rootCause = GeneratedColumn<String>(
    'root_cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctionPlanMeta = const VerificationMeta(
    'correctionPlan',
  );
  @override
  late final GeneratedColumn<String> correctionPlan = GeneratedColumn<String>(
    'correction_plan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evidencePhotoUrlMeta = const VerificationMeta(
    'evidencePhotoUrl',
  );
  @override
  late final GeneratedColumn<String> evidencePhotoUrl = GeneratedColumn<String>(
    'evidence_photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evidenceNoteMeta = const VerificationMeta(
    'evidenceNote',
  );
  @override
  late final GeneratedColumn<String> evidenceNote = GeneratedColumn<String>(
    'evidence_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeManagerNameMeta = const VerificationMeta(
    'storeManagerName',
  );
  @override
  late final GeneratedColumn<String> storeManagerName = GeneratedColumn<String>(
    'store_manager_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifierNameMeta = const VerificationMeta(
    'verifierName',
  );
  @override
  late final GeneratedColumn<String> verifierName = GeneratedColumn<String>(
    'verifier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    submissionId,
    answerId,
    criteriaLabel,
    groupTitle,
    planDescription,
    rootCause,
    correctionPlan,
    evidencePhotoUrl,
    evidenceNote,
    status,
    deadline,
    closedAt,
    storeName,
    storeId,
    storeManagerName,
    verifierName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_action_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedActionPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('submission_id')) {
      context.handle(
        _submissionIdMeta,
        submissionId.isAcceptableOrUnknown(
          data['submission_id']!,
          _submissionIdMeta,
        ),
      );
    }
    if (data.containsKey('answer_id')) {
      context.handle(
        _answerIdMeta,
        answerId.isAcceptableOrUnknown(data['answer_id']!, _answerIdMeta),
      );
    }
    if (data.containsKey('criteria_label')) {
      context.handle(
        _criteriaLabelMeta,
        criteriaLabel.isAcceptableOrUnknown(
          data['criteria_label']!,
          _criteriaLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_criteriaLabelMeta);
    }
    if (data.containsKey('group_title')) {
      context.handle(
        _groupTitleMeta,
        groupTitle.isAcceptableOrUnknown(data['group_title']!, _groupTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_groupTitleMeta);
    }
    if (data.containsKey('plan_description')) {
      context.handle(
        _planDescriptionMeta,
        planDescription.isAcceptableOrUnknown(
          data['plan_description']!,
          _planDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('root_cause')) {
      context.handle(
        _rootCauseMeta,
        rootCause.isAcceptableOrUnknown(data['root_cause']!, _rootCauseMeta),
      );
    }
    if (data.containsKey('correction_plan')) {
      context.handle(
        _correctionPlanMeta,
        correctionPlan.isAcceptableOrUnknown(
          data['correction_plan']!,
          _correctionPlanMeta,
        ),
      );
    }
    if (data.containsKey('evidence_photo_url')) {
      context.handle(
        _evidencePhotoUrlMeta,
        evidencePhotoUrl.isAcceptableOrUnknown(
          data['evidence_photo_url']!,
          _evidencePhotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('evidence_note')) {
      context.handle(
        _evidenceNoteMeta,
        evidenceNote.isAcceptableOrUnknown(
          data['evidence_note']!,
          _evidenceNoteMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('store_manager_name')) {
      context.handle(
        _storeManagerNameMeta,
        storeManagerName.isAcceptableOrUnknown(
          data['store_manager_name']!,
          _storeManagerNameMeta,
        ),
      );
    }
    if (data.containsKey('verifier_name')) {
      context.handle(
        _verifierNameMeta,
        verifierName.isAcceptableOrUnknown(
          data['verifier_name']!,
          _verifierNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedActionPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedActionPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      submissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_id'],
      ),
      answerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_id'],
      ),
      criteriaLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria_label'],
      )!,
      groupTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_title'],
      )!,
      planDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_description'],
      ),
      rootCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_cause'],
      ),
      correctionPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correction_plan'],
      ),
      evidencePhotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_photo_url'],
      ),
      evidenceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      storeManagerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_manager_name'],
      ),
      verifierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verifier_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedActionPlansTable createAlias(String alias) {
    return $CachedActionPlansTable(attachedDatabase, alias);
  }
}

class CachedActionPlan extends DataClass
    implements Insertable<CachedActionPlan> {
  final String id;
  final String? submissionId;
  final String? answerId;
  final String criteriaLabel;
  final String groupTitle;
  final String? planDescription;
  final String? rootCause;
  final String? correctionPlan;
  final String? evidencePhotoUrl;
  final String? evidenceNote;
  final String status;
  final DateTime? deadline;
  final DateTime? closedAt;
  final String? storeName;
  final String? storeId;
  final String? storeManagerName;
  final String? verifierName;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedActionPlan({
    required this.id,
    this.submissionId,
    this.answerId,
    required this.criteriaLabel,
    required this.groupTitle,
    this.planDescription,
    this.rootCause,
    this.correctionPlan,
    this.evidencePhotoUrl,
    this.evidenceNote,
    required this.status,
    this.deadline,
    this.closedAt,
    this.storeName,
    this.storeId,
    this.storeManagerName,
    this.verifierName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || submissionId != null) {
      map['submission_id'] = Variable<String>(submissionId);
    }
    if (!nullToAbsent || answerId != null) {
      map['answer_id'] = Variable<String>(answerId);
    }
    map['criteria_label'] = Variable<String>(criteriaLabel);
    map['group_title'] = Variable<String>(groupTitle);
    if (!nullToAbsent || planDescription != null) {
      map['plan_description'] = Variable<String>(planDescription);
    }
    if (!nullToAbsent || rootCause != null) {
      map['root_cause'] = Variable<String>(rootCause);
    }
    if (!nullToAbsent || correctionPlan != null) {
      map['correction_plan'] = Variable<String>(correctionPlan);
    }
    if (!nullToAbsent || evidencePhotoUrl != null) {
      map['evidence_photo_url'] = Variable<String>(evidencePhotoUrl);
    }
    if (!nullToAbsent || evidenceNote != null) {
      map['evidence_note'] = Variable<String>(evidenceNote);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || storeManagerName != null) {
      map['store_manager_name'] = Variable<String>(storeManagerName);
    }
    if (!nullToAbsent || verifierName != null) {
      map['verifier_name'] = Variable<String>(verifierName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedActionPlansCompanion toCompanion(bool nullToAbsent) {
    return CachedActionPlansCompanion(
      id: Value(id),
      submissionId: submissionId == null && nullToAbsent
          ? const Value.absent()
          : Value(submissionId),
      answerId: answerId == null && nullToAbsent
          ? const Value.absent()
          : Value(answerId),
      criteriaLabel: Value(criteriaLabel),
      groupTitle: Value(groupTitle),
      planDescription: planDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(planDescription),
      rootCause: rootCause == null && nullToAbsent
          ? const Value.absent()
          : Value(rootCause),
      correctionPlan: correctionPlan == null && nullToAbsent
          ? const Value.absent()
          : Value(correctionPlan),
      evidencePhotoUrl: evidencePhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(evidencePhotoUrl),
      evidenceNote: evidenceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceNote),
      status: Value(status),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      storeManagerName: storeManagerName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeManagerName),
      verifierName: verifierName == null && nullToAbsent
          ? const Value.absent()
          : Value(verifierName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedActionPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedActionPlan(
      id: serializer.fromJson<String>(json['id']),
      submissionId: serializer.fromJson<String?>(json['submissionId']),
      answerId: serializer.fromJson<String?>(json['answerId']),
      criteriaLabel: serializer.fromJson<String>(json['criteriaLabel']),
      groupTitle: serializer.fromJson<String>(json['groupTitle']),
      planDescription: serializer.fromJson<String?>(json['planDescription']),
      rootCause: serializer.fromJson<String?>(json['rootCause']),
      correctionPlan: serializer.fromJson<String?>(json['correctionPlan']),
      evidencePhotoUrl: serializer.fromJson<String?>(json['evidencePhotoUrl']),
      evidenceNote: serializer.fromJson<String?>(json['evidenceNote']),
      status: serializer.fromJson<String>(json['status']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      storeManagerName: serializer.fromJson<String?>(json['storeManagerName']),
      verifierName: serializer.fromJson<String?>(json['verifierName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'submissionId': serializer.toJson<String?>(submissionId),
      'answerId': serializer.toJson<String?>(answerId),
      'criteriaLabel': serializer.toJson<String>(criteriaLabel),
      'groupTitle': serializer.toJson<String>(groupTitle),
      'planDescription': serializer.toJson<String?>(planDescription),
      'rootCause': serializer.toJson<String?>(rootCause),
      'correctionPlan': serializer.toJson<String?>(correctionPlan),
      'evidencePhotoUrl': serializer.toJson<String?>(evidencePhotoUrl),
      'evidenceNote': serializer.toJson<String?>(evidenceNote),
      'status': serializer.toJson<String>(status),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'storeName': serializer.toJson<String?>(storeName),
      'storeId': serializer.toJson<String?>(storeId),
      'storeManagerName': serializer.toJson<String?>(storeManagerName),
      'verifierName': serializer.toJson<String?>(verifierName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedActionPlan copyWith({
    String? id,
    Value<String?> submissionId = const Value.absent(),
    Value<String?> answerId = const Value.absent(),
    String? criteriaLabel,
    String? groupTitle,
    Value<String?> planDescription = const Value.absent(),
    Value<String?> rootCause = const Value.absent(),
    Value<String?> correctionPlan = const Value.absent(),
    Value<String?> evidencePhotoUrl = const Value.absent(),
    Value<String?> evidenceNote = const Value.absent(),
    String? status,
    Value<DateTime?> deadline = const Value.absent(),
    Value<DateTime?> closedAt = const Value.absent(),
    Value<String?> storeName = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    Value<String?> storeManagerName = const Value.absent(),
    Value<String?> verifierName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedActionPlan(
    id: id ?? this.id,
    submissionId: submissionId.present ? submissionId.value : this.submissionId,
    answerId: answerId.present ? answerId.value : this.answerId,
    criteriaLabel: criteriaLabel ?? this.criteriaLabel,
    groupTitle: groupTitle ?? this.groupTitle,
    planDescription: planDescription.present
        ? planDescription.value
        : this.planDescription,
    rootCause: rootCause.present ? rootCause.value : this.rootCause,
    correctionPlan: correctionPlan.present
        ? correctionPlan.value
        : this.correctionPlan,
    evidencePhotoUrl: evidencePhotoUrl.present
        ? evidencePhotoUrl.value
        : this.evidencePhotoUrl,
    evidenceNote: evidenceNote.present ? evidenceNote.value : this.evidenceNote,
    status: status ?? this.status,
    deadline: deadline.present ? deadline.value : this.deadline,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    storeName: storeName.present ? storeName.value : this.storeName,
    storeId: storeId.present ? storeId.value : this.storeId,
    storeManagerName: storeManagerName.present
        ? storeManagerName.value
        : this.storeManagerName,
    verifierName: verifierName.present ? verifierName.value : this.verifierName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedActionPlan copyWithCompanion(CachedActionPlansCompanion data) {
    return CachedActionPlan(
      id: data.id.present ? data.id.value : this.id,
      submissionId: data.submissionId.present
          ? data.submissionId.value
          : this.submissionId,
      answerId: data.answerId.present ? data.answerId.value : this.answerId,
      criteriaLabel: data.criteriaLabel.present
          ? data.criteriaLabel.value
          : this.criteriaLabel,
      groupTitle: data.groupTitle.present
          ? data.groupTitle.value
          : this.groupTitle,
      planDescription: data.planDescription.present
          ? data.planDescription.value
          : this.planDescription,
      rootCause: data.rootCause.present ? data.rootCause.value : this.rootCause,
      correctionPlan: data.correctionPlan.present
          ? data.correctionPlan.value
          : this.correctionPlan,
      evidencePhotoUrl: data.evidencePhotoUrl.present
          ? data.evidencePhotoUrl.value
          : this.evidencePhotoUrl,
      evidenceNote: data.evidenceNote.present
          ? data.evidenceNote.value
          : this.evidenceNote,
      status: data.status.present ? data.status.value : this.status,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeManagerName: data.storeManagerName.present
          ? data.storeManagerName.value
          : this.storeManagerName,
      verifierName: data.verifierName.present
          ? data.verifierName.value
          : this.verifierName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedActionPlan(')
          ..write('id: $id, ')
          ..write('submissionId: $submissionId, ')
          ..write('answerId: $answerId, ')
          ..write('criteriaLabel: $criteriaLabel, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('planDescription: $planDescription, ')
          ..write('rootCause: $rootCause, ')
          ..write('correctionPlan: $correctionPlan, ')
          ..write('evidencePhotoUrl: $evidencePhotoUrl, ')
          ..write('evidenceNote: $evidenceNote, ')
          ..write('status: $status, ')
          ..write('deadline: $deadline, ')
          ..write('closedAt: $closedAt, ')
          ..write('storeName: $storeName, ')
          ..write('storeId: $storeId, ')
          ..write('storeManagerName: $storeManagerName, ')
          ..write('verifierName: $verifierName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    submissionId,
    answerId,
    criteriaLabel,
    groupTitle,
    planDescription,
    rootCause,
    correctionPlan,
    evidencePhotoUrl,
    evidenceNote,
    status,
    deadline,
    closedAt,
    storeName,
    storeId,
    storeManagerName,
    verifierName,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedActionPlan &&
          other.id == this.id &&
          other.submissionId == this.submissionId &&
          other.answerId == this.answerId &&
          other.criteriaLabel == this.criteriaLabel &&
          other.groupTitle == this.groupTitle &&
          other.planDescription == this.planDescription &&
          other.rootCause == this.rootCause &&
          other.correctionPlan == this.correctionPlan &&
          other.evidencePhotoUrl == this.evidencePhotoUrl &&
          other.evidenceNote == this.evidenceNote &&
          other.status == this.status &&
          other.deadline == this.deadline &&
          other.closedAt == this.closedAt &&
          other.storeName == this.storeName &&
          other.storeId == this.storeId &&
          other.storeManagerName == this.storeManagerName &&
          other.verifierName == this.verifierName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedActionPlansCompanion extends UpdateCompanion<CachedActionPlan> {
  final Value<String> id;
  final Value<String?> submissionId;
  final Value<String?> answerId;
  final Value<String> criteriaLabel;
  final Value<String> groupTitle;
  final Value<String?> planDescription;
  final Value<String?> rootCause;
  final Value<String?> correctionPlan;
  final Value<String?> evidencePhotoUrl;
  final Value<String?> evidenceNote;
  final Value<String> status;
  final Value<DateTime?> deadline;
  final Value<DateTime?> closedAt;
  final Value<String?> storeName;
  final Value<String?> storeId;
  final Value<String?> storeManagerName;
  final Value<String?> verifierName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedActionPlansCompanion({
    this.id = const Value.absent(),
    this.submissionId = const Value.absent(),
    this.answerId = const Value.absent(),
    this.criteriaLabel = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.planDescription = const Value.absent(),
    this.rootCause = const Value.absent(),
    this.correctionPlan = const Value.absent(),
    this.evidencePhotoUrl = const Value.absent(),
    this.evidenceNote = const Value.absent(),
    this.status = const Value.absent(),
    this.deadline = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.storeName = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeManagerName = const Value.absent(),
    this.verifierName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedActionPlansCompanion.insert({
    required String id,
    this.submissionId = const Value.absent(),
    this.answerId = const Value.absent(),
    required String criteriaLabel,
    required String groupTitle,
    this.planDescription = const Value.absent(),
    this.rootCause = const Value.absent(),
    this.correctionPlan = const Value.absent(),
    this.evidencePhotoUrl = const Value.absent(),
    this.evidenceNote = const Value.absent(),
    this.status = const Value.absent(),
    this.deadline = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.storeName = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeManagerName = const Value.absent(),
    this.verifierName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       criteriaLabel = Value(criteriaLabel),
       groupTitle = Value(groupTitle),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedActionPlan> custom({
    Expression<String>? id,
    Expression<String>? submissionId,
    Expression<String>? answerId,
    Expression<String>? criteriaLabel,
    Expression<String>? groupTitle,
    Expression<String>? planDescription,
    Expression<String>? rootCause,
    Expression<String>? correctionPlan,
    Expression<String>? evidencePhotoUrl,
    Expression<String>? evidenceNote,
    Expression<String>? status,
    Expression<DateTime>? deadline,
    Expression<DateTime>? closedAt,
    Expression<String>? storeName,
    Expression<String>? storeId,
    Expression<String>? storeManagerName,
    Expression<String>? verifierName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (submissionId != null) 'submission_id': submissionId,
      if (answerId != null) 'answer_id': answerId,
      if (criteriaLabel != null) 'criteria_label': criteriaLabel,
      if (groupTitle != null) 'group_title': groupTitle,
      if (planDescription != null) 'plan_description': planDescription,
      if (rootCause != null) 'root_cause': rootCause,
      if (correctionPlan != null) 'correction_plan': correctionPlan,
      if (evidencePhotoUrl != null) 'evidence_photo_url': evidencePhotoUrl,
      if (evidenceNote != null) 'evidence_note': evidenceNote,
      if (status != null) 'status': status,
      if (deadline != null) 'deadline': deadline,
      if (closedAt != null) 'closed_at': closedAt,
      if (storeName != null) 'store_name': storeName,
      if (storeId != null) 'store_id': storeId,
      if (storeManagerName != null) 'store_manager_name': storeManagerName,
      if (verifierName != null) 'verifier_name': verifierName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedActionPlansCompanion copyWith({
    Value<String>? id,
    Value<String?>? submissionId,
    Value<String?>? answerId,
    Value<String>? criteriaLabel,
    Value<String>? groupTitle,
    Value<String?>? planDescription,
    Value<String?>? rootCause,
    Value<String?>? correctionPlan,
    Value<String?>? evidencePhotoUrl,
    Value<String?>? evidenceNote,
    Value<String>? status,
    Value<DateTime?>? deadline,
    Value<DateTime?>? closedAt,
    Value<String?>? storeName,
    Value<String?>? storeId,
    Value<String?>? storeManagerName,
    Value<String?>? verifierName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedActionPlansCompanion(
      id: id ?? this.id,
      submissionId: submissionId ?? this.submissionId,
      answerId: answerId ?? this.answerId,
      criteriaLabel: criteriaLabel ?? this.criteriaLabel,
      groupTitle: groupTitle ?? this.groupTitle,
      planDescription: planDescription ?? this.planDescription,
      rootCause: rootCause ?? this.rootCause,
      correctionPlan: correctionPlan ?? this.correctionPlan,
      evidencePhotoUrl: evidencePhotoUrl ?? this.evidencePhotoUrl,
      evidenceNote: evidenceNote ?? this.evidenceNote,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      closedAt: closedAt ?? this.closedAt,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      storeManagerName: storeManagerName ?? this.storeManagerName,
      verifierName: verifierName ?? this.verifierName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (submissionId.present) {
      map['submission_id'] = Variable<String>(submissionId.value);
    }
    if (answerId.present) {
      map['answer_id'] = Variable<String>(answerId.value);
    }
    if (criteriaLabel.present) {
      map['criteria_label'] = Variable<String>(criteriaLabel.value);
    }
    if (groupTitle.present) {
      map['group_title'] = Variable<String>(groupTitle.value);
    }
    if (planDescription.present) {
      map['plan_description'] = Variable<String>(planDescription.value);
    }
    if (rootCause.present) {
      map['root_cause'] = Variable<String>(rootCause.value);
    }
    if (correctionPlan.present) {
      map['correction_plan'] = Variable<String>(correctionPlan.value);
    }
    if (evidencePhotoUrl.present) {
      map['evidence_photo_url'] = Variable<String>(evidencePhotoUrl.value);
    }
    if (evidenceNote.present) {
      map['evidence_note'] = Variable<String>(evidenceNote.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeManagerName.present) {
      map['store_manager_name'] = Variable<String>(storeManagerName.value);
    }
    if (verifierName.present) {
      map['verifier_name'] = Variable<String>(verifierName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedActionPlansCompanion(')
          ..write('id: $id, ')
          ..write('submissionId: $submissionId, ')
          ..write('answerId: $answerId, ')
          ..write('criteriaLabel: $criteriaLabel, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('planDescription: $planDescription, ')
          ..write('rootCause: $rootCause, ')
          ..write('correctionPlan: $correctionPlan, ')
          ..write('evidencePhotoUrl: $evidencePhotoUrl, ')
          ..write('evidenceNote: $evidenceNote, ')
          ..write('status: $status, ')
          ..write('deadline: $deadline, ')
          ..write('closedAt: $closedAt, ')
          ..write('storeName: $storeName, ')
          ..write('storeId: $storeId, ')
          ..write('storeManagerName: $storeManagerName, ')
          ..write('verifierName: $verifierName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedNotificationsTable extends CachedNotifications
    with TableInfo<$CachedNotificationsTable, CachedNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionUrlMeta = const VerificationMeta(
    'actionUrl',
  );
  @override
  late final GeneratedColumn<String> actionUrl = GeneratedColumn<String>(
    'action_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    title,
    message,
    readAt,
    actionUrl,
    metadata,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('action_url')) {
      context.handle(
        _actionUrlMeta,
        actionUrl.isAcceptableOrUnknown(data['action_url']!, _actionUrlMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      actionUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_url'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedNotificationsTable createAlias(String alias) {
    return $CachedNotificationsTable(attachedDatabase, alias);
  }
}

class CachedNotification extends DataClass
    implements Insertable<CachedNotification> {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? message;
  final DateTime? readAt;
  final String? actionUrl;
  final String? metadata;
  final DateTime createdAt;
  const CachedNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.readAt,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || actionUrl != null) {
      map['action_url'] = Variable<String>(actionUrl);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CachedNotificationsCompanion toCompanion(bool nullToAbsent) {
    return CachedNotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      title: Value(title),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      actionUrl: actionUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(actionUrl),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
    );
  }

  factory CachedNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNotification(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String?>(json['message']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      actionUrl: serializer.fromJson<String?>(json['actionUrl']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String?>(message),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'actionUrl': serializer.toJson<String?>(actionUrl),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CachedNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    Value<String?> message = const Value.absent(),
    Value<DateTime?> readAt = const Value.absent(),
    Value<String?> actionUrl = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
  }) => CachedNotification(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    title: title ?? this.title,
    message: message.present ? message.value : this.message,
    readAt: readAt.present ? readAt.value : this.readAt,
    actionUrl: actionUrl.present ? actionUrl.value : this.actionUrl,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedNotification copyWithCompanion(CachedNotificationsCompanion data) {
    return CachedNotification(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      actionUrl: data.actionUrl.present ? data.actionUrl.value : this.actionUrl,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('readAt: $readAt, ')
          ..write('actionUrl: $actionUrl, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    title,
    message,
    readAt,
    actionUrl,
    metadata,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNotification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.title == this.title &&
          other.message == this.message &&
          other.readAt == this.readAt &&
          other.actionUrl == this.actionUrl &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt);
}

class CachedNotificationsCompanion extends UpdateCompanion<CachedNotification> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> message;
  final Value<DateTime?> readAt;
  final Value<String?> actionUrl;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CachedNotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.readAt = const Value.absent(),
    this.actionUrl = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedNotificationsCompanion.insert({
    required String id,
    required String userId,
    required String type,
    required String title,
    this.message = const Value.absent(),
    this.readAt = const Value.absent(),
    this.actionUrl = const Value.absent(),
    this.metadata = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       type = Value(type),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<CachedNotification> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? message,
    Expression<DateTime>? readAt,
    Expression<String>? actionUrl,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (readAt != null) 'read_at': readAt,
      if (actionUrl != null) 'action_url': actionUrl,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? message,
    Value<DateTime?>? readAt,
    Value<String?>? actionUrl,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedNotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (actionUrl.present) {
      map['action_url'] = Variable<String>(actionUrl.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('readAt: $readAt, ')
          ..write('actionUrl: $actionUrl, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPoliciesTable extends CachedPolicies
    with TableInfo<$CachedPoliciesTable, CachedPolicy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPoliciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _capabilityMeta = const VerificationMeta(
    'capability',
  );
  @override
  late final GeneratedColumn<String> capability = GeneratedColumn<String>(
    'capability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [capability];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_policies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPolicy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('capability')) {
      context.handle(
        _capabilityMeta,
        capability.isAcceptableOrUnknown(data['capability']!, _capabilityMeta),
      );
    } else if (isInserting) {
      context.missing(_capabilityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {capability};
  @override
  CachedPolicy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPolicy(
      capability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capability'],
      )!,
    );
  }

  @override
  $CachedPoliciesTable createAlias(String alias) {
    return $CachedPoliciesTable(attachedDatabase, alias);
  }
}

class CachedPolicy extends DataClass implements Insertable<CachedPolicy> {
  /// The capability string, e.g. "templates:create", "submissions:list".
  final String capability;
  const CachedPolicy({required this.capability});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['capability'] = Variable<String>(capability);
    return map;
  }

  CachedPoliciesCompanion toCompanion(bool nullToAbsent) {
    return CachedPoliciesCompanion(capability: Value(capability));
  }

  factory CachedPolicy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPolicy(
      capability: serializer.fromJson<String>(json['capability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'capability': serializer.toJson<String>(capability),
    };
  }

  CachedPolicy copyWith({String? capability}) =>
      CachedPolicy(capability: capability ?? this.capability);
  CachedPolicy copyWithCompanion(CachedPoliciesCompanion data) {
    return CachedPolicy(
      capability: data.capability.present
          ? data.capability.value
          : this.capability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPolicy(')
          ..write('capability: $capability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => capability.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPolicy && other.capability == this.capability);
}

class CachedPoliciesCompanion extends UpdateCompanion<CachedPolicy> {
  final Value<String> capability;
  final Value<int> rowid;
  const CachedPoliciesCompanion({
    this.capability = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPoliciesCompanion.insert({
    required String capability,
    this.rowid = const Value.absent(),
  }) : capability = Value(capability);
  static Insertable<CachedPolicy> custom({
    Expression<String>? capability,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (capability != null) 'capability': capability,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPoliciesCompanion copyWith({
    Value<String>? capability,
    Value<int>? rowid,
  }) {
    return CachedPoliciesCompanion(
      capability: capability ?? this.capability,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (capability.present) {
      map['capability'] = Variable<String>(capability.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPoliciesCompanion(')
          ..write('capability: $capability, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSubmissionsTable extends PendingSubmissions
    with TableInfo<$PendingSubmissionsTable, PendingSubmission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSubmissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientScoreMeta = const VerificationMeta(
    'clientScore',
  );
  @override
  late final GeneratedColumn<double> clientScore = GeneratedColumn<double>(
    'client_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionScoresMeta = const VerificationMeta(
    'sectionScores',
  );
  @override
  late final GeneratedColumn<String> sectionScores = GeneratedColumn<String>(
    'section_scores',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLatMeta = const VerificationMeta('gpsLat');
  @override
  late final GeneratedColumn<double> gpsLat = GeneratedColumn<double>(
    'gps_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLngMeta = const VerificationMeta('gpsLng');
  @override
  late final GeneratedColumn<double> gpsLng = GeneratedColumn<double>(
    'gps_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSubmissionIdMeta =
      const VerificationMeta('targetSubmissionId');
  @override
  late final GeneratedColumn<String> targetSubmissionId =
      GeneratedColumn<String>(
        'target_submission_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    storeId,
    clientScore,
    sectionScores,
    notes,
    gpsLat,
    gpsLng,
    idempotencyKey,
    syncStatus,
    syncError,
    retryCount,
    nextRetryAt,
    createdAt,
    targetSubmissionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_submissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSubmission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('client_score')) {
      context.handle(
        _clientScoreMeta,
        clientScore.isAcceptableOrUnknown(
          data['client_score']!,
          _clientScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientScoreMeta);
    }
    if (data.containsKey('section_scores')) {
      context.handle(
        _sectionScoresMeta,
        sectionScores.isAcceptableOrUnknown(
          data['section_scores']!,
          _sectionScoresMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('gps_lat')) {
      context.handle(
        _gpsLatMeta,
        gpsLat.isAcceptableOrUnknown(data['gps_lat']!, _gpsLatMeta),
      );
    }
    if (data.containsKey('gps_lng')) {
      context.handle(
        _gpsLngMeta,
        gpsLng.isAcceptableOrUnknown(data['gps_lng']!, _gpsLngMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('target_submission_id')) {
      context.handle(
        _targetSubmissionIdMeta,
        targetSubmissionId.isAcceptableOrUnknown(
          data['target_submission_id']!,
          _targetSubmissionIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSubmission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSubmission(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      clientScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}client_score'],
      )!,
      sectionScores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_scores'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      gpsLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lat'],
      ),
      gpsLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lng'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      targetSubmissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_submission_id'],
      ),
    );
  }

  @override
  $PendingSubmissionsTable createAlias(String alias) {
    return $PendingSubmissionsTable(attachedDatabase, alias);
  }
}

class PendingSubmission extends DataClass
    implements Insertable<PendingSubmission> {
  final String id;
  final String templateId;
  final String storeId;
  final double clientScore;
  final String? sectionScores;
  final String? notes;
  final double? gpsLat;
  final double? gpsLng;
  final String idempotencyKey;
  final String syncStatus;
  final String? syncError;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime createdAt;

  /// When non-null, this outbox row is finalizing an EXISTING server-side draft.
  /// SyncEngine routes to PUT /submissions/{id}/finalize instead of POST /submissions.
  /// Null = fresh new audit (default POST path).
  final String? targetSubmissionId;
  const PendingSubmission({
    required this.id,
    required this.templateId,
    required this.storeId,
    required this.clientScore,
    this.sectionScores,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    required this.idempotencyKey,
    required this.syncStatus,
    this.syncError,
    required this.retryCount,
    this.nextRetryAt,
    required this.createdAt,
    this.targetSubmissionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['store_id'] = Variable<String>(storeId);
    map['client_score'] = Variable<double>(clientScore);
    if (!nullToAbsent || sectionScores != null) {
      map['section_scores'] = Variable<String>(sectionScores);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || gpsLat != null) {
      map['gps_lat'] = Variable<double>(gpsLat);
    }
    if (!nullToAbsent || gpsLng != null) {
      map['gps_lng'] = Variable<double>(gpsLng);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || targetSubmissionId != null) {
      map['target_submission_id'] = Variable<String>(targetSubmissionId);
    }
    return map;
  }

  PendingSubmissionsCompanion toCompanion(bool nullToAbsent) {
    return PendingSubmissionsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      storeId: Value(storeId),
      clientScore: Value(clientScore),
      sectionScores: sectionScores == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionScores),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      gpsLat: gpsLat == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLat),
      gpsLng: gpsLng == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLng),
      idempotencyKey: Value(idempotencyKey),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
      targetSubmissionId: targetSubmissionId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSubmissionId),
    );
  }

  factory PendingSubmission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSubmission(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      storeId: serializer.fromJson<String>(json['storeId']),
      clientScore: serializer.fromJson<double>(json['clientScore']),
      sectionScores: serializer.fromJson<String?>(json['sectionScores']),
      notes: serializer.fromJson<String?>(json['notes']),
      gpsLat: serializer.fromJson<double?>(json['gpsLat']),
      gpsLng: serializer.fromJson<double?>(json['gpsLng']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      targetSubmissionId: serializer.fromJson<String?>(
        json['targetSubmissionId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'storeId': serializer.toJson<String>(storeId),
      'clientScore': serializer.toJson<double>(clientScore),
      'sectionScores': serializer.toJson<String?>(sectionScores),
      'notes': serializer.toJson<String?>(notes),
      'gpsLat': serializer.toJson<double?>(gpsLat),
      'gpsLng': serializer.toJson<double?>(gpsLng),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'targetSubmissionId': serializer.toJson<String?>(targetSubmissionId),
    };
  }

  PendingSubmission copyWith({
    String? id,
    String? templateId,
    String? storeId,
    double? clientScore,
    Value<String?> sectionScores = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<double?> gpsLat = const Value.absent(),
    Value<double?> gpsLng = const Value.absent(),
    String? idempotencyKey,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? retryCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    DateTime? createdAt,
    Value<String?> targetSubmissionId = const Value.absent(),
  }) => PendingSubmission(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    storeId: storeId ?? this.storeId,
    clientScore: clientScore ?? this.clientScore,
    sectionScores: sectionScores.present
        ? sectionScores.value
        : this.sectionScores,
    notes: notes.present ? notes.value : this.notes,
    gpsLat: gpsLat.present ? gpsLat.value : this.gpsLat,
    gpsLng: gpsLng.present ? gpsLng.value : this.gpsLng,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
    targetSubmissionId: targetSubmissionId.present
        ? targetSubmissionId.value
        : this.targetSubmissionId,
  );
  PendingSubmission copyWithCompanion(PendingSubmissionsCompanion data) {
    return PendingSubmission(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      clientScore: data.clientScore.present
          ? data.clientScore.value
          : this.clientScore,
      sectionScores: data.sectionScores.present
          ? data.sectionScores.value
          : this.sectionScores,
      notes: data.notes.present ? data.notes.value : this.notes,
      gpsLat: data.gpsLat.present ? data.gpsLat.value : this.gpsLat,
      gpsLng: data.gpsLng.present ? data.gpsLng.value : this.gpsLng,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      targetSubmissionId: data.targetSubmissionId.present
          ? data.targetSubmissionId.value
          : this.targetSubmissionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSubmission(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('storeId: $storeId, ')
          ..write('clientScore: $clientScore, ')
          ..write('sectionScores: $sectionScores, ')
          ..write('notes: $notes, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLng: $gpsLng, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('targetSubmissionId: $targetSubmissionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    storeId,
    clientScore,
    sectionScores,
    notes,
    gpsLat,
    gpsLng,
    idempotencyKey,
    syncStatus,
    syncError,
    retryCount,
    nextRetryAt,
    createdAt,
    targetSubmissionId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSubmission &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.storeId == this.storeId &&
          other.clientScore == this.clientScore &&
          other.sectionScores == this.sectionScores &&
          other.notes == this.notes &&
          other.gpsLat == this.gpsLat &&
          other.gpsLng == this.gpsLng &&
          other.idempotencyKey == this.idempotencyKey &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.targetSubmissionId == this.targetSubmissionId);
}

class PendingSubmissionsCompanion extends UpdateCompanion<PendingSubmission> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> storeId;
  final Value<double> clientScore;
  final Value<String?> sectionScores;
  final Value<String?> notes;
  final Value<double?> gpsLat;
  final Value<double?> gpsLng;
  final Value<String> idempotencyKey;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<DateTime> createdAt;
  final Value<String?> targetSubmissionId;
  final Value<int> rowid;
  const PendingSubmissionsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.clientScore = const Value.absent(),
    this.sectionScores = const Value.absent(),
    this.notes = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLng = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.targetSubmissionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSubmissionsCompanion.insert({
    required String id,
    required String templateId,
    required String storeId,
    required double clientScore,
    this.sectionScores = const Value.absent(),
    this.notes = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLng = const Value.absent(),
    required String idempotencyKey,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required DateTime createdAt,
    this.targetSubmissionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       storeId = Value(storeId),
       clientScore = Value(clientScore),
       idempotencyKey = Value(idempotencyKey),
       createdAt = Value(createdAt);
  static Insertable<PendingSubmission> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? storeId,
    Expression<double>? clientScore,
    Expression<String>? sectionScores,
    Expression<String>? notes,
    Expression<double>? gpsLat,
    Expression<double>? gpsLng,
    Expression<String>? idempotencyKey,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? createdAt,
    Expression<String>? targetSubmissionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (storeId != null) 'store_id': storeId,
      if (clientScore != null) 'client_score': clientScore,
      if (sectionScores != null) 'section_scores': sectionScores,
      if (notes != null) 'notes': notes,
      if (gpsLat != null) 'gps_lat': gpsLat,
      if (gpsLng != null) 'gps_lng': gpsLng,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (targetSubmissionId != null)
        'target_submission_id': targetSubmissionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSubmissionsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? storeId,
    Value<double>? clientScore,
    Value<String?>? sectionScores,
    Value<String?>? notes,
    Value<double?>? gpsLat,
    Value<double?>? gpsLng,
    Value<String>? idempotencyKey,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? retryCount,
    Value<DateTime?>? nextRetryAt,
    Value<DateTime>? createdAt,
    Value<String?>? targetSubmissionId,
    Value<int>? rowid,
  }) {
    return PendingSubmissionsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      storeId: storeId ?? this.storeId,
      clientScore: clientScore ?? this.clientScore,
      sectionScores: sectionScores ?? this.sectionScores,
      notes: notes ?? this.notes,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      targetSubmissionId: targetSubmissionId ?? this.targetSubmissionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (clientScore.present) {
      map['client_score'] = Variable<double>(clientScore.value);
    }
    if (sectionScores.present) {
      map['section_scores'] = Variable<String>(sectionScores.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (gpsLat.present) {
      map['gps_lat'] = Variable<double>(gpsLat.value);
    }
    if (gpsLng.present) {
      map['gps_lng'] = Variable<double>(gpsLng.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (targetSubmissionId.present) {
      map['target_submission_id'] = Variable<String>(targetSubmissionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSubmissionsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('storeId: $storeId, ')
          ..write('clientScore: $clientScore, ')
          ..write('sectionScores: $sectionScores, ')
          ..write('notes: $notes, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLng: $gpsLng, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('targetSubmissionId: $targetSubmissionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingAnswersTable extends PendingAnswers
    with TableInfo<$PendingAnswersTable, PendingAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSubmissionIdMeta =
      const VerificationMeta('pendingSubmissionId');
  @override
  late final GeneratedColumn<String> pendingSubmissionId =
      GeneratedColumn<String>(
        'pending_submission_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pending_submissions (id)',
        ),
      );
  static const VerificationMeta _criteriaIdMeta = const VerificationMeta(
    'criteriaId',
  );
  @override
  late final GeneratedColumn<String> criteriaId = GeneratedColumn<String>(
    'criteria_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numericValueMeta = const VerificationMeta(
    'numericValue',
  );
  @override
  late final GeneratedColumn<double> numericValue = GeneratedColumn<double>(
    'numeric_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRepeatedErrorMeta = const VerificationMeta(
    'isRepeatedError',
  );
  @override
  late final GeneratedColumn<bool> isRepeatedError = GeneratedColumn<bool>(
    'is_repeated_error',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_repeated_error" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pendingSubmissionId,
    criteriaId,
    value,
    numericValue,
    note,
    photoUrl,
    isRepeatedError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pending_submission_id')) {
      context.handle(
        _pendingSubmissionIdMeta,
        pendingSubmissionId.isAcceptableOrUnknown(
          data['pending_submission_id']!,
          _pendingSubmissionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pendingSubmissionIdMeta);
    }
    if (data.containsKey('criteria_id')) {
      context.handle(
        _criteriaIdMeta,
        criteriaId.isAcceptableOrUnknown(data['criteria_id']!, _criteriaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_criteriaIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('numeric_value')) {
      context.handle(
        _numericValueMeta,
        numericValue.isAcceptableOrUnknown(
          data['numeric_value']!,
          _numericValueMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('is_repeated_error')) {
      context.handle(
        _isRepeatedErrorMeta,
        isRepeatedError.isAcceptableOrUnknown(
          data['is_repeated_error']!,
          _isRepeatedErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingAnswer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pendingSubmissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_submission_id'],
      )!,
      criteriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      numericValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}numeric_value'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      isRepeatedError: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_repeated_error'],
      )!,
    );
  }

  @override
  $PendingAnswersTable createAlias(String alias) {
    return $PendingAnswersTable(attachedDatabase, alias);
  }
}

class PendingAnswer extends DataClass implements Insertable<PendingAnswer> {
  final String id;
  final String pendingSubmissionId;
  final String criteriaId;
  final String? value;
  final double? numericValue;
  final String? note;
  final String? photoUrl;
  final bool isRepeatedError;
  const PendingAnswer({
    required this.id,
    required this.pendingSubmissionId,
    required this.criteriaId,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    required this.isRepeatedError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pending_submission_id'] = Variable<String>(pendingSubmissionId);
    map['criteria_id'] = Variable<String>(criteriaId);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || numericValue != null) {
      map['numeric_value'] = Variable<double>(numericValue);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['is_repeated_error'] = Variable<bool>(isRepeatedError);
    return map;
  }

  PendingAnswersCompanion toCompanion(bool nullToAbsent) {
    return PendingAnswersCompanion(
      id: Value(id),
      pendingSubmissionId: Value(pendingSubmissionId),
      criteriaId: Value(criteriaId),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      numericValue: numericValue == null && nullToAbsent
          ? const Value.absent()
          : Value(numericValue),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      isRepeatedError: Value(isRepeatedError),
    );
  }

  factory PendingAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingAnswer(
      id: serializer.fromJson<String>(json['id']),
      pendingSubmissionId: serializer.fromJson<String>(
        json['pendingSubmissionId'],
      ),
      criteriaId: serializer.fromJson<String>(json['criteriaId']),
      value: serializer.fromJson<String?>(json['value']),
      numericValue: serializer.fromJson<double?>(json['numericValue']),
      note: serializer.fromJson<String?>(json['note']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      isRepeatedError: serializer.fromJson<bool>(json['isRepeatedError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pendingSubmissionId': serializer.toJson<String>(pendingSubmissionId),
      'criteriaId': serializer.toJson<String>(criteriaId),
      'value': serializer.toJson<String?>(value),
      'numericValue': serializer.toJson<double?>(numericValue),
      'note': serializer.toJson<String?>(note),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'isRepeatedError': serializer.toJson<bool>(isRepeatedError),
    };
  }

  PendingAnswer copyWith({
    String? id,
    String? pendingSubmissionId,
    String? criteriaId,
    Value<String?> value = const Value.absent(),
    Value<double?> numericValue = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    bool? isRepeatedError,
  }) => PendingAnswer(
    id: id ?? this.id,
    pendingSubmissionId: pendingSubmissionId ?? this.pendingSubmissionId,
    criteriaId: criteriaId ?? this.criteriaId,
    value: value.present ? value.value : this.value,
    numericValue: numericValue.present ? numericValue.value : this.numericValue,
    note: note.present ? note.value : this.note,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    isRepeatedError: isRepeatedError ?? this.isRepeatedError,
  );
  PendingAnswer copyWithCompanion(PendingAnswersCompanion data) {
    return PendingAnswer(
      id: data.id.present ? data.id.value : this.id,
      pendingSubmissionId: data.pendingSubmissionId.present
          ? data.pendingSubmissionId.value
          : this.pendingSubmissionId,
      criteriaId: data.criteriaId.present
          ? data.criteriaId.value
          : this.criteriaId,
      value: data.value.present ? data.value.value : this.value,
      numericValue: data.numericValue.present
          ? data.numericValue.value
          : this.numericValue,
      note: data.note.present ? data.note.value : this.note,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      isRepeatedError: data.isRepeatedError.present
          ? data.isRepeatedError.value
          : this.isRepeatedError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingAnswer(')
          ..write('id: $id, ')
          ..write('pendingSubmissionId: $pendingSubmissionId, ')
          ..write('criteriaId: $criteriaId, ')
          ..write('value: $value, ')
          ..write('numericValue: $numericValue, ')
          ..write('note: $note, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('isRepeatedError: $isRepeatedError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pendingSubmissionId,
    criteriaId,
    value,
    numericValue,
    note,
    photoUrl,
    isRepeatedError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAnswer &&
          other.id == this.id &&
          other.pendingSubmissionId == this.pendingSubmissionId &&
          other.criteriaId == this.criteriaId &&
          other.value == this.value &&
          other.numericValue == this.numericValue &&
          other.note == this.note &&
          other.photoUrl == this.photoUrl &&
          other.isRepeatedError == this.isRepeatedError);
}

class PendingAnswersCompanion extends UpdateCompanion<PendingAnswer> {
  final Value<String> id;
  final Value<String> pendingSubmissionId;
  final Value<String> criteriaId;
  final Value<String?> value;
  final Value<double?> numericValue;
  final Value<String?> note;
  final Value<String?> photoUrl;
  final Value<bool> isRepeatedError;
  final Value<int> rowid;
  const PendingAnswersCompanion({
    this.id = const Value.absent(),
    this.pendingSubmissionId = const Value.absent(),
    this.criteriaId = const Value.absent(),
    this.value = const Value.absent(),
    this.numericValue = const Value.absent(),
    this.note = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.isRepeatedError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingAnswersCompanion.insert({
    required String id,
    required String pendingSubmissionId,
    required String criteriaId,
    this.value = const Value.absent(),
    this.numericValue = const Value.absent(),
    this.note = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.isRepeatedError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pendingSubmissionId = Value(pendingSubmissionId),
       criteriaId = Value(criteriaId);
  static Insertable<PendingAnswer> custom({
    Expression<String>? id,
    Expression<String>? pendingSubmissionId,
    Expression<String>? criteriaId,
    Expression<String>? value,
    Expression<double>? numericValue,
    Expression<String>? note,
    Expression<String>? photoUrl,
    Expression<bool>? isRepeatedError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pendingSubmissionId != null)
        'pending_submission_id': pendingSubmissionId,
      if (criteriaId != null) 'criteria_id': criteriaId,
      if (value != null) 'value': value,
      if (numericValue != null) 'numeric_value': numericValue,
      if (note != null) 'note': note,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (isRepeatedError != null) 'is_repeated_error': isRepeatedError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingAnswersCompanion copyWith({
    Value<String>? id,
    Value<String>? pendingSubmissionId,
    Value<String>? criteriaId,
    Value<String?>? value,
    Value<double?>? numericValue,
    Value<String?>? note,
    Value<String?>? photoUrl,
    Value<bool>? isRepeatedError,
    Value<int>? rowid,
  }) {
    return PendingAnswersCompanion(
      id: id ?? this.id,
      pendingSubmissionId: pendingSubmissionId ?? this.pendingSubmissionId,
      criteriaId: criteriaId ?? this.criteriaId,
      value: value ?? this.value,
      numericValue: numericValue ?? this.numericValue,
      note: note ?? this.note,
      photoUrl: photoUrl ?? this.photoUrl,
      isRepeatedError: isRepeatedError ?? this.isRepeatedError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pendingSubmissionId.present) {
      map['pending_submission_id'] = Variable<String>(
        pendingSubmissionId.value,
      );
    }
    if (criteriaId.present) {
      map['criteria_id'] = Variable<String>(criteriaId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (numericValue.present) {
      map['numeric_value'] = Variable<double>(numericValue.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (isRepeatedError.present) {
      map['is_repeated_error'] = Variable<bool>(isRepeatedError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingAnswersCompanion(')
          ..write('id: $id, ')
          ..write('pendingSubmissionId: $pendingSubmissionId, ')
          ..write('criteriaId: $criteriaId, ')
          ..write('value: $value, ')
          ..write('numericValue: $numericValue, ')
          ..write('note: $note, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('isRepeatedError: $isRepeatedError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingPhotosTable extends PendingPhotos
    with TableInfo<$PendingPhotosTable, PendingPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSubmissionIdMeta =
      const VerificationMeta('pendingSubmissionId');
  @override
  late final GeneratedColumn<String> pendingSubmissionId =
      GeneratedColumn<String>(
        'pending_submission_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pending_submissions (id)',
        ),
      );
  static const VerificationMeta _answerIdMeta = const VerificationMeta(
    'answerId',
  );
  @override
  late final GeneratedColumn<String> answerId = GeneratedColumn<String>(
    'answer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pendingSubmissionId,
    answerId,
    localPath,
    syncStatus,
    syncError,
    retryCount,
    nextRetryAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pending_submission_id')) {
      context.handle(
        _pendingSubmissionIdMeta,
        pendingSubmissionId.isAcceptableOrUnknown(
          data['pending_submission_id']!,
          _pendingSubmissionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pendingSubmissionIdMeta);
    }
    if (data.containsKey('answer_id')) {
      context.handle(
        _answerIdMeta,
        answerId.isAcceptableOrUnknown(data['answer_id']!, _answerIdMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pendingSubmissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_submission_id'],
      )!,
      answerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_id'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingPhotosTable createAlias(String alias) {
    return $PendingPhotosTable(attachedDatabase, alias);
  }
}

class PendingPhoto extends DataClass implements Insertable<PendingPhoto> {
  final String id;
  final String pendingSubmissionId;
  final String? answerId;
  final String localPath;
  final String syncStatus;
  final String? syncError;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  const PendingPhoto({
    required this.id,
    required this.pendingSubmissionId,
    this.answerId,
    required this.localPath,
    required this.syncStatus,
    this.syncError,
    required this.retryCount,
    this.nextRetryAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pending_submission_id'] = Variable<String>(pendingSubmissionId);
    if (!nullToAbsent || answerId != null) {
      map['answer_id'] = Variable<String>(answerId);
    }
    map['local_path'] = Variable<String>(localPath);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingPhotosCompanion toCompanion(bool nullToAbsent) {
    return PendingPhotosCompanion(
      id: Value(id),
      pendingSubmissionId: Value(pendingSubmissionId),
      answerId: answerId == null && nullToAbsent
          ? const Value.absent()
          : Value(answerId),
      localPath: Value(localPath),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
    );
  }

  factory PendingPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingPhoto(
      id: serializer.fromJson<String>(json['id']),
      pendingSubmissionId: serializer.fromJson<String>(
        json['pendingSubmissionId'],
      ),
      answerId: serializer.fromJson<String?>(json['answerId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pendingSubmissionId': serializer.toJson<String>(pendingSubmissionId),
      'answerId': serializer.toJson<String?>(answerId),
      'localPath': serializer.toJson<String>(localPath),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingPhoto copyWith({
    String? id,
    String? pendingSubmissionId,
    Value<String?> answerId = const Value.absent(),
    String? localPath,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? retryCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    DateTime? createdAt,
  }) => PendingPhoto(
    id: id ?? this.id,
    pendingSubmissionId: pendingSubmissionId ?? this.pendingSubmissionId,
    answerId: answerId.present ? answerId.value : this.answerId,
    localPath: localPath ?? this.localPath,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingPhoto copyWithCompanion(PendingPhotosCompanion data) {
    return PendingPhoto(
      id: data.id.present ? data.id.value : this.id,
      pendingSubmissionId: data.pendingSubmissionId.present
          ? data.pendingSubmissionId.value
          : this.pendingSubmissionId,
      answerId: data.answerId.present ? data.answerId.value : this.answerId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingPhoto(')
          ..write('id: $id, ')
          ..write('pendingSubmissionId: $pendingSubmissionId, ')
          ..write('answerId: $answerId, ')
          ..write('localPath: $localPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pendingSubmissionId,
    answerId,
    localPath,
    syncStatus,
    syncError,
    retryCount,
    nextRetryAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingPhoto &&
          other.id == this.id &&
          other.pendingSubmissionId == this.pendingSubmissionId &&
          other.answerId == this.answerId &&
          other.localPath == this.localPath &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt);
}

class PendingPhotosCompanion extends UpdateCompanion<PendingPhoto> {
  final Value<String> id;
  final Value<String> pendingSubmissionId;
  final Value<String?> answerId;
  final Value<String> localPath;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingPhotosCompanion({
    this.id = const Value.absent(),
    this.pendingSubmissionId = const Value.absent(),
    this.answerId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingPhotosCompanion.insert({
    required String id,
    required String pendingSubmissionId,
    this.answerId = const Value.absent(),
    required String localPath,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pendingSubmissionId = Value(pendingSubmissionId),
       localPath = Value(localPath),
       createdAt = Value(createdAt);
  static Insertable<PendingPhoto> custom({
    Expression<String>? id,
    Expression<String>? pendingSubmissionId,
    Expression<String>? answerId,
    Expression<String>? localPath,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pendingSubmissionId != null)
        'pending_submission_id': pendingSubmissionId,
      if (answerId != null) 'answer_id': answerId,
      if (localPath != null) 'local_path': localPath,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? pendingSubmissionId,
    Value<String?>? answerId,
    Value<String>? localPath,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? retryCount,
    Value<DateTime?>? nextRetryAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingPhotosCompanion(
      id: id ?? this.id,
      pendingSubmissionId: pendingSubmissionId ?? this.pendingSubmissionId,
      answerId: answerId ?? this.answerId,
      localPath: localPath ?? this.localPath,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pendingSubmissionId.present) {
      map['pending_submission_id'] = Variable<String>(
        pendingSubmissionId.value,
      );
    }
    if (answerId.present) {
      map['answer_id'] = Variable<String>(answerId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingPhotosCompanion(')
          ..write('id: $id, ')
          ..write('pendingSubmissionId: $pendingSubmissionId, ')
          ..write('answerId: $answerId, ')
          ..write('localPath: $localPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingActionPlanUpdatesTable extends PendingActionPlanUpdates
    with TableInfo<$PendingActionPlanUpdatesTable, PendingActionPlanUpdate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingActionPlanUpdatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionPlanIdMeta = const VerificationMeta(
    'actionPlanId',
  );
  @override
  late final GeneratedColumn<String> actionPlanId = GeneratedColumn<String>(
    'action_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctionPlanMeta = const VerificationMeta(
    'correctionPlan',
  );
  @override
  late final GeneratedColumn<String> correctionPlan = GeneratedColumn<String>(
    'correction_plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceNoteMeta = const VerificationMeta(
    'evidenceNote',
  );
  @override
  late final GeneratedColumn<String> evidenceNote = GeneratedColumn<String>(
    'evidence_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionPlanId,
    correctionPlan,
    evidenceNote,
    syncStatus,
    syncError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_action_plan_updates';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingActionPlanUpdate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action_plan_id')) {
      context.handle(
        _actionPlanIdMeta,
        actionPlanId.isAcceptableOrUnknown(
          data['action_plan_id']!,
          _actionPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actionPlanIdMeta);
    }
    if (data.containsKey('correction_plan')) {
      context.handle(
        _correctionPlanMeta,
        correctionPlan.isAcceptableOrUnknown(
          data['correction_plan']!,
          _correctionPlanMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctionPlanMeta);
    }
    if (data.containsKey('evidence_note')) {
      context.handle(
        _evidenceNoteMeta,
        evidenceNote.isAcceptableOrUnknown(
          data['evidence_note']!,
          _evidenceNoteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceNoteMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingActionPlanUpdate map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingActionPlanUpdate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actionPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_plan_id'],
      )!,
      correctionPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correction_plan'],
      )!,
      evidenceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_note'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingActionPlanUpdatesTable createAlias(String alias) {
    return $PendingActionPlanUpdatesTable(attachedDatabase, alias);
  }
}

class PendingActionPlanUpdate extends DataClass
    implements Insertable<PendingActionPlanUpdate> {
  final String id;
  final String actionPlanId;
  final String correctionPlan;
  final String evidenceNote;
  final String syncStatus;
  final String? syncError;
  final DateTime createdAt;
  const PendingActionPlanUpdate({
    required this.id,
    required this.actionPlanId,
    required this.correctionPlan,
    required this.evidenceNote,
    required this.syncStatus,
    this.syncError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['action_plan_id'] = Variable<String>(actionPlanId);
    map['correction_plan'] = Variable<String>(correctionPlan);
    map['evidence_note'] = Variable<String>(evidenceNote);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingActionPlanUpdatesCompanion toCompanion(bool nullToAbsent) {
    return PendingActionPlanUpdatesCompanion(
      id: Value(id),
      actionPlanId: Value(actionPlanId),
      correctionPlan: Value(correctionPlan),
      evidenceNote: Value(evidenceNote),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
    );
  }

  factory PendingActionPlanUpdate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingActionPlanUpdate(
      id: serializer.fromJson<String>(json['id']),
      actionPlanId: serializer.fromJson<String>(json['actionPlanId']),
      correctionPlan: serializer.fromJson<String>(json['correctionPlan']),
      evidenceNote: serializer.fromJson<String>(json['evidenceNote']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actionPlanId': serializer.toJson<String>(actionPlanId),
      'correctionPlan': serializer.toJson<String>(correctionPlan),
      'evidenceNote': serializer.toJson<String>(evidenceNote),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingActionPlanUpdate copyWith({
    String? id,
    String? actionPlanId,
    String? correctionPlan,
    String? evidenceNote,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
  }) => PendingActionPlanUpdate(
    id: id ?? this.id,
    actionPlanId: actionPlanId ?? this.actionPlanId,
    correctionPlan: correctionPlan ?? this.correctionPlan,
    evidenceNote: evidenceNote ?? this.evidenceNote,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingActionPlanUpdate copyWithCompanion(
    PendingActionPlanUpdatesCompanion data,
  ) {
    return PendingActionPlanUpdate(
      id: data.id.present ? data.id.value : this.id,
      actionPlanId: data.actionPlanId.present
          ? data.actionPlanId.value
          : this.actionPlanId,
      correctionPlan: data.correctionPlan.present
          ? data.correctionPlan.value
          : this.correctionPlan,
      evidenceNote: data.evidenceNote.present
          ? data.evidenceNote.value
          : this.evidenceNote,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionPlanUpdate(')
          ..write('id: $id, ')
          ..write('actionPlanId: $actionPlanId, ')
          ..write('correctionPlan: $correctionPlan, ')
          ..write('evidenceNote: $evidenceNote, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionPlanId,
    correctionPlan,
    evidenceNote,
    syncStatus,
    syncError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingActionPlanUpdate &&
          other.id == this.id &&
          other.actionPlanId == this.actionPlanId &&
          other.correctionPlan == this.correctionPlan &&
          other.evidenceNote == this.evidenceNote &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt);
}

class PendingActionPlanUpdatesCompanion
    extends UpdateCompanion<PendingActionPlanUpdate> {
  final Value<String> id;
  final Value<String> actionPlanId;
  final Value<String> correctionPlan;
  final Value<String> evidenceNote;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingActionPlanUpdatesCompanion({
    this.id = const Value.absent(),
    this.actionPlanId = const Value.absent(),
    this.correctionPlan = const Value.absent(),
    this.evidenceNote = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingActionPlanUpdatesCompanion.insert({
    required String id,
    required String actionPlanId,
    required String correctionPlan,
    required String evidenceNote,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actionPlanId = Value(actionPlanId),
       correctionPlan = Value(correctionPlan),
       evidenceNote = Value(evidenceNote),
       createdAt = Value(createdAt);
  static Insertable<PendingActionPlanUpdate> custom({
    Expression<String>? id,
    Expression<String>? actionPlanId,
    Expression<String>? correctionPlan,
    Expression<String>? evidenceNote,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionPlanId != null) 'action_plan_id': actionPlanId,
      if (correctionPlan != null) 'correction_plan': correctionPlan,
      if (evidenceNote != null) 'evidence_note': evidenceNote,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingActionPlanUpdatesCompanion copyWith({
    Value<String>? id,
    Value<String>? actionPlanId,
    Value<String>? correctionPlan,
    Value<String>? evidenceNote,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingActionPlanUpdatesCompanion(
      id: id ?? this.id,
      actionPlanId: actionPlanId ?? this.actionPlanId,
      correctionPlan: correctionPlan ?? this.correctionPlan,
      evidenceNote: evidenceNote ?? this.evidenceNote,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actionPlanId.present) {
      map['action_plan_id'] = Variable<String>(actionPlanId.value);
    }
    if (correctionPlan.present) {
      map['correction_plan'] = Variable<String>(correctionPlan.value);
    }
    if (evidenceNote.present) {
      map['evidence_note'] = Variable<String>(evidenceNote.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionPlanUpdatesCompanion(')
          ..write('id: $id, ')
          ..write('actionPlanId: $actionPlanId, ')
          ..write('correctionPlan: $correctionPlan, ')
          ..write('evidenceNote: $evidenceNote, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entityType, lastSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String entityType;
  final DateTime lastSyncAt;
  const SyncMetaData({required this.entityType, required this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      entityType: Value(entityType),
      lastSyncAt: Value(lastSyncAt),
    );
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      entityType: serializer.fromJson<String>(json['entityType']),
      lastSyncAt: serializer.fromJson<DateTime>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'lastSyncAt': serializer.toJson<DateTime>(lastSyncAt),
    };
  }

  SyncMetaData copyWith({String? entityType, DateTime? lastSyncAt}) =>
      SyncMetaData(
        entityType: entityType ?? this.entityType,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('entityType: $entityType, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.entityType == this.entityType &&
          other.lastSyncAt == this.lastSyncAt);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> entityType;
  final Value<DateTime> lastSyncAt;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.entityType = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String entityType,
    required DateTime lastSyncAt,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       lastSyncAt = Value(lastSyncAt);
  static Insertable<SyncMetaData> custom({
    Expression<String>? entityType,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? entityType,
    Value<DateTime>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      entityType: entityType ?? this.entityType,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('entityType: $entityType, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftAnswersTable extends DraftAnswers
    with TableInfo<$DraftAnswersTable, DraftAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _draftKeyMeta = const VerificationMeta(
    'draftKey',
  );
  @override
  late final GeneratedColumn<String> draftKey = GeneratedColumn<String>(
    'draft_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answersJsonMeta = const VerificationMeta(
    'answersJson',
  );
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
    'answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesJsonMeta = const VerificationMeta(
    'notesJson',
  );
  @override
  late final GeneratedColumn<String> notesJson = GeneratedColumn<String>(
    'notes_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    draftKey,
    answersJson,
    notesJson,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('draft_key')) {
      context.handle(
        _draftKeyMeta,
        draftKey.isAcceptableOrUnknown(data['draft_key']!, _draftKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_draftKeyMeta);
    }
    if (data.containsKey('answers_json')) {
      context.handle(
        _answersJsonMeta,
        answersJson.isAcceptableOrUnknown(
          data['answers_json']!,
          _answersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answersJsonMeta);
    }
    if (data.containsKey('notes_json')) {
      context.handle(
        _notesJsonMeta,
        notesJson.isAcceptableOrUnknown(data['notes_json']!, _notesJsonMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {draftKey};
  @override
  DraftAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftAnswer(
      draftKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_key'],
      )!,
      answersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers_json'],
      )!,
      notesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes_json'],
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $DraftAnswersTable createAlias(String alias) {
    return $DraftAnswersTable(attachedDatabase, alias);
  }
}

class DraftAnswer extends DataClass implements Insertable<DraftAnswer> {
  final String draftKey;
  final String answersJson;
  final String? notesJson;
  final DateTime savedAt;
  const DraftAnswer({
    required this.draftKey,
    required this.answersJson,
    this.notesJson,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['draft_key'] = Variable<String>(draftKey);
    map['answers_json'] = Variable<String>(answersJson);
    if (!nullToAbsent || notesJson != null) {
      map['notes_json'] = Variable<String>(notesJson);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  DraftAnswersCompanion toCompanion(bool nullToAbsent) {
    return DraftAnswersCompanion(
      draftKey: Value(draftKey),
      answersJson: Value(answersJson),
      notesJson: notesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(notesJson),
      savedAt: Value(savedAt),
    );
  }

  factory DraftAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftAnswer(
      draftKey: serializer.fromJson<String>(json['draftKey']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      notesJson: serializer.fromJson<String?>(json['notesJson']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'draftKey': serializer.toJson<String>(draftKey),
      'answersJson': serializer.toJson<String>(answersJson),
      'notesJson': serializer.toJson<String?>(notesJson),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  DraftAnswer copyWith({
    String? draftKey,
    String? answersJson,
    Value<String?> notesJson = const Value.absent(),
    DateTime? savedAt,
  }) => DraftAnswer(
    draftKey: draftKey ?? this.draftKey,
    answersJson: answersJson ?? this.answersJson,
    notesJson: notesJson.present ? notesJson.value : this.notesJson,
    savedAt: savedAt ?? this.savedAt,
  );
  DraftAnswer copyWithCompanion(DraftAnswersCompanion data) {
    return DraftAnswer(
      draftKey: data.draftKey.present ? data.draftKey.value : this.draftKey,
      answersJson: data.answersJson.present
          ? data.answersJson.value
          : this.answersJson,
      notesJson: data.notesJson.present ? data.notesJson.value : this.notesJson,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftAnswer(')
          ..write('draftKey: $draftKey, ')
          ..write('answersJson: $answersJson, ')
          ..write('notesJson: $notesJson, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(draftKey, answersJson, notesJson, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftAnswer &&
          other.draftKey == this.draftKey &&
          other.answersJson == this.answersJson &&
          other.notesJson == this.notesJson &&
          other.savedAt == this.savedAt);
}

class DraftAnswersCompanion extends UpdateCompanion<DraftAnswer> {
  final Value<String> draftKey;
  final Value<String> answersJson;
  final Value<String?> notesJson;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const DraftAnswersCompanion({
    this.draftKey = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.notesJson = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftAnswersCompanion.insert({
    required String draftKey,
    required String answersJson,
    this.notesJson = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : draftKey = Value(draftKey),
       answersJson = Value(answersJson),
       savedAt = Value(savedAt);
  static Insertable<DraftAnswer> custom({
    Expression<String>? draftKey,
    Expression<String>? answersJson,
    Expression<String>? notesJson,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (draftKey != null) 'draft_key': draftKey,
      if (answersJson != null) 'answers_json': answersJson,
      if (notesJson != null) 'notes_json': notesJson,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftAnswersCompanion copyWith({
    Value<String>? draftKey,
    Value<String>? answersJson,
    Value<String?>? notesJson,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return DraftAnswersCompanion(
      draftKey: draftKey ?? this.draftKey,
      answersJson: answersJson ?? this.answersJson,
      notesJson: notesJson ?? this.notesJson,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (draftKey.present) {
      map['draft_key'] = Variable<String>(draftKey.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (notesJson.present) {
      map['notes_json'] = Variable<String>(notesJson.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftAnswersCompanion(')
          ..write('draftKey: $draftKey, ')
          ..write('answersJson: $answersJson, ')
          ..write('notesJson: $notesJson, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedTemplatesTable cachedTemplates = $CachedTemplatesTable(
    this,
  );
  late final $CachedGroupsTable cachedGroups = $CachedGroupsTable(this);
  late final $CachedCriteriaTable cachedCriteria = $CachedCriteriaTable(this);
  late final $CachedStoresTable cachedStores = $CachedStoresTable(this);
  late final $CachedSubmissionsTable cachedSubmissions =
      $CachedSubmissionsTable(this);
  late final $CachedActionPlansTable cachedActionPlans =
      $CachedActionPlansTable(this);
  late final $CachedNotificationsTable cachedNotifications =
      $CachedNotificationsTable(this);
  late final $CachedPoliciesTable cachedPolicies = $CachedPoliciesTable(this);
  late final $PendingSubmissionsTable pendingSubmissions =
      $PendingSubmissionsTable(this);
  late final $PendingAnswersTable pendingAnswers = $PendingAnswersTable(this);
  late final $PendingPhotosTable pendingPhotos = $PendingPhotosTable(this);
  late final $PendingActionPlanUpdatesTable pendingActionPlanUpdates =
      $PendingActionPlanUpdatesTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $DraftAnswersTable draftAnswers = $DraftAnswersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedTemplates,
    cachedGroups,
    cachedCriteria,
    cachedStores,
    cachedSubmissions,
    cachedActionPlans,
    cachedNotifications,
    cachedPolicies,
    pendingSubmissions,
    pendingAnswers,
    pendingPhotos,
    pendingActionPlanUpdates,
    syncMeta,
    draftAnswers,
  ];
}

typedef $$CachedTemplatesTableCreateCompanionBuilder =
    CachedTemplatesCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      required String type,
      Value<int> version,
      Value<bool> isActive,
      Value<String?> scoringLogicConfig,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedTemplatesTableUpdateCompanionBuilder =
    CachedTemplatesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<String> type,
      Value<int> version,
      Value<bool> isActive,
      Value<String?> scoringLogicConfig,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CachedTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CachedTemplatesTable, CachedTemplate> {
  $$CachedTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CachedGroupsTable, List<CachedGroup>>
  _cachedGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedGroups,
    aliasName: $_aliasNameGenerator(
      db.cachedTemplates.id,
      db.cachedGroups.templateId,
    ),
  );

  $$CachedGroupsTableProcessedTableManager get cachedGroupsRefs {
    final manager = $$CachedGroupsTableTableManager(
      $_db,
      $_db.cachedGroups,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cachedGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTemplatesTable> {
  $$CachedTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringLogicConfig => $composableBuilder(
    column: $table.scoringLogicConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedGroupsRefs(
    Expression<bool> Function($$CachedGroupsTableFilterComposer f) f,
  ) {
    final $$CachedGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedGroups,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedGroupsTableFilterComposer(
            $db: $db,
            $table: $db.cachedGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTemplatesTable> {
  $$CachedTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringLogicConfig => $composableBuilder(
    column: $table.scoringLogicConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTemplatesTable> {
  $$CachedTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get scoringLogicConfig => $composableBuilder(
    column: $table.scoringLogicConfig,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> cachedGroupsRefs<T extends Object>(
    Expression<T> Function($$CachedGroupsTableAnnotationComposer a) f,
  ) {
    final $$CachedGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedGroups,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTemplatesTable,
          CachedTemplate,
          $$CachedTemplatesTableFilterComposer,
          $$CachedTemplatesTableOrderingComposer,
          $$CachedTemplatesTableAnnotationComposer,
          $$CachedTemplatesTableCreateCompanionBuilder,
          $$CachedTemplatesTableUpdateCompanionBuilder,
          (CachedTemplate, $$CachedTemplatesTableReferences),
          CachedTemplate,
          PrefetchHooks Function({bool cachedGroupsRefs})
        > {
  $$CachedTemplatesTableTableManager(
    _$AppDatabase db,
    $CachedTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> scoringLogicConfig = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTemplatesCompanion(
                id: id,
                title: title,
                description: description,
                type: type,
                version: version,
                isActive: isActive,
                scoringLogicConfig: scoringLogicConfig,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required String type,
                Value<int> version = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> scoringLogicConfig = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedTemplatesCompanion.insert(
                id: id,
                title: title,
                description: description,
                type: type,
                version: version,
                isActive: isActive,
                scoringLogicConfig: scoringLogicConfig,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cachedGroupsRefs) db.cachedGroups],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedGroupsRefs)
                    await $_getPrefetchedData<
                      CachedTemplate,
                      $CachedTemplatesTable,
                      CachedGroup
                    >(
                      currentTable: table,
                      referencedTable: $$CachedTemplatesTableReferences
                          ._cachedGroupsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedGroupsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTemplatesTable,
      CachedTemplate,
      $$CachedTemplatesTableFilterComposer,
      $$CachedTemplatesTableOrderingComposer,
      $$CachedTemplatesTableAnnotationComposer,
      $$CachedTemplatesTableCreateCompanionBuilder,
      $$CachedTemplatesTableUpdateCompanionBuilder,
      (CachedTemplate, $$CachedTemplatesTableReferences),
      CachedTemplate,
      PrefetchHooks Function({bool cachedGroupsRefs})
    >;
typedef $$CachedGroupsTableCreateCompanionBuilder =
    CachedGroupsCompanion Function({
      required String id,
      required String templateId,
      required String title,
      Value<String?> description,
      Value<double?> weight,
      Value<double?> maxDeductionPoints,
      Value<double?> minusPerFault,
      Value<int> orderIndex,
      Value<String?> parentId,
      Value<String?> metadata,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedGroupsTableUpdateCompanionBuilder =
    CachedGroupsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> title,
      Value<String?> description,
      Value<double?> weight,
      Value<double?> maxDeductionPoints,
      Value<double?> minusPerFault,
      Value<int> orderIndex,
      Value<String?> parentId,
      Value<String?> metadata,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CachedGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $CachedGroupsTable, CachedGroup> {
  $$CachedGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CachedTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.cachedTemplates.createAlias(
        $_aliasNameGenerator(db.cachedGroups.templateId, db.cachedTemplates.id),
      );

  $$CachedTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$CachedTemplatesTableTableManager(
      $_db,
      $_db.cachedTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CachedCriteriaTable, List<CachedCriteriaData>>
  _cachedCriteriaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedCriteria,
    aliasName: $_aliasNameGenerator(
      db.cachedGroups.id,
      db.cachedCriteria.groupId,
    ),
  );

  $$CachedCriteriaTableProcessedTableManager get cachedCriteriaRefs {
    final manager = $$CachedCriteriaTableTableManager(
      $_db,
      $_db.cachedCriteria,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cachedCriteriaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedGroupsTable> {
  $$CachedGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxDeductionPoints => $composableBuilder(
    column: $table.maxDeductionPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minusPerFault => $composableBuilder(
    column: $table.minusPerFault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedTemplatesTableFilterComposer get templateId {
    final $$CachedTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.cachedTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.cachedTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cachedCriteriaRefs(
    Expression<bool> Function($$CachedCriteriaTableFilterComposer f) f,
  ) {
    final $$CachedCriteriaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedCriteria,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedCriteriaTableFilterComposer(
            $db: $db,
            $table: $db.cachedCriteria,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedGroupsTable> {
  $$CachedGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxDeductionPoints => $composableBuilder(
    column: $table.maxDeductionPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minusPerFault => $composableBuilder(
    column: $table.minusPerFault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedTemplatesTableOrderingComposer get templateId {
    final $$CachedTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.cachedTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.cachedTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedGroupsTable> {
  $$CachedGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get maxDeductionPoints => $composableBuilder(
    column: $table.maxDeductionPoints,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minusPerFault => $composableBuilder(
    column: $table.minusPerFault,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CachedTemplatesTableAnnotationComposer get templateId {
    final $$CachedTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.cachedTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cachedCriteriaRefs<T extends Object>(
    Expression<T> Function($$CachedCriteriaTableAnnotationComposer a) f,
  ) {
    final $$CachedCriteriaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedCriteria,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedCriteriaTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedCriteria,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedGroupsTable,
          CachedGroup,
          $$CachedGroupsTableFilterComposer,
          $$CachedGroupsTableOrderingComposer,
          $$CachedGroupsTableAnnotationComposer,
          $$CachedGroupsTableCreateCompanionBuilder,
          $$CachedGroupsTableUpdateCompanionBuilder,
          (CachedGroup, $$CachedGroupsTableReferences),
          CachedGroup,
          PrefetchHooks Function({bool templateId, bool cachedCriteriaRefs})
        > {
  $$CachedGroupsTableTableManager(_$AppDatabase db, $CachedGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> maxDeductionPoints = const Value.absent(),
                Value<double?> minusPerFault = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedGroupsCompanion(
                id: id,
                templateId: templateId,
                title: title,
                description: description,
                weight: weight,
                maxDeductionPoints: maxDeductionPoints,
                minusPerFault: minusPerFault,
                orderIndex: orderIndex,
                parentId: parentId,
                metadata: metadata,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> maxDeductionPoints = const Value.absent(),
                Value<double?> minusPerFault = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedGroupsCompanion.insert(
                id: id,
                templateId: templateId,
                title: title,
                description: description,
                weight: weight,
                maxDeductionPoints: maxDeductionPoints,
                minusPerFault: minusPerFault,
                orderIndex: orderIndex,
                parentId: parentId,
                metadata: metadata,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateId = false, cachedCriteriaRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cachedCriteriaRefs) db.cachedCriteria,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.templateId,
                                    referencedTable:
                                        $$CachedGroupsTableReferences
                                            ._templateIdTable(db),
                                    referencedColumn:
                                        $$CachedGroupsTableReferences
                                            ._templateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cachedCriteriaRefs)
                        await $_getPrefetchedData<
                          CachedGroup,
                          $CachedGroupsTable,
                          CachedCriteriaData
                        >(
                          currentTable: table,
                          referencedTable: $$CachedGroupsTableReferences
                              ._cachedCriteriaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).cachedCriteriaRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CachedGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedGroupsTable,
      CachedGroup,
      $$CachedGroupsTableFilterComposer,
      $$CachedGroupsTableOrderingComposer,
      $$CachedGroupsTableAnnotationComposer,
      $$CachedGroupsTableCreateCompanionBuilder,
      $$CachedGroupsTableUpdateCompanionBuilder,
      (CachedGroup, $$CachedGroupsTableReferences),
      CachedGroup,
      PrefetchHooks Function({bool templateId, bool cachedCriteriaRefs})
    >;
typedef $$CachedCriteriaTableCreateCompanionBuilder =
    CachedCriteriaCompanion Function({
      required String id,
      required String groupId,
      required String label,
      Value<String?> description,
      required String inputType,
      Value<double?> pointsWeight,
      Value<bool> isCcp,
      Value<bool> isRisk,
      Value<int> orderIndex,
      Value<String?> metadata,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedCriteriaTableUpdateCompanionBuilder =
    CachedCriteriaCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> label,
      Value<String?> description,
      Value<String> inputType,
      Value<double?> pointsWeight,
      Value<bool> isCcp,
      Value<bool> isRisk,
      Value<int> orderIndex,
      Value<String?> metadata,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CachedCriteriaTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedCriteriaTable,
          CachedCriteriaData
        > {
  $$CachedCriteriaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedGroupsTable _groupIdTable(_$AppDatabase db) =>
      db.cachedGroups.createAlias(
        $_aliasNameGenerator(db.cachedCriteria.groupId, db.cachedGroups.id),
      );

  $$CachedGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$CachedGroupsTableTableManager(
      $_db,
      $_db.cachedGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedCriteriaTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCriteriaTable> {
  $$CachedCriteriaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputType => $composableBuilder(
    column: $table.inputType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pointsWeight => $composableBuilder(
    column: $table.pointsWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCcp => $composableBuilder(
    column: $table.isCcp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRisk => $composableBuilder(
    column: $table.isRisk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedGroupsTableFilterComposer get groupId {
    final $$CachedGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.cachedGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedGroupsTableFilterComposer(
            $db: $db,
            $table: $db.cachedGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedCriteriaTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCriteriaTable> {
  $$CachedCriteriaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputType => $composableBuilder(
    column: $table.inputType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pointsWeight => $composableBuilder(
    column: $table.pointsWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCcp => $composableBuilder(
    column: $table.isCcp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRisk => $composableBuilder(
    column: $table.isRisk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedGroupsTableOrderingComposer get groupId {
    final $$CachedGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.cachedGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedCriteriaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCriteriaTable> {
  $$CachedCriteriaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputType =>
      $composableBuilder(column: $table.inputType, builder: (column) => column);

  GeneratedColumn<double> get pointsWeight => $composableBuilder(
    column: $table.pointsWeight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCcp =>
      $composableBuilder(column: $table.isCcp, builder: (column) => column);

  GeneratedColumn<bool> get isRisk =>
      $composableBuilder(column: $table.isRisk, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CachedGroupsTableAnnotationComposer get groupId {
    final $$CachedGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.cachedGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedCriteriaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCriteriaTable,
          CachedCriteriaData,
          $$CachedCriteriaTableFilterComposer,
          $$CachedCriteriaTableOrderingComposer,
          $$CachedCriteriaTableAnnotationComposer,
          $$CachedCriteriaTableCreateCompanionBuilder,
          $$CachedCriteriaTableUpdateCompanionBuilder,
          (CachedCriteriaData, $$CachedCriteriaTableReferences),
          CachedCriteriaData,
          PrefetchHooks Function({bool groupId})
        > {
  $$CachedCriteriaTableTableManager(
    _$AppDatabase db,
    $CachedCriteriaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCriteriaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCriteriaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCriteriaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> inputType = const Value.absent(),
                Value<double?> pointsWeight = const Value.absent(),
                Value<bool> isCcp = const Value.absent(),
                Value<bool> isRisk = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCriteriaCompanion(
                id: id,
                groupId: groupId,
                label: label,
                description: description,
                inputType: inputType,
                pointsWeight: pointsWeight,
                isCcp: isCcp,
                isRisk: isRisk,
                orderIndex: orderIndex,
                metadata: metadata,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String label,
                Value<String?> description = const Value.absent(),
                required String inputType,
                Value<double?> pointsWeight = const Value.absent(),
                Value<bool> isCcp = const Value.absent(),
                Value<bool> isRisk = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCriteriaCompanion.insert(
                id: id,
                groupId: groupId,
                label: label,
                description: description,
                inputType: inputType,
                pointsWeight: pointsWeight,
                isCcp: isCcp,
                isRisk: isRisk,
                orderIndex: orderIndex,
                metadata: metadata,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedCriteriaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$CachedCriteriaTableReferences
                                    ._groupIdTable(db),
                                referencedColumn:
                                    $$CachedCriteriaTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedCriteriaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCriteriaTable,
      CachedCriteriaData,
      $$CachedCriteriaTableFilterComposer,
      $$CachedCriteriaTableOrderingComposer,
      $$CachedCriteriaTableAnnotationComposer,
      $$CachedCriteriaTableCreateCompanionBuilder,
      $$CachedCriteriaTableUpdateCompanionBuilder,
      (CachedCriteriaData, $$CachedCriteriaTableReferences),
      CachedCriteriaData,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$CachedStoresTableCreateCompanionBuilder =
    CachedStoresCompanion Function({
      required String id,
      required String name,
      Value<String?> address,
      Value<String?> areaId,
      Value<String?> areaName,
      Value<double?> gpsLat,
      Value<double?> gpsLng,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedStoresTableUpdateCompanionBuilder =
    CachedStoresCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> address,
      Value<String?> areaId,
      Value<String?> areaName,
      Value<double?> gpsLat,
      Value<double?> gpsLng,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedStoresTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStoresTable> {
  $$CachedStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLat => $composableBuilder(
    column: $table.gpsLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLng => $composableBuilder(
    column: $table.gpsLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStoresTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStoresTable> {
  $$CachedStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLat => $composableBuilder(
    column: $table.gpsLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLng => $composableBuilder(
    column: $table.gpsLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStoresTable> {
  $$CachedStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);

  GeneratedColumn<String> get areaName =>
      $composableBuilder(column: $table.areaName, builder: (column) => column);

  GeneratedColumn<double> get gpsLat =>
      $composableBuilder(column: $table.gpsLat, builder: (column) => column);

  GeneratedColumn<double> get gpsLng =>
      $composableBuilder(column: $table.gpsLng, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedStoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStoresTable,
          CachedStore,
          $$CachedStoresTableFilterComposer,
          $$CachedStoresTableOrderingComposer,
          $$CachedStoresTableAnnotationComposer,
          $$CachedStoresTableCreateCompanionBuilder,
          $$CachedStoresTableUpdateCompanionBuilder,
          (
            CachedStore,
            BaseReferences<_$AppDatabase, $CachedStoresTable, CachedStore>,
          ),
          CachedStore,
          PrefetchHooks Function()
        > {
  $$CachedStoresTableTableManager(_$AppDatabase db, $CachedStoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<double?> gpsLat = const Value.absent(),
                Value<double?> gpsLng = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStoresCompanion(
                id: id,
                name: name,
                address: address,
                areaId: areaId,
                areaName: areaName,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<String?> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<double?> gpsLat = const Value.absent(),
                Value<double?> gpsLng = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedStoresCompanion.insert(
                id: id,
                name: name,
                address: address,
                areaId: areaId,
                areaName: areaName,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStoresTable,
      CachedStore,
      $$CachedStoresTableFilterComposer,
      $$CachedStoresTableOrderingComposer,
      $$CachedStoresTableAnnotationComposer,
      $$CachedStoresTableCreateCompanionBuilder,
      $$CachedStoresTableUpdateCompanionBuilder,
      (
        CachedStore,
        BaseReferences<_$AppDatabase, $CachedStoresTable, CachedStore>,
      ),
      CachedStore,
      PrefetchHooks Function()
    >;
typedef $$CachedSubmissionsTableCreateCompanionBuilder =
    CachedSubmissionsCompanion Function({
      required String id,
      Value<String?> templateId,
      Value<String?> templateTitle,
      Value<String?> storeId,
      Value<String?> storeName,
      Value<String?> auditorId,
      Value<String?> auditorName,
      required String status,
      Value<double?> totalScore,
      Value<String?> sectionScores,
      Value<String?> notes,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<String?> reviewStatus,
      Value<String?> templateSnapshot,
      Value<int?> templateVersion,
      Value<String?> voidReason,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });
typedef $$CachedSubmissionsTableUpdateCompanionBuilder =
    CachedSubmissionsCompanion Function({
      Value<String> id,
      Value<String?> templateId,
      Value<String?> templateTitle,
      Value<String?> storeId,
      Value<String?> storeName,
      Value<String?> auditorId,
      Value<String?> auditorName,
      Value<String> status,
      Value<double?> totalScore,
      Value<String?> sectionScores,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<String?> reviewStatus,
      Value<String?> templateSnapshot,
      Value<int?> templateVersion,
      Value<String?> voidReason,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });

class $$CachedSubmissionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSubmissionsTable> {
  $$CachedSubmissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateTitle => $composableBuilder(
    column: $table.templateTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get auditorId => $composableBuilder(
    column: $table.auditorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get auditorName => $composableBuilder(
    column: $table.auditorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionScores => $composableBuilder(
    column: $table.sectionScores,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSubmissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSubmissionsTable> {
  $$CachedSubmissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateTitle => $composableBuilder(
    column: $table.templateTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get auditorId => $composableBuilder(
    column: $table.auditorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get auditorName => $composableBuilder(
    column: $table.auditorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionScores => $composableBuilder(
    column: $table.sectionScores,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSubmissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSubmissionsTable> {
  $$CachedSubmissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateTitle => $composableBuilder(
    column: $table.templateTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get auditorId =>
      $composableBuilder(column: $table.auditorId, builder: (column) => column);

  GeneratedColumn<String> get auditorName => $composableBuilder(
    column: $table.auditorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionScores => $composableBuilder(
    column: $table.sectionScores,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);
}

class $$CachedSubmissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSubmissionsTable,
          CachedSubmission,
          $$CachedSubmissionsTableFilterComposer,
          $$CachedSubmissionsTableOrderingComposer,
          $$CachedSubmissionsTableAnnotationComposer,
          $$CachedSubmissionsTableCreateCompanionBuilder,
          $$CachedSubmissionsTableUpdateCompanionBuilder,
          (
            CachedSubmission,
            BaseReferences<
              _$AppDatabase,
              $CachedSubmissionsTable,
              CachedSubmission
            >,
          ),
          CachedSubmission,
          PrefetchHooks Function()
        > {
  $$CachedSubmissionsTableTableManager(
    _$AppDatabase db,
    $CachedSubmissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSubmissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSubmissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSubmissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String?> templateTitle = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> auditorId = const Value.absent(),
                Value<String?> auditorName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> totalScore = const Value.absent(),
                Value<String?> sectionScores = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> reviewStatus = const Value.absent(),
                Value<String?> templateSnapshot = const Value.absent(),
                Value<int?> templateVersion = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSubmissionsCompanion(
                id: id,
                templateId: templateId,
                templateTitle: templateTitle,
                storeId: storeId,
                storeName: storeName,
                auditorId: auditorId,
                auditorName: auditorName,
                status: status,
                totalScore: totalScore,
                sectionScores: sectionScores,
                notes: notes,
                createdAt: createdAt,
                completedAt: completedAt,
                reviewStatus: reviewStatus,
                templateSnapshot: templateSnapshot,
                templateVersion: templateVersion,
                voidReason: voidReason,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> templateId = const Value.absent(),
                Value<String?> templateTitle = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> auditorId = const Value.absent(),
                Value<String?> auditorName = const Value.absent(),
                required String status,
                Value<double?> totalScore = const Value.absent(),
                Value<String?> sectionScores = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> reviewStatus = const Value.absent(),
                Value<String?> templateSnapshot = const Value.absent(),
                Value<int?> templateVersion = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSubmissionsCompanion.insert(
                id: id,
                templateId: templateId,
                templateTitle: templateTitle,
                storeId: storeId,
                storeName: storeName,
                auditorId: auditorId,
                auditorName: auditorName,
                status: status,
                totalScore: totalScore,
                sectionScores: sectionScores,
                notes: notes,
                createdAt: createdAt,
                completedAt: completedAt,
                reviewStatus: reviewStatus,
                templateSnapshot: templateSnapshot,
                templateVersion: templateVersion,
                voidReason: voidReason,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSubmissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSubmissionsTable,
      CachedSubmission,
      $$CachedSubmissionsTableFilterComposer,
      $$CachedSubmissionsTableOrderingComposer,
      $$CachedSubmissionsTableAnnotationComposer,
      $$CachedSubmissionsTableCreateCompanionBuilder,
      $$CachedSubmissionsTableUpdateCompanionBuilder,
      (
        CachedSubmission,
        BaseReferences<
          _$AppDatabase,
          $CachedSubmissionsTable,
          CachedSubmission
        >,
      ),
      CachedSubmission,
      PrefetchHooks Function()
    >;
typedef $$CachedActionPlansTableCreateCompanionBuilder =
    CachedActionPlansCompanion Function({
      required String id,
      Value<String?> submissionId,
      Value<String?> answerId,
      required String criteriaLabel,
      required String groupTitle,
      Value<String?> planDescription,
      Value<String?> rootCause,
      Value<String?> correctionPlan,
      Value<String?> evidencePhotoUrl,
      Value<String?> evidenceNote,
      Value<String> status,
      Value<DateTime?> deadline,
      Value<DateTime?> closedAt,
      Value<String?> storeName,
      Value<String?> storeId,
      Value<String?> storeManagerName,
      Value<String?> verifierName,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedActionPlansTableUpdateCompanionBuilder =
    CachedActionPlansCompanion Function({
      Value<String> id,
      Value<String?> submissionId,
      Value<String?> answerId,
      Value<String> criteriaLabel,
      Value<String> groupTitle,
      Value<String?> planDescription,
      Value<String?> rootCause,
      Value<String?> correctionPlan,
      Value<String?> evidencePhotoUrl,
      Value<String?> evidenceNote,
      Value<String> status,
      Value<DateTime?> deadline,
      Value<DateTime?> closedAt,
      Value<String?> storeName,
      Value<String?> storeId,
      Value<String?> storeManagerName,
      Value<String?> verifierName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedActionPlansTableFilterComposer
    extends Composer<_$AppDatabase, $CachedActionPlansTable> {
  $$CachedActionPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteriaLabel => $composableBuilder(
    column: $table.criteriaLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planDescription => $composableBuilder(
    column: $table.planDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootCause => $composableBuilder(
    column: $table.rootCause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctionPlan => $composableBuilder(
    column: $table.correctionPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidencePhotoUrl => $composableBuilder(
    column: $table.evidencePhotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceNote => $composableBuilder(
    column: $table.evidenceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeManagerName => $composableBuilder(
    column: $table.storeManagerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verifierName => $composableBuilder(
    column: $table.verifierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedActionPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedActionPlansTable> {
  $$CachedActionPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteriaLabel => $composableBuilder(
    column: $table.criteriaLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planDescription => $composableBuilder(
    column: $table.planDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootCause => $composableBuilder(
    column: $table.rootCause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctionPlan => $composableBuilder(
    column: $table.correctionPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidencePhotoUrl => $composableBuilder(
    column: $table.evidencePhotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceNote => $composableBuilder(
    column: $table.evidenceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeManagerName => $composableBuilder(
    column: $table.storeManagerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifierName => $composableBuilder(
    column: $table.verifierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedActionPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedActionPlansTable> {
  $$CachedActionPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerId =>
      $composableBuilder(column: $table.answerId, builder: (column) => column);

  GeneratedColumn<String> get criteriaLabel => $composableBuilder(
    column: $table.criteriaLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planDescription => $composableBuilder(
    column: $table.planDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rootCause =>
      $composableBuilder(column: $table.rootCause, builder: (column) => column);

  GeneratedColumn<String> get correctionPlan => $composableBuilder(
    column: $table.correctionPlan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidencePhotoUrl => $composableBuilder(
    column: $table.evidencePhotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidenceNote => $composableBuilder(
    column: $table.evidenceNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeManagerName => $composableBuilder(
    column: $table.storeManagerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verifierName => $composableBuilder(
    column: $table.verifierName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedActionPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedActionPlansTable,
          CachedActionPlan,
          $$CachedActionPlansTableFilterComposer,
          $$CachedActionPlansTableOrderingComposer,
          $$CachedActionPlansTableAnnotationComposer,
          $$CachedActionPlansTableCreateCompanionBuilder,
          $$CachedActionPlansTableUpdateCompanionBuilder,
          (
            CachedActionPlan,
            BaseReferences<
              _$AppDatabase,
              $CachedActionPlansTable,
              CachedActionPlan
            >,
          ),
          CachedActionPlan,
          PrefetchHooks Function()
        > {
  $$CachedActionPlansTableTableManager(
    _$AppDatabase db,
    $CachedActionPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedActionPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedActionPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedActionPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> submissionId = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                Value<String> criteriaLabel = const Value.absent(),
                Value<String> groupTitle = const Value.absent(),
                Value<String?> planDescription = const Value.absent(),
                Value<String?> rootCause = const Value.absent(),
                Value<String?> correctionPlan = const Value.absent(),
                Value<String?> evidencePhotoUrl = const Value.absent(),
                Value<String?> evidenceNote = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> storeManagerName = const Value.absent(),
                Value<String?> verifierName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedActionPlansCompanion(
                id: id,
                submissionId: submissionId,
                answerId: answerId,
                criteriaLabel: criteriaLabel,
                groupTitle: groupTitle,
                planDescription: planDescription,
                rootCause: rootCause,
                correctionPlan: correctionPlan,
                evidencePhotoUrl: evidencePhotoUrl,
                evidenceNote: evidenceNote,
                status: status,
                deadline: deadline,
                closedAt: closedAt,
                storeName: storeName,
                storeId: storeId,
                storeManagerName: storeManagerName,
                verifierName: verifierName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> submissionId = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                required String criteriaLabel,
                required String groupTitle,
                Value<String?> planDescription = const Value.absent(),
                Value<String?> rootCause = const Value.absent(),
                Value<String?> correctionPlan = const Value.absent(),
                Value<String?> evidencePhotoUrl = const Value.absent(),
                Value<String?> evidenceNote = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> storeManagerName = const Value.absent(),
                Value<String?> verifierName = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedActionPlansCompanion.insert(
                id: id,
                submissionId: submissionId,
                answerId: answerId,
                criteriaLabel: criteriaLabel,
                groupTitle: groupTitle,
                planDescription: planDescription,
                rootCause: rootCause,
                correctionPlan: correctionPlan,
                evidencePhotoUrl: evidencePhotoUrl,
                evidenceNote: evidenceNote,
                status: status,
                deadline: deadline,
                closedAt: closedAt,
                storeName: storeName,
                storeId: storeId,
                storeManagerName: storeManagerName,
                verifierName: verifierName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedActionPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedActionPlansTable,
      CachedActionPlan,
      $$CachedActionPlansTableFilterComposer,
      $$CachedActionPlansTableOrderingComposer,
      $$CachedActionPlansTableAnnotationComposer,
      $$CachedActionPlansTableCreateCompanionBuilder,
      $$CachedActionPlansTableUpdateCompanionBuilder,
      (
        CachedActionPlan,
        BaseReferences<
          _$AppDatabase,
          $CachedActionPlansTable,
          CachedActionPlan
        >,
      ),
      CachedActionPlan,
      PrefetchHooks Function()
    >;
typedef $$CachedNotificationsTableCreateCompanionBuilder =
    CachedNotificationsCompanion Function({
      required String id,
      required String userId,
      required String type,
      required String title,
      Value<String?> message,
      Value<DateTime?> readAt,
      Value<String?> actionUrl,
      Value<String?> metadata,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CachedNotificationsTableUpdateCompanionBuilder =
    CachedNotificationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> type,
      Value<String> title,
      Value<String?> message,
      Value<DateTime?> readAt,
      Value<String?> actionUrl,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CachedNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionUrl => $composableBuilder(
    column: $table.actionUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionUrl => $composableBuilder(
    column: $table.actionUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<String> get actionUrl =>
      $composableBuilder(column: $table.actionUrl, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedNotificationsTable,
          CachedNotification,
          $$CachedNotificationsTableFilterComposer,
          $$CachedNotificationsTableOrderingComposer,
          $$CachedNotificationsTableAnnotationComposer,
          $$CachedNotificationsTableCreateCompanionBuilder,
          $$CachedNotificationsTableUpdateCompanionBuilder,
          (
            CachedNotification,
            BaseReferences<
              _$AppDatabase,
              $CachedNotificationsTable,
              CachedNotification
            >,
          ),
          CachedNotification,
          PrefetchHooks Function()
        > {
  $$CachedNotificationsTableTableManager(
    _$AppDatabase db,
    $CachedNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> actionUrl = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedNotificationsCompanion(
                id: id,
                userId: userId,
                type: type,
                title: title,
                message: message,
                readAt: readAt,
                actionUrl: actionUrl,
                metadata: metadata,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String type,
                required String title,
                Value<String?> message = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> actionUrl = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedNotificationsCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                title: title,
                message: message,
                readAt: readAt,
                actionUrl: actionUrl,
                metadata: metadata,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedNotificationsTable,
      CachedNotification,
      $$CachedNotificationsTableFilterComposer,
      $$CachedNotificationsTableOrderingComposer,
      $$CachedNotificationsTableAnnotationComposer,
      $$CachedNotificationsTableCreateCompanionBuilder,
      $$CachedNotificationsTableUpdateCompanionBuilder,
      (
        CachedNotification,
        BaseReferences<
          _$AppDatabase,
          $CachedNotificationsTable,
          CachedNotification
        >,
      ),
      CachedNotification,
      PrefetchHooks Function()
    >;
typedef $$CachedPoliciesTableCreateCompanionBuilder =
    CachedPoliciesCompanion Function({
      required String capability,
      Value<int> rowid,
    });
typedef $$CachedPoliciesTableUpdateCompanionBuilder =
    CachedPoliciesCompanion Function({
      Value<String> capability,
      Value<int> rowid,
    });

class $$CachedPoliciesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPoliciesTable> {
  $$CachedPoliciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPoliciesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPoliciesTable> {
  $$CachedPoliciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPoliciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPoliciesTable> {
  $$CachedPoliciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => column,
  );
}

class $$CachedPoliciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPoliciesTable,
          CachedPolicy,
          $$CachedPoliciesTableFilterComposer,
          $$CachedPoliciesTableOrderingComposer,
          $$CachedPoliciesTableAnnotationComposer,
          $$CachedPoliciesTableCreateCompanionBuilder,
          $$CachedPoliciesTableUpdateCompanionBuilder,
          (
            CachedPolicy,
            BaseReferences<_$AppDatabase, $CachedPoliciesTable, CachedPolicy>,
          ),
          CachedPolicy,
          PrefetchHooks Function()
        > {
  $$CachedPoliciesTableTableManager(
    _$AppDatabase db,
    $CachedPoliciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPoliciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPoliciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPoliciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> capability = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  CachedPoliciesCompanion(capability: capability, rowid: rowid),
          createCompanionCallback:
              ({
                required String capability,
                Value<int> rowid = const Value.absent(),
              }) => CachedPoliciesCompanion.insert(
                capability: capability,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPoliciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPoliciesTable,
      CachedPolicy,
      $$CachedPoliciesTableFilterComposer,
      $$CachedPoliciesTableOrderingComposer,
      $$CachedPoliciesTableAnnotationComposer,
      $$CachedPoliciesTableCreateCompanionBuilder,
      $$CachedPoliciesTableUpdateCompanionBuilder,
      (
        CachedPolicy,
        BaseReferences<_$AppDatabase, $CachedPoliciesTable, CachedPolicy>,
      ),
      CachedPolicy,
      PrefetchHooks Function()
    >;
typedef $$PendingSubmissionsTableCreateCompanionBuilder =
    PendingSubmissionsCompanion Function({
      required String id,
      required String templateId,
      required String storeId,
      required double clientScore,
      Value<String?> sectionScores,
      Value<String?> notes,
      Value<double?> gpsLat,
      Value<double?> gpsLng,
      required String idempotencyKey,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      required DateTime createdAt,
      Value<String?> targetSubmissionId,
      Value<int> rowid,
    });
typedef $$PendingSubmissionsTableUpdateCompanionBuilder =
    PendingSubmissionsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> storeId,
      Value<double> clientScore,
      Value<String?> sectionScores,
      Value<String?> notes,
      Value<double?> gpsLat,
      Value<double?> gpsLng,
      Value<String> idempotencyKey,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<DateTime> createdAt,
      Value<String?> targetSubmissionId,
      Value<int> rowid,
    });

final class $$PendingSubmissionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PendingSubmissionsTable,
          PendingSubmission
        > {
  $$PendingSubmissionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PendingAnswersTable, List<PendingAnswer>>
  _pendingAnswersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingAnswers,
    aliasName: $_aliasNameGenerator(
      db.pendingSubmissions.id,
      db.pendingAnswers.pendingSubmissionId,
    ),
  );

  $$PendingAnswersTableProcessedTableManager get pendingAnswersRefs {
    final manager = $$PendingAnswersTableTableManager($_db, $_db.pendingAnswers)
        .filter(
          (f) =>
              f.pendingSubmissionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_pendingAnswersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingPhotosTable, List<PendingPhoto>>
  _pendingPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingPhotos,
    aliasName: $_aliasNameGenerator(
      db.pendingSubmissions.id,
      db.pendingPhotos.pendingSubmissionId,
    ),
  );

  $$PendingPhotosTableProcessedTableManager get pendingPhotosRefs {
    final manager = $$PendingPhotosTableTableManager($_db, $_db.pendingPhotos)
        .filter(
          (f) =>
              f.pendingSubmissionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_pendingPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PendingSubmissionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSubmissionsTable> {
  $$PendingSubmissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get clientScore => $composableBuilder(
    column: $table.clientScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionScores => $composableBuilder(
    column: $table.sectionScores,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLat => $composableBuilder(
    column: $table.gpsLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLng => $composableBuilder(
    column: $table.gpsLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetSubmissionId => $composableBuilder(
    column: $table.targetSubmissionId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pendingAnswersRefs(
    Expression<bool> Function($$PendingAnswersTableFilterComposer f) f,
  ) {
    final $$PendingAnswersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingAnswers,
      getReferencedColumn: (t) => t.pendingSubmissionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingAnswersTableFilterComposer(
            $db: $db,
            $table: $db.pendingAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pendingPhotosRefs(
    Expression<bool> Function($$PendingPhotosTableFilterComposer f) f,
  ) {
    final $$PendingPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingPhotos,
      getReferencedColumn: (t) => t.pendingSubmissionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingPhotosTableFilterComposer(
            $db: $db,
            $table: $db.pendingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PendingSubmissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSubmissionsTable> {
  $$PendingSubmissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get clientScore => $composableBuilder(
    column: $table.clientScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionScores => $composableBuilder(
    column: $table.sectionScores,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLat => $composableBuilder(
    column: $table.gpsLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLng => $composableBuilder(
    column: $table.gpsLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetSubmissionId => $composableBuilder(
    column: $table.targetSubmissionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSubmissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSubmissionsTable> {
  $$PendingSubmissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<double> get clientScore => $composableBuilder(
    column: $table.clientScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionScores => $composableBuilder(
    column: $table.sectionScores,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get gpsLat =>
      $composableBuilder(column: $table.gpsLat, builder: (column) => column);

  GeneratedColumn<double> get gpsLng =>
      $composableBuilder(column: $table.gpsLng, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get targetSubmissionId => $composableBuilder(
    column: $table.targetSubmissionId,
    builder: (column) => column,
  );

  Expression<T> pendingAnswersRefs<T extends Object>(
    Expression<T> Function($$PendingAnswersTableAnnotationComposer a) f,
  ) {
    final $$PendingAnswersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingAnswers,
      getReferencedColumn: (t) => t.pendingSubmissionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingAnswersTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pendingPhotosRefs<T extends Object>(
    Expression<T> Function($$PendingPhotosTableAnnotationComposer a) f,
  ) {
    final $$PendingPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingPhotos,
      getReferencedColumn: (t) => t.pendingSubmissionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PendingSubmissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSubmissionsTable,
          PendingSubmission,
          $$PendingSubmissionsTableFilterComposer,
          $$PendingSubmissionsTableOrderingComposer,
          $$PendingSubmissionsTableAnnotationComposer,
          $$PendingSubmissionsTableCreateCompanionBuilder,
          $$PendingSubmissionsTableUpdateCompanionBuilder,
          (PendingSubmission, $$PendingSubmissionsTableReferences),
          PendingSubmission,
          PrefetchHooks Function({
            bool pendingAnswersRefs,
            bool pendingPhotosRefs,
          })
        > {
  $$PendingSubmissionsTableTableManager(
    _$AppDatabase db,
    $PendingSubmissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSubmissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSubmissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSubmissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<double> clientScore = const Value.absent(),
                Value<String?> sectionScores = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double?> gpsLat = const Value.absent(),
                Value<double?> gpsLng = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> targetSubmissionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSubmissionsCompanion(
                id: id,
                templateId: templateId,
                storeId: storeId,
                clientScore: clientScore,
                sectionScores: sectionScores,
                notes: notes,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                syncError: syncError,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                targetSubmissionId: targetSubmissionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String storeId,
                required double clientScore,
                Value<String?> sectionScores = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double?> gpsLat = const Value.absent(),
                Value<double?> gpsLng = const Value.absent(),
                required String idempotencyKey,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                required DateTime createdAt,
                Value<String?> targetSubmissionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSubmissionsCompanion.insert(
                id: id,
                templateId: templateId,
                storeId: storeId,
                clientScore: clientScore,
                sectionScores: sectionScores,
                notes: notes,
                gpsLat: gpsLat,
                gpsLng: gpsLng,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                syncError: syncError,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                targetSubmissionId: targetSubmissionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingSubmissionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({pendingAnswersRefs = false, pendingPhotosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pendingAnswersRefs) db.pendingAnswers,
                    if (pendingPhotosRefs) db.pendingPhotos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pendingAnswersRefs)
                        await $_getPrefetchedData<
                          PendingSubmission,
                          $PendingSubmissionsTable,
                          PendingAnswer
                        >(
                          currentTable: table,
                          referencedTable: $$PendingSubmissionsTableReferences
                              ._pendingAnswersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PendingSubmissionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingAnswersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pendingSubmissionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pendingPhotosRefs)
                        await $_getPrefetchedData<
                          PendingSubmission,
                          $PendingSubmissionsTable,
                          PendingPhoto
                        >(
                          currentTable: table,
                          referencedTable: $$PendingSubmissionsTableReferences
                              ._pendingPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PendingSubmissionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pendingSubmissionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PendingSubmissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSubmissionsTable,
      PendingSubmission,
      $$PendingSubmissionsTableFilterComposer,
      $$PendingSubmissionsTableOrderingComposer,
      $$PendingSubmissionsTableAnnotationComposer,
      $$PendingSubmissionsTableCreateCompanionBuilder,
      $$PendingSubmissionsTableUpdateCompanionBuilder,
      (PendingSubmission, $$PendingSubmissionsTableReferences),
      PendingSubmission,
      PrefetchHooks Function({bool pendingAnswersRefs, bool pendingPhotosRefs})
    >;
typedef $$PendingAnswersTableCreateCompanionBuilder =
    PendingAnswersCompanion Function({
      required String id,
      required String pendingSubmissionId,
      required String criteriaId,
      Value<String?> value,
      Value<double?> numericValue,
      Value<String?> note,
      Value<String?> photoUrl,
      Value<bool> isRepeatedError,
      Value<int> rowid,
    });
typedef $$PendingAnswersTableUpdateCompanionBuilder =
    PendingAnswersCompanion Function({
      Value<String> id,
      Value<String> pendingSubmissionId,
      Value<String> criteriaId,
      Value<String?> value,
      Value<double?> numericValue,
      Value<String?> note,
      Value<String?> photoUrl,
      Value<bool> isRepeatedError,
      Value<int> rowid,
    });

final class $$PendingAnswersTableReferences
    extends BaseReferences<_$AppDatabase, $PendingAnswersTable, PendingAnswer> {
  $$PendingAnswersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PendingSubmissionsTable _pendingSubmissionIdTable(_$AppDatabase db) =>
      db.pendingSubmissions.createAlias(
        $_aliasNameGenerator(
          db.pendingAnswers.pendingSubmissionId,
          db.pendingSubmissions.id,
        ),
      );

  $$PendingSubmissionsTableProcessedTableManager get pendingSubmissionId {
    final $_column = $_itemColumn<String>('pending_submission_id')!;

    final manager = $$PendingSubmissionsTableTableManager(
      $_db,
      $_db.pendingSubmissions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pendingSubmissionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $PendingAnswersTable> {
  $$PendingAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteriaId => $composableBuilder(
    column: $table.criteriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get numericValue => $composableBuilder(
    column: $table.numericValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRepeatedError => $composableBuilder(
    column: $table.isRepeatedError,
    builder: (column) => ColumnFilters(column),
  );

  $$PendingSubmissionsTableFilterComposer get pendingSubmissionId {
    final $$PendingSubmissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSubmissionId,
      referencedTable: $db.pendingSubmissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSubmissionsTableFilterComposer(
            $db: $db,
            $table: $db.pendingSubmissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingAnswersTable> {
  $$PendingAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteriaId => $composableBuilder(
    column: $table.criteriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get numericValue => $composableBuilder(
    column: $table.numericValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRepeatedError => $composableBuilder(
    column: $table.isRepeatedError,
    builder: (column) => ColumnOrderings(column),
  );

  $$PendingSubmissionsTableOrderingComposer get pendingSubmissionId {
    final $$PendingSubmissionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSubmissionId,
      referencedTable: $db.pendingSubmissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSubmissionsTableOrderingComposer(
            $db: $db,
            $table: $db.pendingSubmissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingAnswersTable> {
  $$PendingAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get criteriaId => $composableBuilder(
    column: $table.criteriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get numericValue => $composableBuilder(
    column: $table.numericValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<bool> get isRepeatedError => $composableBuilder(
    column: $table.isRepeatedError,
    builder: (column) => column,
  );

  $$PendingSubmissionsTableAnnotationComposer get pendingSubmissionId {
    final $$PendingSubmissionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.pendingSubmissionId,
          referencedTable: $db.pendingSubmissions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PendingSubmissionsTableAnnotationComposer(
                $db: $db,
                $table: $db.pendingSubmissions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PendingAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingAnswersTable,
          PendingAnswer,
          $$PendingAnswersTableFilterComposer,
          $$PendingAnswersTableOrderingComposer,
          $$PendingAnswersTableAnnotationComposer,
          $$PendingAnswersTableCreateCompanionBuilder,
          $$PendingAnswersTableUpdateCompanionBuilder,
          (PendingAnswer, $$PendingAnswersTableReferences),
          PendingAnswer,
          PrefetchHooks Function({bool pendingSubmissionId})
        > {
  $$PendingAnswersTableTableManager(
    _$AppDatabase db,
    $PendingAnswersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pendingSubmissionId = const Value.absent(),
                Value<String> criteriaId = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<double?> numericValue = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<bool> isRepeatedError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingAnswersCompanion(
                id: id,
                pendingSubmissionId: pendingSubmissionId,
                criteriaId: criteriaId,
                value: value,
                numericValue: numericValue,
                note: note,
                photoUrl: photoUrl,
                isRepeatedError: isRepeatedError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pendingSubmissionId,
                required String criteriaId,
                Value<String?> value = const Value.absent(),
                Value<double?> numericValue = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<bool> isRepeatedError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingAnswersCompanion.insert(
                id: id,
                pendingSubmissionId: pendingSubmissionId,
                criteriaId: criteriaId,
                value: value,
                numericValue: numericValue,
                note: note,
                photoUrl: photoUrl,
                isRepeatedError: isRepeatedError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingAnswersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pendingSubmissionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pendingSubmissionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pendingSubmissionId,
                                referencedTable: $$PendingAnswersTableReferences
                                    ._pendingSubmissionIdTable(db),
                                referencedColumn:
                                    $$PendingAnswersTableReferences
                                        ._pendingSubmissionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingAnswersTable,
      PendingAnswer,
      $$PendingAnswersTableFilterComposer,
      $$PendingAnswersTableOrderingComposer,
      $$PendingAnswersTableAnnotationComposer,
      $$PendingAnswersTableCreateCompanionBuilder,
      $$PendingAnswersTableUpdateCompanionBuilder,
      (PendingAnswer, $$PendingAnswersTableReferences),
      PendingAnswer,
      PrefetchHooks Function({bool pendingSubmissionId})
    >;
typedef $$PendingPhotosTableCreateCompanionBuilder =
    PendingPhotosCompanion Function({
      required String id,
      required String pendingSubmissionId,
      Value<String?> answerId,
      required String localPath,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingPhotosTableUpdateCompanionBuilder =
    PendingPhotosCompanion Function({
      Value<String> id,
      Value<String> pendingSubmissionId,
      Value<String?> answerId,
      Value<String> localPath,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PendingPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PendingPhotosTable, PendingPhoto> {
  $$PendingPhotosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PendingSubmissionsTable _pendingSubmissionIdTable(_$AppDatabase db) =>
      db.pendingSubmissions.createAlias(
        $_aliasNameGenerator(
          db.pendingPhotos.pendingSubmissionId,
          db.pendingSubmissions.id,
        ),
      );

  $$PendingSubmissionsTableProcessedTableManager get pendingSubmissionId {
    final $_column = $_itemColumn<String>('pending_submission_id')!;

    final manager = $$PendingSubmissionsTableTableManager(
      $_db,
      $_db.pendingSubmissions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pendingSubmissionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PendingPhotosTable> {
  $$PendingPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PendingSubmissionsTableFilterComposer get pendingSubmissionId {
    final $$PendingSubmissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSubmissionId,
      referencedTable: $db.pendingSubmissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSubmissionsTableFilterComposer(
            $db: $db,
            $table: $db.pendingSubmissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingPhotosTable> {
  $$PendingPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PendingSubmissionsTableOrderingComposer get pendingSubmissionId {
    final $$PendingSubmissionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSubmissionId,
      referencedTable: $db.pendingSubmissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSubmissionsTableOrderingComposer(
            $db: $db,
            $table: $db.pendingSubmissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingPhotosTable> {
  $$PendingPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get answerId =>
      $composableBuilder(column: $table.answerId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PendingSubmissionsTableAnnotationComposer get pendingSubmissionId {
    final $$PendingSubmissionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.pendingSubmissionId,
          referencedTable: $db.pendingSubmissions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PendingSubmissionsTableAnnotationComposer(
                $db: $db,
                $table: $db.pendingSubmissions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PendingPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingPhotosTable,
          PendingPhoto,
          $$PendingPhotosTableFilterComposer,
          $$PendingPhotosTableOrderingComposer,
          $$PendingPhotosTableAnnotationComposer,
          $$PendingPhotosTableCreateCompanionBuilder,
          $$PendingPhotosTableUpdateCompanionBuilder,
          (PendingPhoto, $$PendingPhotosTableReferences),
          PendingPhoto,
          PrefetchHooks Function({bool pendingSubmissionId})
        > {
  $$PendingPhotosTableTableManager(_$AppDatabase db, $PendingPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pendingSubmissionId = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingPhotosCompanion(
                id: id,
                pendingSubmissionId: pendingSubmissionId,
                answerId: answerId,
                localPath: localPath,
                syncStatus: syncStatus,
                syncError: syncError,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pendingSubmissionId,
                Value<String?> answerId = const Value.absent(),
                required String localPath,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingPhotosCompanion.insert(
                id: id,
                pendingSubmissionId: pendingSubmissionId,
                answerId: answerId,
                localPath: localPath,
                syncStatus: syncStatus,
                syncError: syncError,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pendingSubmissionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pendingSubmissionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pendingSubmissionId,
                                referencedTable: $$PendingPhotosTableReferences
                                    ._pendingSubmissionIdTable(db),
                                referencedColumn: $$PendingPhotosTableReferences
                                    ._pendingSubmissionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingPhotosTable,
      PendingPhoto,
      $$PendingPhotosTableFilterComposer,
      $$PendingPhotosTableOrderingComposer,
      $$PendingPhotosTableAnnotationComposer,
      $$PendingPhotosTableCreateCompanionBuilder,
      $$PendingPhotosTableUpdateCompanionBuilder,
      (PendingPhoto, $$PendingPhotosTableReferences),
      PendingPhoto,
      PrefetchHooks Function({bool pendingSubmissionId})
    >;
typedef $$PendingActionPlanUpdatesTableCreateCompanionBuilder =
    PendingActionPlanUpdatesCompanion Function({
      required String id,
      required String actionPlanId,
      required String correctionPlan,
      required String evidenceNote,
      Value<String> syncStatus,
      Value<String?> syncError,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingActionPlanUpdatesTableUpdateCompanionBuilder =
    PendingActionPlanUpdatesCompanion Function({
      Value<String> id,
      Value<String> actionPlanId,
      Value<String> correctionPlan,
      Value<String> evidenceNote,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingActionPlanUpdatesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingActionPlanUpdatesTable> {
  $$PendingActionPlanUpdatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionPlanId => $composableBuilder(
    column: $table.actionPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctionPlan => $composableBuilder(
    column: $table.correctionPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceNote => $composableBuilder(
    column: $table.evidenceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingActionPlanUpdatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingActionPlanUpdatesTable> {
  $$PendingActionPlanUpdatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionPlanId => $composableBuilder(
    column: $table.actionPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctionPlan => $composableBuilder(
    column: $table.correctionPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceNote => $composableBuilder(
    column: $table.evidenceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingActionPlanUpdatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingActionPlanUpdatesTable> {
  $$PendingActionPlanUpdatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionPlanId => $composableBuilder(
    column: $table.actionPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctionPlan => $composableBuilder(
    column: $table.correctionPlan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidenceNote => $composableBuilder(
    column: $table.evidenceNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingActionPlanUpdatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingActionPlanUpdatesTable,
          PendingActionPlanUpdate,
          $$PendingActionPlanUpdatesTableFilterComposer,
          $$PendingActionPlanUpdatesTableOrderingComposer,
          $$PendingActionPlanUpdatesTableAnnotationComposer,
          $$PendingActionPlanUpdatesTableCreateCompanionBuilder,
          $$PendingActionPlanUpdatesTableUpdateCompanionBuilder,
          (
            PendingActionPlanUpdate,
            BaseReferences<
              _$AppDatabase,
              $PendingActionPlanUpdatesTable,
              PendingActionPlanUpdate
            >,
          ),
          PendingActionPlanUpdate,
          PrefetchHooks Function()
        > {
  $$PendingActionPlanUpdatesTableTableManager(
    _$AppDatabase db,
    $PendingActionPlanUpdatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingActionPlanUpdatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingActionPlanUpdatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingActionPlanUpdatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> actionPlanId = const Value.absent(),
                Value<String> correctionPlan = const Value.absent(),
                Value<String> evidenceNote = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingActionPlanUpdatesCompanion(
                id: id,
                actionPlanId: actionPlanId,
                correctionPlan: correctionPlan,
                evidenceNote: evidenceNote,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String actionPlanId,
                required String correctionPlan,
                required String evidenceNote,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingActionPlanUpdatesCompanion.insert(
                id: id,
                actionPlanId: actionPlanId,
                correctionPlan: correctionPlan,
                evidenceNote: evidenceNote,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingActionPlanUpdatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingActionPlanUpdatesTable,
      PendingActionPlanUpdate,
      $$PendingActionPlanUpdatesTableFilterComposer,
      $$PendingActionPlanUpdatesTableOrderingComposer,
      $$PendingActionPlanUpdatesTableAnnotationComposer,
      $$PendingActionPlanUpdatesTableCreateCompanionBuilder,
      $$PendingActionPlanUpdatesTableUpdateCompanionBuilder,
      (
        PendingActionPlanUpdate,
        BaseReferences<
          _$AppDatabase,
          $PendingActionPlanUpdatesTable,
          PendingActionPlanUpdate
        >,
      ),
      PendingActionPlanUpdate,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String entityType,
      required DateTime lastSyncAt,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> entityType,
      Value<DateTime> lastSyncAt,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<DateTime> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                entityType: entityType,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required DateTime lastSyncAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                entityType: entityType,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;
typedef $$DraftAnswersTableCreateCompanionBuilder =
    DraftAnswersCompanion Function({
      required String draftKey,
      required String answersJson,
      Value<String?> notesJson,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$DraftAnswersTableUpdateCompanionBuilder =
    DraftAnswersCompanion Function({
      Value<String> draftKey,
      Value<String> answersJson,
      Value<String?> notesJson,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$DraftAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $DraftAnswersTable> {
  $$DraftAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get draftKey => $composableBuilder(
    column: $table.draftKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notesJson => $composableBuilder(
    column: $table.notesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftAnswersTable> {
  $$DraftAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get draftKey => $composableBuilder(
    column: $table.draftKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notesJson => $composableBuilder(
    column: $table.notesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftAnswersTable> {
  $$DraftAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get draftKey =>
      $composableBuilder(column: $table.draftKey, builder: (column) => column);

  GeneratedColumn<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notesJson =>
      $composableBuilder(column: $table.notesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$DraftAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftAnswersTable,
          DraftAnswer,
          $$DraftAnswersTableFilterComposer,
          $$DraftAnswersTableOrderingComposer,
          $$DraftAnswersTableAnnotationComposer,
          $$DraftAnswersTableCreateCompanionBuilder,
          $$DraftAnswersTableUpdateCompanionBuilder,
          (
            DraftAnswer,
            BaseReferences<_$AppDatabase, $DraftAnswersTable, DraftAnswer>,
          ),
          DraftAnswer,
          PrefetchHooks Function()
        > {
  $$DraftAnswersTableTableManager(_$AppDatabase db, $DraftAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> draftKey = const Value.absent(),
                Value<String> answersJson = const Value.absent(),
                Value<String?> notesJson = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftAnswersCompanion(
                draftKey: draftKey,
                answersJson: answersJson,
                notesJson: notesJson,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String draftKey,
                required String answersJson,
                Value<String?> notesJson = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => DraftAnswersCompanion.insert(
                draftKey: draftKey,
                answersJson: answersJson,
                notesJson: notesJson,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftAnswersTable,
      DraftAnswer,
      $$DraftAnswersTableFilterComposer,
      $$DraftAnswersTableOrderingComposer,
      $$DraftAnswersTableAnnotationComposer,
      $$DraftAnswersTableCreateCompanionBuilder,
      $$DraftAnswersTableUpdateCompanionBuilder,
      (
        DraftAnswer,
        BaseReferences<_$AppDatabase, $DraftAnswersTable, DraftAnswer>,
      ),
      DraftAnswer,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedTemplatesTableTableManager get cachedTemplates =>
      $$CachedTemplatesTableTableManager(_db, _db.cachedTemplates);
  $$CachedGroupsTableTableManager get cachedGroups =>
      $$CachedGroupsTableTableManager(_db, _db.cachedGroups);
  $$CachedCriteriaTableTableManager get cachedCriteria =>
      $$CachedCriteriaTableTableManager(_db, _db.cachedCriteria);
  $$CachedStoresTableTableManager get cachedStores =>
      $$CachedStoresTableTableManager(_db, _db.cachedStores);
  $$CachedSubmissionsTableTableManager get cachedSubmissions =>
      $$CachedSubmissionsTableTableManager(_db, _db.cachedSubmissions);
  $$CachedActionPlansTableTableManager get cachedActionPlans =>
      $$CachedActionPlansTableTableManager(_db, _db.cachedActionPlans);
  $$CachedNotificationsTableTableManager get cachedNotifications =>
      $$CachedNotificationsTableTableManager(_db, _db.cachedNotifications);
  $$CachedPoliciesTableTableManager get cachedPolicies =>
      $$CachedPoliciesTableTableManager(_db, _db.cachedPolicies);
  $$PendingSubmissionsTableTableManager get pendingSubmissions =>
      $$PendingSubmissionsTableTableManager(_db, _db.pendingSubmissions);
  $$PendingAnswersTableTableManager get pendingAnswers =>
      $$PendingAnswersTableTableManager(_db, _db.pendingAnswers);
  $$PendingPhotosTableTableManager get pendingPhotos =>
      $$PendingPhotosTableTableManager(_db, _db.pendingPhotos);
  $$PendingActionPlanUpdatesTableTableManager get pendingActionPlanUpdates =>
      $$PendingActionPlanUpdatesTableTableManager(
        _db,
        _db.pendingActionPlanUpdates,
      );
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$DraftAnswersTableTableManager get draftAnswers =>
      $$DraftAnswersTableTableManager(_db, _db.draftAnswers);
}
