// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContentSourcesTable extends ContentSources
    with TableInfo<$ContentSourcesTable, ContentSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _managedSourcePathMeta = const VerificationMeta(
    'managedSourcePath',
  );
  @override
  late final GeneratedColumn<String> managedSourcePath =
      GeneratedColumn<String>(
        'managed_source_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceSizeMeta = const VerificationMeta(
    'sourceSize',
  );
  @override
  late final GeneratedColumn<int> sourceSize = GeneratedColumn<int>(
    'source_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedEncodingMeta = const VerificationMeta(
    'detectedEncoding',
  );
  @override
  late final GeneratedColumn<String> detectedEncoding = GeneratedColumn<String>(
    'detected_encoding',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    type,
    displayName,
    contentHash,
    managedSourcePath,
    sourceSize,
    detectedEncoding,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('managed_source_path')) {
      context.handle(
        _managedSourcePathMeta,
        managedSourcePath.isAcceptableOrUnknown(
          data['managed_source_path']!,
          _managedSourcePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_managedSourcePathMeta);
    }
    if (data.containsKey('source_size')) {
      context.handle(
        _sourceSizeMeta,
        sourceSize.isAcceptableOrUnknown(data['source_size']!, _sourceSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceSizeMeta);
    }
    if (data.containsKey('detected_encoding')) {
      context.handle(
        _detectedEncodingMeta,
        detectedEncoding.isAcceptableOrUnknown(
          data['detected_encoding']!,
          _detectedEncodingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_detectedEncodingMeta);
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
  ContentSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      managedSourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}managed_source_path'],
      )!,
      sourceSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_size'],
      )!,
      detectedEncoding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_encoding'],
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
  $ContentSourcesTable createAlias(String alias) {
    return $ContentSourcesTable(attachedDatabase, alias);
  }
}

class ContentSource extends DataClass implements Insertable<ContentSource> {
  /// 稳定 ID：`local-txt-source:<contentHash>`（确定性，非 UUID）。
  final String id;

  /// 来源类型：首版仅 localTxt。
  final String type;

  /// 展示名（原始文件名，去除 .txt 扩展）。
  final String displayName;

  /// 内容 SHA-256（稳定内容身份）。
  final String contentHash;

  /// 应用管理目录下的原始文件副本路径。
  final String managedSourcePath;

  /// 源文件字节大小。
  final int sourceSize;

