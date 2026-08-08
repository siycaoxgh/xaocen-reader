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
          PrefetchHooks Function({bool readingProgressRefs})
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
          prefetchHooksCallback: ({readingProgressRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (readingProgressRefs) db.readingProgress,
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
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
      PrefetchHooks Function({bool readingProgressRefs})
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
}
