// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecurringTransactionCollection on Isar {
  IsarCollection<RecurringTransaction> get recurringTransactions =>
      this.collection();
}

const RecurringTransactionSchema = CollectionSchema(
  name: r'RecurringTransaction',
  id: 969840479390105118,
  properties: {
    r'adminFee': PropertySchema(
      id: 0,
      name: r'adminFee',
      type: IsarType.double,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.double,
    ),
    r'autoExecute': PropertySchema(
      id: 2,
      name: r'autoExecute',
      type: IsarType.bool,
    ),
    r'categorySyncId': PropertySchema(
      id: 3,
      name: r'categorySyncId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'endDate': PropertySchema(
      id: 6,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'frequency': PropertySchema(
      id: 7,
      name: r'frequency',
      type: IsarType.string,
    ),
    r'interval': PropertySchema(
      id: 8,
      name: r'interval',
      type: IsarType.long,
    ),
    r'isActive': PropertySchema(
      id: 9,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'lastExecutedDate': PropertySchema(
      id: 10,
      name: r'lastExecutedDate',
      type: IsarType.dateTime,
    ),
    r'maxOccurrences': PropertySchema(
      id: 11,
      name: r'maxOccurrences',
      type: IsarType.long,
    ),
    r'nextDueDate': PropertySchema(
      id: 12,
      name: r'nextDueDate',
      type: IsarType.dateTime,
    ),
    r'occurrenceCount': PropertySchema(
      id: 13,
      name: r'occurrenceCount',
      type: IsarType.long,
    ),
    r'startDate': PropertySchema(
      id: 14,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'syncId': PropertySchema(
      id: 15,
      name: r'syncId',
      type: IsarType.string,
    ),
    r'targetWalletSyncId': PropertySchema(
      id: 16,
      name: r'targetWalletSyncId',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 17,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 18,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'walletSyncId': PropertySchema(
      id: 19,
      name: r'walletSyncId',
      type: IsarType.string,
    )
  },
  estimateSize: _recurringTransactionEstimateSize,
  serialize: _recurringTransactionSerialize,
  deserialize: _recurringTransactionDeserialize,
  deserializeProp: _recurringTransactionDeserializeProp,
  idName: r'id',
  indexes: {
    r'syncId': IndexSchema(
      id: 7538593479801827566,
      name: r'syncId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'walletSyncId': IndexSchema(
      id: -8715096793012908160,
      name: r'walletSyncId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'walletSyncId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'nextDueDate': IndexSchema(
      id: -1749684646791026574,
      name: r'nextDueDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nextDueDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _recurringTransactionGetId,
  getLinks: _recurringTransactionGetLinks,
  attach: _recurringTransactionAttach,
  version: '3.1.0+1',
);

int _recurringTransactionEstimateSize(
  RecurringTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categorySyncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.frequency.length * 3;
  bytesCount += 3 + object.syncId.length * 3;
  {
    final value = object.targetWalletSyncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  bytesCount += 3 + object.walletSyncId.length * 3;
  return bytesCount;
}

void _recurringTransactionSerialize(
  RecurringTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.adminFee);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeBool(offsets[2], object.autoExecute);
  writer.writeString(offsets[3], object.categorySyncId);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.description);
  writer.writeDateTime(offsets[6], object.endDate);
  writer.writeString(offsets[7], object.frequency);
  writer.writeLong(offsets[8], object.interval);
  writer.writeBool(offsets[9], object.isActive);
  writer.writeDateTime(offsets[10], object.lastExecutedDate);
  writer.writeLong(offsets[11], object.maxOccurrences);
  writer.writeDateTime(offsets[12], object.nextDueDate);
  writer.writeLong(offsets[13], object.occurrenceCount);
  writer.writeDateTime(offsets[14], object.startDate);
  writer.writeString(offsets[15], object.syncId);
  writer.writeString(offsets[16], object.targetWalletSyncId);
  writer.writeString(offsets[17], object.type);
  writer.writeDateTime(offsets[18], object.updatedAt);
  writer.writeString(offsets[19], object.walletSyncId);
}

RecurringTransaction _recurringTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecurringTransaction();
  object.adminFee = reader.readDoubleOrNull(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.autoExecute = reader.readBool(offsets[2]);
  object.categorySyncId = reader.readStringOrNull(offsets[3]);
  object.createdAt = reader.readDateTime(offsets[4]);
  object.description = reader.readStringOrNull(offsets[5]);
  object.endDate = reader.readDateTimeOrNull(offsets[6]);
  object.frequency = reader.readString(offsets[7]);
  object.id = id;
  object.interval = reader.readLong(offsets[8]);
  object.isActive = reader.readBool(offsets[9]);
  object.lastExecutedDate = reader.readDateTimeOrNull(offsets[10]);
  object.maxOccurrences = reader.readLongOrNull(offsets[11]);
  object.nextDueDate = reader.readDateTime(offsets[12]);
  object.occurrenceCount = reader.readLong(offsets[13]);
  object.startDate = reader.readDateTime(offsets[14]);
  object.syncId = reader.readString(offsets[15]);
  object.targetWalletSyncId = reader.readStringOrNull(offsets[16]);
  object.type = reader.readString(offsets[17]);
  object.updatedAt = reader.readDateTime(offsets[18]);
  object.walletSyncId = reader.readString(offsets[19]);
  return object;
}

P _recurringTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _recurringTransactionGetId(RecurringTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recurringTransactionGetLinks(
    RecurringTransaction object) {
  return [];
}

void _recurringTransactionAttach(
    IsarCollection<dynamic> col, Id id, RecurringTransaction object) {
  object.id = id;
}

extension RecurringTransactionByIndex on IsarCollection<RecurringTransaction> {
  Future<RecurringTransaction?> getBySyncId(String syncId) {
    return getByIndex(r'syncId', [syncId]);
  }

  RecurringTransaction? getBySyncIdSync(String syncId) {
    return getByIndexSync(r'syncId', [syncId]);
  }

  Future<bool> deleteBySyncId(String syncId) {
    return deleteByIndex(r'syncId', [syncId]);
  }

  bool deleteBySyncIdSync(String syncId) {
    return deleteByIndexSync(r'syncId', [syncId]);
  }

  Future<List<RecurringTransaction?>> getAllBySyncId(
      List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncId', values);
  }

  List<RecurringTransaction?> getAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'syncId', values);
  }

  Future<int> deleteAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'syncId', values);
  }

  int deleteAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'syncId', values);
  }

  Future<Id> putBySyncId(RecurringTransaction object) {
    return putByIndex(r'syncId', object);
  }

  Id putBySyncIdSync(RecurringTransaction object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncId(List<RecurringTransaction> objects) {
    return putAllByIndex(r'syncId', objects);
  }

  List<Id> putAllBySyncIdSync(List<RecurringTransaction> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncId', objects, saveLinks: saveLinks);
  }
}

extension RecurringTransactionQueryWhereSort
    on QueryBuilder<RecurringTransaction, RecurringTransaction, QWhere> {
  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhere>
      anyNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nextDueDate'),
      );
    });
  }
}

