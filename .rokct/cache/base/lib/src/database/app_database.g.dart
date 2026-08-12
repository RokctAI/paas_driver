// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValueTableTable extends KeyValueTable
    with TableInfo<$KeyValueTableTable, KeyValueEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<String> box = GeneratedColumn<String>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [box, id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    } else if (isInserting) {
      context.missing(_boxMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {box, id};
  @override
  KeyValueEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueEntity(
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $KeyValueTableTable createAlias(String alias) {
    return $KeyValueTableTable(attachedDatabase, alias);
  }
}

class KeyValueEntity extends DataClass implements Insertable<KeyValueEntity> {
  final String box;
  final String id;
  final String data;
  const KeyValueEntity({
    required this.box,
    required this.id,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['box'] = Variable<String>(box);
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  KeyValueTableCompanion toCompanion(bool nullToAbsent) {
    return KeyValueTableCompanion(
      box: Value(box),
      id: Value(id),
      data: Value(data),
    );
  }

  factory KeyValueEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueEntity(
      box: serializer.fromJson<String>(json['box']),
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'box': serializer.toJson<String>(box),
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  KeyValueEntity copyWith({String? box, String? id, String? data}) =>
      KeyValueEntity(
        box: box ?? this.box,
        id: id ?? this.id,
        data: data ?? this.data,
      );
  KeyValueEntity copyWithCompanion(KeyValueTableCompanion data) {
    return KeyValueEntity(
      box: data.box.present ? data.box.value : this.box,
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueEntity(')
          ..write('box: $box, ')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(box, id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueEntity &&
          other.box == this.box &&
          other.id == this.id &&
          other.data == this.data);
}

class KeyValueTableCompanion extends UpdateCompanion<KeyValueEntity> {
  final Value<String> box;
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const KeyValueTableCompanion({
    this.box = const Value.absent(),
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueTableCompanion.insert({
    required String box,
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  }) : box = Value(box),
       id = Value(id),
       data = Value(data);
  static Insertable<KeyValueEntity> custom({
    Expression<String>? box,
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (box != null) 'box': box,
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueTableCompanion copyWith({
    Value<String>? box,
    Value<String>? id,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return KeyValueTableCompanion(
      box: box ?? this.box,
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (box.present) {
      map['box'] = Variable<String>(box.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueTableCompanion(')
          ..write('box: $box, ')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTableTable extends OutboxTable
    with TableInfo<$OutboxTableTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sdkMeta = const VerificationMeta('sdk');
  @override
  late final GeneratedColumn<String> sdk = GeneratedColumn<String>(
    'sdk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempIdsMeta = const VerificationMeta(
    'tempIds',
  );
  @override
  late final GeneratedColumn<String> tempIds = GeneratedColumn<String>(
    'temp_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
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
    opType,
    sdk,
    payload,
    tempIds,
    dependsOn,
    status,
    attempts,
    lastError,
    nextAttemptAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('sdk')) {
      context.handle(
        _sdkMeta,
        sdk.isAcceptableOrUnknown(data['sdk']!, _sdkMeta),
      );
    } else if (isInserting) {
      context.missing(_sdkMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('temp_ids')) {
      context.handle(
        _tempIdsMeta,
        tempIds.isAcceptableOrUnknown(data['temp_ids']!, _tempIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_tempIdsMeta);
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_dependsOnMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptsMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
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
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      sdk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sdk'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      tempIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_ids'],
      )!,
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
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
  $OutboxTableTable createAlias(String alias) {
    return $OutboxTableTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  /// Client-generated UUID v4; also the backend idempotency key.
  final String id;

  /// Operation type routed to a registered handler,
  /// e.g. `auth.register`, `order.create`.
  final String opType;

  /// Owning SDK name, e.g. `auth_sdk`, `orders_sdk`.
  final String sdk;

  /// JSON-encoded operation payload. Temp-id tokens (`offline:<uuid>`)
  /// inside it are rewritten to backend ids as dependencies sync.
  final String payload;

  /// JSON-encoded list of temp ids (`offline:<uuid>`) this op creates.
  final String tempIds;

  /// JSON-encoded list of outbox [id]s that must sync before this op.
  final String dependsOn;

  /// [OutboxStatus] name.
  final String status;

  /// Push attempts made so far.
  final int attempts;

  /// Error from the most recent failed attempt.
  final String? lastError;

  /// Earliest time the next retry may run (backoff); null = immediately.
  final DateTime? nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxEntry({
    required this.id,
    required this.opType,
    required this.sdk,
    required this.payload,
    required this.tempIds,
    required this.dependsOn,
    required this.status,
    required this.attempts,
    this.lastError,
    this.nextAttemptAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['op_type'] = Variable<String>(opType);
    map['sdk'] = Variable<String>(sdk);
    map['payload'] = Variable<String>(payload);
    map['temp_ids'] = Variable<String>(tempIds);
    map['depends_on'] = Variable<String>(dependsOn);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxTableCompanion toCompanion(bool nullToAbsent) {
    return OutboxTableCompanion(
      id: Value(id),
      opType: Value(opType),
      sdk: Value(sdk),
      payload: Value(payload),
      tempIds: Value(tempIds),
      dependsOn: Value(dependsOn),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<String>(json['id']),
      opType: serializer.fromJson<String>(json['opType']),
      sdk: serializer.fromJson<String>(json['sdk']),
      payload: serializer.fromJson<String>(json['payload']),
      tempIds: serializer.fromJson<String>(json['tempIds']),
      dependsOn: serializer.fromJson<String>(json['dependsOn']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'opType': serializer.toJson<String>(opType),
      'sdk': serializer.toJson<String>(sdk),
      'payload': serializer.toJson<String>(payload),
      'tempIds': serializer.toJson<String>(tempIds),
      'dependsOn': serializer.toJson<String>(dependsOn),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxEntry copyWith({
    String? id,
    String? opType,
    String? sdk,
    String? payload,
    String? tempIds,
    String? dependsOn,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OutboxEntry(
    id: id ?? this.id,
    opType: opType ?? this.opType,
    sdk: sdk ?? this.sdk,
    payload: payload ?? this.payload,
    tempIds: tempIds ?? this.tempIds,
    dependsOn: dependsOn ?? this.dependsOn,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OutboxEntry copyWithCompanion(OutboxTableCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      opType: data.opType.present ? data.opType.value : this.opType,
      sdk: data.sdk.present ? data.sdk.value : this.sdk,
      payload: data.payload.present ? data.payload.value : this.payload,
      tempIds: data.tempIds.present ? data.tempIds.value : this.tempIds,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('sdk: $sdk, ')
          ..write('payload: $payload, ')
          ..write('tempIds: $tempIds, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    opType,
    sdk,
    payload,
    tempIds,
    dependsOn,
    status,
    attempts,
    lastError,
    nextAttemptAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.opType == this.opType &&
          other.sdk == this.sdk &&
          other.payload == this.payload &&
          other.tempIds == this.tempIds &&
          other.dependsOn == this.dependsOn &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxTableCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<String> id;
  final Value<String> opType;
  final Value<String> sdk;
  final Value<String> payload;
  final Value<String> tempIds;
  final Value<String> dependsOn;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxTableCompanion({
    this.id = const Value.absent(),
    this.opType = const Value.absent(),
    this.sdk = const Value.absent(),
    this.payload = const Value.absent(),
    this.tempIds = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxTableCompanion.insert({
    required String id,
    required String opType,
    required String sdk,
    required String payload,
    required String tempIds,
    required String dependsOn,
    required String status,
    required int attempts,
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       opType = Value(opType),
       sdk = Value(sdk),
       payload = Value(payload),
       tempIds = Value(tempIds),
       dependsOn = Value(dependsOn),
       status = Value(status),
       attempts = Value(attempts),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OutboxEntry> custom({
    Expression<String>? id,
    Expression<String>? opType,
    Expression<String>? sdk,
    Expression<String>? payload,
    Expression<String>? tempIds,
    Expression<String>? dependsOn,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opType != null) 'op_type': opType,
      if (sdk != null) 'sdk': sdk,
      if (payload != null) 'payload': payload,
      if (tempIds != null) 'temp_ids': tempIds,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxTableCompanion copyWith({
    Value<String>? id,
    Value<String>? opType,
    Value<String>? sdk,
    Value<String>? payload,
    Value<String>? tempIds,
    Value<String>? dependsOn,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutboxTableCompanion(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      sdk: sdk ?? this.sdk,
      payload: payload ?? this.payload,
      tempIds: tempIds ?? this.tempIds,
      dependsOn: dependsOn ?? this.dependsOn,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
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
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (sdk.present) {
      map['sdk'] = Variable<String>(sdk.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (tempIds.present) {
      map['temp_ids'] = Variable<String>(tempIds.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
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
    return (StringBuffer('OutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('sdk: $sdk, ')
          ..write('payload: $payload, ')
          ..write('tempIds: $tempIds, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdMappingsTableTable extends IdMappingsTable
    with TableInfo<$IdMappingsTableTable, IdMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdMappingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backendIdMeta = const VerificationMeta(
    'backendId',
  );
  @override
  late final GeneratedColumn<String> backendId = GeneratedColumn<String>(
    'backend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _mappedAtMeta = const VerificationMeta(
    'mappedAt',
  );
  @override
  late final GeneratedColumn<DateTime> mappedAt = GeneratedColumn<DateTime>(
    'mapped_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tempId,
    backendId,
    entityType,
    mappedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'id_mappings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tempIdMeta);
    }
    if (data.containsKey('backend_id')) {
      context.handle(
        _backendIdMeta,
        backendId.isAcceptableOrUnknown(data['backend_id']!, _backendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_backendIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('mapped_at')) {
      context.handle(
        _mappedAtMeta,
        mappedAt.isAcceptableOrUnknown(data['mapped_at']!, _mappedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_mappedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tempId};
  @override
  IdMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdMapping(
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      )!,
      backendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      mappedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mapped_at'],
      )!,
    );
  }

  @override
  $IdMappingsTableTable createAlias(String alias) {
    return $IdMappingsTableTable(attachedDatabase, alias);
  }
}

class IdMapping extends DataClass implements Insertable<IdMapping> {
  /// The locally minted id, e.g. `offline:5f0c...`.
  final String tempId;

  /// The authoritative id assigned by the backend.
  final String backendId;

  /// Entity kind, e.g. `user` / `shop` / `product` / `order`.
  final String entityType;
  final DateTime mappedAt;
  const IdMapping({
    required this.tempId,
    required this.backendId,
    required this.entityType,
    required this.mappedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['temp_id'] = Variable<String>(tempId);
    map['backend_id'] = Variable<String>(backendId);
    map['entity_type'] = Variable<String>(entityType);
    map['mapped_at'] = Variable<DateTime>(mappedAt);
    return map;
  }

  IdMappingsTableCompanion toCompanion(bool nullToAbsent) {
    return IdMappingsTableCompanion(
      tempId: Value(tempId),
      backendId: Value(backendId),
      entityType: Value(entityType),
      mappedAt: Value(mappedAt),
    );
  }

  factory IdMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdMapping(
      tempId: serializer.fromJson<String>(json['tempId']),
      backendId: serializer.fromJson<String>(json['backendId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      mappedAt: serializer.fromJson<DateTime>(json['mappedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tempId': serializer.toJson<String>(tempId),
      'backendId': serializer.toJson<String>(backendId),
      'entityType': serializer.toJson<String>(entityType),
      'mappedAt': serializer.toJson<DateTime>(mappedAt),
    };
  }

  IdMapping copyWith({
    String? tempId,
    String? backendId,
    String? entityType,
    DateTime? mappedAt,
  }) => IdMapping(
    tempId: tempId ?? this.tempId,
    backendId: backendId ?? this.backendId,
    entityType: entityType ?? this.entityType,
    mappedAt: mappedAt ?? this.mappedAt,
  );
  IdMapping copyWithCompanion(IdMappingsTableCompanion data) {
    return IdMapping(
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
      backendId: data.backendId.present ? data.backendId.value : this.backendId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      mappedAt: data.mappedAt.present ? data.mappedAt.value : this.mappedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdMapping(')
          ..write('tempId: $tempId, ')
          ..write('backendId: $backendId, ')
          ..write('entityType: $entityType, ')
          ..write('mappedAt: $mappedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tempId, backendId, entityType, mappedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdMapping &&
          other.tempId == this.tempId &&
          other.backendId == this.backendId &&
          other.entityType == this.entityType &&
          other.mappedAt == this.mappedAt);
}

class IdMappingsTableCompanion extends UpdateCompanion<IdMapping> {
  final Value<String> tempId;
  final Value<String> backendId;
  final Value<String> entityType;
  final Value<DateTime> mappedAt;
  final Value<int> rowid;
  const IdMappingsTableCompanion({
    this.tempId = const Value.absent(),
    this.backendId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.mappedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdMappingsTableCompanion.insert({
    required String tempId,
    required String backendId,
    required String entityType,
    required DateTime mappedAt,
    this.rowid = const Value.absent(),
  }) : tempId = Value(tempId),
       backendId = Value(backendId),
       entityType = Value(entityType),
       mappedAt = Value(mappedAt);
  static Insertable<IdMapping> custom({
    Expression<String>? tempId,
    Expression<String>? backendId,
    Expression<String>? entityType,
    Expression<DateTime>? mappedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tempId != null) 'temp_id': tempId,
      if (backendId != null) 'backend_id': backendId,
      if (entityType != null) 'entity_type': entityType,
      if (mappedAt != null) 'mapped_at': mappedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdMappingsTableCompanion copyWith({
    Value<String>? tempId,
    Value<String>? backendId,
    Value<String>? entityType,
    Value<DateTime>? mappedAt,
    Value<int>? rowid,
  }) {
    return IdMappingsTableCompanion(
      tempId: tempId ?? this.tempId,
      backendId: backendId ?? this.backendId,
      entityType: entityType ?? this.entityType,
      mappedAt: mappedAt ?? this.mappedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (backendId.present) {
      map['backend_id'] = Variable<String>(backendId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (mappedAt.present) {
      map['mapped_at'] = Variable<DateTime>(mappedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdMappingsTableCompanion(')
          ..write('tempId: $tempId, ')
          ..write('backendId: $backendId, ')
          ..write('entityType: $entityType, ')
          ..write('mappedAt: $mappedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineUsersTableTable extends OfflineUsersTable
    with TableInfo<$OfflineUsersTableTable, OfflineUserEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineUsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => '',
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referralMeta = const VerificationMeta(
    'referral',
  );
  @override
  late final GeneratedColumn<String> referral = GeneratedColumn<String>(
    'referral',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _backendUserIdMeta = const VerificationMeta(
    'backendUserId',
  );
  @override
  late final GeneratedColumn<String> backendUserId = GeneratedColumn<String>(
    'backend_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backendTokenMeta = const VerificationMeta(
    'backendToken',
  );
  @override
  late final GeneratedColumn<String> backendToken = GeneratedColumn<String>(
    'backend_token',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    phone,
    email,
    firstName,
    lastName,
    passwordHash,
    referral,
    synced,
    backendUserId,
    backendToken,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_users_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineUserEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('referral')) {
      context.handle(
        _referralMeta,
        referral.isAcceptableOrUnknown(data['referral']!, _referralMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('backend_user_id')) {
      context.handle(
        _backendUserIdMeta,
        backendUserId.isAcceptableOrUnknown(
          data['backend_user_id']!,
          _backendUserIdMeta,
        ),
      );
    }
    if (data.containsKey('backend_token')) {
      context.handle(
        _backendTokenMeta,
        backendToken.isAcceptableOrUnknown(
          data['backend_token']!,
          _backendTokenMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineUserEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineUserEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      referral: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referral'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      backendUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_user_id'],
      ),
      backendToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_token'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OfflineUsersTableTable createAlias(String alias) {
    return $OfflineUsersTableTable(attachedDatabase, alias);
  }
}

class OfflineUserEntity extends DataClass
    implements Insertable<OfflineUserEntity> {
  final String id;
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String passwordHash;
  final String? referral;
  final bool synced;
  final String? backendUserId;
  final String? backendToken;
  final DateTime createdAt;
  const OfflineUserEntity({
    required this.id,
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    required this.passwordHash,
    this.referral,
    required this.synced,
    this.backendUserId,
    this.backendToken,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    map['password_hash'] = Variable<String>(passwordHash);
    if (!nullToAbsent || referral != null) {
      map['referral'] = Variable<String>(referral);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || backendUserId != null) {
      map['backend_user_id'] = Variable<String>(backendUserId);
    }
    if (!nullToAbsent || backendToken != null) {
      map['backend_token'] = Variable<String>(backendToken);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OfflineUsersTableCompanion toCompanion(bool nullToAbsent) {
    return OfflineUsersTableCompanion(
      id: Value(id),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      passwordHash: Value(passwordHash),
      referral: referral == null && nullToAbsent
          ? const Value.absent()
          : Value(referral),
      synced: Value(synced),
      backendUserId: backendUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(backendUserId),
      backendToken: backendToken == null && nullToAbsent
          ? const Value.absent()
          : Value(backendToken),
      createdAt: Value(createdAt),
    );
  }

  factory OfflineUserEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineUserEntity(
      id: serializer.fromJson<String>(json['id']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      referral: serializer.fromJson<String?>(json['referral']),
      synced: serializer.fromJson<bool>(json['synced']),
      backendUserId: serializer.fromJson<String?>(json['backendUserId']),
      backendToken: serializer.fromJson<String?>(json['backendToken']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'referral': serializer.toJson<String?>(referral),
      'synced': serializer.toJson<bool>(synced),
      'backendUserId': serializer.toJson<String?>(backendUserId),
      'backendToken': serializer.toJson<String?>(backendToken),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfflineUserEntity copyWith({
    String? id,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    String? passwordHash,
    Value<String?> referral = const Value.absent(),
    bool? synced,
    Value<String?> backendUserId = const Value.absent(),
    Value<String?> backendToken = const Value.absent(),
    DateTime? createdAt,
  }) => OfflineUserEntity(
    id: id ?? this.id,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    passwordHash: passwordHash ?? this.passwordHash,
    referral: referral.present ? referral.value : this.referral,
    synced: synced ?? this.synced,
    backendUserId: backendUserId.present
        ? backendUserId.value
        : this.backendUserId,
    backendToken: backendToken.present ? backendToken.value : this.backendToken,
    createdAt: createdAt ?? this.createdAt,
  );
  OfflineUserEntity copyWithCompanion(OfflineUsersTableCompanion data) {
    return OfflineUserEntity(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      referral: data.referral.present ? data.referral.value : this.referral,
      synced: data.synced.present ? data.synced.value : this.synced,
      backendUserId: data.backendUserId.present
          ? data.backendUserId.value
          : this.backendUserId,
      backendToken: data.backendToken.present
          ? data.backendToken.value
          : this.backendToken,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineUserEntity(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('referral: $referral, ')
          ..write('synced: $synced, ')
          ..write('backendUserId: $backendUserId, ')
          ..write('backendToken: $backendToken, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    phone,
    email,
    firstName,
    lastName,
    passwordHash,
    referral,
    synced,
    backendUserId,
    backendToken,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineUserEntity &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.passwordHash == this.passwordHash &&
          other.referral == this.referral &&
          other.synced == this.synced &&
          other.backendUserId == this.backendUserId &&
          other.backendToken == this.backendToken &&
          other.createdAt == this.createdAt);
}

class OfflineUsersTableCompanion extends UpdateCompanion<OfflineUserEntity> {
  final Value<String> id;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String> passwordHash;
  final Value<String?> referral;
  final Value<bool> synced;
  final Value<String?> backendUserId;
  final Value<String?> backendToken;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OfflineUsersTableCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.referral = const Value.absent(),
    this.synced = const Value.absent(),
    this.backendUserId = const Value.absent(),
    this.backendToken = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineUsersTableCompanion.insert({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    required String passwordHash,
    this.referral = const Value.absent(),
    this.synced = const Value.absent(),
    this.backendUserId = const Value.absent(),
    this.backendToken = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : passwordHash = Value(passwordHash);
  static Insertable<OfflineUserEntity> custom({
    Expression<String>? id,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? passwordHash,
    Expression<String>? referral,
    Expression<bool>? synced,
    Expression<String>? backendUserId,
    Expression<String>? backendToken,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (referral != null) 'referral': referral,
      if (synced != null) 'synced': synced,
      if (backendUserId != null) 'backend_user_id': backendUserId,
      if (backendToken != null) 'backend_token': backendToken,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineUsersTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String>? passwordHash,
    Value<String?>? referral,
    Value<bool>? synced,
    Value<String?>? backendUserId,
    Value<String?>? backendToken,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OfflineUsersTableCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      passwordHash: passwordHash ?? this.passwordHash,
      referral: referral ?? this.referral,
      synced: synced ?? this.synced,
      backendUserId: backendUserId ?? this.backendUserId,
      backendToken: backendToken ?? this.backendToken,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (referral.present) {
      map['referral'] = Variable<String>(referral.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (backendUserId.present) {
      map['backend_user_id'] = Variable<String>(backendUserId.value);
    }
    if (backendToken.present) {
      map['backend_token'] = Variable<String>(backendToken.value);
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
    return (StringBuffer('OfflineUsersTableCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('referral: $referral, ')
          ..write('synced: $synced, ')
          ..write('backendUserId: $backendUserId, ')
          ..write('backendToken: $backendToken, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValueTableTable keyValueTable = $KeyValueTableTable(this);
  late final $OutboxTableTable outboxTable = $OutboxTableTable(this);
  late final $IdMappingsTableTable idMappingsTable = $IdMappingsTableTable(
    this,
  );
  late final $OfflineUsersTableTable offlineUsersTable =
      $OfflineUsersTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValueTable,
    outboxTable,
    idMappingsTable,
    offlineUsersTable,
  ];
}

typedef $$KeyValueTableTableCreateCompanionBuilder =
    KeyValueTableCompanion Function({
      required String box,
      required String id,
      required String data,
      Value<int> rowid,
    });
typedef $$KeyValueTableTableUpdateCompanionBuilder =
    KeyValueTableCompanion Function({
      Value<String> box,
      Value<String> id,
      Value<String> data,
      Value<int> rowid,
    });

class $$KeyValueTableTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValueTableTable> {
  $$KeyValueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValueTableTable> {
  $$KeyValueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValueTableTable> {
  $$KeyValueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$KeyValueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValueTableTable,
          KeyValueEntity,
          $$KeyValueTableTableFilterComposer,
          $$KeyValueTableTableOrderingComposer,
          $$KeyValueTableTableAnnotationComposer,
          $$KeyValueTableTableCreateCompanionBuilder,
          $$KeyValueTableTableUpdateCompanionBuilder,
          (
            KeyValueEntity,
            BaseReferences<_$AppDatabase, $KeyValueTableTable, KeyValueEntity>,
          ),
          KeyValueEntity,
          PrefetchHooks Function()
        > {
  $$KeyValueTableTableTableManager(_$AppDatabase db, $KeyValueTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> box = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValueTableCompanion(
                box: box,
                id: id,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String box,
                required String id,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => KeyValueTableCompanion.insert(
                box: box,
                id: id,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValueTableTable,
      KeyValueEntity,
      $$KeyValueTableTableFilterComposer,
      $$KeyValueTableTableOrderingComposer,
      $$KeyValueTableTableAnnotationComposer,
      $$KeyValueTableTableCreateCompanionBuilder,
      $$KeyValueTableTableUpdateCompanionBuilder,
      (
        KeyValueEntity,
        BaseReferences<_$AppDatabase, $KeyValueTableTable, KeyValueEntity>,
      ),
      KeyValueEntity,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableTableCreateCompanionBuilder =
    OutboxTableCompanion Function({
      required String id,
      required String opType,
      required String sdk,
      required String payload,
      required String tempIds,
      required String dependsOn,
      required String status,
      required int attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OutboxTableTableUpdateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<String> id,
      Value<String> opType,
      Value<String> sdk,
      Value<String> payload,
      Value<String> tempIds,
      Value<String> dependsOn,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableFilterComposer({
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

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sdk => $composableBuilder(
    column: $table.sdk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempIds => $composableBuilder(
    column: $table.tempIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
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

class $$OutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableOrderingComposer({
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

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sdk => $composableBuilder(
    column: $table.sdk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempIds => $composableBuilder(
    column: $table.tempIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
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

class $$OutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get sdk =>
      $composableBuilder(column: $table.sdk, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get tempIds =>
      $composableBuilder(column: $table.tempIds, builder: (column) => column);

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTableTable,
          OutboxEntry,
          $$OutboxTableTableFilterComposer,
          $$OutboxTableTableOrderingComposer,
          $$OutboxTableTableAnnotationComposer,
          $$OutboxTableTableCreateCompanionBuilder,
          $$OutboxTableTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableTableManager(_$AppDatabase db, $OutboxTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> sdk = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> tempIds = const Value.absent(),
                Value<String> dependsOn = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxTableCompanion(
                id: id,
                opType: opType,
                sdk: sdk,
                payload: payload,
                tempIds: tempIds,
                dependsOn: dependsOn,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String opType,
                required String sdk,
                required String payload,
                required String tempIds,
                required String dependsOn,
                required String status,
                required int attempts,
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxTableCompanion.insert(
                id: id,
                opType: opType,
                sdk: sdk,
                payload: payload,
                tempIds: tempIds,
                dependsOn: dependsOn,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
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

typedef $$OutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTableTable,
      OutboxEntry,
      $$OutboxTableTableFilterComposer,
      $$OutboxTableTableOrderingComposer,
      $$OutboxTableTableAnnotationComposer,
      $$OutboxTableTableCreateCompanionBuilder,
      $$OutboxTableTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$IdMappingsTableTableCreateCompanionBuilder =
    IdMappingsTableCompanion Function({
      required String tempId,
      required String backendId,
      required String entityType,
      required DateTime mappedAt,
      Value<int> rowid,
    });
typedef $$IdMappingsTableTableUpdateCompanionBuilder =
    IdMappingsTableCompanion Function({
      Value<String> tempId,
      Value<String> backendId,
      Value<String> entityType,
      Value<DateTime> mappedAt,
      Value<int> rowid,
    });

class $$IdMappingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $IdMappingsTableTable> {
  $$IdMappingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendId => $composableBuilder(
    column: $table.backendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mappedAt => $composableBuilder(
    column: $table.mappedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IdMappingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $IdMappingsTableTable> {
  $$IdMappingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendId => $composableBuilder(
    column: $table.backendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mappedAt => $composableBuilder(
    column: $table.mappedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IdMappingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdMappingsTableTable> {
  $$IdMappingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);

  GeneratedColumn<String> get backendId =>
      $composableBuilder(column: $table.backendId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get mappedAt =>
      $composableBuilder(column: $table.mappedAt, builder: (column) => column);
}

class $$IdMappingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdMappingsTableTable,
          IdMapping,
          $$IdMappingsTableTableFilterComposer,
          $$IdMappingsTableTableOrderingComposer,
          $$IdMappingsTableTableAnnotationComposer,
          $$IdMappingsTableTableCreateCompanionBuilder,
          $$IdMappingsTableTableUpdateCompanionBuilder,
          (
            IdMapping,
            BaseReferences<_$AppDatabase, $IdMappingsTableTable, IdMapping>,
          ),
          IdMapping,
          PrefetchHooks Function()
        > {
  $$IdMappingsTableTableTableManager(
    _$AppDatabase db,
    $IdMappingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdMappingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdMappingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdMappingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tempId = const Value.absent(),
                Value<String> backendId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<DateTime> mappedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdMappingsTableCompanion(
                tempId: tempId,
                backendId: backendId,
                entityType: entityType,
                mappedAt: mappedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tempId,
                required String backendId,
                required String entityType,
                required DateTime mappedAt,
                Value<int> rowid = const Value.absent(),
              }) => IdMappingsTableCompanion.insert(
                tempId: tempId,
                backendId: backendId,
                entityType: entityType,
                mappedAt: mappedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IdMappingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdMappingsTableTable,
      IdMapping,
      $$IdMappingsTableTableFilterComposer,
      $$IdMappingsTableTableOrderingComposer,
      $$IdMappingsTableTableAnnotationComposer,
      $$IdMappingsTableTableCreateCompanionBuilder,
      $$IdMappingsTableTableUpdateCompanionBuilder,
      (
        IdMapping,
        BaseReferences<_$AppDatabase, $IdMappingsTableTable, IdMapping>,
      ),
      IdMapping,
      PrefetchHooks Function()
    >;
typedef $$OfflineUsersTableTableCreateCompanionBuilder =
    OfflineUsersTableCompanion Function({
      Value<String> id,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> firstName,
      Value<String?> lastName,
      required String passwordHash,
      Value<String?> referral,
      Value<bool> synced,
      Value<String?> backendUserId,
      Value<String?> backendToken,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$OfflineUsersTableTableUpdateCompanionBuilder =
    OfflineUsersTableCompanion Function({
      Value<String> id,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String> passwordHash,
      Value<String?> referral,
      Value<bool> synced,
      Value<String?> backendUserId,
      Value<String?> backendToken,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$OfflineUsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineUsersTableTable> {
  $$OfflineUsersTableTableFilterComposer({
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

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referral => $composableBuilder(
    column: $table.referral,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendUserId => $composableBuilder(
    column: $table.backendUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendToken => $composableBuilder(
    column: $table.backendToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineUsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineUsersTableTable> {
  $$OfflineUsersTableTableOrderingComposer({
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

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referral => $composableBuilder(
    column: $table.referral,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendUserId => $composableBuilder(
    column: $table.backendUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendToken => $composableBuilder(
    column: $table.backendToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineUsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineUsersTableTable> {
  $$OfflineUsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referral =>
      $composableBuilder(column: $table.referral, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get backendUserId => $composableBuilder(
    column: $table.backendUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backendToken => $composableBuilder(
    column: $table.backendToken,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OfflineUsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineUsersTableTable,
          OfflineUserEntity,
          $$OfflineUsersTableTableFilterComposer,
          $$OfflineUsersTableTableOrderingComposer,
          $$OfflineUsersTableTableAnnotationComposer,
          $$OfflineUsersTableTableCreateCompanionBuilder,
          $$OfflineUsersTableTableUpdateCompanionBuilder,
          (
            OfflineUserEntity,
            BaseReferences<
              _$AppDatabase,
              $OfflineUsersTableTable,
              OfflineUserEntity
            >,
          ),
          OfflineUserEntity,
          PrefetchHooks Function()
        > {
  $$OfflineUsersTableTableTableManager(
    _$AppDatabase db,
    $OfflineUsersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineUsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineUsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineUsersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String?> referral = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> backendUserId = const Value.absent(),
                Value<String?> backendToken = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineUsersTableCompanion(
                id: id,
                phone: phone,
                email: email,
                firstName: firstName,
                lastName: lastName,
                passwordHash: passwordHash,
                referral: referral,
                synced: synced,
                backendUserId: backendUserId,
                backendToken: backendToken,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                required String passwordHash,
                Value<String?> referral = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> backendUserId = const Value.absent(),
                Value<String?> backendToken = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineUsersTableCompanion.insert(
                id: id,
                phone: phone,
                email: email,
                firstName: firstName,
                lastName: lastName,
                passwordHash: passwordHash,
                referral: referral,
                synced: synced,
                backendUserId: backendUserId,
                backendToken: backendToken,
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

typedef $$OfflineUsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineUsersTableTable,
      OfflineUserEntity,
      $$OfflineUsersTableTableFilterComposer,
      $$OfflineUsersTableTableOrderingComposer,
      $$OfflineUsersTableTableAnnotationComposer,
      $$OfflineUsersTableTableCreateCompanionBuilder,
      $$OfflineUsersTableTableUpdateCompanionBuilder,
      (
        OfflineUserEntity,
        BaseReferences<
          _$AppDatabase,
          $OfflineUsersTableTable,
          OfflineUserEntity
        >,
      ),
      OfflineUserEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValueTableTableTableManager get keyValueTable =>
      $$KeyValueTableTableTableManager(_db, _db.keyValueTable);
  $$OutboxTableTableTableManager get outboxTable =>
      $$OutboxTableTableTableManager(_db, _db.outboxTable);
  $$IdMappingsTableTableTableManager get idMappingsTable =>
      $$IdMappingsTableTableTableManager(_db, _db.idMappingsTable);
  $$OfflineUsersTableTableTableManager get offlineUsersTable =>
      $$OfflineUsersTableTableTableManager(_db, _db.offlineUsersTable);
}