  /// 检测到的编码名（TextEncoding.name）。
  final String detectedEncoding;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ContentSource({
    required this.id,
    required this.type,
    required this.displayName,
    required this.contentHash,
    required this.managedSourcePath,
    required this.sourceSize,
    required this.detectedEncoding,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['display_name'] = Variable<String>(displayName);
    map['content_hash'] = Variable<String>(contentHash);
    map['managed_source_path'] = Variable<String>(managedSourcePath);
    map['source_size'] = Variable<int>(sourceSize);
    map['detected_encoding'] = Variable<String>(detectedEncoding);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContentSourcesCompanion toCompanion(bool nullToAbsent) {
    return ContentSourcesCompanion(
      id: Value(id),
      type: Value(type),
      displayName: Value(displayName),
      contentHash: Value(contentHash),
      managedSourcePath: Value(managedSourcePath),
      sourceSize: Value(sourceSize),
      detectedEncoding: Value(detectedEncoding),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContentSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentSource(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      displayName: serializer.fromJson<String>(json['displayName']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      managedSourcePath: serializer.fromJson<String>(json['managedSourcePath']),
      sourceSize: serializer.fromJson<int>(json['sourceSize']),
      detectedEncoding: serializer.fromJson<String>(json['detectedEncoding']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'displayName': serializer.toJson<String>(displayName),
      'contentHash': serializer.toJson<String>(contentHash),
      'managedSourcePath': serializer.toJson<String>(managedSourcePath),
      'sourceSize': serializer.toJson<int>(sourceSize),
      'detectedEncoding': serializer.toJson<String>(detectedEncoding),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContentSource copyWith({
    String? id,
    String? type,
    String? displayName,
    String? contentHash,
    String? managedSourcePath,
    int? sourceSize,
    String? detectedEncoding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ContentSource(
    id: id ?? this.id,
    type: type ?? this.type,
    displayName: displayName ?? this.displayName,
    contentHash: contentHash ?? this.contentHash,
    managedSourcePath: managedSourcePath ?? this.managedSourcePath,
    sourceSize: sourceSize ?? this.sourceSize,
    detectedEncoding: detectedEncoding ?? this.detectedEncoding,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContentSource copyWithCompanion(ContentSourcesCompanion data) {
    return ContentSource(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      managedSourcePath: data.managedSourcePath.present
          ? data.managedSourcePath.value
          : this.managedSourcePath,
      sourceSize: data.sourceSize.present
          ? data.sourceSize.value
          : this.sourceSize,
      detectedEncoding: data.detectedEncoding.present
          ? data.detectedEncoding.value
          : this.detectedEncoding,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentSource(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('displayName: $displayName, ')
          ..write('contentHash: $contentHash, ')
          ..write('managedSourcePath: $managedSourcePath, ')
          ..write('sourceSize: $sourceSize, ')
          ..write('detectedEncoding: $detectedEncoding, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    displayName,
    contentHash,
    managedSourcePath,
    sourceSize,
    detectedEncoding,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentSource &&
          other.id == this.id &&
          other.type == this.type &&
          other.displayName == this.displayName &&
          other.contentHash == this.contentHash &&
          other.managedSourcePath == this.managedSourcePath &&
          other.sourceSize == this.sourceSize &&
          other.detectedEncoding == this.detectedEncoding &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContentSourcesCompanion extends UpdateCompanion<ContentSource> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> displayName;
  final Value<String> contentHash;
  final Value<String> managedSourcePath;
  final Value<int> sourceSize;
  final Value<String> detectedEncoding;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ContentSourcesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.displayName = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.managedSourcePath = const Value.absent(),
    this.sourceSize = const Value.absent(),
    this.detectedEncoding = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentSourcesCompanion.insert({
    required String id,
    required String type,
    required String displayName,
    required String contentHash,
    required String managedSourcePath,
    required int sourceSize,
    required String detectedEncoding,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       displayName = Value(displayName),
       contentHash = Value(contentHash),
       managedSourcePath = Value(managedSourcePath),
       sourceSize = Value(sourceSize),
       detectedEncoding = Value(detectedEncoding),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContentSource> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? displayName,
    Expression<String>? contentHash,
    Expression<String>? managedSourcePath,
    Expression<int>? sourceSize,
    Expression<String>? detectedEncoding,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (displayName != null) 'display_name': displayName,
      if (contentHash != null) 'content_hash': contentHash,
      if (managedSourcePath != null) 'managed_source_path': managedSourcePath,
      if (sourceSize != null) 'source_size': sourceSize,
      if (detectedEncoding != null) 'detected_encoding': detectedEncoding,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? displayName,
    Value<String>? contentHash,
    Value<String>? managedSourcePath,
    Value<int>? sourceSize,
    Value<String>? detectedEncoding,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContentSourcesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      contentHash: contentHash ?? this.contentHash,
      managedSourcePath: managedSourcePath ?? this.managedSourcePath,
      sourceSize: sourceSize ?? this.sourceSize,
      detectedEncoding: detectedEncoding ?? this.detectedEncoding,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (managedSourcePath.present) {
      map['managed_source_path'] = Variable<String>(managedSourcePath.value);
    }
    if (sourceSize.present) {
      map['source_size'] = Variable<int>(sourceSize.value);
    }
    if (detectedEncoding.present) {
      map['detected_encoding'] = Variable<String>(detectedEncoding.value);
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
    return (StringBuffer('ContentSourcesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('displayName: $displayName, ')
          ..write('contentHash: $contentHash, ')
          ..write('managedSourcePath: $managedSourcePath, ')
          ..write('sourceSize: $sourceSize, ')
          ..write('detectedEncoding: $detectedEncoding, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentCollectionsTable extends ContentCollections
    with TableInfo<$ContentCollectionsTable, ContentCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
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
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedCharacterLengthMeta =
      const VerificationMeta('normalizedCharacterLength');
  @override
  late final GeneratedColumn<int> normalizedCharacterLength =
      GeneratedColumn<int>(
        'normalized_character_length',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
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
    sourceId,
    title,
    subtitle,
    itemCount,
    normalizedCharacterLength,
    importedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('normalized_character_length')) {
      context.handle(
        _normalizedCharacterLengthMeta,
        normalizedCharacterLength.isAcceptableOrUnknown(
          data['normalized_character_length']!,
          _normalizedCharacterLengthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedCharacterLengthMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
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
  ContentCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentCollection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      normalizedCharacterLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}normalized_character_length'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContentCollectionsTable createAlias(String alias) {
    return $ContentCollectionsTable(attachedDatabase, alias);
  }
}

class ContentCollection extends DataClass
    implements Insertable<ContentCollection> {
  /// 稳定 ID：`local-txt:<contentHash>`。
  final String id;
  final String sourceId;
  final String title;
  final String? subtitle;

  /// 章节 item 数（volume 不计入）。
  final int itemCount;
  final int normalizedCharacterLength;
  final DateTime importedAt;
  final DateTime updatedAt;
  const ContentCollection({
    required this.id,
    required this.sourceId,
    required this.title,
    this.subtitle,
    required this.itemCount,
    required this.normalizedCharacterLength,
    required this.importedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['item_count'] = Variable<int>(itemCount);
    map['normalized_character_length'] = Variable<int>(
      normalizedCharacterLength,
    );
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContentCollectionsCompanion toCompanion(bool nullToAbsent) {
    return ContentCollectionsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      itemCount: Value(itemCount),
      normalizedCharacterLength: Value(normalizedCharacterLength),
      importedAt: Value(importedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContentCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentCollection(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      normalizedCharacterLength: serializer.fromJson<int>(
        json['normalizedCharacterLength'],
      ),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'itemCount': serializer.toJson<int>(itemCount),
      'normalizedCharacterLength': serializer.toJson<int>(
        normalizedCharacterLength,
      ),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContentCollection copyWith({
    String? id,
    String? sourceId,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    int? itemCount,
    int? normalizedCharacterLength,
    DateTime? importedAt,
    DateTime? updatedAt,
  }) => ContentCollection(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    itemCount: itemCount ?? this.itemCount,
    normalizedCharacterLength:
        normalizedCharacterLength ?? this.normalizedCharacterLength,
    importedAt: importedAt ?? this.importedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContentCollection copyWithCompanion(ContentCollectionsCompanion data) {
    return ContentCollection(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      normalizedCharacterLength: data.normalizedCharacterLength.present
          ? data.normalizedCharacterLength.value
          : this.normalizedCharacterLength,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentCollection(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('itemCount: $itemCount, ')
          ..write('normalizedCharacterLength: $normalizedCharacterLength, ')
          ..write('importedAt: $importedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    title,
    subtitle,
    itemCount,
    normalizedCharacterLength,
    importedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentCollection &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.itemCount == this.itemCount &&
          other.normalizedCharacterLength == this.normalizedCharacterLength &&
          other.importedAt == this.importedAt &&
          other.updatedAt == this.updatedAt);
}

class ContentCollectionsCompanion extends UpdateCompanion<ContentCollection> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<int> itemCount;
  final Value<int> normalizedCharacterLength;
  final Value<DateTime> importedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ContentCollectionsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.normalizedCharacterLength = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentCollectionsCompanion.insert({
    required String id,
    required String sourceId,
    required String title,
    this.subtitle = const Value.absent(),
    required int itemCount,
    required int normalizedCharacterLength,
    required DateTime importedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       title = Value(title),
       itemCount = Value(itemCount),
       normalizedCharacterLength = Value(normalizedCharacterLength),
       importedAt = Value(importedAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContentCollection> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<int>? itemCount,
    Expression<int>? normalizedCharacterLength,
    Expression<DateTime>? importedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (itemCount != null) 'item_count': itemCount,
      if (normalizedCharacterLength != null)
        'normalized_character_length': normalizedCharacterLength,
      if (importedAt != null) 'imported_at': importedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentCollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<int>? itemCount,
    Value<int>? normalizedCharacterLength,
    Value<DateTime>? importedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContentCollectionsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      itemCount: itemCount ?? this.itemCount,
      normalizedCharacterLength:
          normalizedCharacterLength ?? this.normalizedCharacterLength,
      importedAt: importedAt ?? this.importedAt,
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
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (normalizedCharacterLength.present) {
      map['normalized_character_length'] = Variable<int>(
        normalizedCharacterLength.value,
      );
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
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
    return (StringBuffer('ContentCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('itemCount: $itemCount, ')
          ..write('normalizedCharacterLength: $normalizedCharacterLength, ')
          ..write('importedAt: $importedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentItemsTable extends ContentItems
    with TableInfo<$ContentItemsTable, ContentItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
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
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startCharacterOffsetMeta =
      const VerificationMeta('startCharacterOffset');
  @override
  late final GeneratedColumn<int> startCharacterOffset = GeneratedColumn<int>(
    'start_character_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endCharacterOffsetMeta =
      const VerificationMeta('endCharacterOffset');
  @override
  late final GeneratedColumn<int> endCharacterOffset = GeneratedColumn<int>(
    'end_character_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    collectionId,
    kind,
    title,
    orderIndex,
    startCharacterOffset,
    endCharacterOffset,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('start_character_offset')) {
      context.handle(
        _startCharacterOffsetMeta,
        startCharacterOffset.isAcceptableOrUnknown(
          data['start_character_offset']!,
          _startCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startCharacterOffsetMeta);
    }
    if (data.containsKey('end_character_offset')) {
      context.handle(
        _endCharacterOffsetMeta,
        endCharacterOffset.isAcceptableOrUnknown(
          data['end_character_offset']!,
          _endCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endCharacterOffsetMeta);
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
  ContentItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      startCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_character_offset'],
      )!,
      endCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_character_offset'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContentItemsTable createAlias(String alias) {
    return $ContentItemsTable(attachedDatabase, alias);
  }
}

class ContentItem extends DataClass implements Insertable<ContentItem> {
  /// 稳定 ID：`local-txt:<hash>:chapter:<startOffset>` 或 `local-txt:<hash>:whole`。
  final String id;
  final String collectionId;

  /// chapter / whole。
  final String kind;
  final String title;
  final int orderIndex;

  /// 规范化 UTF-16 偏移（唯一位置真源）。
  final int startCharacterOffset;
  final int endCharacterOffset;
  final DateTime createdAt;
  const ContentItem({
    required this.id,
    required this.collectionId,
    required this.kind,
    required this.title,
    required this.orderIndex,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['collection_id'] = Variable<String>(collectionId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['order_index'] = Variable<int>(orderIndex);
    map['start_character_offset'] = Variable<int>(startCharacterOffset);
    map['end_character_offset'] = Variable<int>(endCharacterOffset);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContentItemsCompanion toCompanion(bool nullToAbsent) {
    return ContentItemsCompanion(
      id: Value(id),
      collectionId: Value(collectionId),
      kind: Value(kind),
      title: Value(title),
      orderIndex: Value(orderIndex),
      startCharacterOffset: Value(startCharacterOffset),
      endCharacterOffset: Value(endCharacterOffset),
      createdAt: Value(createdAt),
    );
  }

  factory ContentItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentItem(
      id: serializer.fromJson<String>(json['id']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      startCharacterOffset: serializer.fromJson<int>(
        json['startCharacterOffset'],
      ),
      endCharacterOffset: serializer.fromJson<int>(json['endCharacterOffset']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'collectionId': serializer.toJson<String>(collectionId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'startCharacterOffset': serializer.toJson<int>(startCharacterOffset),
      'endCharacterOffset': serializer.toJson<int>(endCharacterOffset),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ContentItem copyWith({
    String? id,
    String? collectionId,
    String? kind,
    String? title,
    int? orderIndex,
    int? startCharacterOffset,
    int? endCharacterOffset,
    DateTime? createdAt,
  }) => ContentItem(
    id: id ?? this.id,
    collectionId: collectionId ?? this.collectionId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    orderIndex: orderIndex ?? this.orderIndex,
    startCharacterOffset: startCharacterOffset ?? this.startCharacterOffset,
    endCharacterOffset: endCharacterOffset ?? this.endCharacterOffset,
    createdAt: createdAt ?? this.createdAt,
  );
  ContentItem copyWithCompanion(ContentItemsCompanion data) {
    return ContentItem(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      startCharacterOffset: data.startCharacterOffset.present
          ? data.startCharacterOffset.value
          : this.startCharacterOffset,
      endCharacterOffset: data.endCharacterOffset.present
          ? data.endCharacterOffset.value
          : this.endCharacterOffset,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentItem(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('startCharacterOffset: $startCharacterOffset, ')
          ..write('endCharacterOffset: $endCharacterOffset, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionId,
    kind,
    title,
    orderIndex,
    startCharacterOffset,
    endCharacterOffset,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentItem &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.orderIndex == this.orderIndex &&
          other.startCharacterOffset == this.startCharacterOffset &&
          other.endCharacterOffset == this.endCharacterOffset &&
          other.createdAt == this.createdAt);
}

class ContentItemsCompanion extends UpdateCompanion<ContentItem> {
  final Value<String> id;
  final Value<String> collectionId;
  final Value<String> kind;
  final Value<String> title;
  final Value<int> orderIndex;
  final Value<int> startCharacterOffset;
  final Value<int> endCharacterOffset;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ContentItemsCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.startCharacterOffset = const Value.absent(),
    this.endCharacterOffset = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentItemsCompanion.insert({
    required String id,
    required String collectionId,
    required String kind,
    required String title,
    required int orderIndex,
    required int startCharacterOffset,
    required int endCharacterOffset,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       collectionId = Value(collectionId),
       kind = Value(kind),
       title = Value(title),
       orderIndex = Value(orderIndex),
       startCharacterOffset = Value(startCharacterOffset),
       endCharacterOffset = Value(endCharacterOffset),
       createdAt = Value(createdAt);
  static Insertable<ContentItem> custom({
    Expression<String>? id,
    Expression<String>? collectionId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<int>? orderIndex,
    Expression<int>? startCharacterOffset,
    Expression<int>? endCharacterOffset,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (orderIndex != null) 'order_index': orderIndex,
      if (startCharacterOffset != null)
        'start_character_offset': startCharacterOffset,
      if (endCharacterOffset != null)
        'end_character_offset': endCharacterOffset,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? collectionId,
    Value<String>? kind,
    Value<String>? title,
    Value<int>? orderIndex,
    Value<int>? startCharacterOffset,
    Value<int>? endCharacterOffset,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ContentItemsCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      startCharacterOffset: startCharacterOffset ?? this.startCharacterOffset,
      endCharacterOffset: endCharacterOffset ?? this.endCharacterOffset,
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
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (startCharacterOffset.present) {
      map['start_character_offset'] = Variable<int>(startCharacterOffset.value);
    }
    if (endCharacterOffset.present) {
      map['end_character_offset'] = Variable<int>(endCharacterOffset.value);
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
    return (StringBuffer('ContentItemsCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('startCharacterOffset: $startCharacterOffset, ')
          ..write('endCharacterOffset: $endCharacterOffset, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentDocumentsTable extends ContentDocuments
    with TableInfo<$ContentDocumentsTable, ContentDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startCharacterOffsetMeta =
      const VerificationMeta('startCharacterOffset');
  @override
  late final GeneratedColumn<int> startCharacterOffset = GeneratedColumn<int>(
    'start_character_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endCharacterOffsetMeta =
      const VerificationMeta('endCharacterOffset');
  @override
  late final GeneratedColumn<int> endCharacterOffset = GeneratedColumn<int>(
    'end_character_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizationVersionMeta =
      const VerificationMeta('normalizationVersion');
  @override
  late final GeneratedColumn<String> normalizationVersion =
      GeneratedColumn<String>(
        'normalization_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    storagePath,
    mediaType,
    startCharacterOffset,
    endCharacterOffset,
    contentHash,
    normalizationVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storagePathMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('start_character_offset')) {
      context.handle(
        _startCharacterOffsetMeta,
        startCharacterOffset.isAcceptableOrUnknown(
          data['start_character_offset']!,
          _startCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startCharacterOffsetMeta);
    }
    if (data.containsKey('end_character_offset')) {
      context.handle(
        _endCharacterOffsetMeta,
        endCharacterOffset.isAcceptableOrUnknown(
          data['end_character_offset']!,
          _endCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endCharacterOffsetMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('normalization_version')) {
      context.handle(
        _normalizationVersionMeta,
        normalizationVersion.isAcceptableOrUnknown(
          data['normalization_version']!,
          _normalizationVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizationVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      startCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_character_offset'],
      )!,
      endCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_character_offset'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      normalizationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalization_version'],
      )!,
    );
  }

  @override
  $ContentDocumentsTable createAlias(String alias) {
    return $ContentDocumentsTable(attachedDatabase, alias);
  }
}

class ContentDocument extends DataClass implements Insertable<ContentDocument> {
  /// 稳定 ID：`local-txt:<hash>:document:<startOffset>`。
  final String id;
  final String itemId;

  /// 应用管理目录下 normalized.txt 的路径。
  final String storagePath;
  final String mediaType;
  final int startCharacterOffset;
  final int endCharacterOffset;

  /// 文档范围内容 hash（用于校验派生数据）。
  final String contentHash;
  final String normalizationVersion;
  const ContentDocument({
    required this.id,
    required this.itemId,
    required this.storagePath,
    required this.mediaType,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    required this.contentHash,
    required this.normalizationVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['storage_path'] = Variable<String>(storagePath);
    map['media_type'] = Variable<String>(mediaType);
    map['start_character_offset'] = Variable<int>(startCharacterOffset);
    map['end_character_offset'] = Variable<int>(endCharacterOffset);
    map['content_hash'] = Variable<String>(contentHash);
    map['normalization_version'] = Variable<String>(normalizationVersion);
    return map;
  }

  ContentDocumentsCompanion toCompanion(bool nullToAbsent) {
    return ContentDocumentsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      storagePath: Value(storagePath),
      mediaType: Value(mediaType),
      startCharacterOffset: Value(startCharacterOffset),
      endCharacterOffset: Value(endCharacterOffset),
      contentHash: Value(contentHash),
      normalizationVersion: Value(normalizationVersion),
    );
  }

  factory ContentDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentDocument(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      storagePath: serializer.fromJson<String>(json['storagePath']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      startCharacterOffset: serializer.fromJson<int>(
        json['startCharacterOffset'],
      ),
      endCharacterOffset: serializer.fromJson<int>(json['endCharacterOffset']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      normalizationVersion: serializer.fromJson<String>(
        json['normalizationVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'storagePath': serializer.toJson<String>(storagePath),
      'mediaType': serializer.toJson<String>(mediaType),
      'startCharacterOffset': serializer.toJson<int>(startCharacterOffset),
      'endCharacterOffset': serializer.toJson<int>(endCharacterOffset),
      'contentHash': serializer.toJson<String>(contentHash),
      'normalizationVersion': serializer.toJson<String>(normalizationVersion),
    };
  }

  ContentDocument copyWith({
    String? id,
    String? itemId,
    String? storagePath,
    String? mediaType,
    int? startCharacterOffset,
    int? endCharacterOffset,
    String? contentHash,
    String? normalizationVersion,
  }) => ContentDocument(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    storagePath: storagePath ?? this.storagePath,
    mediaType: mediaType ?? this.mediaType,
    startCharacterOffset: startCharacterOffset ?? this.startCharacterOffset,
    endCharacterOffset: endCharacterOffset ?? this.endCharacterOffset,
    contentHash: contentHash ?? this.contentHash,
    normalizationVersion: normalizationVersion ?? this.normalizationVersion,
  );
  ContentDocument copyWithCompanion(ContentDocumentsCompanion data) {
    return ContentDocument(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      startCharacterOffset: data.startCharacterOffset.present
          ? data.startCharacterOffset.value
          : this.startCharacterOffset,
      endCharacterOffset: data.endCharacterOffset.present
          ? data.endCharacterOffset.value
          : this.endCharacterOffset,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      normalizationVersion: data.normalizationVersion.present
          ? data.normalizationVersion.value
          : this.normalizationVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentDocument(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('storagePath: $storagePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('startCharacterOffset: $startCharacterOffset, ')
          ..write('endCharacterOffset: $endCharacterOffset, ')
          ..write('contentHash: $contentHash, ')
          ..write('normalizationVersion: $normalizationVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    storagePath,
    mediaType,
    startCharacterOffset,
    endCharacterOffset,
    contentHash,
    normalizationVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentDocument &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.storagePath == this.storagePath &&
          other.mediaType == this.mediaType &&
          other.startCharacterOffset == this.startCharacterOffset &&
          other.endCharacterOffset == this.endCharacterOffset &&
          other.contentHash == this.contentHash &&
          other.normalizationVersion == this.normalizationVersion);
}

class ContentDocumentsCompanion extends UpdateCompanion<ContentDocument> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> storagePath;
  final Value<String> mediaType;
  final Value<int> startCharacterOffset;
  final Value<int> endCharacterOffset;
  final Value<String> contentHash;
  final Value<String> normalizationVersion;
  final Value<int> rowid;
  const ContentDocumentsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.startCharacterOffset = const Value.absent(),
    this.endCharacterOffset = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.normalizationVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentDocumentsCompanion.insert({
    required String id,
    required String itemId,
    required String storagePath,
    required String mediaType,
    required int startCharacterOffset,
    required int endCharacterOffset,
    required String contentHash,
    required String normalizationVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       storagePath = Value(storagePath),
       mediaType = Value(mediaType),
       startCharacterOffset = Value(startCharacterOffset),
       endCharacterOffset = Value(endCharacterOffset),
       contentHash = Value(contentHash),
       normalizationVersion = Value(normalizationVersion);
  static Insertable<ContentDocument> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? storagePath,
    Expression<String>? mediaType,
    Expression<int>? startCharacterOffset,
    Expression<int>? endCharacterOffset,
    Expression<String>? contentHash,
    Expression<String>? normalizationVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (storagePath != null) 'storage_path': storagePath,
      if (mediaType != null) 'media_type': mediaType,
      if (startCharacterOffset != null)
        'start_character_offset': startCharacterOffset,
      if (endCharacterOffset != null)
        'end_character_offset': endCharacterOffset,
      if (contentHash != null) 'content_hash': contentHash,
      if (normalizationVersion != null)
        'normalization_version': normalizationVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? storagePath,
    Value<String>? mediaType,
    Value<int>? startCharacterOffset,
    Value<int>? endCharacterOffset,
    Value<String>? contentHash,
    Value<String>? normalizationVersion,
    Value<int>? rowid,
  }) {
    return ContentDocumentsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      storagePath: storagePath ?? this.storagePath,
      mediaType: mediaType ?? this.mediaType,
      startCharacterOffset: startCharacterOffset ?? this.startCharacterOffset,
      endCharacterOffset: endCharacterOffset ?? this.endCharacterOffset,
      contentHash: contentHash ?? this.contentHash,
      normalizationVersion: normalizationVersion ?? this.normalizationVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (startCharacterOffset.present) {
      map['start_character_offset'] = Variable<int>(startCharacterOffset.value);
    }
    if (endCharacterOffset.present) {
      map['end_character_offset'] = Variable<int>(endCharacterOffset.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (normalizationVersion.present) {
      map['normalization_version'] = Variable<String>(
        normalizationVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('storagePath: $storagePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('startCharacterOffset: $startCharacterOffset, ')
          ..write('endCharacterOffset: $endCharacterOffset, ')
          ..write('contentHash: $contentHash, ')
          ..write('normalizationVersion: $normalizationVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TocEntriesTable extends TocEntries
    with TableInfo<$TocEntriesTable, TocEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TocEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startCharacterOffsetMeta =
      const VerificationMeta('startCharacterOffset');
  @override
  late final GeneratedColumn<int> startCharacterOffset = GeneratedColumn<int>(
    'start_character_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endCharacterOffsetMeta =
      const VerificationMeta('endCharacterOffset');
  @override
  late final GeneratedColumn<int> endCharacterOffset = GeneratedColumn<int>(
    'end_character_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectionId,
    itemId,
    parentId,
    kind,
    level,
    title,
    orderIndex,
    startCharacterOffset,
    endCharacterOffset,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'toc_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TocEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('start_character_offset')) {
      context.handle(
        _startCharacterOffsetMeta,
        startCharacterOffset.isAcceptableOrUnknown(
          data['start_character_offset']!,
          _startCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startCharacterOffsetMeta);
    }
    if (data.containsKey('end_character_offset')) {
      context.handle(
        _endCharacterOffsetMeta,
        endCharacterOffset.isAcceptableOrUnknown(
          data['end_character_offset']!,
          _endCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endCharacterOffsetMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TocEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TocEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      startCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_character_offset'],
      )!,
      endCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_character_offset'],
      )!,
    );
  }

  @override
  $TocEntriesTable createAlias(String alias) {
    return $TocEntriesTable(attachedDatabase, alias);
  }
}

class TocEntry extends DataClass implements Insertable<TocEntry> {
  /// 稳定 ID（与 TxtIndex tocEntries id 一致）。
  final String id;
  final String collectionId;

  /// volume 为 null；chapter 指向 content_items。
  final String? itemId;
  final String? parentId;

  /// volume / chapter。
  final String kind;
  final int level;
  final String title;
  final int orderIndex;
  final int startCharacterOffset;
  final int endCharacterOffset;
  const TocEntry({
    required this.id,
    required this.collectionId,
    this.itemId,
    this.parentId,
    required this.kind,
    required this.level,
    required this.title,
    required this.orderIndex,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['collection_id'] = Variable<String>(collectionId);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['kind'] = Variable<String>(kind);
    map['level'] = Variable<int>(level);
    map['title'] = Variable<String>(title);
    map['order_index'] = Variable<int>(orderIndex);
    map['start_character_offset'] = Variable<int>(startCharacterOffset);
    map['end_character_offset'] = Variable<int>(endCharacterOffset);
    return map;
  }

  TocEntriesCompanion toCompanion(bool nullToAbsent) {
    return TocEntriesCompanion(
      id: Value(id),
      collectionId: Value(collectionId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      kind: Value(kind),
      level: Value(level),
      title: Value(title),
      orderIndex: Value(orderIndex),
      startCharacterOffset: Value(startCharacterOffset),
      endCharacterOffset: Value(endCharacterOffset),
    );
  }

  factory TocEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TocEntry(
      id: serializer.fromJson<String>(json['id']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      kind: serializer.fromJson<String>(json['kind']),
      level: serializer.fromJson<int>(json['level']),
      title: serializer.fromJson<String>(json['title']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      startCharacterOffset: serializer.fromJson<int>(
        json['startCharacterOffset'],
      ),
      endCharacterOffset: serializer.fromJson<int>(json['endCharacterOffset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'collectionId': serializer.toJson<String>(collectionId),
      'itemId': serializer.toJson<String?>(itemId),
      'parentId': serializer.toJson<String?>(parentId),
      'kind': serializer.toJson<String>(kind),
      'level': serializer.toJson<int>(level),
      'title': serializer.toJson<String>(title),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'startCharacterOffset': serializer.toJson<int>(startCharacterOffset),
      'endCharacterOffset': serializer.toJson<int>(endCharacterOffset),
    };
  }

  TocEntry copyWith({
    String? id,
    String? collectionId,
    Value<String?> itemId = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    String? kind,
    int? level,
    String? title,
    int? orderIndex,
    int? startCharacterOffset,
    int? endCharacterOffset,
  }) => TocEntry(
    id: id ?? this.id,
    collectionId: collectionId ?? this.collectionId,
    itemId: itemId.present ? itemId.value : this.itemId,
    parentId: parentId.present ? parentId.value : this.parentId,
    kind: kind ?? this.kind,
    level: level ?? this.level,
    title: title ?? this.title,
    orderIndex: orderIndex ?? this.orderIndex,
    startCharacterOffset: startCharacterOffset ?? this.startCharacterOffset,
    endCharacterOffset: endCharacterOffset ?? this.endCharacterOffset,
  );
  TocEntry copyWithCompanion(TocEntriesCompanion data) {
    return TocEntry(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      kind: data.kind.present ? data.kind.value : this.kind,
      level: data.level.present ? data.level.value : this.level,
      title: data.title.present ? data.title.value : this.title,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      startCharacterOffset: data.startCharacterOffset.present
          ? data.startCharacterOffset.value
          : this.startCharacterOffset,
      endCharacterOffset: data.endCharacterOffset.present
          ? data.endCharacterOffset.value
          : this.endCharacterOffset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TocEntry(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('itemId: $itemId, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('level: $level, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('startCharacterOffset: $startCharacterOffset, ')
          ..write('endCharacterOffset: $endCharacterOffset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionId,
    itemId,
    parentId,
    kind,
    level,
    title,
    orderIndex,
    startCharacterOffset,
    endCharacterOffset,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TocEntry &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.itemId == this.itemId &&
          other.parentId == this.parentId &&
          other.kind == this.kind &&
          other.level == this.level &&
          other.title == this.title &&
          other.orderIndex == this.orderIndex &&
          other.startCharacterOffset == this.startCharacterOffset &&
          other.endCharacterOffset == this.endCharacterOffset);
}

class TocEntriesCompanion extends UpdateCompanion<TocEntry> {
  final Value<String> id;
  final Value<String> collectionId;
  final Value<String?> itemId;
  final Value<String?> parentId;
  final Value<String> kind;
  final Value<int> level;
  final Value<String> title;
  final Value<int> orderIndex;
  final Value<int> startCharacterOffset;
  final Value<int> endCharacterOffset;
  final Value<int> rowid;
  const TocEntriesCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.level = const Value.absent(),
    this.title = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.startCharacterOffset = const Value.absent(),
    this.endCharacterOffset = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TocEntriesCompanion.insert({
    required String id,
    required String collectionId,
    this.itemId = const Value.absent(),
    this.parentId = const Value.absent(),
    required String kind,
    required int level,
    required String title,
    required int orderIndex,
    required int startCharacterOffset,
    required int endCharacterOffset,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       collectionId = Value(collectionId),
       kind = Value(kind),
       level = Value(level),
       title = Value(title),
       orderIndex = Value(orderIndex),
       startCharacterOffset = Value(startCharacterOffset),
       endCharacterOffset = Value(endCharacterOffset);
  static Insertable<TocEntry> custom({
    Expression<String>? id,
    Expression<String>? collectionId,
    Expression<String>? itemId,
    Expression<String>? parentId,
    Expression<String>? kind,
    Expression<int>? level,
    Expression<String>? title,
    Expression<int>? orderIndex,
    Expression<int>? startCharacterOffset,
    Expression<int>? endCharacterOffset,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (itemId != null) 'item_id': itemId,
      if (parentId != null) 'parent_id': parentId,
      if (kind != null) 'kind': kind,
      if (level != null) 'level': level,
      if (title != null) 'title': title,
      if (orderIndex != null) 'order_index': orderIndex,
      if (startCharacterOffset != null)
        'start_character_offset': startCharacterOffset,
      if (endCharacterOffset != null)
        'end_character_offset': endCharacterOffset,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TocEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? collectionId,
    Value<String?>? itemId,
    Value<String?>? parentId,
    Value<String>? kind,
    Value<int>? level,
    Value<String>? title,
    Value<int>? orderIndex,
    Value<int>? startCharacterOffset,
    Value<int>? endCharacterOffset,
    Value<int>? rowid,
  }) {
    return TocEntriesCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      itemId: itemId ?? this.itemId,
      parentId: parentId ?? this.parentId,
      kind: kind ?? this.kind,
      level: level ?? this.level,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      startCharacterOffset: startCharacterOffset ?? this.startCharacterOffset,
      endCharacterOffset: endCharacterOffset ?? this.endCharacterOffset,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (startCharacterOffset.present) {
      map['start_character_offset'] = Variable<int>(startCharacterOffset.value);
    }
    if (endCharacterOffset.present) {
      map['end_character_offset'] = Variable<int>(endCharacterOffset.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TocEntriesCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('itemId: $itemId, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('level: $level, ')
          ..write('title: $title, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('startCharacterOffset: $startCharacterOffset, ')
          ..write('endCharacterOffset: $endCharacterOffset, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportRecordsTable extends ImportRecords
    with TableInfo<$ImportRecordsTable, ImportRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  @override
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
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
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceHash,
    state,
    startedAt,
    completedAt,
    errorCode,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
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
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ImportRecordsTable createAlias(String alias) {
    return $ImportRecordsTable(attachedDatabase, alias);
  }
}

class ImportRecord extends DataClass implements Insertable<ImportRecord> {
  /// 稳定 ID：`import:<sourceHash>:<startedAtEpochMs>`。
  final String id;
  final String sourceHash;

  /// preparing / copying / indexing / writingFiles / writingDatabase /
  /// completed / failed / cancelled。
  final String state;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorCode;
  final String? errorMessage;
  const ImportRecord({
    required this.id,
    required this.sourceHash,
    required this.state,
    required this.startedAt,
    this.completedAt,
    this.errorCode,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_hash'] = Variable<String>(sourceHash);
    map['state'] = Variable<String>(state);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ImportRecordsCompanion toCompanion(bool nullToAbsent) {
    return ImportRecordsCompanion(
      id: Value(id),
      sourceHash: Value(sourceHash),
      state: Value(state),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ImportRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportRecord(
      id: serializer.fromJson<String>(json['id']),
      sourceHash: serializer.fromJson<String>(json['sourceHash']),
      state: serializer.fromJson<String>(json['state']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceHash': serializer.toJson<String>(sourceHash),
      'state': serializer.toJson<String>(state),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ImportRecord copyWith({
    String? id,
    String? sourceHash,
    String? state,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => ImportRecord(
    id: id ?? this.id,
    sourceHash: sourceHash ?? this.sourceHash,
    state: state ?? this.state,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ImportRecord copyWithCompanion(ImportRecordsCompanion data) {
    return ImportRecord(
      id: data.id.present ? data.id.value : this.id,
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
      state: data.state.present ? data.state.value : this.state,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportRecord(')
          ..write('id: $id, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('state: $state, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceHash,
    state,
    startedAt,
    completedAt,
    errorCode,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportRecord &&
          other.id == this.id &&
          other.sourceHash == this.sourceHash &&
          other.state == this.state &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.errorCode == this.errorCode &&
          other.errorMessage == this.errorMessage);
}

class ImportRecordsCompanion extends UpdateCompanion<ImportRecord> {
  final Value<String> id;
  final Value<String> sourceHash;
  final Value<String> state;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> errorCode;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const ImportRecordsCompanion({
    this.id = const Value.absent(),
    this.sourceHash = const Value.absent(),
    this.state = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportRecordsCompanion.insert({
    required String id,
    required String sourceHash,
    required String state,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceHash = Value(sourceHash),
       state = Value(state),
       startedAt = Value(startedAt);
  static Insertable<ImportRecord> custom({
    Expression<String>? id,
    Expression<String>? sourceHash,
    Expression<String>? state,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? errorCode,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceHash != null) 'source_hash': sourceHash,
      if (state != null) 'state': state,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceHash,
    Value<String>? state,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? errorCode,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return ImportRecordsCompanion(
      id: id ?? this.id,
      sourceHash: sourceHash ?? this.sourceHash,
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('state: $state, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES content_collections (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _absoluteCharacterOffsetMeta =
      const VerificationMeta('absoluteCharacterOffset');
  @override
  late final GeneratedColumn<int> absoluteCharacterOffset =
      GeneratedColumn<int>(
        'absolute_character_offset',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _readingModeMeta = const VerificationMeta(
    'readingMode',
  );
  @override
  late final GeneratedColumn<String> readingMode = GeneratedColumn<String>(
    'reading_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('vertical'),
  );
  static const VerificationMeta _itemIdHintMeta = const VerificationMeta(
    'itemIdHint',
  );
  @override
  late final GeneratedColumn<String> itemIdHint = GeneratedColumn<String>(
    'item_id_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _locatorVersionMeta = const VerificationMeta(
    'locatorVersion',
  );
  @override
  late final GeneratedColumn<int> locatorVersion = GeneratedColumn<int>(
    'locator_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizationVersionMeta =
      const VerificationMeta('normalizationVersion');
  @override
  late final GeneratedColumn<String> normalizationVersion =
      GeneratedColumn<String>(
        'normalization_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    collectionId,
    absoluteCharacterOffset,
    readingMode,
    itemIdHint,
    updatedAt,
    locatorVersion,
    normalizationVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('absolute_character_offset')) {
      context.handle(
        _absoluteCharacterOffsetMeta,
        absoluteCharacterOffset.isAcceptableOrUnknown(
          data['absolute_character_offset']!,
          _absoluteCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_absoluteCharacterOffsetMeta);
    }
    if (data.containsKey('reading_mode')) {
      context.handle(
        _readingModeMeta,
        readingMode.isAcceptableOrUnknown(
          data['reading_mode']!,
          _readingModeMeta,
        ),
      );
    }
    if (data.containsKey('item_id_hint')) {
      context.handle(
        _itemIdHintMeta,
        itemIdHint.isAcceptableOrUnknown(
          data['item_id_hint']!,
          _itemIdHintMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('locator_version')) {
      context.handle(
        _locatorVersionMeta,
        locatorVersion.isAcceptableOrUnknown(
          data['locator_version']!,
          _locatorVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locatorVersionMeta);
    }
    if (data.containsKey('normalization_version')) {
      context.handle(
        _normalizationVersionMeta,
        normalizationVersion.isAcceptableOrUnknown(
          data['normalization_version']!,
          _normalizationVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizationVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId};
  @override
  ReadingProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressData(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      absoluteCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}absolute_character_offset'],
      )!,
      readingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_mode'],
      )!,
      itemIdHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id_hint'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      locatorVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}locator_version'],
      )!,
      normalizationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalization_version'],
      )!,
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressData extends DataClass
    implements Insertable<ReadingProgressData> {
  /// collection ID（`local-txt:<hash>`，主键 + 外键（级联删除））。
  final String collectionId;

  /// 唯一位置真源：normalized.txt UTF-16 码元偏移。
  final int absoluteCharacterOffset;

  /// 阅读表现状态：'vertical' / 'paged'（schema 3 新增，旧数据默认 vertical）。
  final String readingMode;

  /// 快速识别章节的提示（非位置真源），可空。
  final String? itemIdHint;
  final DateTime updatedAt;

  /// ReaderLocator 版本（区分未来 locator 语义）。
  final int locatorVersion;

  /// M1 normalization 版本（normalizationVersion）。
  final String normalizationVersion;
  const ReadingProgressData({
    required this.collectionId,
    required this.absoluteCharacterOffset,
    required this.readingMode,
    this.itemIdHint,
    required this.updatedAt,
    required this.locatorVersion,
    required this.normalizationVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['absolute_character_offset'] = Variable<int>(absoluteCharacterOffset);
    map['reading_mode'] = Variable<String>(readingMode);
    if (!nullToAbsent || itemIdHint != null) {
      map['item_id_hint'] = Variable<String>(itemIdHint);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['locator_version'] = Variable<int>(locatorVersion);
    map['normalization_version'] = Variable<String>(normalizationVersion);
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      collectionId: Value(collectionId),
      absoluteCharacterOffset: Value(absoluteCharacterOffset),
      readingMode: Value(readingMode),
      itemIdHint: itemIdHint == null && nullToAbsent
          ? const Value.absent()
          : Value(itemIdHint),
      updatedAt: Value(updatedAt),
      locatorVersion: Value(locatorVersion),
      normalizationVersion: Value(normalizationVersion),
    );
  }

  factory ReadingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressData(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      absoluteCharacterOffset: serializer.fromJson<int>(
        json['absoluteCharacterOffset'],
      ),
      readingMode: serializer.fromJson<String>(json['readingMode']),
      itemIdHint: serializer.fromJson<String?>(json['itemIdHint']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      locatorVersion: serializer.fromJson<int>(json['locatorVersion']),
      normalizationVersion: serializer.fromJson<String>(
        json['normalizationVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'absoluteCharacterOffset': serializer.toJson<int>(
        absoluteCharacterOffset,
      ),
      'readingMode': serializer.toJson<String>(readingMode),
      'itemIdHint': serializer.toJson<String?>(itemIdHint),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'locatorVersion': serializer.toJson<int>(locatorVersion),
      'normalizationVersion': serializer.toJson<String>(normalizationVersion),
    };
  }

  ReadingProgressData copyWith({
    String? collectionId,
    int? absoluteCharacterOffset,
    String? readingMode,
    Value<String?> itemIdHint = const Value.absent(),
    DateTime? updatedAt,
    int? locatorVersion,
    String? normalizationVersion,
  }) => ReadingProgressData(
    collectionId: collectionId ?? this.collectionId,
    absoluteCharacterOffset:
        absoluteCharacterOffset ?? this.absoluteCharacterOffset,
    readingMode: readingMode ?? this.readingMode,
    itemIdHint: itemIdHint.present ? itemIdHint.value : this.itemIdHint,
    updatedAt: updatedAt ?? this.updatedAt,
    locatorVersion: locatorVersion ?? this.locatorVersion,
    normalizationVersion: normalizationVersion ?? this.normalizationVersion,
  );
  ReadingProgressData copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressData(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      absoluteCharacterOffset: data.absoluteCharacterOffset.present
          ? data.absoluteCharacterOffset.value
          : this.absoluteCharacterOffset,
      readingMode: data.readingMode.present
          ? data.readingMode.value
          : this.readingMode,
      itemIdHint: data.itemIdHint.present
          ? data.itemIdHint.value
          : this.itemIdHint,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      locatorVersion: data.locatorVersion.present
          ? data.locatorVersion.value
          : this.locatorVersion,
      normalizationVersion: data.normalizationVersion.present
          ? data.normalizationVersion.value
          : this.normalizationVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressData(')
          ..write('collectionId: $collectionId, ')
          ..write('absoluteCharacterOffset: $absoluteCharacterOffset, ')
          ..write('readingMode: $readingMode, ')
          ..write('itemIdHint: $itemIdHint, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('locatorVersion: $locatorVersion, ')
          ..write('normalizationVersion: $normalizationVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    collectionId,
    absoluteCharacterOffset,
    readingMode,
    itemIdHint,
    updatedAt,
    locatorVersion,
    normalizationVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressData &&
          other.collectionId == this.collectionId &&
          other.absoluteCharacterOffset == this.absoluteCharacterOffset &&
          other.readingMode == this.readingMode &&
          other.itemIdHint == this.itemIdHint &&
          other.updatedAt == this.updatedAt &&
          other.locatorVersion == this.locatorVersion &&
          other.normalizationVersion == this.normalizationVersion);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressData> {
  final Value<String> collectionId;
  final Value<int> absoluteCharacterOffset;
  final Value<String> readingMode;
  final Value<String?> itemIdHint;
  final Value<DateTime> updatedAt;
  final Value<int> locatorVersion;
  final Value<String> normalizationVersion;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.collectionId = const Value.absent(),
    this.absoluteCharacterOffset = const Value.absent(),
    this.readingMode = const Value.absent(),
    this.itemIdHint = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.locatorVersion = const Value.absent(),
    this.normalizationVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String collectionId,
    required int absoluteCharacterOffset,
    this.readingMode = const Value.absent(),
    this.itemIdHint = const Value.absent(),
    required DateTime updatedAt,
    required int locatorVersion,
    required String normalizationVersion,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       absoluteCharacterOffset = Value(absoluteCharacterOffset),
       updatedAt = Value(updatedAt),
       locatorVersion = Value(locatorVersion),
       normalizationVersion = Value(normalizationVersion);
  static Insertable<ReadingProgressData> custom({
    Expression<String>? collectionId,
    Expression<int>? absoluteCharacterOffset,
    Expression<String>? readingMode,
    Expression<String>? itemIdHint,
    Expression<DateTime>? updatedAt,
    Expression<int>? locatorVersion,
    Expression<String>? normalizationVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (absoluteCharacterOffset != null)
        'absolute_character_offset': absoluteCharacterOffset,
      if (readingMode != null) 'reading_mode': readingMode,
      if (itemIdHint != null) 'item_id_hint': itemIdHint,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (locatorVersion != null) 'locator_version': locatorVersion,
      if (normalizationVersion != null)
        'normalization_version': normalizationVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? collectionId,
    Value<int>? absoluteCharacterOffset,
    Value<String>? readingMode,
    Value<String?>? itemIdHint,
    Value<DateTime>? updatedAt,
    Value<int>? locatorVersion,
    Value<String>? normalizationVersion,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      collectionId: collectionId ?? this.collectionId,
      absoluteCharacterOffset:
          absoluteCharacterOffset ?? this.absoluteCharacterOffset,
      readingMode: readingMode ?? this.readingMode,
      itemIdHint: itemIdHint ?? this.itemIdHint,
      updatedAt: updatedAt ?? this.updatedAt,
      locatorVersion: locatorVersion ?? this.locatorVersion,
      normalizationVersion: normalizationVersion ?? this.normalizationVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (absoluteCharacterOffset.present) {
      map['absolute_character_offset'] = Variable<int>(
        absoluteCharacterOffset.value,
      );
    }
    if (readingMode.present) {
      map['reading_mode'] = Variable<String>(readingMode.value);
    }
    if (itemIdHint.present) {
      map['item_id_hint'] = Variable<String>(itemIdHint.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (locatorVersion.present) {
      map['locator_version'] = Variable<int>(locatorVersion.value);
    }
    if (normalizationVersion.present) {
      map['normalization_version'] = Variable<String>(
        normalizationVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('absoluteCharacterOffset: $absoluteCharacterOffset, ')
          ..write('readingMode: $readingMode, ')
          ..write('itemIdHint: $itemIdHint, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('locatorVersion: $locatorVersion, ')
          ..write('normalizationVersion: $normalizationVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
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
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderPreferencesRowsTable extends ReaderPreferencesRows
    with TableInfo<$ReaderPreferencesRowsTable, ReaderPreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderPreferencesRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES content_collections (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _fontIdMeta = const VerificationMeta('fontId');
  @override
  late final GeneratedColumn<String> fontId = GeneratedColumn<String>(
    'font_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fontSizeMeta = const VerificationMeta(
    'fontSize',
  );
  @override
  late final GeneratedColumn<double> fontSize = GeneratedColumn<double>(
    'font_size',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _letterSpacingMeta = const VerificationMeta(
    'letterSpacing',
  );
  @override
  late final GeneratedColumn<double> letterSpacing = GeneratedColumn<double>(
    'letter_spacing',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineHeightMeta = const VerificationMeta(
    'lineHeight',
  );
  @override
  late final GeneratedColumn<double> lineHeight = GeneratedColumn<double>(
    'line_height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paragraphSpacingMeta = const VerificationMeta(
    'paragraphSpacing',
  );
  @override
  late final GeneratedColumn<double> paragraphSpacing = GeneratedColumn<double>(
    'paragraph_spacing',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstLineIndentMeta = const VerificationMeta(
    'firstLineIndent',
  );
  @override
  late final GeneratedColumn<double> firstLineIndent = GeneratedColumn<double>(
    'first_line_indent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paddingTopMeta = const VerificationMeta(
    'paddingTop',
  );
  @override
  late final GeneratedColumn<double> paddingTop = GeneratedColumn<double>(
    'padding_top',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paddingBottomMeta = const VerificationMeta(
    'paddingBottom',
  );
  @override
  late final GeneratedColumn<double> paddingBottom = GeneratedColumn<double>(
    'padding_bottom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paddingLeftMeta = const VerificationMeta(
    'paddingLeft',
  );
  @override
  late final GeneratedColumn<double> paddingLeft = GeneratedColumn<double>(
    'padding_left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paddingRightMeta = const VerificationMeta(
    'paddingRight',
  );
  @override
  late final GeneratedColumn<double> paddingRight = GeneratedColumn<double>(
    'padding_right',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paletteIdMeta = const VerificationMeta(
    'paletteId',
  );
  @override
  late final GeneratedColumn<String> paletteId = GeneratedColumn<String>(
    'palette_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('paperWhite'),
  );
  static const VerificationMeta _textColorArgbMeta = const VerificationMeta(
    'textColorArgb',
  );
  @override
  late final GeneratedColumn<int> textColorArgb = GeneratedColumn<int>(
    'text_color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backgroundColorArgbMeta =
      const VerificationMeta('backgroundColorArgb');
  @override
  late final GeneratedColumn<int> backgroundColorArgb = GeneratedColumn<int>(
    'background_color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lightTextColorArgbMeta =
      const VerificationMeta('lightTextColorArgb');
  @override
  late final GeneratedColumn<int> lightTextColorArgb = GeneratedColumn<int>(
    'light_text_color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lightBackgroundColorArgbMeta =
      const VerificationMeta('lightBackgroundColorArgb');
  @override
  late final GeneratedColumn<int> lightBackgroundColorArgb =
      GeneratedColumn<int>(
        'light_background_color_argb',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _darkTextColorArgbMeta = const VerificationMeta(
    'darkTextColorArgb',
  );
  @override
  late final GeneratedColumn<int> darkTextColorArgb = GeneratedColumn<int>(
    'dark_text_color_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _darkBackgroundColorArgbMeta =
      const VerificationMeta('darkBackgroundColorArgb');
  @override
  late final GeneratedColumn<int> darkBackgroundColorArgb =
      GeneratedColumn<int>(
        'dark_background_color_argb',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backgroundImagePathMeta =
      const VerificationMeta('backgroundImagePath');
  @override
  late final GeneratedColumn<String> backgroundImagePath =
      GeneratedColumn<String>(
        'background_image_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backgroundImageOpacityMeta =
      const VerificationMeta('backgroundImageOpacity');
  @override
  late final GeneratedColumn<double> backgroundImageOpacity =
      GeneratedColumn<double>(
        'background_image_opacity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.0),
      );
  static const VerificationMeta _backgroundOverlayOpacityMeta =
      const VerificationMeta('backgroundOverlayOpacity');
  @override
  late final GeneratedColumn<double> backgroundOverlayOpacity =
      GeneratedColumn<double>(
        'background_overlay_opacity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.45),
      );
  static const VerificationMeta _showTopInfoBarMeta = const VerificationMeta(
    'showTopInfoBar',
  );
  @override
  late final GeneratedColumn<bool> showTopInfoBar = GeneratedColumn<bool>(
    'show_top_info_bar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_top_info_bar" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showBottomInfoBarMeta = const VerificationMeta(
    'showBottomInfoBar',
  );
  @override
  late final GeneratedColumn<bool> showBottomInfoBar = GeneratedColumn<bool>(
    'show_bottom_info_bar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_bottom_info_bar" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showProgressInfoMeta = const VerificationMeta(
    'showProgressInfo',
  );
  @override
  late final GeneratedColumn<bool> showProgressInfo = GeneratedColumn<bool>(
    'show_progress_info',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_progress_info" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showSystemStatusBarMeta =
      const VerificationMeta('showSystemStatusBar');
  @override
  late final GeneratedColumn<bool> showSystemStatusBar = GeneratedColumn<bool>(
    'show_system_status_bar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_system_status_bar" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _statusBarModeMeta = const VerificationMeta(
    'statusBarMode',
  );
  @override
  late final GeneratedColumn<String> statusBarMode = GeneratedColumn<String>(
    'status_bar_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _timeDisplayModeMeta = const VerificationMeta(
    'timeDisplayMode',
  );
  @override
  late final GeneratedColumn<String> timeDisplayMode = GeneratedColumn<String>(
    'time_display_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('twentyFourHour'),
  );
  static const VerificationMeta _showChapterInfoMeta = const VerificationMeta(
    'showChapterInfo',
  );
  @override
  late final GeneratedColumn<bool> showChapterInfo = GeneratedColumn<bool>(
    'show_chapter_info',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_chapter_info" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showChapterProgressInfoMeta =
      const VerificationMeta('showChapterProgressInfo');
  @override
  late final GeneratedColumn<bool> showChapterProgressInfo =
      GeneratedColumn<bool>(
        'show_chapter_progress_info',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_chapter_progress_info" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _showClockInfoMeta = const VerificationMeta(
    'showClockInfo',
  );
  @override
  late final GeneratedColumn<bool> showClockInfo = GeneratedColumn<bool>(
    'show_clock_info',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_clock_info" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showWholeBookProgressInfoMeta =
      const VerificationMeta('showWholeBookProgressInfo');
  @override
  late final GeneratedColumn<bool> showWholeBookProgressInfo =
      GeneratedColumn<bool>(
        'show_whole_book_progress_info',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_whole_book_progress_info" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _showInfoDividerMeta = const VerificationMeta(
    'showInfoDivider',
  );
  @override
  late final GeneratedColumn<bool> showInfoDivider = GeneratedColumn<bool>(
    'show_info_divider',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_info_divider" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showTopInfoDividerMeta =
      const VerificationMeta('showTopInfoDivider');
  @override
  late final GeneratedColumn<bool> showTopInfoDivider = GeneratedColumn<bool>(
    'show_top_info_divider',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_top_info_divider" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showBottomInfoDividerMeta =
      const VerificationMeta('showBottomInfoDivider');
  @override
  late final GeneratedColumn<bool> showBottomInfoDivider =
      GeneratedColumn<bool>(
        'show_bottom_info_divider',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_bottom_info_divider" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _showAutoReadMinimalInfoMeta =
      const VerificationMeta('showAutoReadMinimalInfo');
  @override
  late final GeneratedColumn<bool> showAutoReadMinimalInfo =
      GeneratedColumn<bool>(
        'show_auto_read_minimal_info',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_auto_read_minimal_info" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _chapterInfoSlotMeta = const VerificationMeta(
    'chapterInfoSlot',
  );
  @override
  late final GeneratedColumn<String> chapterInfoSlot = GeneratedColumn<String>(
    'chapter_info_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('topLeft'),
  );
  static const VerificationMeta _chapterProgressInfoSlotMeta =
      const VerificationMeta('chapterProgressInfoSlot');
  @override
  late final GeneratedColumn<String> chapterProgressInfoSlot =
      GeneratedColumn<String>(
        'chapter_progress_info_slot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('topRight'),
      );
  static const VerificationMeta _clockInfoSlotMeta = const VerificationMeta(
    'clockInfoSlot',
  );
  @override
  late final GeneratedColumn<String> clockInfoSlot = GeneratedColumn<String>(
    'clock_info_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('bottomLeft'),
  );
  static const VerificationMeta _wholeBookProgressInfoSlotMeta =
      const VerificationMeta('wholeBookProgressInfoSlot');
  @override
  late final GeneratedColumn<String> wholeBookProgressInfoSlot =
      GeneratedColumn<String>(
        'whole_book_progress_info_slot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('bottomRight'),
      );
  static const VerificationMeta _infoDividerSlotMeta = const VerificationMeta(
    'infoDividerSlot',
  );
  @override
  late final GeneratedColumn<String> infoDividerSlot = GeneratedColumn<String>(
    'info_divider_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('topCenter'),
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
    collectionId,
    fontId,
    fontSize,
    letterSpacing,
    lineHeight,
    paragraphSpacing,
    firstLineIndent,
    paddingTop,
    paddingBottom,
    paddingLeft,
    paddingRight,
    themeMode,
    paletteId,
    textColorArgb,
    backgroundColorArgb,
    lightTextColorArgb,
    lightBackgroundColorArgb,
    darkTextColorArgb,
    darkBackgroundColorArgb,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundOverlayOpacity,
    showTopInfoBar,
    showBottomInfoBar,
    showProgressInfo,
    showSystemStatusBar,
    statusBarMode,
    timeDisplayMode,
    showChapterInfo,
    showChapterProgressInfo,
    showClockInfo,
    showWholeBookProgressInfo,
    showInfoDivider,
    showTopInfoDivider,
    showBottomInfoDivider,
    showAutoReadMinimalInfo,
    chapterInfoSlot,
    chapterProgressInfoSlot,
    clockInfoSlot,
    wholeBookProgressInfoSlot,
    infoDividerSlot,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderPreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('font_id')) {
      context.handle(
        _fontIdMeta,
        fontId.isAcceptableOrUnknown(data['font_id']!, _fontIdMeta),
      );
    }
    if (data.containsKey('font_size')) {
      context.handle(
        _fontSizeMeta,
        fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fontSizeMeta);
    }
    if (data.containsKey('letter_spacing')) {
      context.handle(
        _letterSpacingMeta,
        letterSpacing.isAcceptableOrUnknown(
          data['letter_spacing']!,
          _letterSpacingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_letterSpacingMeta);
    }
    if (data.containsKey('line_height')) {
      context.handle(
        _lineHeightMeta,
        lineHeight.isAcceptableOrUnknown(data['line_height']!, _lineHeightMeta),
      );
    } else if (isInserting) {
      context.missing(_lineHeightMeta);
    }
    if (data.containsKey('paragraph_spacing')) {
      context.handle(
        _paragraphSpacingMeta,
        paragraphSpacing.isAcceptableOrUnknown(
          data['paragraph_spacing']!,
          _paragraphSpacingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paragraphSpacingMeta);
    }
    if (data.containsKey('first_line_indent')) {
      context.handle(
        _firstLineIndentMeta,
        firstLineIndent.isAcceptableOrUnknown(
          data['first_line_indent']!,
          _firstLineIndentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstLineIndentMeta);
    }
    if (data.containsKey('padding_top')) {
      context.handle(
        _paddingTopMeta,
        paddingTop.isAcceptableOrUnknown(data['padding_top']!, _paddingTopMeta),
      );
    } else if (isInserting) {
      context.missing(_paddingTopMeta);
    }
    if (data.containsKey('padding_bottom')) {
      context.handle(
        _paddingBottomMeta,
        paddingBottom.isAcceptableOrUnknown(
          data['padding_bottom']!,
          _paddingBottomMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paddingBottomMeta);
    }
    if (data.containsKey('padding_left')) {
      context.handle(
        _paddingLeftMeta,
        paddingLeft.isAcceptableOrUnknown(
          data['padding_left']!,
          _paddingLeftMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paddingLeftMeta);
    }
    if (data.containsKey('padding_right')) {
      context.handle(
        _paddingRightMeta,
        paddingRight.isAcceptableOrUnknown(
          data['padding_right']!,
          _paddingRightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paddingRightMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('palette_id')) {
      context.handle(
        _paletteIdMeta,
        paletteId.isAcceptableOrUnknown(data['palette_id']!, _paletteIdMeta),
      );
    }
    if (data.containsKey('text_color_argb')) {
      context.handle(
        _textColorArgbMeta,
        textColorArgb.isAcceptableOrUnknown(
          data['text_color_argb']!,
          _textColorArgbMeta,
        ),
      );
    }
    if (data.containsKey('background_color_argb')) {
      context.handle(
        _backgroundColorArgbMeta,
        backgroundColorArgb.isAcceptableOrUnknown(
          data['background_color_argb']!,
          _backgroundColorArgbMeta,
        ),
      );
    }
    if (data.containsKey('light_text_color_argb')) {
      context.handle(
        _lightTextColorArgbMeta,
        lightTextColorArgb.isAcceptableOrUnknown(
          data['light_text_color_argb']!,
          _lightTextColorArgbMeta,
        ),
      );
    }
    if (data.containsKey('light_background_color_argb')) {
      context.handle(
        _lightBackgroundColorArgbMeta,
        lightBackgroundColorArgb.isAcceptableOrUnknown(
          data['light_background_color_argb']!,
          _lightBackgroundColorArgbMeta,
        ),
      );
    }
    if (data.containsKey('dark_text_color_argb')) {
      context.handle(
        _darkTextColorArgbMeta,
        darkTextColorArgb.isAcceptableOrUnknown(
          data['dark_text_color_argb']!,
          _darkTextColorArgbMeta,
        ),
      );
    }
    if (data.containsKey('dark_background_color_argb')) {
      context.handle(
        _darkBackgroundColorArgbMeta,
        darkBackgroundColorArgb.isAcceptableOrUnknown(
          data['dark_background_color_argb']!,
          _darkBackgroundColorArgbMeta,
        ),
      );
    }
    if (data.containsKey('background_image_path')) {
      context.handle(
        _backgroundImagePathMeta,
        backgroundImagePath.isAcceptableOrUnknown(
          data['background_image_path']!,
          _backgroundImagePathMeta,
        ),
      );
    }
    if (data.containsKey('background_image_opacity')) {
      context.handle(
        _backgroundImageOpacityMeta,
        backgroundImageOpacity.isAcceptableOrUnknown(
          data['background_image_opacity']!,
          _backgroundImageOpacityMeta,
        ),
      );
    }
    if (data.containsKey('background_overlay_opacity')) {
      context.handle(
        _backgroundOverlayOpacityMeta,
        backgroundOverlayOpacity.isAcceptableOrUnknown(
          data['background_overlay_opacity']!,
          _backgroundOverlayOpacityMeta,
        ),
      );
    }
    if (data.containsKey('show_top_info_bar')) {
      context.handle(
        _showTopInfoBarMeta,
        showTopInfoBar.isAcceptableOrUnknown(
          data['show_top_info_bar']!,
          _showTopInfoBarMeta,
        ),
      );
    }
    if (data.containsKey('show_bottom_info_bar')) {
      context.handle(
        _showBottomInfoBarMeta,
        showBottomInfoBar.isAcceptableOrUnknown(
          data['show_bottom_info_bar']!,
          _showBottomInfoBarMeta,
        ),
      );
    }
    if (data.containsKey('show_progress_info')) {
      context.handle(
        _showProgressInfoMeta,
        showProgressInfo.isAcceptableOrUnknown(
          data['show_progress_info']!,
          _showProgressInfoMeta,
        ),
      );
    }
    if (data.containsKey('show_system_status_bar')) {
      context.handle(
        _showSystemStatusBarMeta,
        showSystemStatusBar.isAcceptableOrUnknown(
          data['show_system_status_bar']!,
          _showSystemStatusBarMeta,
        ),
      );
    }
    if (data.containsKey('status_bar_mode')) {
      context.handle(
        _statusBarModeMeta,
        statusBarMode.isAcceptableOrUnknown(
          data['status_bar_mode']!,
          _statusBarModeMeta,
        ),
      );
    }
    if (data.containsKey('time_display_mode')) {
      context.handle(
        _timeDisplayModeMeta,
        timeDisplayMode.isAcceptableOrUnknown(
          data['time_display_mode']!,
          _timeDisplayModeMeta,
        ),
      );
    }
    if (data.containsKey('show_chapter_info')) {
      context.handle(
        _showChapterInfoMeta,
        showChapterInfo.isAcceptableOrUnknown(
          data['show_chapter_info']!,
          _showChapterInfoMeta,
        ),
      );
    }
    if (data.containsKey('show_chapter_progress_info')) {
      context.handle(
        _showChapterProgressInfoMeta,
        showChapterProgressInfo.isAcceptableOrUnknown(
          data['show_chapter_progress_info']!,
          _showChapterProgressInfoMeta,
        ),
      );
    }
    if (data.containsKey('show_clock_info')) {
      context.handle(
        _showClockInfoMeta,
        showClockInfo.isAcceptableOrUnknown(
          data['show_clock_info']!,
          _showClockInfoMeta,
        ),
      );
    }
    if (data.containsKey('show_whole_book_progress_info')) {
      context.handle(
        _showWholeBookProgressInfoMeta,
        showWholeBookProgressInfo.isAcceptableOrUnknown(
          data['show_whole_book_progress_info']!,
          _showWholeBookProgressInfoMeta,
        ),
      );
    }
    if (data.containsKey('show_info_divider')) {
      context.handle(
        _showInfoDividerMeta,
        showInfoDivider.isAcceptableOrUnknown(
          data['show_info_divider']!,
          _showInfoDividerMeta,
        ),
      );
    }
    if (data.containsKey('show_top_info_divider')) {
      context.handle(
        _showTopInfoDividerMeta,
        showTopInfoDivider.isAcceptableOrUnknown(
          data['show_top_info_divider']!,
          _showTopInfoDividerMeta,
        ),
      );
    }
    if (data.containsKey('show_bottom_info_divider')) {
      context.handle(
        _showBottomInfoDividerMeta,
        showBottomInfoDivider.isAcceptableOrUnknown(
          data['show_bottom_info_divider']!,
          _showBottomInfoDividerMeta,
        ),
      );
    }
    if (data.containsKey('show_auto_read_minimal_info')) {
      context.handle(
        _showAutoReadMinimalInfoMeta,
        showAutoReadMinimalInfo.isAcceptableOrUnknown(
          data['show_auto_read_minimal_info']!,
          _showAutoReadMinimalInfoMeta,
        ),
      );
    }
    if (data.containsKey('chapter_info_slot')) {
      context.handle(
        _chapterInfoSlotMeta,
        chapterInfoSlot.isAcceptableOrUnknown(
          data['chapter_info_slot']!,
          _chapterInfoSlotMeta,
        ),
      );
    }
    if (data.containsKey('chapter_progress_info_slot')) {
      context.handle(
        _chapterProgressInfoSlotMeta,
        chapterProgressInfoSlot.isAcceptableOrUnknown(
          data['chapter_progress_info_slot']!,
          _chapterProgressInfoSlotMeta,
        ),
      );
    }
    if (data.containsKey('clock_info_slot')) {
      context.handle(
        _clockInfoSlotMeta,
        clockInfoSlot.isAcceptableOrUnknown(
          data['clock_info_slot']!,
          _clockInfoSlotMeta,
        ),
      );
    }
    if (data.containsKey('whole_book_progress_info_slot')) {
      context.handle(
        _wholeBookProgressInfoSlotMeta,
        wholeBookProgressInfoSlot.isAcceptableOrUnknown(
          data['whole_book_progress_info_slot']!,
          _wholeBookProgressInfoSlotMeta,
        ),
      );
    }
    if (data.containsKey('info_divider_slot')) {
      context.handle(
        _infoDividerSlotMeta,
        infoDividerSlot.isAcceptableOrUnknown(
          data['info_divider_slot']!,
          _infoDividerSlotMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {collectionId};
  @override
  ReaderPreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderPreferencesRow(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      fontId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_id'],
      ),
      fontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}font_size'],
      )!,
      letterSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}letter_spacing'],
      )!,
      lineHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_height'],
      )!,
      paragraphSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paragraph_spacing'],
      )!,
      firstLineIndent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}first_line_indent'],
      )!,
      paddingTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}padding_top'],
      )!,
      paddingBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}padding_bottom'],
      )!,
      paddingLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}padding_left'],
      )!,
      paddingRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}padding_right'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      paletteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}palette_id'],
      )!,
      textColorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_color_argb'],
      ),
      backgroundColorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}background_color_argb'],
      ),
      lightTextColorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}light_text_color_argb'],
      ),
      lightBackgroundColorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}light_background_color_argb'],
      ),
      darkTextColorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dark_text_color_argb'],
      ),
      darkBackgroundColorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dark_background_color_argb'],
      ),
      backgroundImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_image_path'],
      ),
      backgroundImageOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}background_image_opacity'],
      )!,
      backgroundOverlayOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}background_overlay_opacity'],
      )!,
      showTopInfoBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_top_info_bar'],
      )!,
      showBottomInfoBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_bottom_info_bar'],
      )!,
      showProgressInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_progress_info'],
      )!,
      showSystemStatusBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_system_status_bar'],
      )!,
      statusBarMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_bar_mode'],
      )!,
      timeDisplayMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_display_mode'],
      )!,
      showChapterInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_chapter_info'],
      )!,
      showChapterProgressInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_chapter_progress_info'],
      )!,
      showClockInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_clock_info'],
      )!,
      showWholeBookProgressInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_whole_book_progress_info'],
      )!,
      showInfoDivider: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_info_divider'],
      )!,
      showTopInfoDivider: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_top_info_divider'],
      )!,
      showBottomInfoDivider: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_bottom_info_divider'],
      )!,
      showAutoReadMinimalInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_auto_read_minimal_info'],
      )!,
      chapterInfoSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_info_slot'],
      )!,
      chapterProgressInfoSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_progress_info_slot'],
      )!,
      clockInfoSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clock_info_slot'],
      )!,
      wholeBookProgressInfoSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whole_book_progress_info_slot'],
      )!,
      infoDividerSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}info_divider_slot'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReaderPreferencesRowsTable createAlias(String alias) {
    return $ReaderPreferencesRowsTable(attachedDatabase, alias);
  }
}

class ReaderPreferencesRow extends DataClass
    implements Insertable<ReaderPreferencesRow> {
  final String collectionId;

  /// Null means the per-book choice is the platform/system default.
  final String? fontId;
  final double fontSize;
  final double letterSpacing;
  final double lineHeight;
  final double paragraphSpacing;
  final double firstLineIndent;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final String themeMode;
  final String paletteId;
  final int? textColorArgb;
  final int? backgroundColorArgb;
  final int? lightTextColorArgb;
  final int? lightBackgroundColorArgb;
  final int? darkTextColorArgb;
  final int? darkBackgroundColorArgb;
  final String? backgroundImagePath;
  final double backgroundImageOpacity;
  final double backgroundOverlayOpacity;
  final bool showTopInfoBar;
  final bool showBottomInfoBar;
  final bool showProgressInfo;
  final bool showSystemStatusBar;
  final String statusBarMode;
  final String timeDisplayMode;
  final bool showChapterInfo;
  final bool showChapterProgressInfo;
  final bool showClockInfo;
  final bool showWholeBookProgressInfo;
  final bool showInfoDivider;
  final bool showTopInfoDivider;
  final bool showBottomInfoDivider;
  final bool showAutoReadMinimalInfo;
  final String chapterInfoSlot;
  final String chapterProgressInfoSlot;
  final String clockInfoSlot;
  final String wholeBookProgressInfoSlot;
  final String infoDividerSlot;
  final DateTime updatedAt;
  const ReaderPreferencesRow({
    required this.collectionId,
    this.fontId,
    required this.fontSize,
    required this.letterSpacing,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
    required this.themeMode,
    required this.paletteId,
    this.textColorArgb,
    this.backgroundColorArgb,
    this.lightTextColorArgb,
    this.lightBackgroundColorArgb,
    this.darkTextColorArgb,
    this.darkBackgroundColorArgb,
    this.backgroundImagePath,
    required this.backgroundImageOpacity,
    required this.backgroundOverlayOpacity,
    required this.showTopInfoBar,
    required this.showBottomInfoBar,
    required this.showProgressInfo,
    required this.showSystemStatusBar,
    required this.statusBarMode,
    required this.timeDisplayMode,
    required this.showChapterInfo,
    required this.showChapterProgressInfo,
    required this.showClockInfo,
    required this.showWholeBookProgressInfo,
    required this.showInfoDivider,
    required this.showTopInfoDivider,
    required this.showBottomInfoDivider,
    required this.showAutoReadMinimalInfo,
    required this.chapterInfoSlot,
    required this.chapterProgressInfoSlot,
    required this.clockInfoSlot,
    required this.wholeBookProgressInfoSlot,
    required this.infoDividerSlot,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    if (!nullToAbsent || fontId != null) {
      map['font_id'] = Variable<String>(fontId);
    }
    map['font_size'] = Variable<double>(fontSize);
    map['letter_spacing'] = Variable<double>(letterSpacing);
    map['line_height'] = Variable<double>(lineHeight);
    map['paragraph_spacing'] = Variable<double>(paragraphSpacing);
    map['first_line_indent'] = Variable<double>(firstLineIndent);
    map['padding_top'] = Variable<double>(paddingTop);
    map['padding_bottom'] = Variable<double>(paddingBottom);
    map['padding_left'] = Variable<double>(paddingLeft);
    map['padding_right'] = Variable<double>(paddingRight);
    map['theme_mode'] = Variable<String>(themeMode);
    map['palette_id'] = Variable<String>(paletteId);
    if (!nullToAbsent || textColorArgb != null) {
      map['text_color_argb'] = Variable<int>(textColorArgb);
    }
    if (!nullToAbsent || backgroundColorArgb != null) {
      map['background_color_argb'] = Variable<int>(backgroundColorArgb);
    }
    if (!nullToAbsent || lightTextColorArgb != null) {
      map['light_text_color_argb'] = Variable<int>(lightTextColorArgb);
    }
    if (!nullToAbsent || lightBackgroundColorArgb != null) {
      map['light_background_color_argb'] = Variable<int>(
        lightBackgroundColorArgb,
      );
    }
    if (!nullToAbsent || darkTextColorArgb != null) {
      map['dark_text_color_argb'] = Variable<int>(darkTextColorArgb);
    }
    if (!nullToAbsent || darkBackgroundColorArgb != null) {
      map['dark_background_color_argb'] = Variable<int>(
        darkBackgroundColorArgb,
      );
    }
    if (!nullToAbsent || backgroundImagePath != null) {
      map['background_image_path'] = Variable<String>(backgroundImagePath);
    }
    map['background_image_opacity'] = Variable<double>(backgroundImageOpacity);
    map['background_overlay_opacity'] = Variable<double>(
      backgroundOverlayOpacity,
    );
    map['show_top_info_bar'] = Variable<bool>(showTopInfoBar);
    map['show_bottom_info_bar'] = Variable<bool>(showBottomInfoBar);
    map['show_progress_info'] = Variable<bool>(showProgressInfo);
    map['show_system_status_bar'] = Variable<bool>(showSystemStatusBar);
    map['status_bar_mode'] = Variable<String>(statusBarMode);
    map['time_display_mode'] = Variable<String>(timeDisplayMode);
    map['show_chapter_info'] = Variable<bool>(showChapterInfo);
    map['show_chapter_progress_info'] = Variable<bool>(showChapterProgressInfo);
    map['show_clock_info'] = Variable<bool>(showClockInfo);
    map['show_whole_book_progress_info'] = Variable<bool>(
      showWholeBookProgressInfo,
    );
    map['show_info_divider'] = Variable<bool>(showInfoDivider);
    map['show_top_info_divider'] = Variable<bool>(showTopInfoDivider);
    map['show_bottom_info_divider'] = Variable<bool>(showBottomInfoDivider);
    map['show_auto_read_minimal_info'] = Variable<bool>(
      showAutoReadMinimalInfo,
    );
    map['chapter_info_slot'] = Variable<String>(chapterInfoSlot);
    map['chapter_progress_info_slot'] = Variable<String>(
      chapterProgressInfoSlot,
    );
    map['clock_info_slot'] = Variable<String>(clockInfoSlot);
    map['whole_book_progress_info_slot'] = Variable<String>(
      wholeBookProgressInfoSlot,
    );
    map['info_divider_slot'] = Variable<String>(infoDividerSlot);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReaderPreferencesRowsCompanion toCompanion(bool nullToAbsent) {
    return ReaderPreferencesRowsCompanion(
      collectionId: Value(collectionId),
      fontId: fontId == null && nullToAbsent
          ? const Value.absent()
          : Value(fontId),
      fontSize: Value(fontSize),
      letterSpacing: Value(letterSpacing),
      lineHeight: Value(lineHeight),
      paragraphSpacing: Value(paragraphSpacing),
      firstLineIndent: Value(firstLineIndent),
      paddingTop: Value(paddingTop),
      paddingBottom: Value(paddingBottom),
      paddingLeft: Value(paddingLeft),
      paddingRight: Value(paddingRight),
      themeMode: Value(themeMode),
      paletteId: Value(paletteId),
      textColorArgb: textColorArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(textColorArgb),
      backgroundColorArgb: backgroundColorArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundColorArgb),
      lightTextColorArgb: lightTextColorArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(lightTextColorArgb),
      lightBackgroundColorArgb: lightBackgroundColorArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(lightBackgroundColorArgb),
      darkTextColorArgb: darkTextColorArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(darkTextColorArgb),
      darkBackgroundColorArgb: darkBackgroundColorArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(darkBackgroundColorArgb),
      backgroundImagePath: backgroundImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundImagePath),
      backgroundImageOpacity: Value(backgroundImageOpacity),
      backgroundOverlayOpacity: Value(backgroundOverlayOpacity),
      showTopInfoBar: Value(showTopInfoBar),
      showBottomInfoBar: Value(showBottomInfoBar),
      showProgressInfo: Value(showProgressInfo),
      showSystemStatusBar: Value(showSystemStatusBar),
      statusBarMode: Value(statusBarMode),
      timeDisplayMode: Value(timeDisplayMode),
      showChapterInfo: Value(showChapterInfo),
      showChapterProgressInfo: Value(showChapterProgressInfo),
      showClockInfo: Value(showClockInfo),
      showWholeBookProgressInfo: Value(showWholeBookProgressInfo),
      showInfoDivider: Value(showInfoDivider),
      showTopInfoDivider: Value(showTopInfoDivider),
      showBottomInfoDivider: Value(showBottomInfoDivider),
      showAutoReadMinimalInfo: Value(showAutoReadMinimalInfo),
      chapterInfoSlot: Value(chapterInfoSlot),
      chapterProgressInfoSlot: Value(chapterProgressInfoSlot),
      clockInfoSlot: Value(clockInfoSlot),
      wholeBookProgressInfoSlot: Value(wholeBookProgressInfoSlot),
      infoDividerSlot: Value(infoDividerSlot),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReaderPreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderPreferencesRow(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      fontId: serializer.fromJson<String?>(json['fontId']),
      fontSize: serializer.fromJson<double>(json['fontSize']),
      letterSpacing: serializer.fromJson<double>(json['letterSpacing']),
      lineHeight: serializer.fromJson<double>(json['lineHeight']),
      paragraphSpacing: serializer.fromJson<double>(json['paragraphSpacing']),
      firstLineIndent: serializer.fromJson<double>(json['firstLineIndent']),
      paddingTop: serializer.fromJson<double>(json['paddingTop']),
      paddingBottom: serializer.fromJson<double>(json['paddingBottom']),
      paddingLeft: serializer.fromJson<double>(json['paddingLeft']),
      paddingRight: serializer.fromJson<double>(json['paddingRight']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      paletteId: serializer.fromJson<String>(json['paletteId']),
      textColorArgb: serializer.fromJson<int?>(json['textColorArgb']),
      backgroundColorArgb: serializer.fromJson<int?>(
        json['backgroundColorArgb'],
      ),
      lightTextColorArgb: serializer.fromJson<int?>(json['lightTextColorArgb']),
      lightBackgroundColorArgb: serializer.fromJson<int?>(
        json['lightBackgroundColorArgb'],
      ),
      darkTextColorArgb: serializer.fromJson<int?>(json['darkTextColorArgb']),
      darkBackgroundColorArgb: serializer.fromJson<int?>(
        json['darkBackgroundColorArgb'],
      ),
      backgroundImagePath: serializer.fromJson<String?>(
        json['backgroundImagePath'],
      ),
      backgroundImageOpacity: serializer.fromJson<double>(
        json['backgroundImageOpacity'],
      ),
      backgroundOverlayOpacity: serializer.fromJson<double>(
        json['backgroundOverlayOpacity'],
      ),
      showTopInfoBar: serializer.fromJson<bool>(json['showTopInfoBar']),
      showBottomInfoBar: serializer.fromJson<bool>(json['showBottomInfoBar']),
      showProgressInfo: serializer.fromJson<bool>(json['showProgressInfo']),
      showSystemStatusBar: serializer.fromJson<bool>(
        json['showSystemStatusBar'],
      ),
      statusBarMode: serializer.fromJson<String>(json['statusBarMode']),
      timeDisplayMode: serializer.fromJson<String>(json['timeDisplayMode']),
      showChapterInfo: serializer.fromJson<bool>(json['showChapterInfo']),
      showChapterProgressInfo: serializer.fromJson<bool>(
        json['showChapterProgressInfo'],
      ),
      showClockInfo: serializer.fromJson<bool>(json['showClockInfo']),
      showWholeBookProgressInfo: serializer.fromJson<bool>(
        json['showWholeBookProgressInfo'],
      ),
      showInfoDivider: serializer.fromJson<bool>(json['showInfoDivider']),
      showTopInfoDivider: serializer.fromJson<bool>(json['showTopInfoDivider']),
      showBottomInfoDivider: serializer.fromJson<bool>(
        json['showBottomInfoDivider'],
      ),
      showAutoReadMinimalInfo: serializer.fromJson<bool>(
        json['showAutoReadMinimalInfo'],
      ),
      chapterInfoSlot: serializer.fromJson<String>(json['chapterInfoSlot']),
      chapterProgressInfoSlot: serializer.fromJson<String>(
        json['chapterProgressInfoSlot'],
      ),
      clockInfoSlot: serializer.fromJson<String>(json['clockInfoSlot']),
      wholeBookProgressInfoSlot: serializer.fromJson<String>(
        json['wholeBookProgressInfoSlot'],
      ),
      infoDividerSlot: serializer.fromJson<String>(json['infoDividerSlot']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'fontId': serializer.toJson<String?>(fontId),
      'fontSize': serializer.toJson<double>(fontSize),
      'letterSpacing': serializer.toJson<double>(letterSpacing),
      'lineHeight': serializer.toJson<double>(lineHeight),
      'paragraphSpacing': serializer.toJson<double>(paragraphSpacing),
      'firstLineIndent': serializer.toJson<double>(firstLineIndent),
      'paddingTop': serializer.toJson<double>(paddingTop),
      'paddingBottom': serializer.toJson<double>(paddingBottom),
      'paddingLeft': serializer.toJson<double>(paddingLeft),
      'paddingRight': serializer.toJson<double>(paddingRight),
      'themeMode': serializer.toJson<String>(themeMode),
      'paletteId': serializer.toJson<String>(paletteId),
      'textColorArgb': serializer.toJson<int?>(textColorArgb),
      'backgroundColorArgb': serializer.toJson<int?>(backgroundColorArgb),
      'lightTextColorArgb': serializer.toJson<int?>(lightTextColorArgb),
      'lightBackgroundColorArgb': serializer.toJson<int?>(
        lightBackgroundColorArgb,
      ),
      'darkTextColorArgb': serializer.toJson<int?>(darkTextColorArgb),
      'darkBackgroundColorArgb': serializer.toJson<int?>(
        darkBackgroundColorArgb,
      ),
      'backgroundImagePath': serializer.toJson<String?>(backgroundImagePath),
      'backgroundImageOpacity': serializer.toJson<double>(
        backgroundImageOpacity,
      ),
      'backgroundOverlayOpacity': serializer.toJson<double>(
        backgroundOverlayOpacity,
      ),
      'showTopInfoBar': serializer.toJson<bool>(showTopInfoBar),
      'showBottomInfoBar': serializer.toJson<bool>(showBottomInfoBar),
      'showProgressInfo': serializer.toJson<bool>(showProgressInfo),
      'showSystemStatusBar': serializer.toJson<bool>(showSystemStatusBar),
      'statusBarMode': serializer.toJson<String>(statusBarMode),
      'timeDisplayMode': serializer.toJson<String>(timeDisplayMode),
      'showChapterInfo': serializer.toJson<bool>(showChapterInfo),
      'showChapterProgressInfo': serializer.toJson<bool>(
        showChapterProgressInfo,
      ),
      'showClockInfo': serializer.toJson<bool>(showClockInfo),
      'showWholeBookProgressInfo': serializer.toJson<bool>(
        showWholeBookProgressInfo,
      ),
      'showInfoDivider': serializer.toJson<bool>(showInfoDivider),
      'showTopInfoDivider': serializer.toJson<bool>(showTopInfoDivider),
      'showBottomInfoDivider': serializer.toJson<bool>(showBottomInfoDivider),
      'showAutoReadMinimalInfo': serializer.toJson<bool>(
        showAutoReadMinimalInfo,
      ),
      'chapterInfoSlot': serializer.toJson<String>(chapterInfoSlot),
      'chapterProgressInfoSlot': serializer.toJson<String>(
        chapterProgressInfoSlot,
      ),
      'clockInfoSlot': serializer.toJson<String>(clockInfoSlot),
      'wholeBookProgressInfoSlot': serializer.toJson<String>(
        wholeBookProgressInfoSlot,
      ),
      'infoDividerSlot': serializer.toJson<String>(infoDividerSlot),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReaderPreferencesRow copyWith({
    String? collectionId,
    Value<String?> fontId = const Value.absent(),
    double? fontSize,
    double? letterSpacing,
    double? lineHeight,
    double? paragraphSpacing,
    double? firstLineIndent,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    String? themeMode,
    String? paletteId,
    Value<int?> textColorArgb = const Value.absent(),
    Value<int?> backgroundColorArgb = const Value.absent(),
    Value<int?> lightTextColorArgb = const Value.absent(),
    Value<int?> lightBackgroundColorArgb = const Value.absent(),
    Value<int?> darkTextColorArgb = const Value.absent(),
    Value<int?> darkBackgroundColorArgb = const Value.absent(),
    Value<String?> backgroundImagePath = const Value.absent(),
    double? backgroundImageOpacity,
    double? backgroundOverlayOpacity,
    bool? showTopInfoBar,
    bool? showBottomInfoBar,
    bool? showProgressInfo,
    bool? showSystemStatusBar,
    String? statusBarMode,
    String? timeDisplayMode,
    bool? showChapterInfo,
    bool? showChapterProgressInfo,
    bool? showClockInfo,
    bool? showWholeBookProgressInfo,
    bool? showInfoDivider,
    bool? showTopInfoDivider,
    bool? showBottomInfoDivider,
    bool? showAutoReadMinimalInfo,
    String? chapterInfoSlot,
    String? chapterProgressInfoSlot,
    String? clockInfoSlot,
    String? wholeBookProgressInfoSlot,
    String? infoDividerSlot,
    DateTime? updatedAt,
  }) => ReaderPreferencesRow(
    collectionId: collectionId ?? this.collectionId,
    fontId: fontId.present ? fontId.value : this.fontId,
    fontSize: fontSize ?? this.fontSize,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    lineHeight: lineHeight ?? this.lineHeight,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    firstLineIndent: firstLineIndent ?? this.firstLineIndent,
    paddingTop: paddingTop ?? this.paddingTop,
    paddingBottom: paddingBottom ?? this.paddingBottom,
    paddingLeft: paddingLeft ?? this.paddingLeft,
    paddingRight: paddingRight ?? this.paddingRight,
    themeMode: themeMode ?? this.themeMode,
    paletteId: paletteId ?? this.paletteId,
    textColorArgb: textColorArgb.present
        ? textColorArgb.value
        : this.textColorArgb,
    backgroundColorArgb: backgroundColorArgb.present
        ? backgroundColorArgb.value
        : this.backgroundColorArgb,
    lightTextColorArgb: lightTextColorArgb.present
        ? lightTextColorArgb.value
        : this.lightTextColorArgb,
    lightBackgroundColorArgb: lightBackgroundColorArgb.present
        ? lightBackgroundColorArgb.value
        : this.lightBackgroundColorArgb,
    darkTextColorArgb: darkTextColorArgb.present
        ? darkTextColorArgb.value
        : this.darkTextColorArgb,
    darkBackgroundColorArgb: darkBackgroundColorArgb.present
        ? darkBackgroundColorArgb.value
        : this.darkBackgroundColorArgb,
    backgroundImagePath: backgroundImagePath.present
        ? backgroundImagePath.value
        : this.backgroundImagePath,
    backgroundImageOpacity:
        backgroundImageOpacity ?? this.backgroundImageOpacity,
    backgroundOverlayOpacity:
        backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
    showTopInfoBar: showTopInfoBar ?? this.showTopInfoBar,
    showBottomInfoBar: showBottomInfoBar ?? this.showBottomInfoBar,
    showProgressInfo: showProgressInfo ?? this.showProgressInfo,
    showSystemStatusBar: showSystemStatusBar ?? this.showSystemStatusBar,
    statusBarMode: statusBarMode ?? this.statusBarMode,
    timeDisplayMode: timeDisplayMode ?? this.timeDisplayMode,
    showChapterInfo: showChapterInfo ?? this.showChapterInfo,
    showChapterProgressInfo:
        showChapterProgressInfo ?? this.showChapterProgressInfo,
    showClockInfo: showClockInfo ?? this.showClockInfo,
    showWholeBookProgressInfo:
        showWholeBookProgressInfo ?? this.showWholeBookProgressInfo,
    showInfoDivider: showInfoDivider ?? this.showInfoDivider,
    showTopInfoDivider: showTopInfoDivider ?? this.showTopInfoDivider,
    showBottomInfoDivider: showBottomInfoDivider ?? this.showBottomInfoDivider,
    showAutoReadMinimalInfo:
        showAutoReadMinimalInfo ?? this.showAutoReadMinimalInfo,
    chapterInfoSlot: chapterInfoSlot ?? this.chapterInfoSlot,
    chapterProgressInfoSlot:
        chapterProgressInfoSlot ?? this.chapterProgressInfoSlot,
    clockInfoSlot: clockInfoSlot ?? this.clockInfoSlot,
    wholeBookProgressInfoSlot:
        wholeBookProgressInfoSlot ?? this.wholeBookProgressInfoSlot,
    infoDividerSlot: infoDividerSlot ?? this.infoDividerSlot,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReaderPreferencesRow copyWithCompanion(ReaderPreferencesRowsCompanion data) {
    return ReaderPreferencesRow(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      fontId: data.fontId.present ? data.fontId.value : this.fontId,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      letterSpacing: data.letterSpacing.present
          ? data.letterSpacing.value
          : this.letterSpacing,
      lineHeight: data.lineHeight.present
          ? data.lineHeight.value
          : this.lineHeight,
      paragraphSpacing: data.paragraphSpacing.present
          ? data.paragraphSpacing.value
          : this.paragraphSpacing,
      firstLineIndent: data.firstLineIndent.present
          ? data.firstLineIndent.value
          : this.firstLineIndent,
      paddingTop: data.paddingTop.present
          ? data.paddingTop.value
          : this.paddingTop,
      paddingBottom: data.paddingBottom.present
          ? data.paddingBottom.value
          : this.paddingBottom,
      paddingLeft: data.paddingLeft.present
          ? data.paddingLeft.value
          : this.paddingLeft,
      paddingRight: data.paddingRight.present
          ? data.paddingRight.value
          : this.paddingRight,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      paletteId: data.paletteId.present ? data.paletteId.value : this.paletteId,
      textColorArgb: data.textColorArgb.present
          ? data.textColorArgb.value
          : this.textColorArgb,
      backgroundColorArgb: data.backgroundColorArgb.present
          ? data.backgroundColorArgb.value
          : this.backgroundColorArgb,
      lightTextColorArgb: data.lightTextColorArgb.present
          ? data.lightTextColorArgb.value
          : this.lightTextColorArgb,
      lightBackgroundColorArgb: data.lightBackgroundColorArgb.present
          ? data.lightBackgroundColorArgb.value
          : this.lightBackgroundColorArgb,
      darkTextColorArgb: data.darkTextColorArgb.present
          ? data.darkTextColorArgb.value
          : this.darkTextColorArgb,
      darkBackgroundColorArgb: data.darkBackgroundColorArgb.present
          ? data.darkBackgroundColorArgb.value
          : this.darkBackgroundColorArgb,
      backgroundImagePath: data.backgroundImagePath.present
          ? data.backgroundImagePath.value
          : this.backgroundImagePath,
      backgroundImageOpacity: data.backgroundImageOpacity.present
          ? data.backgroundImageOpacity.value
          : this.backgroundImageOpacity,
      backgroundOverlayOpacity: data.backgroundOverlayOpacity.present
          ? data.backgroundOverlayOpacity.value
          : this.backgroundOverlayOpacity,
      showTopInfoBar: data.showTopInfoBar.present
          ? data.showTopInfoBar.value
          : this.showTopInfoBar,
      showBottomInfoBar: data.showBottomInfoBar.present
          ? data.showBottomInfoBar.value
          : this.showBottomInfoBar,
      showProgressInfo: data.showProgressInfo.present
          ? data.showProgressInfo.value
          : this.showProgressInfo,
      showSystemStatusBar: data.showSystemStatusBar.present
          ? data.showSystemStatusBar.value
          : this.showSystemStatusBar,
      statusBarMode: data.statusBarMode.present
          ? data.statusBarMode.value
          : this.statusBarMode,
      timeDisplayMode: data.timeDisplayMode.present
          ? data.timeDisplayMode.value
          : this.timeDisplayMode,
      showChapterInfo: data.showChapterInfo.present
          ? data.showChapterInfo.value
          : this.showChapterInfo,
      showChapterProgressInfo: data.showChapterProgressInfo.present
          ? data.showChapterProgressInfo.value
          : this.showChapterProgressInfo,
      showClockInfo: data.showClockInfo.present
          ? data.showClockInfo.value
          : this.showClockInfo,
      showWholeBookProgressInfo: data.showWholeBookProgressInfo.present
          ? data.showWholeBookProgressInfo.value
          : this.showWholeBookProgressInfo,
      showInfoDivider: data.showInfoDivider.present
          ? data.showInfoDivider.value
          : this.showInfoDivider,
      showTopInfoDivider: data.showTopInfoDivider.present
          ? data.showTopInfoDivider.value
          : this.showTopInfoDivider,
      showBottomInfoDivider: data.showBottomInfoDivider.present
          ? data.showBottomInfoDivider.value
          : this.showBottomInfoDivider,
      showAutoReadMinimalInfo: data.showAutoReadMinimalInfo.present
          ? data.showAutoReadMinimalInfo.value
          : this.showAutoReadMinimalInfo,
      chapterInfoSlot: data.chapterInfoSlot.present
          ? data.chapterInfoSlot.value
          : this.chapterInfoSlot,
      chapterProgressInfoSlot: data.chapterProgressInfoSlot.present
          ? data.chapterProgressInfoSlot.value
          : this.chapterProgressInfoSlot,
      clockInfoSlot: data.clockInfoSlot.present
          ? data.clockInfoSlot.value
          : this.clockInfoSlot,
      wholeBookProgressInfoSlot: data.wholeBookProgressInfoSlot.present
          ? data.wholeBookProgressInfoSlot.value
          : this.wholeBookProgressInfoSlot,
      infoDividerSlot: data.infoDividerSlot.present
          ? data.infoDividerSlot.value
          : this.infoDividerSlot,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderPreferencesRow(')
          ..write('collectionId: $collectionId, ')
          ..write('fontId: $fontId, ')
          ..write('fontSize: $fontSize, ')
          ..write('letterSpacing: $letterSpacing, ')
          ..write('lineHeight: $lineHeight, ')
          ..write('paragraphSpacing: $paragraphSpacing, ')
          ..write('firstLineIndent: $firstLineIndent, ')
          ..write('paddingTop: $paddingTop, ')
          ..write('paddingBottom: $paddingBottom, ')
          ..write('paddingLeft: $paddingLeft, ')
          ..write('paddingRight: $paddingRight, ')
          ..write('themeMode: $themeMode, ')
          ..write('paletteId: $paletteId, ')
          ..write('textColorArgb: $textColorArgb, ')
          ..write('backgroundColorArgb: $backgroundColorArgb, ')
          ..write('lightTextColorArgb: $lightTextColorArgb, ')
          ..write('lightBackgroundColorArgb: $lightBackgroundColorArgb, ')
          ..write('darkTextColorArgb: $darkTextColorArgb, ')
          ..write('darkBackgroundColorArgb: $darkBackgroundColorArgb, ')
          ..write('backgroundImagePath: $backgroundImagePath, ')
          ..write('backgroundImageOpacity: $backgroundImageOpacity, ')
          ..write('backgroundOverlayOpacity: $backgroundOverlayOpacity, ')
          ..write('showTopInfoBar: $showTopInfoBar, ')
          ..write('showBottomInfoBar: $showBottomInfoBar, ')
          ..write('showProgressInfo: $showProgressInfo, ')
          ..write('showSystemStatusBar: $showSystemStatusBar, ')
          ..write('statusBarMode: $statusBarMode, ')
          ..write('timeDisplayMode: $timeDisplayMode, ')
          ..write('showChapterInfo: $showChapterInfo, ')
          ..write('showChapterProgressInfo: $showChapterProgressInfo, ')
          ..write('showClockInfo: $showClockInfo, ')
          ..write('showWholeBookProgressInfo: $showWholeBookProgressInfo, ')
          ..write('showInfoDivider: $showInfoDivider, ')
          ..write('showTopInfoDivider: $showTopInfoDivider, ')
          ..write('showBottomInfoDivider: $showBottomInfoDivider, ')
          ..write('showAutoReadMinimalInfo: $showAutoReadMinimalInfo, ')
          ..write('chapterInfoSlot: $chapterInfoSlot, ')
          ..write('chapterProgressInfoSlot: $chapterProgressInfoSlot, ')
          ..write('clockInfoSlot: $clockInfoSlot, ')
          ..write('wholeBookProgressInfoSlot: $wholeBookProgressInfoSlot, ')
          ..write('infoDividerSlot: $infoDividerSlot, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    collectionId,
    fontId,
    fontSize,
    letterSpacing,
    lineHeight,
    paragraphSpacing,
    firstLineIndent,
    paddingTop,
    paddingBottom,
    paddingLeft,
    paddingRight,
    themeMode,
    paletteId,
    textColorArgb,
    backgroundColorArgb,
    lightTextColorArgb,
    lightBackgroundColorArgb,
    darkTextColorArgb,
    darkBackgroundColorArgb,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundOverlayOpacity,
    showTopInfoBar,
    showBottomInfoBar,
    showProgressInfo,
    showSystemStatusBar,
    statusBarMode,
    timeDisplayMode,
    showChapterInfo,
    showChapterProgressInfo,
    showClockInfo,
    showWholeBookProgressInfo,
    showInfoDivider,
    showTopInfoDivider,
    showBottomInfoDivider,
    showAutoReadMinimalInfo,
    chapterInfoSlot,
    chapterProgressInfoSlot,
    clockInfoSlot,
    wholeBookProgressInfoSlot,
    infoDividerSlot,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderPreferencesRow &&
          other.collectionId == this.collectionId &&
          other.fontId == this.fontId &&
          other.fontSize == this.fontSize &&
          other.letterSpacing == this.letterSpacing &&
          other.lineHeight == this.lineHeight &&
          other.paragraphSpacing == this.paragraphSpacing &&
          other.firstLineIndent == this.firstLineIndent &&
          other.paddingTop == this.paddingTop &&
          other.paddingBottom == this.paddingBottom &&
          other.paddingLeft == this.paddingLeft &&
          other.paddingRight == this.paddingRight &&
          other.themeMode == this.themeMode &&
          other.paletteId == this.paletteId &&
          other.textColorArgb == this.textColorArgb &&
          other.backgroundColorArgb == this.backgroundColorArgb &&
          other.lightTextColorArgb == this.lightTextColorArgb &&
          other.lightBackgroundColorArgb == this.lightBackgroundColorArgb &&
          other.darkTextColorArgb == this.darkTextColorArgb &&
          other.darkBackgroundColorArgb == this.darkBackgroundColorArgb &&
          other.backgroundImagePath == this.backgroundImagePath &&
          other.backgroundImageOpacity == this.backgroundImageOpacity &&
          other.backgroundOverlayOpacity == this.backgroundOverlayOpacity &&
          other.showTopInfoBar == this.showTopInfoBar &&
          other.showBottomInfoBar == this.showBottomInfoBar &&
          other.showProgressInfo == this.showProgressInfo &&
          other.showSystemStatusBar == this.showSystemStatusBar &&
          other.statusBarMode == this.statusBarMode &&
          other.timeDisplayMode == this.timeDisplayMode &&
          other.showChapterInfo == this.showChapterInfo &&
          other.showChapterProgressInfo == this.showChapterProgressInfo &&
          other.showClockInfo == this.showClockInfo &&
          other.showWholeBookProgressInfo == this.showWholeBookProgressInfo &&
          other.showInfoDivider == this.showInfoDivider &&
          other.showTopInfoDivider == this.showTopInfoDivider &&
          other.showBottomInfoDivider == this.showBottomInfoDivider &&
          other.showAutoReadMinimalInfo == this.showAutoReadMinimalInfo &&
          other.chapterInfoSlot == this.chapterInfoSlot &&
          other.chapterProgressInfoSlot == this.chapterProgressInfoSlot &&
          other.clockInfoSlot == this.clockInfoSlot &&
          other.wholeBookProgressInfoSlot == this.wholeBookProgressInfoSlot &&
          other.infoDividerSlot == this.infoDividerSlot &&
          other.updatedAt == this.updatedAt);
}

class ReaderPreferencesRowsCompanion
    extends UpdateCompanion<ReaderPreferencesRow> {
  final Value<String> collectionId;
  final Value<String?> fontId;
  final Value<double> fontSize;
  final Value<double> letterSpacing;
  final Value<double> lineHeight;
  final Value<double> paragraphSpacing;
  final Value<double> firstLineIndent;
  final Value<double> paddingTop;
  final Value<double> paddingBottom;
  final Value<double> paddingLeft;
  final Value<double> paddingRight;
  final Value<String> themeMode;
  final Value<String> paletteId;
  final Value<int?> textColorArgb;
  final Value<int?> backgroundColorArgb;
  final Value<int?> lightTextColorArgb;
  final Value<int?> lightBackgroundColorArgb;
  final Value<int?> darkTextColorArgb;
  final Value<int?> darkBackgroundColorArgb;
  final Value<String?> backgroundImagePath;
  final Value<double> backgroundImageOpacity;
  final Value<double> backgroundOverlayOpacity;
  final Value<bool> showTopInfoBar;
  final Value<bool> showBottomInfoBar;
  final Value<bool> showProgressInfo;
  final Value<bool> showSystemStatusBar;
  final Value<String> statusBarMode;
  final Value<String> timeDisplayMode;
  final Value<bool> showChapterInfo;
  final Value<bool> showChapterProgressInfo;
  final Value<bool> showClockInfo;
  final Value<bool> showWholeBookProgressInfo;
  final Value<bool> showInfoDivider;
  final Value<bool> showTopInfoDivider;
  final Value<bool> showBottomInfoDivider;
  final Value<bool> showAutoReadMinimalInfo;
  final Value<String> chapterInfoSlot;
  final Value<String> chapterProgressInfoSlot;
  final Value<String> clockInfoSlot;
  final Value<String> wholeBookProgressInfoSlot;
  final Value<String> infoDividerSlot;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReaderPreferencesRowsCompanion({
    this.collectionId = const Value.absent(),
    this.fontId = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.letterSpacing = const Value.absent(),
    this.lineHeight = const Value.absent(),
    this.paragraphSpacing = const Value.absent(),
    this.firstLineIndent = const Value.absent(),
    this.paddingTop = const Value.absent(),
    this.paddingBottom = const Value.absent(),
    this.paddingLeft = const Value.absent(),
    this.paddingRight = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.paletteId = const Value.absent(),
    this.textColorArgb = const Value.absent(),
    this.backgroundColorArgb = const Value.absent(),
    this.lightTextColorArgb = const Value.absent(),
    this.lightBackgroundColorArgb = const Value.absent(),
    this.darkTextColorArgb = const Value.absent(),
    this.darkBackgroundColorArgb = const Value.absent(),
    this.backgroundImagePath = const Value.absent(),
    this.backgroundImageOpacity = const Value.absent(),
    this.backgroundOverlayOpacity = const Value.absent(),
    this.showTopInfoBar = const Value.absent(),
    this.showBottomInfoBar = const Value.absent(),
    this.showProgressInfo = const Value.absent(),
    this.showSystemStatusBar = const Value.absent(),
    this.statusBarMode = const Value.absent(),
    this.timeDisplayMode = const Value.absent(),
    this.showChapterInfo = const Value.absent(),
    this.showChapterProgressInfo = const Value.absent(),
    this.showClockInfo = const Value.absent(),
    this.showWholeBookProgressInfo = const Value.absent(),
    this.showInfoDivider = const Value.absent(),
    this.showTopInfoDivider = const Value.absent(),
    this.showBottomInfoDivider = const Value.absent(),
    this.showAutoReadMinimalInfo = const Value.absent(),
    this.chapterInfoSlot = const Value.absent(),
    this.chapterProgressInfoSlot = const Value.absent(),
    this.clockInfoSlot = const Value.absent(),
    this.wholeBookProgressInfoSlot = const Value.absent(),
    this.infoDividerSlot = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderPreferencesRowsCompanion.insert({
    required String collectionId,
    this.fontId = const Value.absent(),
    required double fontSize,
    required double letterSpacing,
    required double lineHeight,
    required double paragraphSpacing,
    required double firstLineIndent,
    required double paddingTop,
    required double paddingBottom,
    required double paddingLeft,
    required double paddingRight,
    required String themeMode,
    this.paletteId = const Value.absent(),
    this.textColorArgb = const Value.absent(),
    this.backgroundColorArgb = const Value.absent(),
    this.lightTextColorArgb = const Value.absent(),
    this.lightBackgroundColorArgb = const Value.absent(),
    this.darkTextColorArgb = const Value.absent(),
    this.darkBackgroundColorArgb = const Value.absent(),
    this.backgroundImagePath = const Value.absent(),
    this.backgroundImageOpacity = const Value.absent(),
    this.backgroundOverlayOpacity = const Value.absent(),
    this.showTopInfoBar = const Value.absent(),
    this.showBottomInfoBar = const Value.absent(),
    this.showProgressInfo = const Value.absent(),
    this.showSystemStatusBar = const Value.absent(),
    this.statusBarMode = const Value.absent(),
    this.timeDisplayMode = const Value.absent(),
    this.showChapterInfo = const Value.absent(),
    this.showChapterProgressInfo = const Value.absent(),
    this.showClockInfo = const Value.absent(),
    this.showWholeBookProgressInfo = const Value.absent(),
    this.showInfoDivider = const Value.absent(),
    this.showTopInfoDivider = const Value.absent(),
    this.showBottomInfoDivider = const Value.absent(),
    this.showAutoReadMinimalInfo = const Value.absent(),
    this.chapterInfoSlot = const Value.absent(),
    this.chapterProgressInfoSlot = const Value.absent(),
    this.clockInfoSlot = const Value.absent(),
    this.wholeBookProgressInfoSlot = const Value.absent(),
    this.infoDividerSlot = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       fontSize = Value(fontSize),
       letterSpacing = Value(letterSpacing),
       lineHeight = Value(lineHeight),
       paragraphSpacing = Value(paragraphSpacing),
       firstLineIndent = Value(firstLineIndent),
       paddingTop = Value(paddingTop),
       paddingBottom = Value(paddingBottom),
       paddingLeft = Value(paddingLeft),
       paddingRight = Value(paddingRight),
       themeMode = Value(themeMode),
       updatedAt = Value(updatedAt);
  static Insertable<ReaderPreferencesRow> custom({
    Expression<String>? collectionId,
    Expression<String>? fontId,
    Expression<double>? fontSize,
    Expression<double>? letterSpacing,
    Expression<double>? lineHeight,
    Expression<double>? paragraphSpacing,
    Expression<double>? firstLineIndent,
    Expression<double>? paddingTop,
    Expression<double>? paddingBottom,
    Expression<double>? paddingLeft,
    Expression<double>? paddingRight,
    Expression<String>? themeMode,
    Expression<String>? paletteId,
    Expression<int>? textColorArgb,
    Expression<int>? backgroundColorArgb,
    Expression<int>? lightTextColorArgb,
    Expression<int>? lightBackgroundColorArgb,
    Expression<int>? darkTextColorArgb,
    Expression<int>? darkBackgroundColorArgb,
    Expression<String>? backgroundImagePath,
    Expression<double>? backgroundImageOpacity,
    Expression<double>? backgroundOverlayOpacity,
    Expression<bool>? showTopInfoBar,
    Expression<bool>? showBottomInfoBar,
    Expression<bool>? showProgressInfo,
    Expression<bool>? showSystemStatusBar,
    Expression<String>? statusBarMode,
    Expression<String>? timeDisplayMode,
    Expression<bool>? showChapterInfo,
    Expression<bool>? showChapterProgressInfo,
    Expression<bool>? showClockInfo,
    Expression<bool>? showWholeBookProgressInfo,
    Expression<bool>? showInfoDivider,
    Expression<bool>? showTopInfoDivider,
    Expression<bool>? showBottomInfoDivider,
    Expression<bool>? showAutoReadMinimalInfo,
    Expression<String>? chapterInfoSlot,
    Expression<String>? chapterProgressInfoSlot,
    Expression<String>? clockInfoSlot,
    Expression<String>? wholeBookProgressInfoSlot,
    Expression<String>? infoDividerSlot,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (fontId != null) 'font_id': fontId,
      if (fontSize != null) 'font_size': fontSize,
      if (letterSpacing != null) 'letter_spacing': letterSpacing,
      if (lineHeight != null) 'line_height': lineHeight,
      if (paragraphSpacing != null) 'paragraph_spacing': paragraphSpacing,
      if (firstLineIndent != null) 'first_line_indent': firstLineIndent,
      if (paddingTop != null) 'padding_top': paddingTop,
      if (paddingBottom != null) 'padding_bottom': paddingBottom,
      if (paddingLeft != null) 'padding_left': paddingLeft,
      if (paddingRight != null) 'padding_right': paddingRight,
      if (themeMode != null) 'theme_mode': themeMode,
      if (paletteId != null) 'palette_id': paletteId,
      if (textColorArgb != null) 'text_color_argb': textColorArgb,
      if (backgroundColorArgb != null)
        'background_color_argb': backgroundColorArgb,
      if (lightTextColorArgb != null)
        'light_text_color_argb': lightTextColorArgb,
      if (lightBackgroundColorArgb != null)
        'light_background_color_argb': lightBackgroundColorArgb,
      if (darkTextColorArgb != null) 'dark_text_color_argb': darkTextColorArgb,
      if (darkBackgroundColorArgb != null)
        'dark_background_color_argb': darkBackgroundColorArgb,
      if (backgroundImagePath != null)
        'background_image_path': backgroundImagePath,
      if (backgroundImageOpacity != null)
        'background_image_opacity': backgroundImageOpacity,
      if (backgroundOverlayOpacity != null)
        'background_overlay_opacity': backgroundOverlayOpacity,
      if (showTopInfoBar != null) 'show_top_info_bar': showTopInfoBar,
      if (showBottomInfoBar != null) 'show_bottom_info_bar': showBottomInfoBar,
      if (showProgressInfo != null) 'show_progress_info': showProgressInfo,
      if (showSystemStatusBar != null)
        'show_system_status_bar': showSystemStatusBar,
      if (statusBarMode != null) 'status_bar_mode': statusBarMode,
      if (timeDisplayMode != null) 'time_display_mode': timeDisplayMode,
      if (showChapterInfo != null) 'show_chapter_info': showChapterInfo,
      if (showChapterProgressInfo != null)
        'show_chapter_progress_info': showChapterProgressInfo,
      if (showClockInfo != null) 'show_clock_info': showClockInfo,
      if (showWholeBookProgressInfo != null)
        'show_whole_book_progress_info': showWholeBookProgressInfo,
      if (showInfoDivider != null) 'show_info_divider': showInfoDivider,
      if (showTopInfoDivider != null)
        'show_top_info_divider': showTopInfoDivider,
      if (showBottomInfoDivider != null)
        'show_bottom_info_divider': showBottomInfoDivider,
      if (showAutoReadMinimalInfo != null)
        'show_auto_read_minimal_info': showAutoReadMinimalInfo,
      if (chapterInfoSlot != null) 'chapter_info_slot': chapterInfoSlot,
      if (chapterProgressInfoSlot != null)
        'chapter_progress_info_slot': chapterProgressInfoSlot,
      if (clockInfoSlot != null) 'clock_info_slot': clockInfoSlot,
      if (wholeBookProgressInfoSlot != null)
        'whole_book_progress_info_slot': wholeBookProgressInfoSlot,
      if (infoDividerSlot != null) 'info_divider_slot': infoDividerSlot,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderPreferencesRowsCompanion copyWith({
    Value<String>? collectionId,
    Value<String?>? fontId,
    Value<double>? fontSize,
    Value<double>? letterSpacing,
    Value<double>? lineHeight,
    Value<double>? paragraphSpacing,
    Value<double>? firstLineIndent,
    Value<double>? paddingTop,
    Value<double>? paddingBottom,
    Value<double>? paddingLeft,
    Value<double>? paddingRight,
    Value<String>? themeMode,
    Value<String>? paletteId,
    Value<int?>? textColorArgb,
    Value<int?>? backgroundColorArgb,
    Value<int?>? lightTextColorArgb,
    Value<int?>? lightBackgroundColorArgb,
    Value<int?>? darkTextColorArgb,
    Value<int?>? darkBackgroundColorArgb,
    Value<String?>? backgroundImagePath,
    Value<double>? backgroundImageOpacity,
    Value<double>? backgroundOverlayOpacity,
    Value<bool>? showTopInfoBar,
    Value<bool>? showBottomInfoBar,
    Value<bool>? showProgressInfo,
    Value<bool>? showSystemStatusBar,
    Value<String>? statusBarMode,
    Value<String>? timeDisplayMode,
    Value<bool>? showChapterInfo,
    Value<bool>? showChapterProgressInfo,
    Value<bool>? showClockInfo,
    Value<bool>? showWholeBookProgressInfo,
    Value<bool>? showInfoDivider,
    Value<bool>? showTopInfoDivider,
    Value<bool>? showBottomInfoDivider,
    Value<bool>? showAutoReadMinimalInfo,
    Value<String>? chapterInfoSlot,
    Value<String>? chapterProgressInfoSlot,
    Value<String>? clockInfoSlot,
    Value<String>? wholeBookProgressInfoSlot,
    Value<String>? infoDividerSlot,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReaderPreferencesRowsCompanion(
      collectionId: collectionId ?? this.collectionId,
      fontId: fontId ?? this.fontId,
      fontSize: fontSize ?? this.fontSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      firstLineIndent: firstLineIndent ?? this.firstLineIndent,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      themeMode: themeMode ?? this.themeMode,
      paletteId: paletteId ?? this.paletteId,
      textColorArgb: textColorArgb ?? this.textColorArgb,
      backgroundColorArgb: backgroundColorArgb ?? this.backgroundColorArgb,
      lightTextColorArgb: lightTextColorArgb ?? this.lightTextColorArgb,
      lightBackgroundColorArgb:
          lightBackgroundColorArgb ?? this.lightBackgroundColorArgb,
      darkTextColorArgb: darkTextColorArgb ?? this.darkTextColorArgb,
      darkBackgroundColorArgb:
          darkBackgroundColorArgb ?? this.darkBackgroundColorArgb,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      showTopInfoBar: showTopInfoBar ?? this.showTopInfoBar,
      showBottomInfoBar: showBottomInfoBar ?? this.showBottomInfoBar,
      showProgressInfo: showProgressInfo ?? this.showProgressInfo,
      showSystemStatusBar: showSystemStatusBar ?? this.showSystemStatusBar,
      statusBarMode: statusBarMode ?? this.statusBarMode,
      timeDisplayMode: timeDisplayMode ?? this.timeDisplayMode,
      showChapterInfo: showChapterInfo ?? this.showChapterInfo,
      showChapterProgressInfo:
          showChapterProgressInfo ?? this.showChapterProgressInfo,
      showClockInfo: showClockInfo ?? this.showClockInfo,
      showWholeBookProgressInfo:
          showWholeBookProgressInfo ?? this.showWholeBookProgressInfo,
      showInfoDivider: showInfoDivider ?? this.showInfoDivider,
      showTopInfoDivider: showTopInfoDivider ?? this.showTopInfoDivider,
      showBottomInfoDivider:
          showBottomInfoDivider ?? this.showBottomInfoDivider,
      showAutoReadMinimalInfo:
          showAutoReadMinimalInfo ?? this.showAutoReadMinimalInfo,
      chapterInfoSlot: chapterInfoSlot ?? this.chapterInfoSlot,
      chapterProgressInfoSlot:
          chapterProgressInfoSlot ?? this.chapterProgressInfoSlot,
      clockInfoSlot: clockInfoSlot ?? this.clockInfoSlot,
      wholeBookProgressInfoSlot:
          wholeBookProgressInfoSlot ?? this.wholeBookProgressInfoSlot,
      infoDividerSlot: infoDividerSlot ?? this.infoDividerSlot,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (fontId.present) {
      map['font_id'] = Variable<String>(fontId.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<double>(fontSize.value);
    }
    if (letterSpacing.present) {
      map['letter_spacing'] = Variable<double>(letterSpacing.value);
    }
    if (lineHeight.present) {
      map['line_height'] = Variable<double>(lineHeight.value);
    }
    if (paragraphSpacing.present) {
      map['paragraph_spacing'] = Variable<double>(paragraphSpacing.value);
    }
    if (firstLineIndent.present) {
      map['first_line_indent'] = Variable<double>(firstLineIndent.value);
    }
    if (paddingTop.present) {
      map['padding_top'] = Variable<double>(paddingTop.value);
    }
    if (paddingBottom.present) {
      map['padding_bottom'] = Variable<double>(paddingBottom.value);
    }
    if (paddingLeft.present) {
      map['padding_left'] = Variable<double>(paddingLeft.value);
    }
    if (paddingRight.present) {
      map['padding_right'] = Variable<double>(paddingRight.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (paletteId.present) {
      map['palette_id'] = Variable<String>(paletteId.value);
    }
    if (textColorArgb.present) {
      map['text_color_argb'] = Variable<int>(textColorArgb.value);
    }
    if (backgroundColorArgb.present) {
      map['background_color_argb'] = Variable<int>(backgroundColorArgb.value);
    }
    if (lightTextColorArgb.present) {
      map['light_text_color_argb'] = Variable<int>(lightTextColorArgb.value);
    }
    if (lightBackgroundColorArgb.present) {
      map['light_background_color_argb'] = Variable<int>(
        lightBackgroundColorArgb.value,
      );
    }
    if (darkTextColorArgb.present) {
      map['dark_text_color_argb'] = Variable<int>(darkTextColorArgb.value);
    }
    if (darkBackgroundColorArgb.present) {
      map['dark_background_color_argb'] = Variable<int>(
        darkBackgroundColorArgb.value,
      );
    }
    if (backgroundImagePath.present) {
      map['background_image_path'] = Variable<String>(
        backgroundImagePath.value,
      );
    }
    if (backgroundImageOpacity.present) {
      map['background_image_opacity'] = Variable<double>(
        backgroundImageOpacity.value,
      );
    }
    if (backgroundOverlayOpacity.present) {
      map['background_overlay_opacity'] = Variable<double>(
        backgroundOverlayOpacity.value,
      );
    }
    if (showTopInfoBar.present) {
      map['show_top_info_bar'] = Variable<bool>(showTopInfoBar.value);
    }
    if (showBottomInfoBar.present) {
      map['show_bottom_info_bar'] = Variable<bool>(showBottomInfoBar.value);
    }
    if (showProgressInfo.present) {
      map['show_progress_info'] = Variable<bool>(showProgressInfo.value);
    }
    if (showSystemStatusBar.present) {
      map['show_system_status_bar'] = Variable<bool>(showSystemStatusBar.value);
    }
    if (statusBarMode.present) {
      map['status_bar_mode'] = Variable<String>(statusBarMode.value);
    }
    if (timeDisplayMode.present) {
      map['time_display_mode'] = Variable<String>(timeDisplayMode.value);
    }
    if (showChapterInfo.present) {
      map['show_chapter_info'] = Variable<bool>(showChapterInfo.value);
    }
    if (showChapterProgressInfo.present) {
      map['show_chapter_progress_info'] = Variable<bool>(
        showChapterProgressInfo.value,
      );
    }
    if (showClockInfo.present) {
      map['show_clock_info'] = Variable<bool>(showClockInfo.value);
    }
    if (showWholeBookProgressInfo.present) {
      map['show_whole_book_progress_info'] = Variable<bool>(
        showWholeBookProgressInfo.value,
      );
    }
    if (showInfoDivider.present) {
      map['show_info_divider'] = Variable<bool>(showInfoDivider.value);
    }
    if (showTopInfoDivider.present) {
      map['show_top_info_divider'] = Variable<bool>(showTopInfoDivider.value);
    }
    if (showBottomInfoDivider.present) {
      map['show_bottom_info_divider'] = Variable<bool>(
        showBottomInfoDivider.value,
      );
    }
    if (showAutoReadMinimalInfo.present) {
      map['show_auto_read_minimal_info'] = Variable<bool>(
        showAutoReadMinimalInfo.value,
      );
    }
    if (chapterInfoSlot.present) {
      map['chapter_info_slot'] = Variable<String>(chapterInfoSlot.value);
    }
    if (chapterProgressInfoSlot.present) {
      map['chapter_progress_info_slot'] = Variable<String>(
        chapterProgressInfoSlot.value,
      );
    }
    if (clockInfoSlot.present) {
      map['clock_info_slot'] = Variable<String>(clockInfoSlot.value);
    }
    if (wholeBookProgressInfoSlot.present) {
      map['whole_book_progress_info_slot'] = Variable<String>(
        wholeBookProgressInfoSlot.value,
      );
    }
    if (infoDividerSlot.present) {
      map['info_divider_slot'] = Variable<String>(infoDividerSlot.value);
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
    return (StringBuffer('ReaderPreferencesRowsCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('fontId: $fontId, ')
          ..write('fontSize: $fontSize, ')
          ..write('letterSpacing: $letterSpacing, ')
          ..write('lineHeight: $lineHeight, ')
          ..write('paragraphSpacing: $paragraphSpacing, ')
          ..write('firstLineIndent: $firstLineIndent, ')
          ..write('paddingTop: $paddingTop, ')
          ..write('paddingBottom: $paddingBottom, ')
          ..write('paddingLeft: $paddingLeft, ')
          ..write('paddingRight: $paddingRight, ')
          ..write('themeMode: $themeMode, ')
          ..write('paletteId: $paletteId, ')
          ..write('textColorArgb: $textColorArgb, ')
          ..write('backgroundColorArgb: $backgroundColorArgb, ')
          ..write('lightTextColorArgb: $lightTextColorArgb, ')
          ..write('lightBackgroundColorArgb: $lightBackgroundColorArgb, ')
          ..write('darkTextColorArgb: $darkTextColorArgb, ')
          ..write('darkBackgroundColorArgb: $darkBackgroundColorArgb, ')
          ..write('backgroundImagePath: $backgroundImagePath, ')
          ..write('backgroundImageOpacity: $backgroundImageOpacity, ')
          ..write('backgroundOverlayOpacity: $backgroundOverlayOpacity, ')
          ..write('showTopInfoBar: $showTopInfoBar, ')
          ..write('showBottomInfoBar: $showBottomInfoBar, ')
          ..write('showProgressInfo: $showProgressInfo, ')
          ..write('showSystemStatusBar: $showSystemStatusBar, ')
          ..write('statusBarMode: $statusBarMode, ')
          ..write('timeDisplayMode: $timeDisplayMode, ')
          ..write('showChapterInfo: $showChapterInfo, ')
          ..write('showChapterProgressInfo: $showChapterProgressInfo, ')
          ..write('showClockInfo: $showClockInfo, ')
          ..write('showWholeBookProgressInfo: $showWholeBookProgressInfo, ')
          ..write('showInfoDivider: $showInfoDivider, ')
          ..write('showTopInfoDivider: $showTopInfoDivider, ')
          ..write('showBottomInfoDivider: $showBottomInfoDivider, ')
          ..write('showAutoReadMinimalInfo: $showAutoReadMinimalInfo, ')
          ..write('chapterInfoSlot: $chapterInfoSlot, ')
          ..write('chapterProgressInfoSlot: $chapterProgressInfoSlot, ')
          ..write('clockInfoSlot: $clockInfoSlot, ')
          ..write('wholeBookProgressInfoSlot: $wholeBookProgressInfoSlot, ')
          ..write('infoDividerSlot: $infoDividerSlot, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderFontAssetRowsTable extends ReaderFontAssetRows
    with TableInfo<$ReaderFontAssetRowsTable, ReaderFontAssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderFontAssetRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fontIdMeta = const VerificationMeta('fontId');
  @override
  late final GeneratedColumn<String> fontId = GeneratedColumn<String>(
    'font_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyNameSnapshotMeta =
      const VerificationMeta('familyNameSnapshot');
  @override
  late final GeneratedColumn<String> familyNameSnapshot =
      GeneratedColumn<String>(
        'family_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _styleNameSnapshotMeta = const VerificationMeta(
    'styleNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> styleNameSnapshot =
      GeneratedColumn<String>(
        'style_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _faceIndexMeta = const VerificationMeta(
    'faceIndex',
  );
  @override
  late final GeneratedColumn<int> faceIndex = GeneratedColumn<int>(
    'face_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    fontId,
    contentHash,
    relativePath,
    format,
    familyNameSnapshot,
    styleNameSnapshot,
    faceIndex,
    fileSize,
    createdAt,
    lastUsedAt,
    availability,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_font_asset_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderFontAssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('font_id')) {
      context.handle(
        _fontIdMeta,
        fontId.isAcceptableOrUnknown(data['font_id']!, _fontIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fontIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('family_name_snapshot')) {
      context.handle(
        _familyNameSnapshotMeta,
        familyNameSnapshot.isAcceptableOrUnknown(
          data['family_name_snapshot']!,
          _familyNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_familyNameSnapshotMeta);
    }
    if (data.containsKey('style_name_snapshot')) {
      context.handle(
        _styleNameSnapshotMeta,
        styleNameSnapshot.isAcceptableOrUnknown(
          data['style_name_snapshot']!,
          _styleNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('face_index')) {
      context.handle(
        _faceIndexMeta,
        faceIndex.isAcceptableOrUnknown(data['face_index']!, _faceIndexMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fontId};
  @override
  ReaderFontAssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderFontAssetRow(
      fontId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      familyNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_name_snapshot'],
      )!,
      styleNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_name_snapshot'],
      ),
      faceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_index'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      )!,
    );
  }

  @override
  $ReaderFontAssetRowsTable createAlias(String alias) {
    return $ReaderFontAssetRowsTable(attachedDatabase, alias);
  }
}

class ReaderFontAssetRow extends DataClass
    implements Insertable<ReaderFontAssetRow> {
  final String fontId;
  final String contentHash;
  final String relativePath;
  final String format;
  final String familyNameSnapshot;
  final String? styleNameSnapshot;
  final int? faceIndex;
  final int fileSize;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final String availability;
  const ReaderFontAssetRow({
    required this.fontId,
    required this.contentHash,
    required this.relativePath,
    required this.format,
    required this.familyNameSnapshot,
    this.styleNameSnapshot,
    this.faceIndex,
    required this.fileSize,
    required this.createdAt,
    required this.lastUsedAt,
    required this.availability,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['font_id'] = Variable<String>(fontId);
    map['content_hash'] = Variable<String>(contentHash);
    map['relative_path'] = Variable<String>(relativePath);
    map['format'] = Variable<String>(format);
    map['family_name_snapshot'] = Variable<String>(familyNameSnapshot);
    if (!nullToAbsent || styleNameSnapshot != null) {
      map['style_name_snapshot'] = Variable<String>(styleNameSnapshot);
    }
    if (!nullToAbsent || faceIndex != null) {
      map['face_index'] = Variable<int>(faceIndex);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    map['availability'] = Variable<String>(availability);
    return map;
  }

  ReaderFontAssetRowsCompanion toCompanion(bool nullToAbsent) {
    return ReaderFontAssetRowsCompanion(
      fontId: Value(fontId),
      contentHash: Value(contentHash),
      relativePath: Value(relativePath),
      format: Value(format),
      familyNameSnapshot: Value(familyNameSnapshot),
      styleNameSnapshot: styleNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(styleNameSnapshot),
      faceIndex: faceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(faceIndex),
      fileSize: Value(fileSize),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
      availability: Value(availability),
    );
  }

  factory ReaderFontAssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderFontAssetRow(
      fontId: serializer.fromJson<String>(json['fontId']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      format: serializer.fromJson<String>(json['format']),
      familyNameSnapshot: serializer.fromJson<String>(
        json['familyNameSnapshot'],
      ),
      styleNameSnapshot: serializer.fromJson<String?>(
        json['styleNameSnapshot'],
      ),
      faceIndex: serializer.fromJson<int?>(json['faceIndex']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      availability: serializer.fromJson<String>(json['availability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fontId': serializer.toJson<String>(fontId),
      'contentHash': serializer.toJson<String>(contentHash),
      'relativePath': serializer.toJson<String>(relativePath),
      'format': serializer.toJson<String>(format),
      'familyNameSnapshot': serializer.toJson<String>(familyNameSnapshot),
      'styleNameSnapshot': serializer.toJson<String?>(styleNameSnapshot),
      'faceIndex': serializer.toJson<int?>(faceIndex),
      'fileSize': serializer.toJson<int>(fileSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'availability': serializer.toJson<String>(availability),
    };
  }

  ReaderFontAssetRow copyWith({
    String? fontId,
    String? contentHash,
    String? relativePath,
    String? format,
    String? familyNameSnapshot,
    Value<String?> styleNameSnapshot = const Value.absent(),
    Value<int?> faceIndex = const Value.absent(),
    int? fileSize,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? availability,
  }) => ReaderFontAssetRow(
    fontId: fontId ?? this.fontId,
    contentHash: contentHash ?? this.contentHash,
    relativePath: relativePath ?? this.relativePath,
    format: format ?? this.format,
    familyNameSnapshot: familyNameSnapshot ?? this.familyNameSnapshot,
    styleNameSnapshot: styleNameSnapshot.present
        ? styleNameSnapshot.value
        : this.styleNameSnapshot,
    faceIndex: faceIndex.present ? faceIndex.value : this.faceIndex,
    fileSize: fileSize ?? this.fileSize,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    availability: availability ?? this.availability,
  );
  ReaderFontAssetRow copyWithCompanion(ReaderFontAssetRowsCompanion data) {
    return ReaderFontAssetRow(
      fontId: data.fontId.present ? data.fontId.value : this.fontId,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      format: data.format.present ? data.format.value : this.format,
      familyNameSnapshot: data.familyNameSnapshot.present
          ? data.familyNameSnapshot.value
          : this.familyNameSnapshot,
      styleNameSnapshot: data.styleNameSnapshot.present
          ? data.styleNameSnapshot.value
          : this.styleNameSnapshot,
      faceIndex: data.faceIndex.present ? data.faceIndex.value : this.faceIndex,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderFontAssetRow(')
          ..write('fontId: $fontId, ')
          ..write('contentHash: $contentHash, ')
          ..write('relativePath: $relativePath, ')
          ..write('format: $format, ')
          ..write('familyNameSnapshot: $familyNameSnapshot, ')
          ..write('styleNameSnapshot: $styleNameSnapshot, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('fileSize: $fileSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('availability: $availability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fontId,
    contentHash,
    relativePath,
    format,
    familyNameSnapshot,
    styleNameSnapshot,
    faceIndex,
    fileSize,
    createdAt,
    lastUsedAt,
    availability,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderFontAssetRow &&
          other.fontId == this.fontId &&
          other.contentHash == this.contentHash &&
          other.relativePath == this.relativePath &&
          other.format == this.format &&
          other.familyNameSnapshot == this.familyNameSnapshot &&
          other.styleNameSnapshot == this.styleNameSnapshot &&
          other.faceIndex == this.faceIndex &&
          other.fileSize == this.fileSize &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt &&
          other.availability == this.availability);
}

class ReaderFontAssetRowsCompanion extends UpdateCompanion<ReaderFontAssetRow> {
  final Value<String> fontId;
  final Value<String> contentHash;
  final Value<String> relativePath;
  final Value<String> format;
  final Value<String> familyNameSnapshot;
  final Value<String?> styleNameSnapshot;
  final Value<int?> faceIndex;
  final Value<int> fileSize;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastUsedAt;
  final Value<String> availability;
  final Value<int> rowid;
  const ReaderFontAssetRowsCompanion({
    this.fontId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.format = const Value.absent(),
    this.familyNameSnapshot = const Value.absent(),
    this.styleNameSnapshot = const Value.absent(),
    this.faceIndex = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.availability = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderFontAssetRowsCompanion.insert({
    required String fontId,
    required String contentHash,
    required String relativePath,
    required String format,
    required String familyNameSnapshot,
    this.styleNameSnapshot = const Value.absent(),
    this.faceIndex = const Value.absent(),
    required int fileSize,
    required DateTime createdAt,
    required DateTime lastUsedAt,
    this.availability = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fontId = Value(fontId),
       contentHash = Value(contentHash),
       relativePath = Value(relativePath),
       format = Value(format),
       familyNameSnapshot = Value(familyNameSnapshot),
       fileSize = Value(fileSize),
       createdAt = Value(createdAt),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<ReaderFontAssetRow> custom({
    Expression<String>? fontId,
    Expression<String>? contentHash,
    Expression<String>? relativePath,
    Expression<String>? format,
    Expression<String>? familyNameSnapshot,
    Expression<String>? styleNameSnapshot,
    Expression<int>? faceIndex,
    Expression<int>? fileSize,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
    Expression<String>? availability,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fontId != null) 'font_id': fontId,
      if (contentHash != null) 'content_hash': contentHash,
      if (relativePath != null) 'relative_path': relativePath,
      if (format != null) 'format': format,
      if (familyNameSnapshot != null)
        'family_name_snapshot': familyNameSnapshot,
      if (styleNameSnapshot != null) 'style_name_snapshot': styleNameSnapshot,
      if (faceIndex != null) 'face_index': faceIndex,
      if (fileSize != null) 'file_size': fileSize,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (availability != null) 'availability': availability,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderFontAssetRowsCompanion copyWith({
    Value<String>? fontId,
    Value<String>? contentHash,
    Value<String>? relativePath,
    Value<String>? format,
    Value<String>? familyNameSnapshot,
    Value<String?>? styleNameSnapshot,
    Value<int?>? faceIndex,
    Value<int>? fileSize,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastUsedAt,
    Value<String>? availability,
    Value<int>? rowid,
  }) {
    return ReaderFontAssetRowsCompanion(
      fontId: fontId ?? this.fontId,
      contentHash: contentHash ?? this.contentHash,
      relativePath: relativePath ?? this.relativePath,
      format: format ?? this.format,
      familyNameSnapshot: familyNameSnapshot ?? this.familyNameSnapshot,
      styleNameSnapshot: styleNameSnapshot ?? this.styleNameSnapshot,
      faceIndex: faceIndex ?? this.faceIndex,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      availability: availability ?? this.availability,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fontId.present) {
      map['font_id'] = Variable<String>(fontId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (familyNameSnapshot.present) {
      map['family_name_snapshot'] = Variable<String>(familyNameSnapshot.value);
    }
    if (styleNameSnapshot.present) {
      map['style_name_snapshot'] = Variable<String>(styleNameSnapshot.value);
    }
    if (faceIndex.present) {
      map['face_index'] = Variable<int>(faceIndex.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderFontAssetRowsCompanion(')
          ..write('fontId: $fontId, ')
          ..write('contentHash: $contentHash, ')
          ..write('relativePath: $relativePath, ')
          ..write('format: $format, ')
          ..write('familyNameSnapshot: $familyNameSnapshot, ')
          ..write('styleNameSnapshot: $styleNameSnapshot, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('fileSize: $fileSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('availability: $availability, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderBookmarksTable extends ReaderBookmarks
    with TableInfo<$ReaderBookmarksTable, ReaderBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'REFERENCES content_collections (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _absoluteCharacterOffsetMeta =
      const VerificationMeta('absoluteCharacterOffset');
  @override
  late final GeneratedColumn<int> absoluteCharacterOffset =
      GeneratedColumn<int>(
        'absolute_character_offset',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _normalizedHashAtCreationMeta =
      const VerificationMeta('normalizedHashAtCreation');
  @override
  late final GeneratedColumn<String> normalizedHashAtCreation =
      GeneratedColumn<String>(
        'normalized_hash_at_creation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bookTitleSnapshotMeta = const VerificationMeta(
    'bookTitleSnapshot',
  );
  @override
  late final GeneratedColumn<String> bookTitleSnapshot =
      GeneratedColumn<String>(
        'book_title_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
    collectionId,
    absoluteCharacterOffset,
    normalizedHashAtCreation,
    bookTitleSnapshot,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    }
    if (data.containsKey('absolute_character_offset')) {
      context.handle(
        _absoluteCharacterOffsetMeta,
        absoluteCharacterOffset.isAcceptableOrUnknown(
          data['absolute_character_offset']!,
          _absoluteCharacterOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_absoluteCharacterOffsetMeta);
    }
    if (data.containsKey('normalized_hash_at_creation')) {
      context.handle(
        _normalizedHashAtCreationMeta,
        normalizedHashAtCreation.isAcceptableOrUnknown(
          data['normalized_hash_at_creation']!,
          _normalizedHashAtCreationMeta,
        ),
      );
    }
    if (data.containsKey('book_title_snapshot')) {
      context.handle(
        _bookTitleSnapshotMeta,
        bookTitleSnapshot.isAcceptableOrUnknown(
          data['book_title_snapshot']!,
          _bookTitleSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookTitleSnapshotMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  ReaderBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderBookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      ),
      absoluteCharacterOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}absolute_character_offset'],
      )!,
      normalizedHashAtCreation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_hash_at_creation'],
      ),
      bookTitleSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_title_snapshot'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
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
  $ReaderBookmarksTable createAlias(String alias) {
    return $ReaderBookmarksTable(attachedDatabase, alias);
  }
}

class ReaderBookmark extends DataClass implements Insertable<ReaderBookmark> {
  final String id;
  final String? collectionId;
  final int absoluteCharacterOffset;
  final String? normalizedHashAtCreation;
  final String bookTitleSnapshot;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReaderBookmark({
    required this.id,
    this.collectionId,
    required this.absoluteCharacterOffset,
    this.normalizedHashAtCreation,
    required this.bookTitleSnapshot,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || collectionId != null) {
      map['collection_id'] = Variable<String>(collectionId);
    }
    map['absolute_character_offset'] = Variable<int>(absoluteCharacterOffset);
    if (!nullToAbsent || normalizedHashAtCreation != null) {
      map['normalized_hash_at_creation'] = Variable<String>(
        normalizedHashAtCreation,
      );
    }
    map['book_title_snapshot'] = Variable<String>(bookTitleSnapshot);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReaderBookmarksCompanion toCompanion(bool nullToAbsent) {
    return ReaderBookmarksCompanion(
      id: Value(id),
      collectionId: collectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(collectionId),
      absoluteCharacterOffset: Value(absoluteCharacterOffset),
      normalizedHashAtCreation: normalizedHashAtCreation == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedHashAtCreation),
      bookTitleSnapshot: Value(bookTitleSnapshot),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReaderBookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderBookmark(
      id: serializer.fromJson<String>(json['id']),
      collectionId: serializer.fromJson<String?>(json['collectionId']),
      absoluteCharacterOffset: serializer.fromJson<int>(
        json['absoluteCharacterOffset'],
      ),
      normalizedHashAtCreation: serializer.fromJson<String?>(
        json['normalizedHashAtCreation'],
      ),
      bookTitleSnapshot: serializer.fromJson<String>(json['bookTitleSnapshot']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'collectionId': serializer.toJson<String?>(collectionId),
      'absoluteCharacterOffset': serializer.toJson<int>(
        absoluteCharacterOffset,
      ),
      'normalizedHashAtCreation': serializer.toJson<String?>(
        normalizedHashAtCreation,
      ),
      'bookTitleSnapshot': serializer.toJson<String>(bookTitleSnapshot),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReaderBookmark copyWith({
    String? id,
    Value<String?> collectionId = const Value.absent(),
    int? absoluteCharacterOffset,
    Value<String?> normalizedHashAtCreation = const Value.absent(),
    String? bookTitleSnapshot,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReaderBookmark(
    id: id ?? this.id,
    collectionId: collectionId.present ? collectionId.value : this.collectionId,
    absoluteCharacterOffset:
        absoluteCharacterOffset ?? this.absoluteCharacterOffset,
    normalizedHashAtCreation: normalizedHashAtCreation.present
        ? normalizedHashAtCreation.value
        : this.normalizedHashAtCreation,
    bookTitleSnapshot: bookTitleSnapshot ?? this.bookTitleSnapshot,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReaderBookmark copyWithCompanion(ReaderBookmarksCompanion data) {
    return ReaderBookmark(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      absoluteCharacterOffset: data.absoluteCharacterOffset.present
          ? data.absoluteCharacterOffset.value
          : this.absoluteCharacterOffset,
      normalizedHashAtCreation: data.normalizedHashAtCreation.present
          ? data.normalizedHashAtCreation.value
          : this.normalizedHashAtCreation,
      bookTitleSnapshot: data.bookTitleSnapshot.present
          ? data.bookTitleSnapshot.value
          : this.bookTitleSnapshot,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderBookmark(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('absoluteCharacterOffset: $absoluteCharacterOffset, ')
          ..write('normalizedHashAtCreation: $normalizedHashAtCreation, ')
          ..write('bookTitleSnapshot: $bookTitleSnapshot, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionId,
    absoluteCharacterOffset,
    normalizedHashAtCreation,
    bookTitleSnapshot,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderBookmark &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.absoluteCharacterOffset == this.absoluteCharacterOffset &&
          other.normalizedHashAtCreation == this.normalizedHashAtCreation &&
          other.bookTitleSnapshot == this.bookTitleSnapshot &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReaderBookmarksCompanion extends UpdateCompanion<ReaderBookmark> {
  final Value<String> id;
  final Value<String?> collectionId;
  final Value<int> absoluteCharacterOffset;
  final Value<String?> normalizedHashAtCreation;
  final Value<String> bookTitleSnapshot;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReaderBookmarksCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.absoluteCharacterOffset = const Value.absent(),
    this.normalizedHashAtCreation = const Value.absent(),
    this.bookTitleSnapshot = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderBookmarksCompanion.insert({
    required String id,
    this.collectionId = const Value.absent(),
    required int absoluteCharacterOffset,
    this.normalizedHashAtCreation = const Value.absent(),
    required String bookTitleSnapshot,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       absoluteCharacterOffset = Value(absoluteCharacterOffset),
       bookTitleSnapshot = Value(bookTitleSnapshot),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReaderBookmark> custom({
    Expression<String>? id,
    Expression<String>? collectionId,
    Expression<int>? absoluteCharacterOffset,
    Expression<String>? normalizedHashAtCreation,
    Expression<String>? bookTitleSnapshot,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (absoluteCharacterOffset != null)
        'absolute_character_offset': absoluteCharacterOffset,
      if (normalizedHashAtCreation != null)
        'normalized_hash_at_creation': normalizedHashAtCreation,
      if (bookTitleSnapshot != null) 'book_title_snapshot': bookTitleSnapshot,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderBookmarksCompanion copyWith({
    Value<String>? id,
    Value<String?>? collectionId,
    Value<int>? absoluteCharacterOffset,
    Value<String?>? normalizedHashAtCreation,
    Value<String>? bookTitleSnapshot,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReaderBookmarksCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      absoluteCharacterOffset:
          absoluteCharacterOffset ?? this.absoluteCharacterOffset,
      normalizedHashAtCreation:
          normalizedHashAtCreation ?? this.normalizedHashAtCreation,
      bookTitleSnapshot: bookTitleSnapshot ?? this.bookTitleSnapshot,
      note: note ?? this.note,
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
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (absoluteCharacterOffset.present) {
      map['absolute_character_offset'] = Variable<int>(
        absoluteCharacterOffset.value,
      );
    }
    if (normalizedHashAtCreation.present) {
      map['normalized_hash_at_creation'] = Variable<String>(
        normalizedHashAtCreation.value,
      );
    }
    if (bookTitleSnapshot.present) {
      map['book_title_snapshot'] = Variable<String>(bookTitleSnapshot.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('ReaderBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('absoluteCharacterOffset: $absoluteCharacterOffset, ')
          ..write('normalizedHashAtCreation: $normalizedHashAtCreation, ')
          ..write('bookTitleSnapshot: $bookTitleSnapshot, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingHistoryTable extends ReadingHistory
    with TableInfo<$ReadingHistoryTable, ReadingHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'REFERENCES content_collections (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _bookTitleSnapshotMeta = const VerificationMeta(
    'bookTitleSnapshot',
  );
  @override
  late final GeneratedColumn<String> bookTitleSnapshot =
      GeneratedColumn<String>(
        'book_title_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _authorSnapshotMeta = const VerificationMeta(
    'authorSnapshot',
  );
  @override
  late final GeneratedColumn<String> authorSnapshot = GeneratedColumn<String>(
    'author_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _normalizedHashSnapshotMeta =
      const VerificationMeta('normalizedHashSnapshot');
  @override
  late final GeneratedColumn<String> normalizedHashSnapshot =
      GeneratedColumn<String>(
        'normalized_hash_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _firstReadAtMeta = const VerificationMeta(
    'firstReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstReadAt = GeneratedColumn<DateTime>(
    'first_read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastChapterTitleSnapshotMeta =
      const VerificationMeta('lastChapterTitleSnapshot');
  @override
  late final GeneratedColumn<String> lastChapterTitleSnapshot =
      GeneratedColumn<String>(
        'last_chapter_title_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastProgressSnapshotMeta =
      const VerificationMeta('lastProgressSnapshot');
  @override
  late final GeneratedColumn<String> lastProgressSnapshot =
      GeneratedColumn<String>(
        'last_progress_snapshot',
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
    collectionId,
    bookTitleSnapshot,
    authorSnapshot,
    normalizedHashSnapshot,
    firstReadAt,
    lastReadAt,
    lastChapterTitleSnapshot,
    lastProgressSnapshot,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    }
    if (data.containsKey('book_title_snapshot')) {
      context.handle(
        _bookTitleSnapshotMeta,
        bookTitleSnapshot.isAcceptableOrUnknown(
          data['book_title_snapshot']!,
          _bookTitleSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookTitleSnapshotMeta);
    }
    if (data.containsKey('author_snapshot')) {
      context.handle(
        _authorSnapshotMeta,
        authorSnapshot.isAcceptableOrUnknown(
          data['author_snapshot']!,
          _authorSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('normalized_hash_snapshot')) {
      context.handle(
        _normalizedHashSnapshotMeta,
        normalizedHashSnapshot.isAcceptableOrUnknown(
          data['normalized_hash_snapshot']!,
          _normalizedHashSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('first_read_at')) {
      context.handle(
        _firstReadAtMeta,
        firstReadAt.isAcceptableOrUnknown(
          data['first_read_at']!,
          _firstReadAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstReadAtMeta);
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastReadAtMeta);
    }
    if (data.containsKey('last_chapter_title_snapshot')) {
      context.handle(
        _lastChapterTitleSnapshotMeta,
        lastChapterTitleSnapshot.isAcceptableOrUnknown(
          data['last_chapter_title_snapshot']!,
          _lastChapterTitleSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('last_progress_snapshot')) {
      context.handle(
        _lastProgressSnapshotMeta,
        lastProgressSnapshot.isAcceptableOrUnknown(
          data['last_progress_snapshot']!,
          _lastProgressSnapshotMeta,
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
  ReadingHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      ),
      bookTitleSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_title_snapshot'],
      )!,
      authorSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_snapshot'],
      ),
      normalizedHashSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_hash_snapshot'],
      ),
      firstReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_read_at'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      )!,
      lastChapterTitleSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_chapter_title_snapshot'],
      ),
      lastProgressSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_progress_snapshot'],
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
  $ReadingHistoryTable createAlias(String alias) {
    return $ReadingHistoryTable(attachedDatabase, alias);
  }
}

class ReadingHistoryData extends DataClass
    implements Insertable<ReadingHistoryData> {
  final String id;
  final String? collectionId;
  final String bookTitleSnapshot;
  final String? authorSnapshot;
  final String? normalizedHashSnapshot;
  final DateTime firstReadAt;
  final DateTime lastReadAt;
  final String? lastChapterTitleSnapshot;
  final String? lastProgressSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReadingHistoryData({
    required this.id,
    this.collectionId,
    required this.bookTitleSnapshot,
    this.authorSnapshot,
    this.normalizedHashSnapshot,
    required this.firstReadAt,
    required this.lastReadAt,
    this.lastChapterTitleSnapshot,
    this.lastProgressSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || collectionId != null) {
      map['collection_id'] = Variable<String>(collectionId);
    }
    map['book_title_snapshot'] = Variable<String>(bookTitleSnapshot);
    if (!nullToAbsent || authorSnapshot != null) {
      map['author_snapshot'] = Variable<String>(authorSnapshot);
    }
    if (!nullToAbsent || normalizedHashSnapshot != null) {
      map['normalized_hash_snapshot'] = Variable<String>(
        normalizedHashSnapshot,
      );
    }
    map['first_read_at'] = Variable<DateTime>(firstReadAt);
    map['last_read_at'] = Variable<DateTime>(lastReadAt);
    if (!nullToAbsent || lastChapterTitleSnapshot != null) {
      map['last_chapter_title_snapshot'] = Variable<String>(
        lastChapterTitleSnapshot,
      );
    }
    if (!nullToAbsent || lastProgressSnapshot != null) {
      map['last_progress_snapshot'] = Variable<String>(lastProgressSnapshot);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReadingHistoryCompanion toCompanion(bool nullToAbsent) {
    return ReadingHistoryCompanion(
      id: Value(id),
      collectionId: collectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(collectionId),
      bookTitleSnapshot: Value(bookTitleSnapshot),
      authorSnapshot: authorSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(authorSnapshot),
      normalizedHashSnapshot: normalizedHashSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedHashSnapshot),
      firstReadAt: Value(firstReadAt),
      lastReadAt: Value(lastReadAt),
      lastChapterTitleSnapshot: lastChapterTitleSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChapterTitleSnapshot),
      lastProgressSnapshot: lastProgressSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProgressSnapshot),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingHistoryData(
      id: serializer.fromJson<String>(json['id']),
      collectionId: serializer.fromJson<String?>(json['collectionId']),
      bookTitleSnapshot: serializer.fromJson<String>(json['bookTitleSnapshot']),
      authorSnapshot: serializer.fromJson<String?>(json['authorSnapshot']),
      normalizedHashSnapshot: serializer.fromJson<String?>(
        json['normalizedHashSnapshot'],
      ),
      firstReadAt: serializer.fromJson<DateTime>(json['firstReadAt']),
      lastReadAt: serializer.fromJson<DateTime>(json['lastReadAt']),
      lastChapterTitleSnapshot: serializer.fromJson<String?>(
        json['lastChapterTitleSnapshot'],
      ),
      lastProgressSnapshot: serializer.fromJson<String?>(
        json['lastProgressSnapshot'],
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
      'collectionId': serializer.toJson<String?>(collectionId),
      'bookTitleSnapshot': serializer.toJson<String>(bookTitleSnapshot),
      'authorSnapshot': serializer.toJson<String?>(authorSnapshot),
      'normalizedHashSnapshot': serializer.toJson<String?>(
        normalizedHashSnapshot,
      ),
      'firstReadAt': serializer.toJson<DateTime>(firstReadAt),
      'lastReadAt': serializer.toJson<DateTime>(lastReadAt),
      'lastChapterTitleSnapshot': serializer.toJson<String?>(
        lastChapterTitleSnapshot,
      ),
      'lastProgressSnapshot': serializer.toJson<String?>(lastProgressSnapshot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingHistoryData copyWith({
    String? id,
    Value<String?> collectionId = const Value.absent(),
    String? bookTitleSnapshot,
    Value<String?> authorSnapshot = const Value.absent(),
    Value<String?> normalizedHashSnapshot = const Value.absent(),
    DateTime? firstReadAt,
    DateTime? lastReadAt,
    Value<String?> lastChapterTitleSnapshot = const Value.absent(),
    Value<String?> lastProgressSnapshot = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReadingHistoryData(
    id: id ?? this.id,
    collectionId: collectionId.present ? collectionId.value : this.collectionId,
    bookTitleSnapshot: bookTitleSnapshot ?? this.bookTitleSnapshot,
    authorSnapshot: authorSnapshot.present
        ? authorSnapshot.value
        : this.authorSnapshot,
    normalizedHashSnapshot: normalizedHashSnapshot.present
        ? normalizedHashSnapshot.value
        : this.normalizedHashSnapshot,
    firstReadAt: firstReadAt ?? this.firstReadAt,
    lastReadAt: lastReadAt ?? this.lastReadAt,
    lastChapterTitleSnapshot: lastChapterTitleSnapshot.present
        ? lastChapterTitleSnapshot.value
        : this.lastChapterTitleSnapshot,
    lastProgressSnapshot: lastProgressSnapshot.present
        ? lastProgressSnapshot.value
        : this.lastProgressSnapshot,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingHistoryData copyWithCompanion(ReadingHistoryCompanion data) {
    return ReadingHistoryData(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      bookTitleSnapshot: data.bookTitleSnapshot.present
          ? data.bookTitleSnapshot.value
          : this.bookTitleSnapshot,
      authorSnapshot: data.authorSnapshot.present
          ? data.authorSnapshot.value
          : this.authorSnapshot,
      normalizedHashSnapshot: data.normalizedHashSnapshot.present
          ? data.normalizedHashSnapshot.value
          : this.normalizedHashSnapshot,
      firstReadAt: data.firstReadAt.present
          ? data.firstReadAt.value
          : this.firstReadAt,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      lastChapterTitleSnapshot: data.lastChapterTitleSnapshot.present
          ? data.lastChapterTitleSnapshot.value
          : this.lastChapterTitleSnapshot,
      lastProgressSnapshot: data.lastProgressSnapshot.present
          ? data.lastProgressSnapshot.value
          : this.lastProgressSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryData(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('bookTitleSnapshot: $bookTitleSnapshot, ')
          ..write('authorSnapshot: $authorSnapshot, ')
          ..write('normalizedHashSnapshot: $normalizedHashSnapshot, ')
          ..write('firstReadAt: $firstReadAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('lastChapterTitleSnapshot: $lastChapterTitleSnapshot, ')
          ..write('lastProgressSnapshot: $lastProgressSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionId,
    bookTitleSnapshot,
    authorSnapshot,
    normalizedHashSnapshot,
    firstReadAt,
    lastReadAt,
    lastChapterTitleSnapshot,
    lastProgressSnapshot,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingHistoryData &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.bookTitleSnapshot == this.bookTitleSnapshot &&
          other.authorSnapshot == this.authorSnapshot &&
          other.normalizedHashSnapshot == this.normalizedHashSnapshot &&
          other.firstReadAt == this.firstReadAt &&
          other.lastReadAt == this.lastReadAt &&
          other.lastChapterTitleSnapshot == this.lastChapterTitleSnapshot &&
          other.lastProgressSnapshot == this.lastProgressSnapshot &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReadingHistoryCompanion extends UpdateCompanion<ReadingHistoryData> {
  final Value<String> id;
  final Value<String?> collectionId;
  final Value<String> bookTitleSnapshot;
  final Value<String?> authorSnapshot;
  final Value<String?> normalizedHashSnapshot;
  final Value<DateTime> firstReadAt;
  final Value<DateTime> lastReadAt;
  final Value<String?> lastChapterTitleSnapshot;
  final Value<String?> lastProgressSnapshot;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReadingHistoryCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.bookTitleSnapshot = const Value.absent(),
    this.authorSnapshot = const Value.absent(),
    this.normalizedHashSnapshot = const Value.absent(),
    this.firstReadAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.lastChapterTitleSnapshot = const Value.absent(),
    this.lastProgressSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingHistoryCompanion.insert({
    required String id,
    this.collectionId = const Value.absent(),
    required String bookTitleSnapshot,
    this.authorSnapshot = const Value.absent(),
    this.normalizedHashSnapshot = const Value.absent(),
    required DateTime firstReadAt,
    required DateTime lastReadAt,
    this.lastChapterTitleSnapshot = const Value.absent(),
    this.lastProgressSnapshot = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookTitleSnapshot = Value(bookTitleSnapshot),
       firstReadAt = Value(firstReadAt),
       lastReadAt = Value(lastReadAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingHistoryData> custom({
    Expression<String>? id,
    Expression<String>? collectionId,
    Expression<String>? bookTitleSnapshot,
    Expression<String>? authorSnapshot,
    Expression<String>? normalizedHashSnapshot,
    Expression<DateTime>? firstReadAt,
    Expression<DateTime>? lastReadAt,
    Expression<String>? lastChapterTitleSnapshot,
    Expression<String>? lastProgressSnapshot,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (bookTitleSnapshot != null) 'book_title_snapshot': bookTitleSnapshot,
      if (authorSnapshot != null) 'author_snapshot': authorSnapshot,
      if (normalizedHashSnapshot != null)
        'normalized_hash_snapshot': normalizedHashSnapshot,
      if (firstReadAt != null) 'first_read_at': firstReadAt,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (lastChapterTitleSnapshot != null)
        'last_chapter_title_snapshot': lastChapterTitleSnapshot,
      if (lastProgressSnapshot != null)
        'last_progress_snapshot': lastProgressSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingHistoryCompanion copyWith({
    Value<String>? id,
    Value<String?>? collectionId,
    Value<String>? bookTitleSnapshot,
    Value<String?>? authorSnapshot,
    Value<String?>? normalizedHashSnapshot,
    Value<DateTime>? firstReadAt,
    Value<DateTime>? lastReadAt,
    Value<String?>? lastChapterTitleSnapshot,
    Value<String?>? lastProgressSnapshot,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingHistoryCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      bookTitleSnapshot: bookTitleSnapshot ?? this.bookTitleSnapshot,
      authorSnapshot: authorSnapshot ?? this.authorSnapshot,
      normalizedHashSnapshot:
          normalizedHashSnapshot ?? this.normalizedHashSnapshot,
      firstReadAt: firstReadAt ?? this.firstReadAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      lastChapterTitleSnapshot:
          lastChapterTitleSnapshot ?? this.lastChapterTitleSnapshot,
      lastProgressSnapshot: lastProgressSnapshot ?? this.lastProgressSnapshot,
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
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (bookTitleSnapshot.present) {
      map['book_title_snapshot'] = Variable<String>(bookTitleSnapshot.value);
    }
    if (authorSnapshot.present) {
      map['author_snapshot'] = Variable<String>(authorSnapshot.value);
    }
    if (normalizedHashSnapshot.present) {
      map['normalized_hash_snapshot'] = Variable<String>(
        normalizedHashSnapshot.value,
      );
    }
    if (firstReadAt.present) {
      map['first_read_at'] = Variable<DateTime>(firstReadAt.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (lastChapterTitleSnapshot.present) {
      map['last_chapter_title_snapshot'] = Variable<String>(
        lastChapterTitleSnapshot.value,
      );
    }
    if (lastProgressSnapshot.present) {
      map['last_progress_snapshot'] = Variable<String>(
        lastProgressSnapshot.value,
      );
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
    return (StringBuffer('ReadingHistoryCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('bookTitleSnapshot: $bookTitleSnapshot, ')
          ..write('authorSnapshot: $authorSnapshot, ')
          ..write('normalizedHashSnapshot: $normalizedHashSnapshot, ')
          ..write('firstReadAt: $firstReadAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('lastChapterTitleSnapshot: $lastChapterTitleSnapshot, ')
          ..write('lastProgressSnapshot: $lastProgressSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _historyEntryIdMeta = const VerificationMeta(
    'historyEntryId',
  );
  @override
  late final GeneratedColumn<String> historyEntryId = GeneratedColumn<String>(
    'history_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES reading_history (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectiveReadingSecondsMeta =
      const VerificationMeta('effectiveReadingSeconds');
  @override
  late final GeneratedColumn<int> effectiveReadingSeconds =
      GeneratedColumn<int>(
        'effective_reading_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    historyEntryId,
    startedAt,
    endedAt,
    effectiveReadingSeconds,
    platform,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('history_entry_id')) {
      context.handle(
        _historyEntryIdMeta,
        historyEntryId.isAcceptableOrUnknown(
          data['history_entry_id']!,
          _historyEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_historyEntryIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('effective_reading_seconds')) {
      context.handle(
        _effectiveReadingSecondsMeta,
        effectiveReadingSeconds.isAcceptableOrUnknown(
          data['effective_reading_seconds']!,
          _effectiveReadingSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveReadingSecondsMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      historyEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history_entry_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      effectiveReadingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_reading_seconds'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final String id;
  final String historyEntryId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int effectiveReadingSeconds;
  final String? platform;
  final String? deviceId;
  const ReadingSession({
    required this.id,
    required this.historyEntryId,
    required this.startedAt,
    this.endedAt,
    required this.effectiveReadingSeconds,
    this.platform,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['history_entry_id'] = Variable<String>(historyEntryId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['effective_reading_seconds'] = Variable<int>(effectiveReadingSeconds);
    if (!nullToAbsent || platform != null) {
      map['platform'] = Variable<String>(platform);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      historyEntryId: Value(historyEntryId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      effectiveReadingSeconds: Value(effectiveReadingSeconds),
      platform: platform == null && nullToAbsent
          ? const Value.absent()
          : Value(platform),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory ReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<String>(json['id']),
      historyEntryId: serializer.fromJson<String>(json['historyEntryId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      effectiveReadingSeconds: serializer.fromJson<int>(
        json['effectiveReadingSeconds'],
      ),
      platform: serializer.fromJson<String?>(json['platform']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'historyEntryId': serializer.toJson<String>(historyEntryId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'effectiveReadingSeconds': serializer.toJson<int>(
        effectiveReadingSeconds,
      ),
      'platform': serializer.toJson<String?>(platform),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  ReadingSession copyWith({
    String? id,
    String? historyEntryId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? effectiveReadingSeconds,
    Value<String?> platform = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
  }) => ReadingSession(
    id: id ?? this.id,
    historyEntryId: historyEntryId ?? this.historyEntryId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    effectiveReadingSeconds:
        effectiveReadingSeconds ?? this.effectiveReadingSeconds,
    platform: platform.present ? platform.value : this.platform,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  ReadingSession copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      historyEntryId: data.historyEntryId.present
          ? data.historyEntryId.value
          : this.historyEntryId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      effectiveReadingSeconds: data.effectiveReadingSeconds.present
          ? data.effectiveReadingSeconds.value
          : this.effectiveReadingSeconds,
      platform: data.platform.present ? data.platform.value : this.platform,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('historyEntryId: $historyEntryId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('effectiveReadingSeconds: $effectiveReadingSeconds, ')
          ..write('platform: $platform, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    historyEntryId,
    startedAt,
    endedAt,
    effectiveReadingSeconds,
    platform,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.historyEntryId == this.historyEntryId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.effectiveReadingSeconds == this.effectiveReadingSeconds &&
          other.platform == this.platform &&
          other.deviceId == this.deviceId);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<String> id;
  final Value<String> historyEntryId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> effectiveReadingSeconds;
  final Value<String?> platform;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.historyEntryId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.effectiveReadingSeconds = const Value.absent(),
    this.platform = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    required String id,
    required String historyEntryId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int effectiveReadingSeconds,
    this.platform = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       historyEntryId = Value(historyEntryId),
       startedAt = Value(startedAt),
       effectiveReadingSeconds = Value(effectiveReadingSeconds);
  static Insertable<ReadingSession> custom({
    Expression<String>? id,
    Expression<String>? historyEntryId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? effectiveReadingSeconds,
    Expression<String>? platform,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (historyEntryId != null) 'history_entry_id': historyEntryId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (effectiveReadingSeconds != null)
        'effective_reading_seconds': effectiveReadingSeconds,
      if (platform != null) 'platform': platform,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? historyEntryId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? effectiveReadingSeconds,
    Value<String?>? platform,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      historyEntryId: historyEntryId ?? this.historyEntryId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      effectiveReadingSeconds:
          effectiveReadingSeconds ?? this.effectiveReadingSeconds,
      platform: platform ?? this.platform,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (historyEntryId.present) {
      map['history_entry_id'] = Variable<String>(historyEntryId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (effectiveReadingSeconds.present) {
      map['effective_reading_seconds'] = Variable<int>(
        effectiveReadingSeconds.value,
      );
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('historyEntryId: $historyEntryId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('effectiveReadingSeconds: $effectiveReadingSeconds, ')
          ..write('platform: $platform, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContentSourcesTable contentSources = $ContentSourcesTable(this);
  late final $ContentCollectionsTable contentCollections =
      $ContentCollectionsTable(this);
  late final $ContentItemsTable contentItems = $ContentItemsTable(this);
  late final $ContentDocumentsTable contentDocuments = $ContentDocumentsTable(
    this,
  );
  late final $TocEntriesTable tocEntries = $TocEntriesTable(this);
  late final $ImportRecordsTable importRecords = $ImportRecordsTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ReaderPreferencesRowsTable readerPreferencesRows =
      $ReaderPreferencesRowsTable(this);
  late final $ReaderFontAssetRowsTable readerFontAssetRows =
      $ReaderFontAssetRowsTable(this);
  late final $ReaderBookmarksTable readerBookmarks = $ReaderBookmarksTable(
    this,
  );
  late final $ReadingHistoryTable readingHistory = $ReadingHistoryTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contentSources,
    contentCollections,
    contentItems,
    contentDocuments,
    tocEntries,
    importRecords,
    readingProgress,
    appSettings,
    readerPreferencesRows,
    readerFontAssetRows,
    readerBookmarks,
    readingHistory,
    readingSessions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'content_collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'content_collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reader_preferences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'content_collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reader_bookmarks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'content_collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_history', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'reading_history',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ContentSourcesTableCreateCompanionBuilder =
    ContentSourcesCompanion Function({
      required String id,
      required String type,
      required String displayName,
      required String contentHash,
      required String managedSourcePath,
      required int sourceSize,
      required String detectedEncoding,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ContentSourcesTableUpdateCompanionBuilder =
    ContentSourcesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> displayName,
      Value<String> contentHash,
      Value<String> managedSourcePath,
      Value<int> sourceSize,
      Value<String> detectedEncoding,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ContentSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ContentSourcesTable> {
  $$ContentSourcesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managedSourcePath => $composableBuilder(
    column: $table.managedSourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceSize => $composableBuilder(
    column: $table.sourceSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectedEncoding => $composableBuilder(
    column: $table.detectedEncoding,
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

class $$ContentSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentSourcesTable> {
  $$ContentSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managedSourcePath => $composableBuilder(
    column: $table.managedSourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceSize => $composableBuilder(
    column: $table.sourceSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectedEncoding => $composableBuilder(
    column: $table.detectedEncoding,
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

class $$ContentSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentSourcesTable> {
  $$ContentSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managedSourcePath => $composableBuilder(
    column: $table.managedSourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceSize => $composableBuilder(
    column: $table.sourceSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detectedEncoding => $composableBuilder(
    column: $table.detectedEncoding,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContentSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentSourcesTable,
          ContentSource,
          $$ContentSourcesTableFilterComposer,
          $$ContentSourcesTableOrderingComposer,
          $$ContentSourcesTableAnnotationComposer,
          $$ContentSourcesTableCreateCompanionBuilder,
          $$ContentSourcesTableUpdateCompanionBuilder,
          (
            ContentSource,
            BaseReferences<_$AppDatabase, $ContentSourcesTable, ContentSource>,
          ),
          ContentSource,
          PrefetchHooks Function()
        > {
  $$ContentSourcesTableTableManager(
    _$AppDatabase db,
    $ContentSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> managedSourcePath = const Value.absent(),
                Value<int> sourceSize = const Value.absent(),
                Value<String> detectedEncoding = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentSourcesCompanion(
                id: id,
                type: type,
                displayName: displayName,
                contentHash: contentHash,
                managedSourcePath: managedSourcePath,
                sourceSize: sourceSize,
                detectedEncoding: detectedEncoding,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String displayName,
                required String contentHash,
                required String managedSourcePath,
                required int sourceSize,
                required String detectedEncoding,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentSourcesCompanion.insert(
                id: id,
                type: type,
                displayName: displayName,
                contentHash: contentHash,
                managedSourcePath: managedSourcePath,
                sourceSize: sourceSize,
                detectedEncoding: detectedEncoding,
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

typedef $$ContentSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentSourcesTable,
      ContentSource,
      $$ContentSourcesTableFilterComposer,
      $$ContentSourcesTableOrderingComposer,
      $$ContentSourcesTableAnnotationComposer,
      $$ContentSourcesTableCreateCompanionBuilder,
      $$ContentSourcesTableUpdateCompanionBuilder,
      (
        ContentSource,
        BaseReferences<_$AppDatabase, $ContentSourcesTable, ContentSource>,
      ),
      ContentSource,
      PrefetchHooks Function()
    >;
typedef $$ContentCollectionsTableCreateCompanionBuilder =
    ContentCollectionsCompanion Function({
      required String id,
      required String sourceId,
      required String title,
      Value<String?> subtitle,
      required int itemCount,
      required int normalizedCharacterLength,
      required DateTime importedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ContentCollectionsTableUpdateCompanionBuilder =
    ContentCollectionsCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String> title,
      Value<String?> subtitle,
      Value<int> itemCount,
      Value<int> normalizedCharacterLength,
      Value<DateTime> importedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ContentCollectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ContentCollectionsTable,
          ContentCollection
        > {
  $$ContentCollectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ReadingProgressTable, List<ReadingProgressData>>
  _readingProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingProgress,
    aliasName: $_aliasNameGenerator(
      db.contentCollections.id,
      db.readingProgress.collectionId,
    ),
  );

  $$ReadingProgressTableProcessedTableManager get readingProgressRefs {
    final manager = $$ReadingProgressTableTableManager(
      $_db,
      $_db.readingProgress,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ReaderPreferencesRowsTable,
    List<ReaderPreferencesRow>
  >
  _readerPreferencesRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.readerPreferencesRows,
        aliasName: $_aliasNameGenerator(
          db.contentCollections.id,
          db.readerPreferencesRows.collectionId,
        ),
      );

  $$ReaderPreferencesRowsTableProcessedTableManager
  get readerPreferencesRowsRefs {
    final manager = $$ReaderPreferencesRowsTableTableManager(
      $_db,
      $_db.readerPreferencesRows,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readerPreferencesRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReaderBookmarksTable, List<ReaderBookmark>>
  _readerBookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readerBookmarks,
    aliasName: $_aliasNameGenerator(
      db.contentCollections.id,
      db.readerBookmarks.collectionId,
    ),
  );

  $$ReaderBookmarksTableProcessedTableManager get readerBookmarksRefs {
    final manager = $$ReaderBookmarksTableTableManager(
      $_db,
      $_db.readerBookmarks,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readerBookmarksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingHistoryTable, List<ReadingHistoryData>>
  _readingHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingHistory,
    aliasName: $_aliasNameGenerator(
      db.contentCollections.id,
      db.readingHistory.collectionId,
    ),
  );

  $$ReadingHistoryTableProcessedTableManager get readingHistoryRefs {
    final manager = $$ReadingHistoryTableTableManager(
      $_db,
      $_db.readingHistory,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContentCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentCollectionsTable> {
  $$ContentCollectionsTableFilterComposer({
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

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get normalizedCharacterLength => $composableBuilder(
    column: $table.normalizedCharacterLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingProgressRefs(
    Expression<bool> Function($$ReadingProgressTableFilterComposer f) f,
  ) {
    final $$ReadingProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableFilterComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readerPreferencesRowsRefs(
    Expression<bool> Function($$ReaderPreferencesRowsTableFilterComposer f) f,
  ) {
    final $$ReaderPreferencesRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.readerPreferencesRows,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReaderPreferencesRowsTableFilterComposer(
                $db: $db,
                $table: $db.readerPreferencesRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> readerBookmarksRefs(
    Expression<bool> Function($$ReaderBookmarksTableFilterComposer f) f,
  ) {
    final $$ReaderBookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readerBookmarks,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReaderBookmarksTableFilterComposer(
            $db: $db,
            $table: $db.readerBookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingHistoryRefs(
    Expression<bool> Function($$ReadingHistoryTableFilterComposer f) f,
  ) {
    final $$ReadingHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableFilterComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContentCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentCollectionsTable> {
  $$ContentCollectionsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get normalizedCharacterLength => $composableBuilder(
    column: $table.normalizedCharacterLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentCollectionsTable> {
  $$ContentCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<int> get normalizedCharacterLength => $composableBuilder(
    column: $table.normalizedCharacterLength,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> readingProgressRefs<T extends Object>(
    Expression<T> Function($$ReadingProgressTableAnnotationComposer a) f,
  ) {
    final $$ReadingProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readerPreferencesRowsRefs<T extends Object>(
    Expression<T> Function($$ReaderPreferencesRowsTableAnnotationComposer a) f,
  ) {
    final $$ReaderPreferencesRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.readerPreferencesRows,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReaderPreferencesRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.readerPreferencesRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> readerBookmarksRefs<T extends Object>(
    Expression<T> Function($$ReaderBookmarksTableAnnotationComposer a) f,
  ) {
    final $$ReaderBookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readerBookmarks,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReaderBookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.readerBookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingHistoryRefs<T extends Object>(
    Expression<T> Function($$ReadingHistoryTableAnnotationComposer a) f,
  ) {
    final $$ReadingHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContentCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentCollectionsTable,
          ContentCollection,
          $$ContentCollectionsTableFilterComposer,
          $$ContentCollectionsTableOrderingComposer,
          $$ContentCollectionsTableAnnotationComposer,
          $$ContentCollectionsTableCreateCompanionBuilder,
          $$ContentCollectionsTableUpdateCompanionBuilder,
          (ContentCollection, $$ContentCollectionsTableReferences),
          ContentCollection,
          PrefetchHooks Function({
            bool readingProgressRefs,
            bool readerPreferencesRowsRefs,
            bool readerBookmarksRefs,
            bool readingHistoryRefs,
          })
        > {
  $$ContentCollectionsTableTableManager(
    _$AppDatabase db,
    $ContentCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentCollectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int> normalizedCharacterLength = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentCollectionsCompanion(
                id: id,
                sourceId: sourceId,
                title: title,
                subtitle: subtitle,
                itemCount: itemCount,
                normalizedCharacterLength: normalizedCharacterLength,
                importedAt: importedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                required int itemCount,
                required int normalizedCharacterLength,
                required DateTime importedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentCollectionsCompanion.insert(
                id: id,
                sourceId: sourceId,
                title: title,
                subtitle: subtitle,
                itemCount: itemCount,
                normalizedCharacterLength: normalizedCharacterLength,
                importedAt: importedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContentCollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                readingProgressRefs = false,
                readerPreferencesRowsRefs = false,
                readerBookmarksRefs = false,
                readingHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (readingProgressRefs) db.readingProgress,
                    if (readerPreferencesRowsRefs) db.readerPreferencesRows,
                    if (readerBookmarksRefs) db.readerBookmarks,
                    if (readingHistoryRefs) db.readingHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (readingProgressRefs)
                        await $_getPrefetchedData<
                          ContentCollection,
                          $ContentCollectionsTable,
                          ReadingProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$ContentCollectionsTableReferences
                              ._readingProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContentCollectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).readingProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.collectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readerPreferencesRowsRefs)
                        await $_getPrefetchedData<
                          ContentCollection,
                          $ContentCollectionsTable,
                          ReaderPreferencesRow
                        >(
                          currentTable: table,
                          referencedTable: $$ContentCollectionsTableReferences
                              ._readerPreferencesRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContentCollectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).readerPreferencesRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.collectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readerBookmarksRefs)
                        await $_getPrefetchedData<
                          ContentCollection,
                          $ContentCollectionsTable,
                          ReaderBookmark
                        >(
                          currentTable: table,
                          referencedTable: $$ContentCollectionsTableReferences
                              ._readerBookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContentCollectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).readerBookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.collectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingHistoryRefs)
                        await $_getPrefetchedData<
                          ContentCollection,
                          $ContentCollectionsTable,
                          ReadingHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ContentCollectionsTableReferences
                              ._readingHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContentCollectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).readingHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.collectionId == item.id,
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

typedef $$ContentCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentCollectionsTable,
      ContentCollection,
      $$ContentCollectionsTableFilterComposer,
      $$ContentCollectionsTableOrderingComposer,
      $$ContentCollectionsTableAnnotationComposer,
      $$ContentCollectionsTableCreateCompanionBuilder,
      $$ContentCollectionsTableUpdateCompanionBuilder,
      (ContentCollection, $$ContentCollectionsTableReferences),
      ContentCollection,
      PrefetchHooks Function({
        bool readingProgressRefs,
        bool readerPreferencesRowsRefs,
        bool readerBookmarksRefs,
        bool readingHistoryRefs,
      })
    >;
typedef $$ContentItemsTableCreateCompanionBuilder =
    ContentItemsCompanion Function({
      required String id,
      required String collectionId,
      required String kind,
      required String title,
      required int orderIndex,
      required int startCharacterOffset,
      required int endCharacterOffset,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ContentItemsTableUpdateCompanionBuilder =
    ContentItemsCompanion Function({
      Value<String> id,
      Value<String> collectionId,
      Value<String> kind,
      Value<String> title,
      Value<int> orderIndex,
      Value<int> startCharacterOffset,
      Value<int> endCharacterOffset,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ContentItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentItemsTable> {
  $$ContentItemsTableFilterComposer({
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

  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentItemsTable> {
  $$ContentItemsTableOrderingComposer({
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

  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentItemsTable> {
  $$ContentItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ContentItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentItemsTable,
          ContentItem,
          $$ContentItemsTableFilterComposer,
          $$ContentItemsTableOrderingComposer,
          $$ContentItemsTableAnnotationComposer,
          $$ContentItemsTableCreateCompanionBuilder,
          $$ContentItemsTableUpdateCompanionBuilder,
          (
            ContentItem,
            BaseReferences<_$AppDatabase, $ContentItemsTable, ContentItem>,
          ),
          ContentItem,
          PrefetchHooks Function()
        > {
  $$ContentItemsTableTableManager(_$AppDatabase db, $ContentItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> startCharacterOffset = const Value.absent(),
                Value<int> endCharacterOffset = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentItemsCompanion(
                id: id,
                collectionId: collectionId,
                kind: kind,
                title: title,
                orderIndex: orderIndex,
                startCharacterOffset: startCharacterOffset,
                endCharacterOffset: endCharacterOffset,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String collectionId,
                required String kind,
                required String title,
                required int orderIndex,
                required int startCharacterOffset,
                required int endCharacterOffset,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentItemsCompanion.insert(
                id: id,
                collectionId: collectionId,
                kind: kind,
                title: title,
                orderIndex: orderIndex,
                startCharacterOffset: startCharacterOffset,
                endCharacterOffset: endCharacterOffset,
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

typedef $$ContentItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentItemsTable,
      ContentItem,
      $$ContentItemsTableFilterComposer,
      $$ContentItemsTableOrderingComposer,
      $$ContentItemsTableAnnotationComposer,
      $$ContentItemsTableCreateCompanionBuilder,
      $$ContentItemsTableUpdateCompanionBuilder,
      (
        ContentItem,
        BaseReferences<_$AppDatabase, $ContentItemsTable, ContentItem>,
      ),
      ContentItem,
      PrefetchHooks Function()
    >;
typedef $$ContentDocumentsTableCreateCompanionBuilder =
    ContentDocumentsCompanion Function({
      required String id,
      required String itemId,
      required String storagePath,
      required String mediaType,
      required int startCharacterOffset,
      required int endCharacterOffset,
      required String contentHash,
      required String normalizationVersion,
      Value<int> rowid,
    });
typedef $$ContentDocumentsTableUpdateCompanionBuilder =
    ContentDocumentsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> storagePath,
      Value<String> mediaType,
      Value<int> startCharacterOffset,
      Value<int> endCharacterOffset,
      Value<String> contentHash,
      Value<String> normalizationVersion,
      Value<int> rowid,
    });

class $$ContentDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentDocumentsTable> {
  $$ContentDocumentsTableFilterComposer({
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

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizationVersion => $composableBuilder(
    column: $table.normalizationVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentDocumentsTable> {
  $$ContentDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizationVersion => $composableBuilder(
    column: $table.normalizationVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentDocumentsTable> {
  $$ContentDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizationVersion => $composableBuilder(
    column: $table.normalizationVersion,
    builder: (column) => column,
  );
}

class $$ContentDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentDocumentsTable,
          ContentDocument,
          $$ContentDocumentsTableFilterComposer,
          $$ContentDocumentsTableOrderingComposer,
          $$ContentDocumentsTableAnnotationComposer,
          $$ContentDocumentsTableCreateCompanionBuilder,
          $$ContentDocumentsTableUpdateCompanionBuilder,
          (
            ContentDocument,
            BaseReferences<
              _$AppDatabase,
              $ContentDocumentsTable,
              ContentDocument
            >,
          ),
          ContentDocument,
          PrefetchHooks Function()
        > {
  $$ContentDocumentsTableTableManager(
    _$AppDatabase db,
    $ContentDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> storagePath = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int> startCharacterOffset = const Value.absent(),
                Value<int> endCharacterOffset = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> normalizationVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentDocumentsCompanion(
                id: id,
                itemId: itemId,
                storagePath: storagePath,
                mediaType: mediaType,
                startCharacterOffset: startCharacterOffset,
                endCharacterOffset: endCharacterOffset,
                contentHash: contentHash,
                normalizationVersion: normalizationVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String storagePath,
                required String mediaType,
                required int startCharacterOffset,
                required int endCharacterOffset,
                required String contentHash,
                required String normalizationVersion,
                Value<int> rowid = const Value.absent(),
              }) => ContentDocumentsCompanion.insert(
                id: id,
                itemId: itemId,
                storagePath: storagePath,
                mediaType: mediaType,
                startCharacterOffset: startCharacterOffset,
                endCharacterOffset: endCharacterOffset,
                contentHash: contentHash,
                normalizationVersion: normalizationVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentDocumentsTable,
      ContentDocument,
      $$ContentDocumentsTableFilterComposer,
      $$ContentDocumentsTableOrderingComposer,
      $$ContentDocumentsTableAnnotationComposer,
      $$ContentDocumentsTableCreateCompanionBuilder,
      $$ContentDocumentsTableUpdateCompanionBuilder,
      (
        ContentDocument,
        BaseReferences<_$AppDatabase, $ContentDocumentsTable, ContentDocument>,
      ),
      ContentDocument,
      PrefetchHooks Function()
    >;
typedef $$TocEntriesTableCreateCompanionBuilder =
    TocEntriesCompanion Function({
      required String id,
      required String collectionId,
      Value<String?> itemId,
      Value<String?> parentId,
      required String kind,
      required int level,
      required String title,
      required int orderIndex,
      required int startCharacterOffset,
      required int endCharacterOffset,
      Value<int> rowid,
    });
typedef $$TocEntriesTableUpdateCompanionBuilder =
    TocEntriesCompanion Function({
      Value<String> id,
      Value<String> collectionId,
      Value<String?> itemId,
      Value<String?> parentId,
      Value<String> kind,
      Value<int> level,
      Value<String> title,
      Value<int> orderIndex,
      Value<int> startCharacterOffset,
      Value<int> endCharacterOffset,
      Value<int> rowid,
    });

class $$TocEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TocEntriesTable> {
  $$TocEntriesTableFilterComposer({
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

  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TocEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TocEntriesTable> {
  $$TocEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TocEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TocEntriesTable> {
  $$TocEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startCharacterOffset => $composableBuilder(
    column: $table.startCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endCharacterOffset => $composableBuilder(
    column: $table.endCharacterOffset,
    builder: (column) => column,
  );
}

class $$TocEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TocEntriesTable,
          TocEntry,
          $$TocEntriesTableFilterComposer,
          $$TocEntriesTableOrderingComposer,
          $$TocEntriesTableAnnotationComposer,
          $$TocEntriesTableCreateCompanionBuilder,
          $$TocEntriesTableUpdateCompanionBuilder,
          (TocEntry, BaseReferences<_$AppDatabase, $TocEntriesTable, TocEntry>),
          TocEntry,
          PrefetchHooks Function()
        > {
  $$TocEntriesTableTableManager(_$AppDatabase db, $TocEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TocEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TocEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TocEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> startCharacterOffset = const Value.absent(),
                Value<int> endCharacterOffset = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TocEntriesCompanion(
                id: id,
                collectionId: collectionId,
                itemId: itemId,
                parentId: parentId,
                kind: kind,
                level: level,
                title: title,
                orderIndex: orderIndex,
                startCharacterOffset: startCharacterOffset,
                endCharacterOffset: endCharacterOffset,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String collectionId,
                Value<String?> itemId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                required String kind,
                required int level,
                required String title,
                required int orderIndex,
                required int startCharacterOffset,
                required int endCharacterOffset,
                Value<int> rowid = const Value.absent(),
              }) => TocEntriesCompanion.insert(
                id: id,
                collectionId: collectionId,
                itemId: itemId,
                parentId: parentId,
                kind: kind,
                level: level,
                title: title,
                orderIndex: orderIndex,
                startCharacterOffset: startCharacterOffset,
                endCharacterOffset: endCharacterOffset,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TocEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TocEntriesTable,
      TocEntry,
      $$TocEntriesTableFilterComposer,
      $$TocEntriesTableOrderingComposer,
      $$TocEntriesTableAnnotationComposer,
      $$TocEntriesTableCreateCompanionBuilder,
      $$TocEntriesTableUpdateCompanionBuilder,
      (TocEntry, BaseReferences<_$AppDatabase, $TocEntriesTable, TocEntry>),
      TocEntry,
      PrefetchHooks Function()
    >;
typedef $$ImportRecordsTableCreateCompanionBuilder =
    ImportRecordsCompanion Function({
      required String id,
      required String sourceHash,
      required String state,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$ImportRecordsTableUpdateCompanionBuilder =
    ImportRecordsCompanion Function({
      Value<String> id,
      Value<String> sourceHash,
      Value<String> state,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$ImportRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportRecordsTable> {
  $$ImportRecordsTableFilterComposer({
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

  ColumnFilters<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportRecordsTable> {
  $$ImportRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportRecordsTable> {
  $$ImportRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$ImportRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportRecordsTable,
          ImportRecord,
          $$ImportRecordsTableFilterComposer,
          $$ImportRecordsTableOrderingComposer,
          $$ImportRecordsTableAnnotationComposer,
          $$ImportRecordsTableCreateCompanionBuilder,
          $$ImportRecordsTableUpdateCompanionBuilder,
          (
            ImportRecord,
            BaseReferences<_$AppDatabase, $ImportRecordsTable, ImportRecord>,
          ),
          ImportRecord,
          PrefetchHooks Function()
        > {
  $$ImportRecordsTableTableManager(_$AppDatabase db, $ImportRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceHash = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportRecordsCompanion(
                id: id,
                sourceHash: sourceHash,
                state: state,
                startedAt: startedAt,
                completedAt: completedAt,
                errorCode: errorCode,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceHash,
                required String state,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportRecordsCompanion.insert(
                id: id,
                sourceHash: sourceHash,
                state: state,
                startedAt: startedAt,
                completedAt: completedAt,
                errorCode: errorCode,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportRecordsTable,
      ImportRecord,
      $$ImportRecordsTableFilterComposer,
      $$ImportRecordsTableOrderingComposer,
      $$ImportRecordsTableAnnotationComposer,
      $$ImportRecordsTableCreateCompanionBuilder,
      $$ImportRecordsTableUpdateCompanionBuilder,
      (
        ImportRecord,
        BaseReferences<_$AppDatabase, $ImportRecordsTable, ImportRecord>,
      ),
      ImportRecord,
      PrefetchHooks Function()
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      required String collectionId,
      required int absoluteCharacterOffset,
      Value<String> readingMode,
      Value<String?> itemIdHint,
      required DateTime updatedAt,
      required int locatorVersion,
      required String normalizationVersion,
      Value<int> rowid,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<String> collectionId,
      Value<int> absoluteCharacterOffset,
      Value<String> readingMode,
      Value<String?> itemIdHint,
      Value<DateTime> updatedAt,
      Value<int> locatorVersion,
      Value<String> normalizationVersion,
      Value<int> rowid,
    });

final class $$ReadingProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressData
        > {
  $$ReadingProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContentCollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.contentCollections.createAlias(
        $_aliasNameGenerator(
          db.readingProgress.collectionId,
          db.contentCollections.id,
        ),
      );

  $$ContentCollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$ContentCollectionsTableTableManager(
      $_db,
      $_db.contentCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get absoluteCharacterOffset => $composableBuilder(
    column: $table.absoluteCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingMode => $composableBuilder(
    column: $table.readingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemIdHint => $composableBuilder(
    column: $table.itemIdHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get locatorVersion => $composableBuilder(
    column: $table.locatorVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizationVersion => $composableBuilder(
    column: $table.normalizationVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ContentCollectionsTableFilterComposer get collectionId {
    final $$ContentCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get absoluteCharacterOffset => $composableBuilder(
    column: $table.absoluteCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingMode => $composableBuilder(
    column: $table.readingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemIdHint => $composableBuilder(
    column: $table.itemIdHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get locatorVersion => $composableBuilder(
    column: $table.locatorVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizationVersion => $composableBuilder(
    column: $table.normalizationVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContentCollectionsTableOrderingComposer get collectionId {
    final $$ContentCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get absoluteCharacterOffset => $composableBuilder(
    column: $table.absoluteCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readingMode => $composableBuilder(
    column: $table.readingMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemIdHint => $composableBuilder(
    column: $table.itemIdHint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get locatorVersion => $composableBuilder(
    column: $table.locatorVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizationVersion => $composableBuilder(
    column: $table.normalizationVersion,
    builder: (column) => column,
  );

  $$ContentCollectionsTableAnnotationComposer get collectionId {
    final $$ContentCollectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.collectionId,
          referencedTable: $db.contentCollections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentCollectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contentCollections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressData,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (ReadingProgressData, $$ReadingProgressTableReferences),
          ReadingProgressData,
          PrefetchHooks Function({bool collectionId})
        > {
  $$ReadingProgressTableTableManager(
    _$AppDatabase db,
    $ReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<int> absoluteCharacterOffset = const Value.absent(),
                Value<String> readingMode = const Value.absent(),
                Value<String?> itemIdHint = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> locatorVersion = const Value.absent(),
                Value<String> normalizationVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion(
                collectionId: collectionId,
                absoluteCharacterOffset: absoluteCharacterOffset,
                readingMode: readingMode,
                itemIdHint: itemIdHint,
                updatedAt: updatedAt,
                locatorVersion: locatorVersion,
                normalizationVersion: normalizationVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required int absoluteCharacterOffset,
                Value<String> readingMode = const Value.absent(),
                Value<String?> itemIdHint = const Value.absent(),
                required DateTime updatedAt,
                required int locatorVersion,
                required String normalizationVersion,
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                collectionId: collectionId,
                absoluteCharacterOffset: absoluteCharacterOffset,
                readingMode: readingMode,
                itemIdHint: itemIdHint,
                updatedAt: updatedAt,
                locatorVersion: locatorVersion,
                normalizationVersion: normalizationVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false}) {
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
                    if (collectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.collectionId,
                                referencedTable:
                                    $$ReadingProgressTableReferences
                                        ._collectionIdTable(db),
                                referencedColumn:
                                    $$ReadingProgressTableReferences
                                        ._collectionIdTable(db)
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

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingProgressTable,
      ReadingProgressData,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (ReadingProgressData, $$ReadingProgressTableReferences),
      ReadingProgressData,
      PrefetchHooks Function({bool collectionId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$ReaderPreferencesRowsTableCreateCompanionBuilder =
    ReaderPreferencesRowsCompanion Function({
      required String collectionId,
      Value<String?> fontId,
      required double fontSize,
      required double letterSpacing,
      required double lineHeight,
      required double paragraphSpacing,
      required double firstLineIndent,
      required double paddingTop,
      required double paddingBottom,
      required double paddingLeft,
      required double paddingRight,
      required String themeMode,
      Value<String> paletteId,
      Value<int?> textColorArgb,
      Value<int?> backgroundColorArgb,
      Value<int?> lightTextColorArgb,
      Value<int?> lightBackgroundColorArgb,
      Value<int?> darkTextColorArgb,
      Value<int?> darkBackgroundColorArgb,
      Value<String?> backgroundImagePath,
      Value<double> backgroundImageOpacity,
      Value<double> backgroundOverlayOpacity,
      Value<bool> showTopInfoBar,
      Value<bool> showBottomInfoBar,
      Value<bool> showProgressInfo,
      Value<bool> showSystemStatusBar,
      Value<String> statusBarMode,
      Value<String> timeDisplayMode,
      Value<bool> showChapterInfo,
      Value<bool> showChapterProgressInfo,
      Value<bool> showClockInfo,
      Value<bool> showWholeBookProgressInfo,
      Value<bool> showInfoDivider,
      Value<bool> showTopInfoDivider,
      Value<bool> showBottomInfoDivider,
      Value<bool> showAutoReadMinimalInfo,
      Value<String> chapterInfoSlot,
      Value<String> chapterProgressInfoSlot,
      Value<String> clockInfoSlot,
      Value<String> wholeBookProgressInfoSlot,
      Value<String> infoDividerSlot,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReaderPreferencesRowsTableUpdateCompanionBuilder =
    ReaderPreferencesRowsCompanion Function({
      Value<String> collectionId,
      Value<String?> fontId,
      Value<double> fontSize,
      Value<double> letterSpacing,
      Value<double> lineHeight,
      Value<double> paragraphSpacing,
      Value<double> firstLineIndent,
      Value<double> paddingTop,
      Value<double> paddingBottom,
      Value<double> paddingLeft,
      Value<double> paddingRight,
      Value<String> themeMode,
      Value<String> paletteId,
      Value<int?> textColorArgb,
      Value<int?> backgroundColorArgb,
      Value<int?> lightTextColorArgb,
      Value<int?> lightBackgroundColorArgb,
      Value<int?> darkTextColorArgb,
      Value<int?> darkBackgroundColorArgb,
      Value<String?> backgroundImagePath,
      Value<double> backgroundImageOpacity,
      Value<double> backgroundOverlayOpacity,
      Value<bool> showTopInfoBar,
      Value<bool> showBottomInfoBar,
      Value<bool> showProgressInfo,
      Value<bool> showSystemStatusBar,
      Value<String> statusBarMode,
      Value<String> timeDisplayMode,
      Value<bool> showChapterInfo,
      Value<bool> showChapterProgressInfo,
      Value<bool> showClockInfo,
      Value<bool> showWholeBookProgressInfo,
      Value<bool> showInfoDivider,
      Value<bool> showTopInfoDivider,
      Value<bool> showBottomInfoDivider,
      Value<bool> showAutoReadMinimalInfo,
      Value<String> chapterInfoSlot,
      Value<String> chapterProgressInfoSlot,
      Value<String> clockInfoSlot,
      Value<String> wholeBookProgressInfoSlot,
      Value<String> infoDividerSlot,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReaderPreferencesRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReaderPreferencesRowsTable,
          ReaderPreferencesRow
        > {
  $$ReaderPreferencesRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContentCollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.contentCollections.createAlias(
        $_aliasNameGenerator(
          db.readerPreferencesRows.collectionId,
          db.contentCollections.id,
        ),
      );

  $$ContentCollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$ContentCollectionsTableTableManager(
      $_db,
      $_db.contentCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReaderPreferencesRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderPreferencesRowsTable> {
  $$ReaderPreferencesRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fontId => $composableBuilder(
    column: $table.fontId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get letterSpacing => $composableBuilder(
    column: $table.letterSpacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineHeight => $composableBuilder(
    column: $table.lineHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paragraphSpacing => $composableBuilder(
    column: $table.paragraphSpacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get firstLineIndent => $composableBuilder(
    column: $table.firstLineIndent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paddingTop => $composableBuilder(
    column: $table.paddingTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paddingBottom => $composableBuilder(
    column: $table.paddingBottom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paddingLeft => $composableBuilder(
    column: $table.paddingLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paddingRight => $composableBuilder(
    column: $table.paddingRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paletteId => $composableBuilder(
    column: $table.paletteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textColorArgb => $composableBuilder(
    column: $table.textColorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backgroundColorArgb => $composableBuilder(
    column: $table.backgroundColorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lightTextColorArgb => $composableBuilder(
    column: $table.lightTextColorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lightBackgroundColorArgb => $composableBuilder(
    column: $table.lightBackgroundColorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get darkTextColorArgb => $composableBuilder(
    column: $table.darkTextColorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get darkBackgroundColorArgb => $composableBuilder(
    column: $table.darkBackgroundColorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundImagePath => $composableBuilder(
    column: $table.backgroundImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get backgroundImageOpacity => $composableBuilder(
    column: $table.backgroundImageOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get backgroundOverlayOpacity => $composableBuilder(
    column: $table.backgroundOverlayOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showTopInfoBar => $composableBuilder(
    column: $table.showTopInfoBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showBottomInfoBar => $composableBuilder(
    column: $table.showBottomInfoBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showProgressInfo => $composableBuilder(
    column: $table.showProgressInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showSystemStatusBar => $composableBuilder(
    column: $table.showSystemStatusBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusBarMode => $composableBuilder(
    column: $table.statusBarMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeDisplayMode => $composableBuilder(
    column: $table.timeDisplayMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showChapterInfo => $composableBuilder(
    column: $table.showChapterInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showChapterProgressInfo => $composableBuilder(
    column: $table.showChapterProgressInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showClockInfo => $composableBuilder(
    column: $table.showClockInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showWholeBookProgressInfo => $composableBuilder(
    column: $table.showWholeBookProgressInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showInfoDivider => $composableBuilder(
    column: $table.showInfoDivider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showTopInfoDivider => $composableBuilder(
    column: $table.showTopInfoDivider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showBottomInfoDivider => $composableBuilder(
    column: $table.showBottomInfoDivider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showAutoReadMinimalInfo => $composableBuilder(
    column: $table.showAutoReadMinimalInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterInfoSlot => $composableBuilder(
    column: $table.chapterInfoSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterProgressInfoSlot => $composableBuilder(
    column: $table.chapterProgressInfoSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clockInfoSlot => $composableBuilder(
    column: $table.clockInfoSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wholeBookProgressInfoSlot => $composableBuilder(
    column: $table.wholeBookProgressInfoSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get infoDividerSlot => $composableBuilder(
    column: $table.infoDividerSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContentCollectionsTableFilterComposer get collectionId {
    final $$ContentCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPreferencesRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderPreferencesRowsTable> {
  $$ReaderPreferencesRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fontId => $composableBuilder(
    column: $table.fontId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get letterSpacing => $composableBuilder(
    column: $table.letterSpacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineHeight => $composableBuilder(
    column: $table.lineHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paragraphSpacing => $composableBuilder(
    column: $table.paragraphSpacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get firstLineIndent => $composableBuilder(
    column: $table.firstLineIndent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paddingTop => $composableBuilder(
    column: $table.paddingTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paddingBottom => $composableBuilder(
    column: $table.paddingBottom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paddingLeft => $composableBuilder(
    column: $table.paddingLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paddingRight => $composableBuilder(
    column: $table.paddingRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paletteId => $composableBuilder(
    column: $table.paletteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textColorArgb => $composableBuilder(
    column: $table.textColorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backgroundColorArgb => $composableBuilder(
    column: $table.backgroundColorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lightTextColorArgb => $composableBuilder(
    column: $table.lightTextColorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lightBackgroundColorArgb => $composableBuilder(
    column: $table.lightBackgroundColorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get darkTextColorArgb => $composableBuilder(
    column: $table.darkTextColorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get darkBackgroundColorArgb => $composableBuilder(
    column: $table.darkBackgroundColorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundImagePath => $composableBuilder(
    column: $table.backgroundImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get backgroundImageOpacity => $composableBuilder(
    column: $table.backgroundImageOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get backgroundOverlayOpacity => $composableBuilder(
    column: $table.backgroundOverlayOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showTopInfoBar => $composableBuilder(
    column: $table.showTopInfoBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showBottomInfoBar => $composableBuilder(
    column: $table.showBottomInfoBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showProgressInfo => $composableBuilder(
    column: $table.showProgressInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showSystemStatusBar => $composableBuilder(
    column: $table.showSystemStatusBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusBarMode => $composableBuilder(
    column: $table.statusBarMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeDisplayMode => $composableBuilder(
    column: $table.timeDisplayMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showChapterInfo => $composableBuilder(
    column: $table.showChapterInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showChapterProgressInfo => $composableBuilder(
    column: $table.showChapterProgressInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showClockInfo => $composableBuilder(
    column: $table.showClockInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showWholeBookProgressInfo => $composableBuilder(
    column: $table.showWholeBookProgressInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showInfoDivider => $composableBuilder(
    column: $table.showInfoDivider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showTopInfoDivider => $composableBuilder(
    column: $table.showTopInfoDivider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showBottomInfoDivider => $composableBuilder(
    column: $table.showBottomInfoDivider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showAutoReadMinimalInfo => $composableBuilder(
    column: $table.showAutoReadMinimalInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterInfoSlot => $composableBuilder(
    column: $table.chapterInfoSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterProgressInfoSlot => $composableBuilder(
    column: $table.chapterProgressInfoSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clockInfoSlot => $composableBuilder(
    column: $table.clockInfoSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wholeBookProgressInfoSlot => $composableBuilder(
    column: $table.wholeBookProgressInfoSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get infoDividerSlot => $composableBuilder(
    column: $table.infoDividerSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContentCollectionsTableOrderingComposer get collectionId {
    final $$ContentCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPreferencesRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderPreferencesRowsTable> {
  $$ReaderPreferencesRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fontId =>
      $composableBuilder(column: $table.fontId, builder: (column) => column);

  GeneratedColumn<double> get fontSize =>
      $composableBuilder(column: $table.fontSize, builder: (column) => column);

  GeneratedColumn<double> get letterSpacing => $composableBuilder(
    column: $table.letterSpacing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lineHeight => $composableBuilder(
    column: $table.lineHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paragraphSpacing => $composableBuilder(
    column: $table.paragraphSpacing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get firstLineIndent => $composableBuilder(
    column: $table.firstLineIndent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paddingTop => $composableBuilder(
    column: $table.paddingTop,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paddingBottom => $composableBuilder(
    column: $table.paddingBottom,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paddingLeft => $composableBuilder(
    column: $table.paddingLeft,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paddingRight => $composableBuilder(
    column: $table.paddingRight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get paletteId =>
      $composableBuilder(column: $table.paletteId, builder: (column) => column);

  GeneratedColumn<int> get textColorArgb => $composableBuilder(
    column: $table.textColorArgb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get backgroundColorArgb => $composableBuilder(
    column: $table.backgroundColorArgb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lightTextColorArgb => $composableBuilder(
    column: $table.lightTextColorArgb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lightBackgroundColorArgb => $composableBuilder(
    column: $table.lightBackgroundColorArgb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get darkTextColorArgb => $composableBuilder(
    column: $table.darkTextColorArgb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get darkBackgroundColorArgb => $composableBuilder(
    column: $table.darkBackgroundColorArgb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundImagePath => $composableBuilder(
    column: $table.backgroundImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get backgroundImageOpacity => $composableBuilder(
    column: $table.backgroundImageOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get backgroundOverlayOpacity => $composableBuilder(
    column: $table.backgroundOverlayOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showTopInfoBar => $composableBuilder(
    column: $table.showTopInfoBar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showBottomInfoBar => $composableBuilder(
    column: $table.showBottomInfoBar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showProgressInfo => $composableBuilder(
    column: $table.showProgressInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showSystemStatusBar => $composableBuilder(
    column: $table.showSystemStatusBar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusBarMode => $composableBuilder(
    column: $table.statusBarMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeDisplayMode => $composableBuilder(
    column: $table.timeDisplayMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showChapterInfo => $composableBuilder(
    column: $table.showChapterInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showChapterProgressInfo => $composableBuilder(
    column: $table.showChapterProgressInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showClockInfo => $composableBuilder(
    column: $table.showClockInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showWholeBookProgressInfo => $composableBuilder(
    column: $table.showWholeBookProgressInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showInfoDivider => $composableBuilder(
    column: $table.showInfoDivider,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showTopInfoDivider => $composableBuilder(
    column: $table.showTopInfoDivider,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showBottomInfoDivider => $composableBuilder(
    column: $table.showBottomInfoDivider,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showAutoReadMinimalInfo => $composableBuilder(
    column: $table.showAutoReadMinimalInfo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chapterInfoSlot => $composableBuilder(
    column: $table.chapterInfoSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chapterProgressInfoSlot => $composableBuilder(
    column: $table.chapterProgressInfoSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clockInfoSlot => $composableBuilder(
    column: $table.clockInfoSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wholeBookProgressInfoSlot => $composableBuilder(
    column: $table.wholeBookProgressInfoSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get infoDividerSlot => $composableBuilder(
    column: $table.infoDividerSlot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ContentCollectionsTableAnnotationComposer get collectionId {
    final $$ContentCollectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.collectionId,
          referencedTable: $db.contentCollections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentCollectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contentCollections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReaderPreferencesRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderPreferencesRowsTable,
          ReaderPreferencesRow,
          $$ReaderPreferencesRowsTableFilterComposer,
          $$ReaderPreferencesRowsTableOrderingComposer,
          $$ReaderPreferencesRowsTableAnnotationComposer,
          $$ReaderPreferencesRowsTableCreateCompanionBuilder,
          $$ReaderPreferencesRowsTableUpdateCompanionBuilder,
          (ReaderPreferencesRow, $$ReaderPreferencesRowsTableReferences),
          ReaderPreferencesRow,
          PrefetchHooks Function({bool collectionId})
        > {
  $$ReaderPreferencesRowsTableTableManager(
    _$AppDatabase db,
    $ReaderPreferencesRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderPreferencesRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ReaderPreferencesRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReaderPreferencesRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String?> fontId = const Value.absent(),
                Value<double> fontSize = const Value.absent(),
                Value<double> letterSpacing = const Value.absent(),
                Value<double> lineHeight = const Value.absent(),
                Value<double> paragraphSpacing = const Value.absent(),
                Value<double> firstLineIndent = const Value.absent(),
                Value<double> paddingTop = const Value.absent(),
                Value<double> paddingBottom = const Value.absent(),
                Value<double> paddingLeft = const Value.absent(),
                Value<double> paddingRight = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> paletteId = const Value.absent(),
                Value<int?> textColorArgb = const Value.absent(),
                Value<int?> backgroundColorArgb = const Value.absent(),
                Value<int?> lightTextColorArgb = const Value.absent(),
                Value<int?> lightBackgroundColorArgb = const Value.absent(),
                Value<int?> darkTextColorArgb = const Value.absent(),
                Value<int?> darkBackgroundColorArgb = const Value.absent(),
                Value<String?> backgroundImagePath = const Value.absent(),
                Value<double> backgroundImageOpacity = const Value.absent(),
                Value<double> backgroundOverlayOpacity = const Value.absent(),
                Value<bool> showTopInfoBar = const Value.absent(),
                Value<bool> showBottomInfoBar = const Value.absent(),
                Value<bool> showProgressInfo = const Value.absent(),
                Value<bool> showSystemStatusBar = const Value.absent(),
                Value<String> statusBarMode = const Value.absent(),
                Value<String> timeDisplayMode = const Value.absent(),
                Value<bool> showChapterInfo = const Value.absent(),
                Value<bool> showChapterProgressInfo = const Value.absent(),
                Value<bool> showClockInfo = const Value.absent(),
                Value<bool> showWholeBookProgressInfo = const Value.absent(),
                Value<bool> showInfoDivider = const Value.absent(),
                Value<bool> showTopInfoDivider = const Value.absent(),
                Value<bool> showBottomInfoDivider = const Value.absent(),
                Value<bool> showAutoReadMinimalInfo = const Value.absent(),
                Value<String> chapterInfoSlot = const Value.absent(),
                Value<String> chapterProgressInfoSlot = const Value.absent(),
                Value<String> clockInfoSlot = const Value.absent(),
                Value<String> wholeBookProgressInfoSlot = const Value.absent(),
                Value<String> infoDividerSlot = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderPreferencesRowsCompanion(
                collectionId: collectionId,
                fontId: fontId,
                fontSize: fontSize,
                letterSpacing: letterSpacing,
                lineHeight: lineHeight,
                paragraphSpacing: paragraphSpacing,
                firstLineIndent: firstLineIndent,
                paddingTop: paddingTop,
                paddingBottom: paddingBottom,
                paddingLeft: paddingLeft,
                paddingRight: paddingRight,
                themeMode: themeMode,
                paletteId: paletteId,
                textColorArgb: textColorArgb,
                backgroundColorArgb: backgroundColorArgb,
                lightTextColorArgb: lightTextColorArgb,
                lightBackgroundColorArgb: lightBackgroundColorArgb,
                darkTextColorArgb: darkTextColorArgb,
                darkBackgroundColorArgb: darkBackgroundColorArgb,
                backgroundImagePath: backgroundImagePath,
                backgroundImageOpacity: backgroundImageOpacity,
                backgroundOverlayOpacity: backgroundOverlayOpacity,
                showTopInfoBar: showTopInfoBar,
                showBottomInfoBar: showBottomInfoBar,
                showProgressInfo: showProgressInfo,
                showSystemStatusBar: showSystemStatusBar,
                statusBarMode: statusBarMode,
                timeDisplayMode: timeDisplayMode,
                showChapterInfo: showChapterInfo,
                showChapterProgressInfo: showChapterProgressInfo,
                showClockInfo: showClockInfo,
                showWholeBookProgressInfo: showWholeBookProgressInfo,
                showInfoDivider: showInfoDivider,
                showTopInfoDivider: showTopInfoDivider,
                showBottomInfoDivider: showBottomInfoDivider,
                showAutoReadMinimalInfo: showAutoReadMinimalInfo,
                chapterInfoSlot: chapterInfoSlot,
                chapterProgressInfoSlot: chapterProgressInfoSlot,
                clockInfoSlot: clockInfoSlot,
                wholeBookProgressInfoSlot: wholeBookProgressInfoSlot,
                infoDividerSlot: infoDividerSlot,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                Value<String?> fontId = const Value.absent(),
                required double fontSize,
                required double letterSpacing,
                required double lineHeight,
                required double paragraphSpacing,
                required double firstLineIndent,
                required double paddingTop,
                required double paddingBottom,
                required double paddingLeft,
                required double paddingRight,
                required String themeMode,
                Value<String> paletteId = const Value.absent(),
                Value<int?> textColorArgb = const Value.absent(),
                Value<int?> backgroundColorArgb = const Value.absent(),
                Value<int?> lightTextColorArgb = const Value.absent(),
                Value<int?> lightBackgroundColorArgb = const Value.absent(),
                Value<int?> darkTextColorArgb = const Value.absent(),
                Value<int?> darkBackgroundColorArgb = const Value.absent(),
                Value<String?> backgroundImagePath = const Value.absent(),
                Value<double> backgroundImageOpacity = const Value.absent(),
                Value<double> backgroundOverlayOpacity = const Value.absent(),
                Value<bool> showTopInfoBar = const Value.absent(),
                Value<bool> showBottomInfoBar = const Value.absent(),
                Value<bool> showProgressInfo = const Value.absent(),
                Value<bool> showSystemStatusBar = const Value.absent(),
                Value<String> statusBarMode = const Value.absent(),
                Value<String> timeDisplayMode = const Value.absent(),
                Value<bool> showChapterInfo = const Value.absent(),
                Value<bool> showChapterProgressInfo = const Value.absent(),
                Value<bool> showClockInfo = const Value.absent(),
                Value<bool> showWholeBookProgressInfo = const Value.absent(),
                Value<bool> showInfoDivider = const Value.absent(),
                Value<bool> showTopInfoDivider = const Value.absent(),
                Value<bool> showBottomInfoDivider = const Value.absent(),
                Value<bool> showAutoReadMinimalInfo = const Value.absent(),
                Value<String> chapterInfoSlot = const Value.absent(),
                Value<String> chapterProgressInfoSlot = const Value.absent(),
                Value<String> clockInfoSlot = const Value.absent(),
                Value<String> wholeBookProgressInfoSlot = const Value.absent(),
                Value<String> infoDividerSlot = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReaderPreferencesRowsCompanion.insert(
                collectionId: collectionId,
                fontId: fontId,
                fontSize: fontSize,
                letterSpacing: letterSpacing,
                lineHeight: lineHeight,
                paragraphSpacing: paragraphSpacing,
                firstLineIndent: firstLineIndent,
                paddingTop: paddingTop,
                paddingBottom: paddingBottom,
                paddingLeft: paddingLeft,
                paddingRight: paddingRight,
                themeMode: themeMode,
                paletteId: paletteId,
                textColorArgb: textColorArgb,
                backgroundColorArgb: backgroundColorArgb,
                lightTextColorArgb: lightTextColorArgb,
                lightBackgroundColorArgb: lightBackgroundColorArgb,
                darkTextColorArgb: darkTextColorArgb,
                darkBackgroundColorArgb: darkBackgroundColorArgb,
                backgroundImagePath: backgroundImagePath,
                backgroundImageOpacity: backgroundImageOpacity,
                backgroundOverlayOpacity: backgroundOverlayOpacity,
                showTopInfoBar: showTopInfoBar,
                showBottomInfoBar: showBottomInfoBar,
                showProgressInfo: showProgressInfo,
                showSystemStatusBar: showSystemStatusBar,
                statusBarMode: statusBarMode,
                timeDisplayMode: timeDisplayMode,
                showChapterInfo: showChapterInfo,
                showChapterProgressInfo: showChapterProgressInfo,
                showClockInfo: showClockInfo,
                showWholeBookProgressInfo: showWholeBookProgressInfo,
                showInfoDivider: showInfoDivider,
                showTopInfoDivider: showTopInfoDivider,
                showBottomInfoDivider: showBottomInfoDivider,
                showAutoReadMinimalInfo: showAutoReadMinimalInfo,
                chapterInfoSlot: chapterInfoSlot,
                chapterProgressInfoSlot: chapterProgressInfoSlot,
                clockInfoSlot: clockInfoSlot,
                wholeBookProgressInfoSlot: wholeBookProgressInfoSlot,
                infoDividerSlot: infoDividerSlot,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReaderPreferencesRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false}) {
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
                    if (collectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.collectionId,
                                referencedTable:
                                    $$ReaderPreferencesRowsTableReferences
                                        ._collectionIdTable(db),
                                referencedColumn:
                                    $$ReaderPreferencesRowsTableReferences
                                        ._collectionIdTable(db)
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

typedef $$ReaderPreferencesRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderPreferencesRowsTable,
      ReaderPreferencesRow,
      $$ReaderPreferencesRowsTableFilterComposer,
      $$ReaderPreferencesRowsTableOrderingComposer,
      $$ReaderPreferencesRowsTableAnnotationComposer,
      $$ReaderPreferencesRowsTableCreateCompanionBuilder,
      $$ReaderPreferencesRowsTableUpdateCompanionBuilder,
      (ReaderPreferencesRow, $$ReaderPreferencesRowsTableReferences),
      ReaderPreferencesRow,
      PrefetchHooks Function({bool collectionId})
    >;
typedef $$ReaderFontAssetRowsTableCreateCompanionBuilder =
    ReaderFontAssetRowsCompanion Function({
      required String fontId,
      required String contentHash,
      required String relativePath,
      required String format,
      required String familyNameSnapshot,
      Value<String?> styleNameSnapshot,
      Value<int?> faceIndex,
      required int fileSize,
      required DateTime createdAt,
      required DateTime lastUsedAt,
      Value<String> availability,
      Value<int> rowid,
    });
typedef $$ReaderFontAssetRowsTableUpdateCompanionBuilder =
    ReaderFontAssetRowsCompanion Function({
      Value<String> fontId,
      Value<String> contentHash,
      Value<String> relativePath,
      Value<String> format,
      Value<String> familyNameSnapshot,
      Value<String?> styleNameSnapshot,
      Value<int?> faceIndex,
      Value<int> fileSize,
      Value<DateTime> createdAt,
      Value<DateTime> lastUsedAt,
      Value<String> availability,
      Value<int> rowid,
    });

class $$ReaderFontAssetRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderFontAssetRowsTable> {
  $$ReaderFontAssetRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fontId => $composableBuilder(
    column: $table.fontId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get familyNameSnapshot => $composableBuilder(
    column: $table.familyNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get styleNameSnapshot => $composableBuilder(
    column: $table.styleNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReaderFontAssetRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderFontAssetRowsTable> {
  $$ReaderFontAssetRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fontId => $composableBuilder(
    column: $table.fontId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get familyNameSnapshot => $composableBuilder(
    column: $table.familyNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styleNameSnapshot => $composableBuilder(
    column: $table.styleNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReaderFontAssetRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderFontAssetRowsTable> {
  $$ReaderFontAssetRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fontId =>
      $composableBuilder(column: $table.fontId, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get familyNameSnapshot => $composableBuilder(
    column: $table.familyNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get styleNameSnapshot => $composableBuilder(
    column: $table.styleNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get faceIndex =>
      $composableBuilder(column: $table.faceIndex, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );
}

class $$ReaderFontAssetRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderFontAssetRowsTable,
          ReaderFontAssetRow,
          $$ReaderFontAssetRowsTableFilterComposer,
          $$ReaderFontAssetRowsTableOrderingComposer,
          $$ReaderFontAssetRowsTableAnnotationComposer,
          $$ReaderFontAssetRowsTableCreateCompanionBuilder,
          $$ReaderFontAssetRowsTableUpdateCompanionBuilder,
          (
            ReaderFontAssetRow,
            BaseReferences<
              _$AppDatabase,
              $ReaderFontAssetRowsTable,
              ReaderFontAssetRow
            >,
          ),
          ReaderFontAssetRow,
          PrefetchHooks Function()
        > {
  $$ReaderFontAssetRowsTableTableManager(
    _$AppDatabase db,
    $ReaderFontAssetRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderFontAssetRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderFontAssetRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReaderFontAssetRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> fontId = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> familyNameSnapshot = const Value.absent(),
                Value<String?> styleNameSnapshot = const Value.absent(),
                Value<int?> faceIndex = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<String> availability = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderFontAssetRowsCompanion(
                fontId: fontId,
                contentHash: contentHash,
                relativePath: relativePath,
                format: format,
                familyNameSnapshot: familyNameSnapshot,
                styleNameSnapshot: styleNameSnapshot,
                faceIndex: faceIndex,
                fileSize: fileSize,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                availability: availability,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fontId,
                required String contentHash,
                required String relativePath,
                required String format,
                required String familyNameSnapshot,
                Value<String?> styleNameSnapshot = const Value.absent(),
                Value<int?> faceIndex = const Value.absent(),
                required int fileSize,
                required DateTime createdAt,
                required DateTime lastUsedAt,
                Value<String> availability = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderFontAssetRowsCompanion.insert(
                fontId: fontId,
                contentHash: contentHash,
                relativePath: relativePath,
                format: format,
                familyNameSnapshot: familyNameSnapshot,
                styleNameSnapshot: styleNameSnapshot,
                faceIndex: faceIndex,
                fileSize: fileSize,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                availability: availability,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReaderFontAssetRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderFontAssetRowsTable,
      ReaderFontAssetRow,
      $$ReaderFontAssetRowsTableFilterComposer,
      $$ReaderFontAssetRowsTableOrderingComposer,
      $$ReaderFontAssetRowsTableAnnotationComposer,
      $$ReaderFontAssetRowsTableCreateCompanionBuilder,
      $$ReaderFontAssetRowsTableUpdateCompanionBuilder,
      (
        ReaderFontAssetRow,
        BaseReferences<
          _$AppDatabase,
          $ReaderFontAssetRowsTable,
          ReaderFontAssetRow
        >,
      ),
      ReaderFontAssetRow,
      PrefetchHooks Function()
    >;
typedef $$ReaderBookmarksTableCreateCompanionBuilder =
    ReaderBookmarksCompanion Function({
      required String id,
      Value<String?> collectionId,
      required int absoluteCharacterOffset,
      Value<String?> normalizedHashAtCreation,
      required String bookTitleSnapshot,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReaderBookmarksTableUpdateCompanionBuilder =
    ReaderBookmarksCompanion Function({
      Value<String> id,
      Value<String?> collectionId,
      Value<int> absoluteCharacterOffset,
      Value<String?> normalizedHashAtCreation,
      Value<String> bookTitleSnapshot,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReaderBookmarksTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReaderBookmarksTable, ReaderBookmark> {
  $$ReaderBookmarksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContentCollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.contentCollections.createAlias(
        $_aliasNameGenerator(
          db.readerBookmarks.collectionId,
          db.contentCollections.id,
        ),
      );

  $$ContentCollectionsTableProcessedTableManager? get collectionId {
    final $_column = $_itemColumn<String>('collection_id');
    if ($_column == null) return null;
    final manager = $$ContentCollectionsTableTableManager(
      $_db,
      $_db.contentCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReaderBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderBookmarksTable> {
  $$ReaderBookmarksTableFilterComposer({
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

  ColumnFilters<int> get absoluteCharacterOffset => $composableBuilder(
    column: $table.absoluteCharacterOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedHashAtCreation => $composableBuilder(
    column: $table.normalizedHashAtCreation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookTitleSnapshot => $composableBuilder(
    column: $table.bookTitleSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  $$ContentCollectionsTableFilterComposer get collectionId {
    final $$ContentCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderBookmarksTable> {
  $$ReaderBookmarksTableOrderingComposer({
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

  ColumnOrderings<int> get absoluteCharacterOffset => $composableBuilder(
    column: $table.absoluteCharacterOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedHashAtCreation => $composableBuilder(
    column: $table.normalizedHashAtCreation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookTitleSnapshot => $composableBuilder(
    column: $table.bookTitleSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

  $$ContentCollectionsTableOrderingComposer get collectionId {
    final $$ContentCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderBookmarksTable> {
  $$ReaderBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get absoluteCharacterOffset => $composableBuilder(
    column: $table.absoluteCharacterOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedHashAtCreation => $composableBuilder(
    column: $table.normalizedHashAtCreation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookTitleSnapshot => $composableBuilder(
    column: $table.bookTitleSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ContentCollectionsTableAnnotationComposer get collectionId {
    final $$ContentCollectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.collectionId,
          referencedTable: $db.contentCollections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentCollectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contentCollections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReaderBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderBookmarksTable,
          ReaderBookmark,
          $$ReaderBookmarksTableFilterComposer,
          $$ReaderBookmarksTableOrderingComposer,
          $$ReaderBookmarksTableAnnotationComposer,
          $$ReaderBookmarksTableCreateCompanionBuilder,
          $$ReaderBookmarksTableUpdateCompanionBuilder,
          (ReaderBookmark, $$ReaderBookmarksTableReferences),
          ReaderBookmark,
          PrefetchHooks Function({bool collectionId})
        > {
  $$ReaderBookmarksTableTableManager(
    _$AppDatabase db,
    $ReaderBookmarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> collectionId = const Value.absent(),
                Value<int> absoluteCharacterOffset = const Value.absent(),
                Value<String?> normalizedHashAtCreation = const Value.absent(),
                Value<String> bookTitleSnapshot = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderBookmarksCompanion(
                id: id,
                collectionId: collectionId,
                absoluteCharacterOffset: absoluteCharacterOffset,
                normalizedHashAtCreation: normalizedHashAtCreation,
                bookTitleSnapshot: bookTitleSnapshot,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> collectionId = const Value.absent(),
                required int absoluteCharacterOffset,
                Value<String?> normalizedHashAtCreation = const Value.absent(),
                required String bookTitleSnapshot,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReaderBookmarksCompanion.insert(
                id: id,
                collectionId: collectionId,
                absoluteCharacterOffset: absoluteCharacterOffset,
                normalizedHashAtCreation: normalizedHashAtCreation,
                bookTitleSnapshot: bookTitleSnapshot,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReaderBookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false}) {
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
                    if (collectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.collectionId,
                                referencedTable:
                                    $$ReaderBookmarksTableReferences
                                        ._collectionIdTable(db),
                                referencedColumn:
                                    $$ReaderBookmarksTableReferences
                                        ._collectionIdTable(db)
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

typedef $$ReaderBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderBookmarksTable,
      ReaderBookmark,
      $$ReaderBookmarksTableFilterComposer,
      $$ReaderBookmarksTableOrderingComposer,
      $$ReaderBookmarksTableAnnotationComposer,
      $$ReaderBookmarksTableCreateCompanionBuilder,
      $$ReaderBookmarksTableUpdateCompanionBuilder,
      (ReaderBookmark, $$ReaderBookmarksTableReferences),
      ReaderBookmark,
      PrefetchHooks Function({bool collectionId})
    >;
typedef $$ReadingHistoryTableCreateCompanionBuilder =
    ReadingHistoryCompanion Function({
      required String id,
      Value<String?> collectionId,
      required String bookTitleSnapshot,
      Value<String?> authorSnapshot,
      Value<String?> normalizedHashSnapshot,
      required DateTime firstReadAt,
      required DateTime lastReadAt,
      Value<String?> lastChapterTitleSnapshot,
      Value<String?> lastProgressSnapshot,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReadingHistoryTableUpdateCompanionBuilder =
    ReadingHistoryCompanion Function({
      Value<String> id,
      Value<String?> collectionId,
      Value<String> bookTitleSnapshot,
      Value<String?> authorSnapshot,
      Value<String?> normalizedHashSnapshot,
      Value<DateTime> firstReadAt,
      Value<DateTime> lastReadAt,
      Value<String?> lastChapterTitleSnapshot,
      Value<String?> lastProgressSnapshot,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReadingHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingHistoryTable,
          ReadingHistoryData
        > {
  $$ReadingHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContentCollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.contentCollections.createAlias(
        $_aliasNameGenerator(
          db.readingHistory.collectionId,
          db.contentCollections.id,
        ),
      );

  $$ContentCollectionsTableProcessedTableManager? get collectionId {
    final $_column = $_itemColumn<String>('collection_id');
    if ($_column == null) return null;
    final manager = $$ContentCollectionsTableTableManager(
      $_db,
      $_db.contentCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
  _readingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingSessions,
    aliasName: $_aliasNameGenerator(
      db.readingHistory.id,
      db.readingSessions.historyEntryId,
    ),
  );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.historyEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReadingHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableFilterComposer({
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

  ColumnFilters<String> get bookTitleSnapshot => $composableBuilder(
    column: $table.bookTitleSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorSnapshot => $composableBuilder(
    column: $table.authorSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedHashSnapshot => $composableBuilder(
    column: $table.normalizedHashSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastChapterTitleSnapshot => $composableBuilder(
    column: $table.lastChapterTitleSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastProgressSnapshot => $composableBuilder(
    column: $table.lastProgressSnapshot,
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

  $$ContentCollectionsTableFilterComposer get collectionId {
    final $$ContentCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.historyEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReadingHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get bookTitleSnapshot => $composableBuilder(
    column: $table.bookTitleSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorSnapshot => $composableBuilder(
    column: $table.authorSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedHashSnapshot => $composableBuilder(
    column: $table.normalizedHashSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastChapterTitleSnapshot => $composableBuilder(
    column: $table.lastChapterTitleSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastProgressSnapshot => $composableBuilder(
    column: $table.lastProgressSnapshot,
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

  $$ContentCollectionsTableOrderingComposer get collectionId {
    final $$ContentCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.contentCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.contentCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookTitleSnapshot => $composableBuilder(
    column: $table.bookTitleSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorSnapshot => $composableBuilder(
    column: $table.authorSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedHashSnapshot => $composableBuilder(
    column: $table.normalizedHashSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastChapterTitleSnapshot => $composableBuilder(
    column: $table.lastChapterTitleSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastProgressSnapshot => $composableBuilder(
    column: $table.lastProgressSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ContentCollectionsTableAnnotationComposer get collectionId {
    final $$ContentCollectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.collectionId,
          referencedTable: $db.contentCollections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentCollectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contentCollections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.historyEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReadingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingHistoryTable,
          ReadingHistoryData,
          $$ReadingHistoryTableFilterComposer,
          $$ReadingHistoryTableOrderingComposer,
          $$ReadingHistoryTableAnnotationComposer,
          $$ReadingHistoryTableCreateCompanionBuilder,
          $$ReadingHistoryTableUpdateCompanionBuilder,
          (ReadingHistoryData, $$ReadingHistoryTableReferences),
          ReadingHistoryData,
          PrefetchHooks Function({bool collectionId, bool readingSessionsRefs})
        > {
  $$ReadingHistoryTableTableManager(
    _$AppDatabase db,
    $ReadingHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> collectionId = const Value.absent(),
                Value<String> bookTitleSnapshot = const Value.absent(),
                Value<String?> authorSnapshot = const Value.absent(),
                Value<String?> normalizedHashSnapshot = const Value.absent(),
                Value<DateTime> firstReadAt = const Value.absent(),
                Value<DateTime> lastReadAt = const Value.absent(),
                Value<String?> lastChapterTitleSnapshot = const Value.absent(),
                Value<String?> lastProgressSnapshot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion(
                id: id,
                collectionId: collectionId,
                bookTitleSnapshot: bookTitleSnapshot,
                authorSnapshot: authorSnapshot,
                normalizedHashSnapshot: normalizedHashSnapshot,
                firstReadAt: firstReadAt,
                lastReadAt: lastReadAt,
                lastChapterTitleSnapshot: lastChapterTitleSnapshot,
                lastProgressSnapshot: lastProgressSnapshot,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> collectionId = const Value.absent(),
                required String bookTitleSnapshot,
                Value<String?> authorSnapshot = const Value.absent(),
                Value<String?> normalizedHashSnapshot = const Value.absent(),
                required DateTime firstReadAt,
                required DateTime lastReadAt,
                Value<String?> lastChapterTitleSnapshot = const Value.absent(),
                Value<String?> lastProgressSnapshot = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion.insert(
                id: id,
                collectionId: collectionId,
                bookTitleSnapshot: bookTitleSnapshot,
                authorSnapshot: authorSnapshot,
                normalizedHashSnapshot: normalizedHashSnapshot,
                firstReadAt: firstReadAt,
                lastReadAt: lastReadAt,
                lastChapterTitleSnapshot: lastChapterTitleSnapshot,
                lastProgressSnapshot: lastProgressSnapshot,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({collectionId = false, readingSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (readingSessionsRefs) db.readingSessions,
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
                        if (collectionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.collectionId,
                                    referencedTable:
                                        $$ReadingHistoryTableReferences
                                            ._collectionIdTable(db),
                                    referencedColumn:
                                        $$ReadingHistoryTableReferences
                                            ._collectionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          ReadingHistoryData,
                          $ReadingHistoryTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$ReadingHistoryTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReadingHistoryTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.historyEntryId == item.id,
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

typedef $$ReadingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingHistoryTable,
      ReadingHistoryData,
      $$ReadingHistoryTableFilterComposer,
      $$ReadingHistoryTableOrderingComposer,
      $$ReadingHistoryTableAnnotationComposer,
      $$ReadingHistoryTableCreateCompanionBuilder,
      $$ReadingHistoryTableUpdateCompanionBuilder,
      (ReadingHistoryData, $$ReadingHistoryTableReferences),
      ReadingHistoryData,
      PrefetchHooks Function({bool collectionId, bool readingSessionsRefs})
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      required String id,
      required String historyEntryId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required int effectiveReadingSeconds,
      Value<String?> platform,
      Value<String?> deviceId,
      Value<int> rowid,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<String> id,
      Value<String> historyEntryId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> effectiveReadingSeconds,
      Value<String?> platform,
      Value<String?> deviceId,
      Value<int> rowid,
    });

final class $$ReadingSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSession> {
  $$ReadingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReadingHistoryTable _historyEntryIdTable(_$AppDatabase db) =>
      db.readingHistory.createAlias(
        $_aliasNameGenerator(
          db.readingSessions.historyEntryId,
          db.readingHistory.id,
        ),
      );

  $$ReadingHistoryTableProcessedTableManager get historyEntryId {
    final $_column = $_itemColumn<String>('history_entry_id')!;

    final manager = $$ReadingHistoryTableTableManager(
      $_db,
      $_db.readingHistory,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_historyEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveReadingSeconds => $composableBuilder(
    column: $table.effectiveReadingSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  $$ReadingHistoryTableFilterComposer get historyEntryId {
    final $$ReadingHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.historyEntryId,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableFilterComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveReadingSeconds => $composableBuilder(
    column: $table.effectiveReadingSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReadingHistoryTableOrderingComposer get historyEntryId {
    final $$ReadingHistoryTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.historyEntryId,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableOrderingComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get effectiveReadingSeconds => $composableBuilder(
    column: $table.effectiveReadingSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  $$ReadingHistoryTableAnnotationComposer get historyEntryId {
    final $$ReadingHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.historyEntryId,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingSessionsTable,
          ReadingSession,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (ReadingSession, $$ReadingSessionsTableReferences),
          ReadingSession,
          PrefetchHooks Function({bool historyEntryId})
        > {
  $$ReadingSessionsTableTableManager(
    _$AppDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> historyEntryId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> effectiveReadingSeconds = const Value.absent(),
                Value<String?> platform = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                historyEntryId: historyEntryId,
                startedAt: startedAt,
                endedAt: endedAt,
                effectiveReadingSeconds: effectiveReadingSeconds,
                platform: platform,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String historyEntryId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required int effectiveReadingSeconds,
                Value<String?> platform = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                id: id,
                historyEntryId: historyEntryId,
                startedAt: startedAt,
                endedAt: endedAt,
                effectiveReadingSeconds: effectiveReadingSeconds,
                platform: platform,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({historyEntryId = false}) {
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
                    if (historyEntryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.historyEntryId,
                                referencedTable:
                                    $$ReadingSessionsTableReferences
                                        ._historyEntryIdTable(db),
                                referencedColumn:
                                    $$ReadingSessionsTableReferences
                                        ._historyEntryIdTable(db)
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

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingSessionsTable,
      ReadingSession,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (ReadingSession, $$ReadingSessionsTableReferences),
      ReadingSession,
      PrefetchHooks Function({bool historyEntryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContentSourcesTableTableManager get contentSources =>
      $$ContentSourcesTableTableManager(_db, _db.contentSources);
  $$ContentCollectionsTableTableManager get contentCollections =>
      $$ContentCollectionsTableTableManager(_db, _db.contentCollections);
  $$ContentItemsTableTableManager get contentItems =>
      $$ContentItemsTableTableManager(_db, _db.contentItems);
  $$ContentDocumentsTableTableManager get contentDocuments =>
      $$ContentDocumentsTableTableManager(_db, _db.contentDocuments);
  $$TocEntriesTableTableManager get tocEntries =>
      $$TocEntriesTableTableManager(_db, _db.tocEntries);
  $$ImportRecordsTableTableManager get importRecords =>
      $$ImportRecordsTableTableManager(_db, _db.importRecords);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ReaderPreferencesRowsTableTableManager get readerPreferencesRows =>
      $$ReaderPreferencesRowsTableTableManager(_db, _db.readerPreferencesRows);
  $$ReaderFontAssetRowsTableTableManager get readerFontAssetRows =>
      $$ReaderFontAssetRowsTableTableManager(_db, _db.readerFontAssetRows);
  $$ReaderBookmarksTableTableManager get readerBookmarks =>
      $$ReaderBookmarksTableTableManager(_db, _db.readerBookmarks);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(_db, _db.readingHistory);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
}
