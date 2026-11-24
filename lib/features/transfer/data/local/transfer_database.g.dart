// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_database.dart';

// ignore_for_file: type=lint
class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, TransferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientNameMeta = const VerificationMeta(
    'recipientName',
  );
  @override
  late final GeneratedColumn<String> recipientName = GeneratedColumn<String>(
    'recipient_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientPhoneMeta = const VerificationMeta(
    'recipientPhone',
  );
  @override
  late final GeneratedColumn<String> recipientPhone = GeneratedColumn<String>(
    'recipient_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransferStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransferStatus>($TransfersTable.$converterstatus);
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
    idempotencyKey,
    serverId,
    amount,
    currency,
    recipientName,
    recipientPhone,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('recipient_name')) {
      context.handle(
        _recipientNameMeta,
        recipientName.isAcceptableOrUnknown(
          data['recipient_name']!,
          _recipientNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientNameMeta);
    }
    if (data.containsKey('recipient_phone')) {
      context.handle(
        _recipientPhoneMeta,
        recipientPhone.isAcceptableOrUnknown(
          data['recipient_phone']!,
          _recipientPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientPhoneMeta);
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
  Set<GeneratedColumn> get $primaryKey => {idempotencyKey};
  @override
  TransferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferRow(
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      recipientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_name'],
      )!,
      recipientPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_phone'],
      )!,
      status: $TransfersTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
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
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransferStatus, String, String> $converterstatus =
      const EnumNameConverter<TransferStatus>(TransferStatus.values);
}

class TransferRow extends DataClass implements Insertable<TransferRow> {
  final String idempotencyKey;
  final String? serverId;
  final int amount;
  final String currency;
  final String recipientName;
  final String recipientPhone;

  /// Stocké par son nom (« unknownOutcome ») : lisible, et insensible à
  /// l'ordre des valeurs de l'enum.
  final TransferStatus status;

  /// Dates en secondes Unix (choix par défaut de Drift) : le tri est
  /// numérique, sans piège de fuseau horaire.
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransferRow({
    required this.idempotencyKey,
    this.serverId,
    required this.amount,
    required this.currency,
    required this.recipientName,
    required this.recipientPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    map['recipient_name'] = Variable<String>(recipientName);
    map['recipient_phone'] = Variable<String>(recipientPhone);
    {
      map['status'] = Variable<String>(
        $TransfersTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      idempotencyKey: Value(idempotencyKey),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      amount: Value(amount),
      currency: Value(currency),
      recipientName: Value(recipientName),
      recipientPhone: Value(recipientPhone),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferRow(
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      recipientName: serializer.fromJson<String>(json['recipientName']),
      recipientPhone: serializer.fromJson<String>(json['recipientPhone']),
      status: $TransfersTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'serverId': serializer.toJson<String?>(serverId),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'recipientName': serializer.toJson<String>(recipientName),
      'recipientPhone': serializer.toJson<String>(recipientPhone),
      'status': serializer.toJson<String>(
        $TransfersTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransferRow copyWith({
    String? idempotencyKey,
    Value<String?> serverId = const Value.absent(),
    int? amount,
    String? currency,
    String? recipientName,
    String? recipientPhone,
    TransferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransferRow(
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    serverId: serverId.present ? serverId.value : this.serverId,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    recipientName: recipientName ?? this.recipientName,
    recipientPhone: recipientPhone ?? this.recipientPhone,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransferRow copyWithCompanion(TransfersCompanion data) {
    return TransferRow(
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      recipientName: data.recipientName.present
          ? data.recipientName.value
          : this.recipientName,
      recipientPhone: data.recipientPhone.present
          ? data.recipientPhone.value
          : this.recipientPhone,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferRow(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('serverId: $serverId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('recipientName: $recipientName, ')
          ..write('recipientPhone: $recipientPhone, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idempotencyKey,
    serverId,
    amount,
    currency,
    recipientName,
    recipientPhone,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferRow &&
          other.idempotencyKey == this.idempotencyKey &&
          other.serverId == this.serverId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.recipientName == this.recipientName &&
          other.recipientPhone == this.recipientPhone &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransfersCompanion extends UpdateCompanion<TransferRow> {
  final Value<String> idempotencyKey;
  final Value<String?> serverId;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String> recipientName;
  final Value<String> recipientPhone;
  final Value<TransferStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransfersCompanion({
    this.idempotencyKey = const Value.absent(),
    this.serverId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.recipientName = const Value.absent(),
    this.recipientPhone = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransfersCompanion.insert({
    required String idempotencyKey,
    this.serverId = const Value.absent(),
    required int amount,
    required String currency,
    required String recipientName,
    required String recipientPhone,
    required TransferStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       amount = Value(amount),
       currency = Value(currency),
       recipientName = Value(recipientName),
       recipientPhone = Value(recipientPhone),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransferRow> custom({
    Expression<String>? idempotencyKey,
    Expression<String>? serverId,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? recipientName,
    Expression<String>? recipientPhone,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (serverId != null) 'server_id': serverId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (recipientName != null) 'recipient_name': recipientName,
      if (recipientPhone != null) 'recipient_phone': recipientPhone,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransfersCompanion copyWith({
    Value<String>? idempotencyKey,
    Value<String?>? serverId,
    Value<int>? amount,
    Value<String>? currency,
    Value<String>? recipientName,
    Value<String>? recipientPhone,
    Value<TransferStatus>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransfersCompanion(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      serverId: serverId ?? this.serverId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (recipientName.present) {
      map['recipient_name'] = Variable<String>(recipientName.value);
    }
    if (recipientPhone.present) {
      map['recipient_phone'] = Variable<String>(recipientPhone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TransfersTable.$converterstatus.toSql(status.value),
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
    return (StringBuffer('TransfersCompanion(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('serverId: $serverId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('recipientName: $recipientName, ')
          ..write('recipientPhone: $recipientPhone, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastSyncedAt, balance];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final int id;
  final DateTime lastSyncedAt;

  /// Ajouté en version 2. Null tant qu'aucune synchro n'a apporté de solde
  /// (base créée en version 1).
  final int? balance;
  const SyncStateRow({
    required this.id,
    required this.lastSyncedAt,
    this.balance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<int>(balance);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      lastSyncedAt: Value(lastSyncedAt),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      id: serializer.fromJson<int>(json['id']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      balance: serializer.fromJson<int?>(json['balance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'balance': serializer.toJson<int?>(balance),
    };
  }

  SyncStateRow copyWith({
    int? id,
    DateTime? lastSyncedAt,
    Value<int?> balance = const Value.absent(),
  }) => SyncStateRow(
    id: id ?? this.id,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    balance: balance.present ? balance.value : this.balance,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      id: data.id.present ? data.id.value : this.id,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      balance: data.balance.present ? data.balance.value : this.balance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('balance: $balance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastSyncedAt, balance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.id == this.id &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.balance == this.balance);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<int> id;
  final Value<DateTime> lastSyncedAt;
  final Value<int?> balance;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.balance = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    required DateTime lastSyncedAt,
    this.balance = const Value.absent(),
  }) : lastSyncedAt = Value(lastSyncedAt);
  static Insertable<SyncStateRow> custom({
    Expression<int>? id,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? balance,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (balance != null) 'balance': balance,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? lastSyncedAt,
    Value<int?>? balance,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      balance: balance ?? this.balance,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('balance: $balance')
          ..write(')'))
        .toString();
  }
}

abstract class _$TransferDatabase extends GeneratedDatabase {
  _$TransferDatabase(QueryExecutor e) : super(e);
  $TransferDatabaseManager get managers => $TransferDatabaseManager(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [transfers, syncState];
}

typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  required String idempotencyKey,
  Value<String?> serverId,
  required int amount,
  required String currency,
  required String recipientName,
  required String recipientPhone,
  required TransferStatus status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<String> idempotencyKey,
  Value<String?> serverId,
  Value<int> amount,
  Value<String> currency,
  Value<String> recipientName,
  Value<String> recipientPhone,
  Value<TransferStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TransfersTableFilterComposer
    extends Composer<_$TransferDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientName => $composableBuilder(
    column: $table.recipientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientPhone => $composableBuilder(
    column: $table.recipientPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransferStatus, TransferStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

class $$TransfersTableOrderingComposer
    extends Composer<_$TransferDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientName => $composableBuilder(
    column: $table.recipientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientPhone => $composableBuilder(
    column: $table.recipientPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
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

class $$TransfersTableAnnotationComposer
    extends Composer<_$TransferDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get recipientName => $composableBuilder(
    column: $table.recipientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientPhone => $composableBuilder(
    column: $table.recipientPhone,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransferStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$TransferDatabase,
          $TransfersTable,
          TransferRow,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (
            TransferRow,
            BaseReferences<_$TransferDatabase, $TransfersTable, TransferRow>,
          ),
          TransferRow,
          PrefetchHooks Function()
        > {
  $$TransfersTableTableManager(_$TransferDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> recipientName = const Value.absent(),
                Value<String> recipientPhone = const Value.absent(),
                Value<TransferStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion(
                idempotencyKey: idempotencyKey,
                serverId: serverId,
                amount: amount,
                currency: currency,
                recipientName: recipientName,
                recipientPhone: recipientPhone,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idempotencyKey,
                Value<String?> serverId = const Value.absent(),
                required int amount,
                required String currency,
                required String recipientName,
                required String recipientPhone,
                required TransferStatus status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion.insert(
                idempotencyKey: idempotencyKey,
                serverId: serverId,
                amount: amount,
                currency: currency,
                recipientName: recipientName,
                recipientPhone: recipientPhone,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransfersTable, TransferRow>(table),
                  BaseReferences<
                    _$TransferDatabase,
                    $TransfersTable,
                    TransferRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$TransferDatabase,
      $TransfersTable,
      TransferRow,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (
        TransferRow,
        BaseReferences<_$TransferDatabase, $TransfersTable, TransferRow>,
      ),
      TransferRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  required DateTime lastSyncedAt,
  Value<int?> balance,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  Value<DateTime> lastSyncedAt,
  Value<int?> balance,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$TransferDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$TransferDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$TransferDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$TransferDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$TransferDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$TransferDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<int?> balance = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                lastSyncedAt: lastSyncedAt,
                balance: balance,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime lastSyncedAt,
                Value<int?> balance = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                lastSyncedAt: lastSyncedAt,
                balance: balance,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateRow>(table),
                  BaseReferences<
                    _$TransferDatabase,
                    $SyncStateTable,
                    SyncStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$TransferDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$TransferDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;

class $TransferDatabaseManager {
  final _$TransferDatabase _db;
  $TransferDatabaseManager(this._db);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