extension RecurringTransactionQueryWhere
    on QueryBuilder<RecurringTransaction, RecurringTransaction, QWhereClause> {
  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      syncIdEqualTo(String syncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncId',
        value: [syncId],
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      syncIdNotEqualTo(String syncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [],
              upper: [syncId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [syncId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [syncId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [],
              upper: [syncId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      typeEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      typeNotEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      walletSyncIdEqualTo(String walletSyncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletSyncId',
        value: [walletSyncId],
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      walletSyncIdNotEqualTo(String walletSyncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletSyncId',
              lower: [],
              upper: [walletSyncId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletSyncId',
              lower: [walletSyncId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletSyncId',
              lower: [walletSyncId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletSyncId',
              lower: [],
              upper: [walletSyncId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      nextDueDateEqualTo(DateTime nextDueDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nextDueDate',
        value: [nextDueDate],
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      nextDueDateNotEqualTo(DateTime nextDueDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueDate',
              lower: [],
              upper: [nextDueDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueDate',
              lower: [nextDueDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueDate',
              lower: [nextDueDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueDate',
              lower: [],
              upper: [nextDueDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      nextDueDateGreaterThan(
    DateTime nextDueDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextDueDate',
        lower: [nextDueDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      nextDueDateLessThan(
    DateTime nextDueDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextDueDate',
        lower: [],
        upper: [nextDueDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterWhereClause>
      nextDueDateBetween(
    DateTime lowerNextDueDate,
    DateTime upperNextDueDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextDueDate',
        lower: [lowerNextDueDate],
        includeLower: includeLower,
        upper: [upperNextDueDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RecurringTransactionQueryFilter on QueryBuilder<RecurringTransaction,
    RecurringTransaction, QFilterCondition> {
  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> adminFeeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'adminFee',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> adminFeeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'adminFee',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> adminFeeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adminFee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> adminFeeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'adminFee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> adminFeeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'adminFee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> adminFeeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'adminFee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> autoExecuteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoExecute',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categorySyncId',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categorySyncId',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categorySyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categorySyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categorySyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categorySyncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categorySyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categorySyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      categorySyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categorySyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      categorySyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categorySyncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categorySyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> categorySyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categorySyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      frequencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      frequencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'frequency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> frequencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'frequency',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> intervalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interval',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> intervalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'interval',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> intervalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'interval',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> intervalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'interval',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> lastExecutedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastExecutedDate',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> lastExecutedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastExecutedDate',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> lastExecutedDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastExecutedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> lastExecutedDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastExecutedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> lastExecutedDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastExecutedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> lastExecutedDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastExecutedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> maxOccurrencesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maxOccurrences',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> maxOccurrencesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maxOccurrences',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> maxOccurrencesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxOccurrences',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> maxOccurrencesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxOccurrences',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> maxOccurrencesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxOccurrences',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> maxOccurrencesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxOccurrences',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> nextDueDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> nextDueDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> nextDueDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> nextDueDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextDueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> occurrenceCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occurrenceCount',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> occurrenceCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'occurrenceCount',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> occurrenceCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'occurrenceCount',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> occurrenceCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'occurrenceCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> startDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> startDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      syncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      syncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetWalletSyncId',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetWalletSyncId',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetWalletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetWalletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetWalletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetWalletSyncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetWalletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetWalletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      targetWalletSyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetWalletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      targetWalletSyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetWalletSyncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetWalletSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> targetWalletSyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetWalletSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'walletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'walletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'walletSyncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'walletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'walletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      walletSyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
          QAfterFilterCondition>
      walletSyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletSyncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction,
      QAfterFilterCondition> walletSyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletSyncId',
        value: '',
      ));
    });
  }
}

extension RecurringTransactionQueryObject on QueryBuilder<RecurringTransaction,
    RecurringTransaction, QFilterCondition> {}

extension RecurringTransactionQueryLinks on QueryBuilder<RecurringTransaction,
    RecurringTransaction, QFilterCondition> {}

extension RecurringTransactionQuerySortBy
    on QueryBuilder<RecurringTransaction, RecurringTransaction, QSortBy> {
  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByAdminFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminFee', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByAdminFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminFee', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByAutoExecute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoExecute', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByAutoExecuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoExecute', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByCategorySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySyncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByCategorySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySyncId', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interval', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interval', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByLastExecutedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecutedDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByLastExecutedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecutedDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByMaxOccurrences() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOccurrences', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByMaxOccurrencesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOccurrences', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByNextDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByOccurrenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceCount', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByOccurrenceCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceCount', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByTargetWalletSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetWalletSyncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByTargetWalletSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetWalletSyncId', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByWalletSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletSyncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      sortByWalletSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletSyncId', Sort.desc);
    });
  }
}

extension RecurringTransactionQuerySortThenBy
    on QueryBuilder<RecurringTransaction, RecurringTransaction, QSortThenBy> {
  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByAdminFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminFee', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByAdminFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminFee', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByAutoExecute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoExecute', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByAutoExecuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoExecute', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByCategorySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySyncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByCategorySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySyncId', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interval', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interval', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByLastExecutedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecutedDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByLastExecutedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecutedDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByMaxOccurrences() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOccurrences', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByMaxOccurrencesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOccurrences', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByNextDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByOccurrenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceCount', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByOccurrenceCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceCount', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByTargetWalletSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetWalletSyncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByTargetWalletSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetWalletSyncId', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByWalletSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletSyncId', Sort.asc);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QAfterSortBy>
      thenByWalletSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletSyncId', Sort.desc);
    });
  }
}

extension RecurringTransactionQueryWhereDistinct
    on QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct> {
  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByAdminFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'adminFee');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByAutoExecute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoExecute');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByCategorySyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categorySyncId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByFrequency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'interval');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByLastExecutedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastExecutedDate');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByMaxOccurrences() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxOccurrences');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextDueDate');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByOccurrenceCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurrenceCount');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctBySyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByTargetWalletSyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetWalletSyncId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<RecurringTransaction, RecurringTransaction, QDistinct>
      distinctByWalletSyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletSyncId', caseSensitive: caseSensitive);
    });
  }
}

extension RecurringTransactionQueryProperty on QueryBuilder<
    RecurringTransaction, RecurringTransaction, QQueryProperty> {
  QueryBuilder<RecurringTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecurringTransaction, double?, QQueryOperations>
      adminFeeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'adminFee');
    });
  }

  QueryBuilder<RecurringTransaction, double, QQueryOperations>
      amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<RecurringTransaction, bool, QQueryOperations>
      autoExecuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoExecute');
    });
  }

  QueryBuilder<RecurringTransaction, String?, QQueryOperations>
      categorySyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categorySyncId');
    });
  }

  QueryBuilder<RecurringTransaction, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RecurringTransaction, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<RecurringTransaction, DateTime?, QQueryOperations>
      endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<RecurringTransaction, String, QQueryOperations>
      frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<RecurringTransaction, int, QQueryOperations> intervalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interval');
    });
  }

  QueryBuilder<RecurringTransaction, bool, QQueryOperations>
      isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<RecurringTransaction, DateTime?, QQueryOperations>
      lastExecutedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastExecutedDate');
    });
  }

  QueryBuilder<RecurringTransaction, int?, QQueryOperations>
      maxOccurrencesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxOccurrences');
    });
  }

  QueryBuilder<RecurringTransaction, DateTime, QQueryOperations>
      nextDueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextDueDate');
    });
  }

  QueryBuilder<RecurringTransaction, int, QQueryOperations>
      occurrenceCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurrenceCount');
    });
  }

  QueryBuilder<RecurringTransaction, DateTime, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<RecurringTransaction, String, QQueryOperations>
      syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<RecurringTransaction, String?, QQueryOperations>
      targetWalletSyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetWalletSyncId');
    });
  }

  QueryBuilder<RecurringTransaction, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<RecurringTransaction, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<RecurringTransaction, String, QQueryOperations>
      walletSyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletSyncId');
    });
  }
}
