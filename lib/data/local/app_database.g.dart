// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
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
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _measurementUnitIdMeta = const VerificationMeta(
    'measurementUnitId',
  );
  @override
  late final GeneratedColumn<String> measurementUnitId =
      GeneratedColumn<String>(
        'measurement_unit_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _measurementUnitAbbrMeta =
      const VerificationMeta('measurementUnitAbbr');
  @override
  late final GeneratedColumn<String> measurementUnitAbbr =
      GeneratedColumn<String>(
        'measurement_unit_abbr',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String>
  lowStockThreshold = GeneratedColumn<String>(
    'low_stock_threshold',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Decimal>($LocalProductsTable.$converterlowStockThreshold);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> sellingPrice =
      GeneratedColumn<String>(
        'selling_price',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($LocalProductsTable.$convertersellingPrice);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> costPrice =
      GeneratedColumn<String>(
        'cost_price',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($LocalProductsTable.$convertercostPrice);
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    name,
    categoryId,
    description,
    measurementUnitId,
    measurementUnitAbbr,
    lowStockThreshold,
    sellingPrice,
    costPrice,
    isActive,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
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
    if (data.containsKey('measurement_unit_id')) {
      context.handle(
        _measurementUnitIdMeta,
        measurementUnitId.isAcceptableOrUnknown(
          data['measurement_unit_id']!,
          _measurementUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementUnitIdMeta);
    }
    if (data.containsKey('measurement_unit_abbr')) {
      context.handle(
        _measurementUnitAbbrMeta,
        measurementUnitAbbr.isAcceptableOrUnknown(
          data['measurement_unit_abbr']!,
          _measurementUnitAbbrMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementUnitAbbrMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      measurementUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_unit_id'],
      )!,
      measurementUnitAbbr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_unit_abbr'],
      )!,
      lowStockThreshold: $LocalProductsTable.$converterlowStockThreshold
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}low_stock_threshold'],
            )!,
          ),
      sellingPrice: $LocalProductsTable.$convertersellingPrice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}selling_price'],
        ),
      ),
      costPrice: $LocalProductsTable.$convertercostPrice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cost_price'],
        ),
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterlowStockThreshold =
      const _Dec();
  static TypeConverter<Decimal?, String?> $convertersellingPrice =
      const _NullDec();
  static TypeConverter<Decimal?, String?> $convertercostPrice =
      const _NullDec();
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String shopId;
  final String name;
  final String? categoryId;
  final String? description;
  final String measurementUnitId;
  final String measurementUnitAbbr;
  final Decimal lowStockThreshold;
  final Decimal? sellingPrice;
  final Decimal? costPrice;
  final bool isActive;
  final DateTime syncedAt;
  const ProductRow({
    required this.id,
    required this.shopId,
    required this.name,
    this.categoryId,
    this.description,
    required this.measurementUnitId,
    required this.measurementUnitAbbr,
    required this.lowStockThreshold,
    this.sellingPrice,
    this.costPrice,
    required this.isActive,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['measurement_unit_id'] = Variable<String>(measurementUnitId);
    map['measurement_unit_abbr'] = Variable<String>(measurementUnitAbbr);
    {
      map['low_stock_threshold'] = Variable<String>(
        $LocalProductsTable.$converterlowStockThreshold.toSql(
          lowStockThreshold,
        ),
      );
    }
    if (!nullToAbsent || sellingPrice != null) {
      map['selling_price'] = Variable<String>(
        $LocalProductsTable.$convertersellingPrice.toSql(sellingPrice),
      );
    }
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<String>(
        $LocalProductsTable.$convertercostPrice.toSql(costPrice),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      measurementUnitId: Value(measurementUnitId),
      measurementUnitAbbr: Value(measurementUnitAbbr),
      lowStockThreshold: Value(lowStockThreshold),
      sellingPrice: sellingPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(sellingPrice),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      isActive: Value(isActive),
      syncedAt: Value(syncedAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      description: serializer.fromJson<String?>(json['description']),
      measurementUnitId: serializer.fromJson<String>(json['measurementUnitId']),
      measurementUnitAbbr: serializer.fromJson<String>(
        json['measurementUnitAbbr'],
      ),
      lowStockThreshold: serializer.fromJson<Decimal>(
        json['lowStockThreshold'],
      ),
      sellingPrice: serializer.fromJson<Decimal?>(json['sellingPrice']),
      costPrice: serializer.fromJson<Decimal?>(json['costPrice']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String?>(categoryId),
      'description': serializer.toJson<String?>(description),
      'measurementUnitId': serializer.toJson<String>(measurementUnitId),
      'measurementUnitAbbr': serializer.toJson<String>(measurementUnitAbbr),
      'lowStockThreshold': serializer.toJson<Decimal>(lowStockThreshold),
      'sellingPrice': serializer.toJson<Decimal?>(sellingPrice),
      'costPrice': serializer.toJson<Decimal?>(costPrice),
      'isActive': serializer.toJson<bool>(isActive),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  ProductRow copyWith({
    String? id,
    String? shopId,
    String? name,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? measurementUnitId,
    String? measurementUnitAbbr,
    Decimal? lowStockThreshold,
    Value<Decimal?> sellingPrice = const Value.absent(),
    Value<Decimal?> costPrice = const Value.absent(),
    bool? isActive,
    DateTime? syncedAt,
  }) => ProductRow(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    description: description.present ? description.value : this.description,
    measurementUnitId: measurementUnitId ?? this.measurementUnitId,
    measurementUnitAbbr: measurementUnitAbbr ?? this.measurementUnitAbbr,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    sellingPrice: sellingPrice.present ? sellingPrice.value : this.sellingPrice,
    costPrice: costPrice.present ? costPrice.value : this.costPrice,
    isActive: isActive ?? this.isActive,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  ProductRow copyWithCompanion(LocalProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      description: data.description.present
          ? data.description.value
          : this.description,
      measurementUnitId: data.measurementUnitId.present
          ? data.measurementUnitId.value
          : this.measurementUnitId,
      measurementUnitAbbr: data.measurementUnitAbbr.present
          ? data.measurementUnitAbbr.value
          : this.measurementUnitAbbr,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('measurementUnitId: $measurementUnitId, ')
          ..write('measurementUnitAbbr: $measurementUnitAbbr, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('isActive: $isActive, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopId,
    name,
    categoryId,
    description,
    measurementUnitId,
    measurementUnitAbbr,
    lowStockThreshold,
    sellingPrice,
    costPrice,
    isActive,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.measurementUnitId == this.measurementUnitId &&
          other.measurementUnitAbbr == this.measurementUnitAbbr &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.sellingPrice == this.sellingPrice &&
          other.costPrice == this.costPrice &&
          other.isActive == this.isActive &&
          other.syncedAt == this.syncedAt);
}

class LocalProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> name;
  final Value<String?> categoryId;
  final Value<String?> description;
  final Value<String> measurementUnitId;
  final Value<String> measurementUnitAbbr;
  final Value<Decimal> lowStockThreshold;
  final Value<Decimal?> sellingPrice;
  final Value<Decimal?> costPrice;
  final Value<bool> isActive;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.measurementUnitId = const Value.absent(),
    this.measurementUnitAbbr = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    required String id,
    required String shopId,
    required String name,
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    required String measurementUnitId,
    required String measurementUnitAbbr,
    required Decimal lowStockThreshold,
    this.sellingPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    required bool isActive,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       name = Value(name),
       measurementUnitId = Value(measurementUnitId),
       measurementUnitAbbr = Value(measurementUnitAbbr),
       lowStockThreshold = Value(lowStockThreshold),
       isActive = Value(isActive),
       syncedAt = Value(syncedAt);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? description,
    Expression<String>? measurementUnitId,
    Expression<String>? measurementUnitAbbr,
    Expression<String>? lowStockThreshold,
    Expression<String>? sellingPrice,
    Expression<String>? costPrice,
    Expression<bool>? isActive,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (measurementUnitId != null) 'measurement_unit_id': measurementUnitId,
      if (measurementUnitAbbr != null)
        'measurement_unit_abbr': measurementUnitAbbr,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (costPrice != null) 'cost_price': costPrice,
      if (isActive != null) 'is_active': isActive,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? name,
    Value<String?>? categoryId,
    Value<String?>? description,
    Value<String>? measurementUnitId,
    Value<String>? measurementUnitAbbr,
    Value<Decimal>? lowStockThreshold,
    Value<Decimal?>? sellingPrice,
    Value<Decimal?>? costPrice,
    Value<bool>? isActive,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      measurementUnitId: measurementUnitId ?? this.measurementUnitId,
      measurementUnitAbbr: measurementUnitAbbr ?? this.measurementUnitAbbr,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      isActive: isActive ?? this.isActive,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (measurementUnitId.present) {
      map['measurement_unit_id'] = Variable<String>(measurementUnitId.value);
    }
    if (measurementUnitAbbr.present) {
      map['measurement_unit_abbr'] = Variable<String>(
        measurementUnitAbbr.value,
      );
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<String>(
        $LocalProductsTable.$converterlowStockThreshold.toSql(
          lowStockThreshold.value,
        ),
      );
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<String>(
        $LocalProductsTable.$convertersellingPrice.toSql(sellingPrice.value),
      );
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<String>(
        $LocalProductsTable.$convertercostPrice.toSql(costPrice.value),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('measurementUnitId: $measurementUnitId, ')
          ..write('measurementUnitAbbr: $measurementUnitAbbr, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('isActive: $isActive, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStockTable extends LocalStock
    with TableInfo<$LocalStockTable, StockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStockTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantity =
      GeneratedColumn<String>(
        'quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalStockTable.$converterquantity);
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    branchId,
    quantity,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stock';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, branchId};
  @override
  StockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      quantity: $LocalStockTable.$converterquantity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity'],
        )!,
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalStockTable createAlias(String alias) {
    return $LocalStockTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterquantity = const _Dec();
}

class StockRow extends DataClass implements Insertable<StockRow> {
  final String productId;
  final String branchId;
  final Decimal quantity;
  final DateTime syncedAt;
  const StockRow({
    required this.productId,
    required this.branchId,
    required this.quantity,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['branch_id'] = Variable<String>(branchId);
    {
      map['quantity'] = Variable<String>(
        $LocalStockTable.$converterquantity.toSql(quantity),
      );
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalStockCompanion toCompanion(bool nullToAbsent) {
    return LocalStockCompanion(
      productId: Value(productId),
      branchId: Value(branchId),
      quantity: Value(quantity),
      syncedAt: Value(syncedAt),
    );
  }

  factory StockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockRow(
      productId: serializer.fromJson<String>(json['productId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      quantity: serializer.fromJson<Decimal>(json['quantity']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'branchId': serializer.toJson<String>(branchId),
      'quantity': serializer.toJson<Decimal>(quantity),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  StockRow copyWith({
    String? productId,
    String? branchId,
    Decimal? quantity,
    DateTime? syncedAt,
  }) => StockRow(
    productId: productId ?? this.productId,
    branchId: branchId ?? this.branchId,
    quantity: quantity ?? this.quantity,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  StockRow copyWithCompanion(LocalStockCompanion data) {
    return StockRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockRow(')
          ..write('productId: $productId, ')
          ..write('branchId: $branchId, ')
          ..write('quantity: $quantity, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, branchId, quantity, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockRow &&
          other.productId == this.productId &&
          other.branchId == this.branchId &&
          other.quantity == this.quantity &&
          other.syncedAt == this.syncedAt);
}

class LocalStockCompanion extends UpdateCompanion<StockRow> {
  final Value<String> productId;
  final Value<String> branchId;
  final Value<Decimal> quantity;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalStockCompanion({
    this.productId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStockCompanion.insert({
    required String productId,
    required String branchId,
    required Decimal quantity,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       branchId = Value(branchId),
       quantity = Value(quantity),
       syncedAt = Value(syncedAt);
  static Insertable<StockRow> custom({
    Expression<String>? productId,
    Expression<String>? branchId,
    Expression<String>? quantity,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (branchId != null) 'branch_id': branchId,
      if (quantity != null) 'quantity': quantity,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStockCompanion copyWith({
    Value<String>? productId,
    Value<String>? branchId,
    Value<Decimal>? quantity,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalStockCompanion(
      productId: productId ?? this.productId,
      branchId: branchId ?? this.branchId,
      quantity: quantity ?? this.quantity,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(
        $LocalStockTable.$converterquantity.toSql(quantity.value),
      );
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockCompanion(')
          ..write('productId: $productId, ')
          ..write('branchId: $branchId, ')
          ..write('quantity: $quantity, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSalesTable extends LocalSales
    with TableInfo<$LocalSalesTable, SaleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodIdMeta = const VerificationMeta(
    'paymentMethodId',
  );
  @override
  late final GeneratedColumn<String> paymentMethodId = GeneratedColumn<String>(
    'payment_method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> subtotal =
      GeneratedColumn<String>(
        'subtotal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSalesTable.$convertersubtotal);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> discountAmount =
      GeneratedColumn<String>(
        'discount_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSalesTable.$converterdiscountAmount);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> total =
      GeneratedColumn<String>(
        'total',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSalesTable.$convertertotal);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _voidedByMeta = const VerificationMeta(
    'voidedBy',
  );
  @override
  late final GeneratedColumn<String> voidedBy = GeneratedColumn<String>(
    'voided_by',
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
  static const VerificationMeta _isCreditMeta = const VerificationMeta(
    'isCredit',
  );
  @override
  late final GeneratedColumn<bool> isCredit = GeneratedColumn<bool>(
    'is_credit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_credit" IN (0, 1))',
    ),
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
  static const VerificationMeta _creditSettledAtMeta = const VerificationMeta(
    'creditSettledAt',
  );
  @override
  late final GeneratedColumn<DateTime> creditSettledAt =
      GeneratedColumn<DateTime>(
        'credit_settled_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    branchId,
    customerId,
    cashierId,
    paymentMethodId,
    subtotal,
    discountAmount,
    total,
    status,
    voidReason,
    voidedBy,
    voidedAt,
    isCredit,
    notes,
    createdAt,
    creditSettledAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
        _paymentMethodIdMeta,
        paymentMethodId.isAcceptableOrUnknown(
          data['payment_method_id']!,
          _paymentMethodIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('voided_by')) {
      context.handle(
        _voidedByMeta,
        voidedBy.isAcceptableOrUnknown(data['voided_by']!, _voidedByMeta),
      );
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    if (data.containsKey('is_credit')) {
      context.handle(
        _isCreditMeta,
        isCredit.isAcceptableOrUnknown(data['is_credit']!, _isCreditMeta),
      );
    } else if (isInserting) {
      context.missing(_isCreditMeta);
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
    if (data.containsKey('credit_settled_at')) {
      context.handle(
        _creditSettledAtMeta,
        creditSettledAt.isAcceptableOrUnknown(
          data['credit_settled_at']!,
          _creditSettledAtMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      paymentMethodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_id'],
      )!,
      subtotal: $LocalSalesTable.$convertersubtotal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subtotal'],
        )!,
      ),
      discountAmount: $LocalSalesTable.$converterdiscountAmount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}discount_amount'],
        )!,
      ),
      total: $LocalSalesTable.$convertertotal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}total'],
        )!,
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_by'],
      ),
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
      isCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credit'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      creditSettledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}credit_settled_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $LocalSalesTable createAlias(String alias) {
    return $LocalSalesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertersubtotal = const _Dec();
  static TypeConverter<Decimal, String> $converterdiscountAmount = const _Dec();
  static TypeConverter<Decimal, String> $convertertotal = const _Dec();
}

class SaleRow extends DataClass implements Insertable<SaleRow> {
  final String id;
  final String branchId;
  final String? customerId;
  final String cashierId;
  final String paymentMethodId;
  final Decimal subtotal;
  final Decimal discountAmount;
  final Decimal total;
  final String status;
  final String? voidReason;
  final String? voidedBy;
  final DateTime? voidedAt;
  final bool isCredit;
  final String? notes;
  final DateTime createdAt;
  final DateTime? creditSettledAt;
  final bool isSynced;
  const SaleRow({
    required this.id,
    required this.branchId,
    this.customerId,
    required this.cashierId,
    required this.paymentMethodId,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.status,
    this.voidReason,
    this.voidedBy,
    this.voidedAt,
    required this.isCredit,
    this.notes,
    required this.createdAt,
    this.creditSettledAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['cashier_id'] = Variable<String>(cashierId);
    map['payment_method_id'] = Variable<String>(paymentMethodId);
    {
      map['subtotal'] = Variable<String>(
        $LocalSalesTable.$convertersubtotal.toSql(subtotal),
      );
    }
    {
      map['discount_amount'] = Variable<String>(
        $LocalSalesTable.$converterdiscountAmount.toSql(discountAmount),
      );
    }
    {
      map['total'] = Variable<String>(
        $LocalSalesTable.$convertertotal.toSql(total),
      );
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidedBy != null) {
      map['voided_by'] = Variable<String>(voidedBy);
    }
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    map['is_credit'] = Variable<bool>(isCredit);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || creditSettledAt != null) {
      map['credit_settled_at'] = Variable<DateTime>(creditSettledAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalSalesCompanion toCompanion(bool nullToAbsent) {
    return LocalSalesCompanion(
      id: Value(id),
      branchId: Value(branchId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      cashierId: Value(cashierId),
      paymentMethodId: Value(paymentMethodId),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      total: Value(total),
      status: Value(status),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidedBy: voidedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedBy),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      isCredit: Value(isCredit),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      creditSettledAt: creditSettledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(creditSettledAt),
      isSynced: Value(isSynced),
    );
  }

  factory SaleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleRow(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      paymentMethodId: serializer.fromJson<String>(json['paymentMethodId']),
      subtotal: serializer.fromJson<Decimal>(json['subtotal']),
      discountAmount: serializer.fromJson<Decimal>(json['discountAmount']),
      total: serializer.fromJson<Decimal>(json['total']),
      status: serializer.fromJson<String>(json['status']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidedBy: serializer.fromJson<String?>(json['voidedBy']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
      isCredit: serializer.fromJson<bool>(json['isCredit']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      creditSettledAt: serializer.fromJson<DateTime?>(json['creditSettledAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'customerId': serializer.toJson<String?>(customerId),
      'cashierId': serializer.toJson<String>(cashierId),
      'paymentMethodId': serializer.toJson<String>(paymentMethodId),
      'subtotal': serializer.toJson<Decimal>(subtotal),
      'discountAmount': serializer.toJson<Decimal>(discountAmount),
      'total': serializer.toJson<Decimal>(total),
      'status': serializer.toJson<String>(status),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidedBy': serializer.toJson<String?>(voidedBy),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
      'isCredit': serializer.toJson<bool>(isCredit),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'creditSettledAt': serializer.toJson<DateTime?>(creditSettledAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  SaleRow copyWith({
    String? id,
    String? branchId,
    Value<String?> customerId = const Value.absent(),
    String? cashierId,
    String? paymentMethodId,
    Decimal? subtotal,
    Decimal? discountAmount,
    Decimal? total,
    String? status,
    Value<String?> voidReason = const Value.absent(),
    Value<String?> voidedBy = const Value.absent(),
    Value<DateTime?> voidedAt = const Value.absent(),
    bool? isCredit,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> creditSettledAt = const Value.absent(),
    bool? isSynced,
  }) => SaleRow(
    id: id ?? this.id,
    branchId: branchId ?? this.branchId,
    customerId: customerId.present ? customerId.value : this.customerId,
    cashierId: cashierId ?? this.cashierId,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    total: total ?? this.total,
    status: status ?? this.status,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidedBy: voidedBy.present ? voidedBy.value : this.voidedBy,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
    isCredit: isCredit ?? this.isCredit,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    creditSettledAt: creditSettledAt.present
        ? creditSettledAt.value
        : this.creditSettledAt,
    isSynced: isSynced ?? this.isSynced,
  );
  SaleRow copyWithCompanion(LocalSalesCompanion data) {
    return SaleRow(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidedBy: data.voidedBy.present ? data.voidedBy.value : this.voidedBy,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      isCredit: data.isCredit.present ? data.isCredit.value : this.isCredit,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      creditSettledAt: data.creditSettledAt.present
          ? data.creditSettledAt.value
          : this.creditSettledAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleRow(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('cashierId: $cashierId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedBy: $voidedBy, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('isCredit: $isCredit, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('creditSettledAt: $creditSettledAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    branchId,
    customerId,
    cashierId,
    paymentMethodId,
    subtotal,
    discountAmount,
    total,
    status,
    voidReason,
    voidedBy,
    voidedAt,
    isCredit,
    notes,
    createdAt,
    creditSettledAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleRow &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.customerId == this.customerId &&
          other.cashierId == this.cashierId &&
          other.paymentMethodId == this.paymentMethodId &&
          other.subtotal == this.subtotal &&
          other.discountAmount == this.discountAmount &&
          other.total == this.total &&
          other.status == this.status &&
          other.voidReason == this.voidReason &&
          other.voidedBy == this.voidedBy &&
          other.voidedAt == this.voidedAt &&
          other.isCredit == this.isCredit &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.creditSettledAt == this.creditSettledAt &&
          other.isSynced == this.isSynced);
}

class LocalSalesCompanion extends UpdateCompanion<SaleRow> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String?> customerId;
  final Value<String> cashierId;
  final Value<String> paymentMethodId;
  final Value<Decimal> subtotal;
  final Value<Decimal> discountAmount;
  final Value<Decimal> total;
  final Value<String> status;
  final Value<String?> voidReason;
  final Value<String?> voidedBy;
  final Value<DateTime?> voidedAt;
  final Value<bool> isCredit;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> creditSettledAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalSalesCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedBy = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.creditSettledAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSalesCompanion.insert({
    required String id,
    required String branchId,
    this.customerId = const Value.absent(),
    required String cashierId,
    required String paymentMethodId,
    required Decimal subtotal,
    required Decimal discountAmount,
    required Decimal total,
    required String status,
    this.voidReason = const Value.absent(),
    this.voidedBy = const Value.absent(),
    this.voidedAt = const Value.absent(),
    required bool isCredit,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.creditSettledAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       branchId = Value(branchId),
       cashierId = Value(cashierId),
       paymentMethodId = Value(paymentMethodId),
       subtotal = Value(subtotal),
       discountAmount = Value(discountAmount),
       total = Value(total),
       status = Value(status),
       isCredit = Value(isCredit),
       createdAt = Value(createdAt);
  static Insertable<SaleRow> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? customerId,
    Expression<String>? cashierId,
    Expression<String>? paymentMethodId,
    Expression<String>? subtotal,
    Expression<String>? discountAmount,
    Expression<String>? total,
    Expression<String>? status,
    Expression<String>? voidReason,
    Expression<String>? voidedBy,
    Expression<DateTime>? voidedAt,
    Expression<bool>? isCredit,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? creditSettledAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (customerId != null) 'customer_id': customerId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidedBy != null) 'voided_by': voidedBy,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (isCredit != null) 'is_credit': isCredit,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (creditSettledAt != null) 'credit_settled_at': creditSettledAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSalesCompanion copyWith({
    Value<String>? id,
    Value<String>? branchId,
    Value<String?>? customerId,
    Value<String>? cashierId,
    Value<String>? paymentMethodId,
    Value<Decimal>? subtotal,
    Value<Decimal>? discountAmount,
    Value<Decimal>? total,
    Value<String>? status,
    Value<String?>? voidReason,
    Value<String?>? voidedBy,
    Value<DateTime?>? voidedAt,
    Value<bool>? isCredit,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? creditSettledAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return LocalSalesCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      voidReason: voidReason ?? this.voidReason,
      voidedBy: voidedBy ?? this.voidedBy,
      voidedAt: voidedAt ?? this.voidedAt,
      isCredit: isCredit ?? this.isCredit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      creditSettledAt: creditSettledAt ?? this.creditSettledAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<String>(paymentMethodId.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(
        $LocalSalesTable.$convertersubtotal.toSql(subtotal.value),
      );
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<String>(
        $LocalSalesTable.$converterdiscountAmount.toSql(discountAmount.value),
      );
    }
    if (total.present) {
      map['total'] = Variable<String>(
        $LocalSalesTable.$convertertotal.toSql(total.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidedBy.present) {
      map['voided_by'] = Variable<String>(voidedBy.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (isCredit.present) {
      map['is_credit'] = Variable<bool>(isCredit.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (creditSettledAt.present) {
      map['credit_settled_at'] = Variable<DateTime>(creditSettledAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSalesCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('cashierId: $cashierId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedBy: $voidedBy, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('isCredit: $isCredit, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('creditSettledAt: $creditSettledAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSaleItemsTable extends LocalSaleItems
    with TableInfo<$LocalSaleItemsTable, SaleItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _measurementUnitIdMeta = const VerificationMeta(
    'measurementUnitId',
  );
  @override
  late final GeneratedColumn<String> measurementUnitId =
      GeneratedColumn<String>(
        'measurement_unit_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantity =
      GeneratedColumn<String>(
        'quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSaleItemsTable.$converterquantity);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> unitPrice =
      GeneratedColumn<String>(
        'unit_price',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSaleItemsTable.$converterunitPrice);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> discountAmount =
      GeneratedColumn<String>(
        'discount_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSaleItemsTable.$converterdiscountAmount);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> total =
      GeneratedColumn<String>(
        'total',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalSaleItemsTable.$convertertotal);
  static const VerificationMeta _inventoryStatusMeta = const VerificationMeta(
    'inventoryStatus',
  );
  @override
  late final GeneratedColumn<String> inventoryStatus = GeneratedColumn<String>(
    'inventory_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String>
  costPriceSnapshot = GeneratedColumn<String>(
    'cost_price_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Decimal?>($LocalSaleItemsTable.$convertercostPriceSnapshot);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    productNameSnapshot,
    measurementUnitId,
    quantity,
    unitPrice,
    discountAmount,
    total,
    inventoryStatus,
    costPriceSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    if (data.containsKey('measurement_unit_id')) {
      context.handle(
        _measurementUnitIdMeta,
        measurementUnitId.isAcceptableOrUnknown(
          data['measurement_unit_id']!,
          _measurementUnitIdMeta,
        ),
      );
    }
    if (data.containsKey('inventory_status')) {
      context.handle(
        _inventoryStatusMeta,
        inventoryStatus.isAcceptableOrUnknown(
          data['inventory_status']!,
          _inventoryStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inventoryStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      )!,
      measurementUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_unit_id'],
      ),
      quantity: $LocalSaleItemsTable.$converterquantity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity'],
        )!,
      ),
      unitPrice: $LocalSaleItemsTable.$converterunitPrice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit_price'],
        )!,
      ),
      discountAmount: $LocalSaleItemsTable.$converterdiscountAmount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}discount_amount'],
        )!,
      ),
      total: $LocalSaleItemsTable.$convertertotal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}total'],
        )!,
      ),
      inventoryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_status'],
      )!,
      costPriceSnapshot: $LocalSaleItemsTable.$convertercostPriceSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}cost_price_snapshot'],
            ),
          ),
    );
  }

  @override
  $LocalSaleItemsTable createAlias(String alias) {
    return $LocalSaleItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterquantity = const _Dec();
  static TypeConverter<Decimal, String> $converterunitPrice = const _Dec();
  static TypeConverter<Decimal, String> $converterdiscountAmount = const _Dec();
  static TypeConverter<Decimal, String> $convertertotal = const _Dec();
  static TypeConverter<Decimal?, String?> $convertercostPriceSnapshot =
      const _NullDec();
}

class SaleItemRow extends DataClass implements Insertable<SaleItemRow> {
  final String id;
  final String saleId;
  final String? productId;
  final String productNameSnapshot;
  final String? measurementUnitId;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal discountAmount;
  final Decimal total;
  final String inventoryStatus;
  final Decimal? costPriceSnapshot;
  const SaleItemRow({
    required this.id,
    required this.saleId,
    this.productId,
    required this.productNameSnapshot,
    this.measurementUnitId,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.total,
    required this.inventoryStatus,
    this.costPriceSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    if (!nullToAbsent || measurementUnitId != null) {
      map['measurement_unit_id'] = Variable<String>(measurementUnitId);
    }
    {
      map['quantity'] = Variable<String>(
        $LocalSaleItemsTable.$converterquantity.toSql(quantity),
      );
    }
    {
      map['unit_price'] = Variable<String>(
        $LocalSaleItemsTable.$converterunitPrice.toSql(unitPrice),
      );
    }
    {
      map['discount_amount'] = Variable<String>(
        $LocalSaleItemsTable.$converterdiscountAmount.toSql(discountAmount),
      );
    }
    {
      map['total'] = Variable<String>(
        $LocalSaleItemsTable.$convertertotal.toSql(total),
      );
    }
    map['inventory_status'] = Variable<String>(inventoryStatus);
    if (!nullToAbsent || costPriceSnapshot != null) {
      map['cost_price_snapshot'] = Variable<String>(
        $LocalSaleItemsTable.$convertercostPriceSnapshot.toSql(
          costPriceSnapshot,
        ),
      );
    }
    return map;
  }

  LocalSaleItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalSaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productNameSnapshot: Value(productNameSnapshot),
      measurementUnitId: measurementUnitId == null && nullToAbsent
          ? const Value.absent()
          : Value(measurementUnitId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      discountAmount: Value(discountAmount),
      total: Value(total),
      inventoryStatus: Value(inventoryStatus),
      costPriceSnapshot: costPriceSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(costPriceSnapshot),
    );
  }

  factory SaleItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItemRow(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productNameSnapshot: serializer.fromJson<String>(
        json['productNameSnapshot'],
      ),
      measurementUnitId: serializer.fromJson<String?>(
        json['measurementUnitId'],
      ),
      quantity: serializer.fromJson<Decimal>(json['quantity']),
      unitPrice: serializer.fromJson<Decimal>(json['unitPrice']),
      discountAmount: serializer.fromJson<Decimal>(json['discountAmount']),
      total: serializer.fromJson<Decimal>(json['total']),
      inventoryStatus: serializer.fromJson<String>(json['inventoryStatus']),
      costPriceSnapshot: serializer.fromJson<Decimal?>(
        json['costPriceSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String?>(productId),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
      'measurementUnitId': serializer.toJson<String?>(measurementUnitId),
      'quantity': serializer.toJson<Decimal>(quantity),
      'unitPrice': serializer.toJson<Decimal>(unitPrice),
      'discountAmount': serializer.toJson<Decimal>(discountAmount),
      'total': serializer.toJson<Decimal>(total),
      'inventoryStatus': serializer.toJson<String>(inventoryStatus),
      'costPriceSnapshot': serializer.toJson<Decimal?>(costPriceSnapshot),
    };
  }

  SaleItemRow copyWith({
    String? id,
    String? saleId,
    Value<String?> productId = const Value.absent(),
    String? productNameSnapshot,
    Value<String?> measurementUnitId = const Value.absent(),
    Decimal? quantity,
    Decimal? unitPrice,
    Decimal? discountAmount,
    Decimal? total,
    String? inventoryStatus,
    Value<Decimal?> costPriceSnapshot = const Value.absent(),
  }) => SaleItemRow(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId.present ? productId.value : this.productId,
    productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
    measurementUnitId: measurementUnitId.present
        ? measurementUnitId.value
        : this.measurementUnitId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    discountAmount: discountAmount ?? this.discountAmount,
    total: total ?? this.total,
    inventoryStatus: inventoryStatus ?? this.inventoryStatus,
    costPriceSnapshot: costPriceSnapshot.present
        ? costPriceSnapshot.value
        : this.costPriceSnapshot,
  );
  SaleItemRow copyWithCompanion(LocalSaleItemsCompanion data) {
    return SaleItemRow(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      measurementUnitId: data.measurementUnitId.present
          ? data.measurementUnitId.value
          : this.measurementUnitId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      total: data.total.present ? data.total.value : this.total,
      inventoryStatus: data.inventoryStatus.present
          ? data.inventoryStatus.value
          : this.inventoryStatus,
      costPriceSnapshot: data.costPriceSnapshot.present
          ? data.costPriceSnapshot.value
          : this.costPriceSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemRow(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('measurementUnitId: $measurementUnitId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('total: $total, ')
          ..write('inventoryStatus: $inventoryStatus, ')
          ..write('costPriceSnapshot: $costPriceSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    productId,
    productNameSnapshot,
    measurementUnitId,
    quantity,
    unitPrice,
    discountAmount,
    total,
    inventoryStatus,
    costPriceSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItemRow &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.measurementUnitId == this.measurementUnitId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.discountAmount == this.discountAmount &&
          other.total == this.total &&
          other.inventoryStatus == this.inventoryStatus &&
          other.costPriceSnapshot == this.costPriceSnapshot);
}

class LocalSaleItemsCompanion extends UpdateCompanion<SaleItemRow> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String?> productId;
  final Value<String> productNameSnapshot;
  final Value<String?> measurementUnitId;
  final Value<Decimal> quantity;
  final Value<Decimal> unitPrice;
  final Value<Decimal> discountAmount;
  final Value<Decimal> total;
  final Value<String> inventoryStatus;
  final Value<Decimal?> costPriceSnapshot;
  final Value<int> rowid;
  const LocalSaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.measurementUnitId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.inventoryStatus = const Value.absent(),
    this.costPriceSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSaleItemsCompanion.insert({
    required String id,
    required String saleId,
    this.productId = const Value.absent(),
    required String productNameSnapshot,
    this.measurementUnitId = const Value.absent(),
    required Decimal quantity,
    required Decimal unitPrice,
    required Decimal discountAmount,
    required Decimal total,
    required String inventoryStatus,
    this.costPriceSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       productNameSnapshot = Value(productNameSnapshot),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       discountAmount = Value(discountAmount),
       total = Value(total),
       inventoryStatus = Value(inventoryStatus);
  static Insertable<SaleItemRow> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<String>? productNameSnapshot,
    Expression<String>? measurementUnitId,
    Expression<String>? quantity,
    Expression<String>? unitPrice,
    Expression<String>? discountAmount,
    Expression<String>? total,
    Expression<String>? inventoryStatus,
    Expression<String>? costPriceSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (measurementUnitId != null) 'measurement_unit_id': measurementUnitId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (total != null) 'total': total,
      if (inventoryStatus != null) 'inventory_status': inventoryStatus,
      if (costPriceSnapshot != null) 'cost_price_snapshot': costPriceSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSaleItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String?>? productId,
    Value<String>? productNameSnapshot,
    Value<String?>? measurementUnitId,
    Value<Decimal>? quantity,
    Value<Decimal>? unitPrice,
    Value<Decimal>? discountAmount,
    Value<Decimal>? total,
    Value<String>? inventoryStatus,
    Value<Decimal?>? costPriceSnapshot,
    Value<int>? rowid,
  }) {
    return LocalSaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      measurementUnitId: measurementUnitId ?? this.measurementUnitId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      inventoryStatus: inventoryStatus ?? this.inventoryStatus,
      costPriceSnapshot: costPriceSnapshot ?? this.costPriceSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (measurementUnitId.present) {
      map['measurement_unit_id'] = Variable<String>(measurementUnitId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(
        $LocalSaleItemsTable.$converterquantity.toSql(quantity.value),
      );
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(
        $LocalSaleItemsTable.$converterunitPrice.toSql(unitPrice.value),
      );
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<String>(
        $LocalSaleItemsTable.$converterdiscountAmount.toSql(
          discountAmount.value,
        ),
      );
    }
    if (total.present) {
      map['total'] = Variable<String>(
        $LocalSaleItemsTable.$convertertotal.toSql(total.value),
      );
    }
    if (inventoryStatus.present) {
      map['inventory_status'] = Variable<String>(inventoryStatus.value);
    }
    if (costPriceSnapshot.present) {
      map['cost_price_snapshot'] = Variable<String>(
        $LocalSaleItemsTable.$convertercostPriceSnapshot.toSql(
          costPriceSnapshot.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('measurementUnitId: $measurementUnitId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('total: $total, ')
          ..write('inventoryStatus: $inventoryStatus, ')
          ..write('costPriceSnapshot: $costPriceSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCustomersTable extends LocalCustomers
    with TableInfo<$LocalCustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> creditBalance =
      GeneratedColumn<String>(
        'credit_balance',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalCustomersTable.$convertercreditBalance);
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    name,
    phone,
    creditBalance,
    updatedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
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
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      creditBalance: $LocalCustomersTable.$convertercreditBalance.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}credit_balance'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $LocalCustomersTable createAlias(String alias) {
    return $LocalCustomersTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertercreditBalance = const _Dec();
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final Decimal creditBalance;
  final DateTime updatedAt;
  final bool isSynced;
  const CustomerRow({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    required this.creditBalance,
    required this.updatedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    {
      map['credit_balance'] = Variable<String>(
        $LocalCustomersTable.$convertercreditBalance.toSql(creditBalance),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalCustomersCompanion toCompanion(bool nullToAbsent) {
    return LocalCustomersCompanion(
      id: Value(id),
      shopId: Value(shopId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      creditBalance: Value(creditBalance),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      creditBalance: serializer.fromJson<Decimal>(json['creditBalance']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'creditBalance': serializer.toJson<Decimal>(creditBalance),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  CustomerRow copyWith({
    String? id,
    String? shopId,
    String? name,
    Value<String?> phone = const Value.absent(),
    Decimal? creditBalance,
    DateTime? updatedAt,
    bool? isSynced,
  }) => CustomerRow(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    creditBalance: creditBalance ?? this.creditBalance,
    updatedAt: updatedAt ?? this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  CustomerRow copyWithCompanion(LocalCustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      creditBalance: data.creditBalance.present
          ? data.creditBalance.value
          : this.creditBalance,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('creditBalance: $creditBalance, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, name, phone, creditBalance, updatedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.creditBalance == this.creditBalance &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class LocalCustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<Decimal> creditBalance;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalCustomersCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.creditBalance = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCustomersCompanion.insert({
    required String id,
    required String shopId,
    required String name,
    this.phone = const Value.absent(),
    required Decimal creditBalance,
    required DateTime updatedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       name = Value(name),
       creditBalance = Value(creditBalance),
       updatedAt = Value(updatedAt);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? creditBalance,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (creditBalance != null) 'credit_balance': creditBalance,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? name,
    Value<String?>? phone,
    Value<Decimal>? creditBalance,
    Value<DateTime>? updatedAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return LocalCustomersCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      creditBalance: creditBalance ?? this.creditBalance,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (creditBalance.present) {
      map['credit_balance'] = Variable<String>(
        $LocalCustomersTable.$convertercreditBalance.toSql(creditBalance.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomersCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('creditBalance: $creditBalance, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExpensesTable extends LocalExpenses
    with TableInfo<$LocalExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> amount =
      GeneratedColumn<String>(
        'amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalExpensesTable.$converteramount);
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
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    branchId,
    categoryId,
    categoryName,
    amount,
    description,
    recordedBy,
    date,
    createdAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
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
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      amount: $LocalExpensesTable.$converteramount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $LocalExpensesTable createAlias(String alias) {
    return $LocalExpensesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converteramount = const _Dec();
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String branchId;
  final String categoryId;
  final String categoryName;
  final Decimal amount;
  final String? description;
  final String recordedBy;
  final DateTime date;
  final DateTime createdAt;
  final bool isSynced;
  const ExpenseRow({
    required this.id,
    required this.branchId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.description,
    required this.recordedBy,
    required this.date,
    required this.createdAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['category_id'] = Variable<String>(categoryId);
    map['category_name'] = Variable<String>(categoryName);
    {
      map['amount'] = Variable<String>(
        $LocalExpensesTable.$converteramount.toSql(amount),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['recorded_by'] = Variable<String>(recordedBy);
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalExpensesCompanion toCompanion(bool nullToAbsent) {
    return LocalExpensesCompanion(
      id: Value(id),
      branchId: Value(branchId),
      categoryId: Value(categoryId),
      categoryName: Value(categoryName),
      amount: Value(amount),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      recordedBy: Value(recordedBy),
      date: Value(date),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      amount: serializer.fromJson<Decimal>(json['amount']),
      description: serializer.fromJson<String?>(json['description']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'categoryId': serializer.toJson<String>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'amount': serializer.toJson<Decimal>(amount),
      'description': serializer.toJson<String?>(description),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? branchId,
    String? categoryId,
    String? categoryName,
    Decimal? amount,
    Value<String?> description = const Value.absent(),
    String? recordedBy,
    DateTime? date,
    DateTime? createdAt,
    bool? isSynced,
  }) => ExpenseRow(
    id: id ?? this.id,
    branchId: branchId ?? this.branchId,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    amount: amount ?? this.amount,
    description: description.present ? description.value : this.description,
    recordedBy: recordedBy ?? this.recordedBy,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
  );
  ExpenseRow copyWithCompanion(LocalExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present
          ? data.description.value
          : this.description,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    branchId,
    categoryId,
    categoryName,
    amount,
    description,
    recordedBy,
    date,
    createdAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.recordedBy == this.recordedBy &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> categoryId;
  final Value<String> categoryName;
  final Value<Decimal> amount;
  final Value<String?> description;
  final Value<String> recordedBy;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalExpensesCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExpensesCompanion.insert({
    required String id,
    required String branchId,
    required String categoryId,
    required String categoryName,
    required Decimal amount,
    this.description = const Value.absent(),
    required String recordedBy,
    required DateTime date,
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       branchId = Value(branchId),
       categoryId = Value(categoryId),
       categoryName = Value(categoryName),
       amount = Value(amount),
       recordedBy = Value(recordedBy),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? amount,
    Expression<String>? description,
    Expression<String>? recordedBy,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? branchId,
    Value<String>? categoryId,
    Value<String>? categoryName,
    Value<Decimal>? amount,
    Value<String?>? description,
    Value<String>? recordedBy,
    Value<DateTime>? date,
    Value<DateTime>? createdAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return LocalExpensesCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(
        $LocalExpensesTable.$converteramount.toSql(amount.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpensesCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryAdjustmentsTable extends LocalInventoryAdjustments
    with TableInfo<$LocalInventoryAdjustmentsTable, InventoryAdjustmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryAdjustmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantityBefore =
      GeneratedColumn<String>(
        'quantity_before',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>(
        $LocalInventoryAdjustmentsTable.$converterquantityBefore,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantityAfter =
      GeneratedColumn<String>(
        'quantity_after',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>(
        $LocalInventoryAdjustmentsTable.$converterquantityAfter,
      );
  static const VerificationMeta _adjustedByMeta = const VerificationMeta(
    'adjustedBy',
  );
  @override
  late final GeneratedColumn<String> adjustedBy = GeneratedColumn<String>(
    'adjusted_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    branchId,
    productId,
    type,
    quantityBefore,
    quantityAfter,
    adjustedBy,
    notes,
    expiryDate,
    createdAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_adjustments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryAdjustmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('adjusted_by')) {
      context.handle(
        _adjustedByMeta,
        adjustedBy.isAcceptableOrUnknown(data['adjusted_by']!, _adjustedByMeta),
      );
    } else if (isInserting) {
      context.missing(_adjustedByMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
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
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryAdjustmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryAdjustmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      quantityBefore: $LocalInventoryAdjustmentsTable.$converterquantityBefore
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}quantity_before'],
            )!,
          ),
      quantityAfter: $LocalInventoryAdjustmentsTable.$converterquantityAfter
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}quantity_after'],
            )!,
          ),
      adjustedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjusted_by'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $LocalInventoryAdjustmentsTable createAlias(String alias) {
    return $LocalInventoryAdjustmentsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterquantityBefore = const _Dec();
  static TypeConverter<Decimal, String> $converterquantityAfter = const _Dec();
}

class InventoryAdjustmentRow extends DataClass
    implements Insertable<InventoryAdjustmentRow> {
  final String id;
  final String branchId;
  final String productId;
  final String type;
  final Decimal quantityBefore;
  final Decimal quantityAfter;
  final String adjustedBy;
  final String? notes;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final bool isSynced;
  const InventoryAdjustmentRow({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.type,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.adjustedBy,
    this.notes,
    this.expiryDate,
    required this.createdAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['product_id'] = Variable<String>(productId);
    map['type'] = Variable<String>(type);
    {
      map['quantity_before'] = Variable<String>(
        $LocalInventoryAdjustmentsTable.$converterquantityBefore.toSql(
          quantityBefore,
        ),
      );
    }
    {
      map['quantity_after'] = Variable<String>(
        $LocalInventoryAdjustmentsTable.$converterquantityAfter.toSql(
          quantityAfter,
        ),
      );
    }
    map['adjusted_by'] = Variable<String>(adjustedBy);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalInventoryAdjustmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryAdjustmentsCompanion(
      id: Value(id),
      branchId: Value(branchId),
      productId: Value(productId),
      type: Value(type),
      quantityBefore: Value(quantityBefore),
      quantityAfter: Value(quantityAfter),
      adjustedBy: Value(adjustedBy),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory InventoryAdjustmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryAdjustmentRow(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      productId: serializer.fromJson<String>(json['productId']),
      type: serializer.fromJson<String>(json['type']),
      quantityBefore: serializer.fromJson<Decimal>(json['quantityBefore']),
      quantityAfter: serializer.fromJson<Decimal>(json['quantityAfter']),
      adjustedBy: serializer.fromJson<String>(json['adjustedBy']),
      notes: serializer.fromJson<String?>(json['notes']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'productId': serializer.toJson<String>(productId),
      'type': serializer.toJson<String>(type),
      'quantityBefore': serializer.toJson<Decimal>(quantityBefore),
      'quantityAfter': serializer.toJson<Decimal>(quantityAfter),
      'adjustedBy': serializer.toJson<String>(adjustedBy),
      'notes': serializer.toJson<String?>(notes),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  InventoryAdjustmentRow copyWith({
    String? id,
    String? branchId,
    String? productId,
    String? type,
    Decimal? quantityBefore,
    Decimal? quantityAfter,
    String? adjustedBy,
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    DateTime? createdAt,
    bool? isSynced,
  }) => InventoryAdjustmentRow(
    id: id ?? this.id,
    branchId: branchId ?? this.branchId,
    productId: productId ?? this.productId,
    type: type ?? this.type,
    quantityBefore: quantityBefore ?? this.quantityBefore,
    quantityAfter: quantityAfter ?? this.quantityAfter,
    adjustedBy: adjustedBy ?? this.adjustedBy,
    notes: notes.present ? notes.value : this.notes,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
  );
  InventoryAdjustmentRow copyWithCompanion(
    LocalInventoryAdjustmentsCompanion data,
  ) {
    return InventoryAdjustmentRow(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      productId: data.productId.present ? data.productId.value : this.productId,
      type: data.type.present ? data.type.value : this.type,
      quantityBefore: data.quantityBefore.present
          ? data.quantityBefore.value
          : this.quantityBefore,
      quantityAfter: data.quantityAfter.present
          ? data.quantityAfter.value
          : this.quantityAfter,
      adjustedBy: data.adjustedBy.present
          ? data.adjustedBy.value
          : this.adjustedBy,
      notes: data.notes.present ? data.notes.value : this.notes,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryAdjustmentRow(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('productId: $productId, ')
          ..write('type: $type, ')
          ..write('quantityBefore: $quantityBefore, ')
          ..write('quantityAfter: $quantityAfter, ')
          ..write('adjustedBy: $adjustedBy, ')
          ..write('notes: $notes, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    branchId,
    productId,
    type,
    quantityBefore,
    quantityAfter,
    adjustedBy,
    notes,
    expiryDate,
    createdAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryAdjustmentRow &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.productId == this.productId &&
          other.type == this.type &&
          other.quantityBefore == this.quantityBefore &&
          other.quantityAfter == this.quantityAfter &&
          other.adjustedBy == this.adjustedBy &&
          other.notes == this.notes &&
          other.expiryDate == this.expiryDate &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalInventoryAdjustmentsCompanion
    extends UpdateCompanion<InventoryAdjustmentRow> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> productId;
  final Value<String> type;
  final Value<Decimal> quantityBefore;
  final Value<Decimal> quantityAfter;
  final Value<String> adjustedBy;
  final Value<String?> notes;
  final Value<DateTime?> expiryDate;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalInventoryAdjustmentsCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.productId = const Value.absent(),
    this.type = const Value.absent(),
    this.quantityBefore = const Value.absent(),
    this.quantityAfter = const Value.absent(),
    this.adjustedBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryAdjustmentsCompanion.insert({
    required String id,
    required String branchId,
    required String productId,
    required String type,
    required Decimal quantityBefore,
    required Decimal quantityAfter,
    required String adjustedBy,
    this.notes = const Value.absent(),
    this.expiryDate = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       branchId = Value(branchId),
       productId = Value(productId),
       type = Value(type),
       quantityBefore = Value(quantityBefore),
       quantityAfter = Value(quantityAfter),
       adjustedBy = Value(adjustedBy),
       createdAt = Value(createdAt);
  static Insertable<InventoryAdjustmentRow> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? productId,
    Expression<String>? type,
    Expression<String>? quantityBefore,
    Expression<String>? quantityAfter,
    Expression<String>? adjustedBy,
    Expression<String>? notes,
    Expression<DateTime>? expiryDate,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (productId != null) 'product_id': productId,
      if (type != null) 'type': type,
      if (quantityBefore != null) 'quantity_before': quantityBefore,
      if (quantityAfter != null) 'quantity_after': quantityAfter,
      if (adjustedBy != null) 'adjusted_by': adjustedBy,
      if (notes != null) 'notes': notes,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryAdjustmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? branchId,
    Value<String>? productId,
    Value<String>? type,
    Value<Decimal>? quantityBefore,
    Value<Decimal>? quantityAfter,
    Value<String>? adjustedBy,
    Value<String?>? notes,
    Value<DateTime?>? expiryDate,
    Value<DateTime>? createdAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return LocalInventoryAdjustmentsCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantityBefore: quantityBefore ?? this.quantityBefore,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      adjustedBy: adjustedBy ?? this.adjustedBy,
      notes: notes ?? this.notes,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (quantityBefore.present) {
      map['quantity_before'] = Variable<String>(
        $LocalInventoryAdjustmentsTable.$converterquantityBefore.toSql(
          quantityBefore.value,
        ),
      );
    }
    if (quantityAfter.present) {
      map['quantity_after'] = Variable<String>(
        $LocalInventoryAdjustmentsTable.$converterquantityAfter.toSql(
          quantityAfter.value,
        ),
      );
    }
    if (adjustedBy.present) {
      map['adjusted_by'] = Variable<String>(adjustedBy.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryAdjustmentsCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('productId: $productId, ')
          ..write('type: $type, ')
          ..write('quantityBefore: $quantityBefore, ')
          ..write('quantityAfter: $quantityAfter, ')
          ..write('adjustedBy: $adjustedBy, ')
          ..write('notes: $notes, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShopsTable extends LocalShops
    with TableInfo<$LocalShopsTable, ShopRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShopsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, config, createdAt, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shops';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShopRow> instance, {
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
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShopRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalShopsTable createAlias(String alias) {
    return $LocalShopsTable(attachedDatabase, alias);
  }
}

class ShopRow extends DataClass implements Insertable<ShopRow> {
  final String id;
  final String name;
  final String config;
  final DateTime createdAt;
  final DateTime syncedAt;
  const ShopRow({
    required this.id,
    required this.name,
    required this.config,
    required this.createdAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['config'] = Variable<String>(config);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalShopsCompanion toCompanion(bool nullToAbsent) {
    return LocalShopsCompanion(
      id: Value(id),
      name: Value(name),
      config: Value(config),
      createdAt: Value(createdAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory ShopRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      config: serializer.fromJson<String>(json['config']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'config': serializer.toJson<String>(config),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  ShopRow copyWith({
    String? id,
    String? name,
    String? config,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) => ShopRow(
    id: id ?? this.id,
    name: name ?? this.name,
    config: config ?? this.config,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  ShopRow copyWithCompanion(LocalShopsCompanion data) {
    return ShopRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      config: data.config.present ? data.config.value : this.config,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('config: $config, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, config, createdAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.config == this.config &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class LocalShopsCompanion extends UpdateCompanion<ShopRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> config;
  final Value<DateTime> createdAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalShopsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.config = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShopsCompanion.insert({
    required String id,
    required String name,
    this.config = const Value.absent(),
    required DateTime createdAt,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       syncedAt = Value(syncedAt);
  static Insertable<ShopRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? config,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (config != null) 'config': config,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShopsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? config,
    Value<DateTime>? createdAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalShopsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShopsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('config: $config, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalBranchesTable extends LocalBranches
    with TableInfo<$LocalBranchesTable, BranchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalBranchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    name,
    address,
    isActive,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BranchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BranchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BranchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalBranchesTable createAlias(String alias) {
    return $LocalBranchesTable(attachedDatabase, alias);
  }
}

class BranchRow extends DataClass implements Insertable<BranchRow> {
  final String id;
  final String shopId;
  final String name;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime syncedAt;
  const BranchRow({
    required this.id,
    required this.shopId,
    required this.name,
    this.address,
    required this.isActive,
    required this.createdAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalBranchesCompanion toCompanion(bool nullToAbsent) {
    return LocalBranchesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory BranchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchRow(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  BranchRow copyWith({
    String? id,
    String? shopId,
    String? name,
    Value<String?> address = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) => BranchRow(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  BranchRow copyWithCompanion(LocalBranchesCompanion data) {
    return BranchRow(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BranchRow(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shopId, name, address, isActive, createdAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BranchRow &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.address == this.address &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class LocalBranchesCompanion extends UpdateCompanion<BranchRow> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> name;
  final Value<String?> address;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalBranchesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalBranchesCompanion.insert({
    required String id,
    required String shopId,
    required String name,
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       name = Value(name),
       createdAt = Value(createdAt),
       syncedAt = Value(syncedAt);
  static Insertable<BranchRow> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalBranchesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? name,
    Value<String?>? address,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalBranchesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalBranchesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShopSettingsTable extends LocalShopSettings
    with TableInfo<$LocalShopSettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShopSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [shopId, key, value, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shop_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopId, key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalShopSettingsTable createAlias(String alias) {
    return $LocalShopSettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String shopId;
  final String key;
  final String value;
  final DateTime syncedAt;
  const SettingRow({
    required this.shopId,
    required this.key,
    required this.value,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_id'] = Variable<String>(shopId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalShopSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalShopSettingsCompanion(
      shopId: Value(shopId),
      key: Value(key),
      value: Value(value),
      syncedAt: Value(syncedAt),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      shopId: serializer.fromJson<String>(json['shopId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopId': serializer.toJson<String>(shopId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  SettingRow copyWith({
    String? shopId,
    String? key,
    String? value,
    DateTime? syncedAt,
  }) => SettingRow(
    shopId: shopId ?? this.shopId,
    key: key ?? this.key,
    value: value ?? this.value,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  SettingRow copyWithCompanion(LocalShopSettingsCompanion data) {
    return SettingRow(
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('shopId: $shopId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shopId, key, value, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.shopId == this.shopId &&
          other.key == this.key &&
          other.value == this.value &&
          other.syncedAt == this.syncedAt);
}

class LocalShopSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> shopId;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalShopSettingsCompanion({
    this.shopId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShopSettingsCompanion.insert({
    required String shopId,
    required String key,
    required String value,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : shopId = Value(shopId),
       key = Value(key),
       value = Value(value),
       syncedAt = Value(syncedAt);
  static Insertable<SettingRow> custom({
    Expression<String>? shopId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopId != null) 'shop_id': shopId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShopSettingsCompanion copyWith({
    Value<String>? shopId,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalShopSettingsCompanion(
      shopId: shopId ?? this.shopId,
      key: key ?? this.key,
      value: value ?? this.value,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShopSettingsCompanion(')
          ..write('shopId: $shopId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPaymentMethodsTable extends LocalPaymentMethods
    with TableInfo<$LocalPaymentMethodsTable, PaymentMethodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPaymentMethodsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, code, isActive, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethodRow> instance, {
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
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalPaymentMethodsTable createAlias(String alias) {
    return $LocalPaymentMethodsTable(attachedDatabase, alias);
  }
}

class PaymentMethodRow extends DataClass
    implements Insertable<PaymentMethodRow> {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final DateTime syncedAt;
  const PaymentMethodRow({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['is_active'] = Variable<bool>(isActive);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalPaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return LocalPaymentMethodsCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      isActive: Value(isActive),
      syncedAt: Value(syncedAt),
    );
  }

  factory PaymentMethodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'isActive': serializer.toJson<bool>(isActive),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  PaymentMethodRow copyWith({
    String? id,
    String? name,
    String? code,
    bool? isActive,
    DateTime? syncedAt,
  }) => PaymentMethodRow(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    isActive: isActive ?? this.isActive,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  PaymentMethodRow copyWithCompanion(LocalPaymentMethodsCompanion data) {
    return PaymentMethodRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('isActive: $isActive, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, code, isActive, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.isActive == this.isActive &&
          other.syncedAt == this.syncedAt);
}

class LocalPaymentMethodsCompanion extends UpdateCompanion<PaymentMethodRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> code;
  final Value<bool> isActive;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalPaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPaymentMethodsCompanion.insert({
    required String id,
    required String name,
    required String code,
    this.isActive = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       code = Value(code),
       syncedAt = Value(syncedAt);
  static Insertable<PaymentMethodRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<bool>? isActive,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (isActive != null) 'is_active': isActive,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPaymentMethodsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? code,
    Value<bool>? isActive,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalPaymentMethodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('isActive: $isActive, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductCategoriesTable extends LocalProductCategories
    with TableInfo<$LocalProductCategoriesTable, ProductCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, shopId, name, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_product_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalProductCategoriesTable createAlias(String alias) {
    return $LocalProductCategoriesTable(attachedDatabase, alias);
  }
}

class ProductCategoryRow extends DataClass
    implements Insertable<ProductCategoryRow> {
  final String id;
  final String shopId;
  final String name;
  final DateTime syncedAt;
  const ProductCategoryRow({
    required this.id,
    required this.shopId,
    required this.name,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shop_id'] = Variable<String>(shopId);
    map['name'] = Variable<String>(name);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalProductCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalProductCategoriesCompanion(
      id: Value(id),
      shopId: Value(shopId),
      name: Value(name),
      syncedAt: Value(syncedAt),
    );
  }

  factory ProductCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String>(shopId),
      'name': serializer.toJson<String>(name),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  ProductCategoryRow copyWith({
    String? id,
    String? shopId,
    String? name,
    DateTime? syncedAt,
  }) => ProductCategoryRow(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    name: name ?? this.name,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  ProductCategoryRow copyWithCompanion(LocalProductCategoriesCompanion data) {
    return ProductCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductCategoryRow(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shopId, name, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductCategoryRow &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.syncedAt == this.syncedAt);
}

class LocalProductCategoriesCompanion
    extends UpdateCompanion<ProductCategoryRow> {
  final Value<String> id;
  final Value<String> shopId;
  final Value<String> name;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalProductCategoriesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductCategoriesCompanion.insert({
    required String id,
    required String shopId,
    required String name,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shopId = Value(shopId),
       name = Value(name),
       syncedAt = Value(syncedAt);
  static Insertable<ProductCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? name,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? shopId,
    Value<String>? name,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalProductCategoriesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMeasurementUnitsTable extends LocalMeasurementUnits
    with TableInfo<$LocalMeasurementUnitsTable, MeasurementUnitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMeasurementUnitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _abbreviationMeta = const VerificationMeta(
    'abbreviation',
  );
  @override
  late final GeneratedColumn<String> abbreviation = GeneratedColumn<String>(
    'abbreviation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, abbreviation, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_measurement_units';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurementUnitRow> instance, {
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
    if (data.containsKey('abbreviation')) {
      context.handle(
        _abbreviationMeta,
        abbreviation.isAcceptableOrUnknown(
          data['abbreviation']!,
          _abbreviationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_abbreviationMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurementUnitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementUnitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      abbreviation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}abbreviation'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalMeasurementUnitsTable createAlias(String alias) {
    return $LocalMeasurementUnitsTable(attachedDatabase, alias);
  }
}

class MeasurementUnitRow extends DataClass
    implements Insertable<MeasurementUnitRow> {
  final String id;
  final String name;
  final String abbreviation;
  final DateTime syncedAt;
  const MeasurementUnitRow({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['abbreviation'] = Variable<String>(abbreviation);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalMeasurementUnitsCompanion toCompanion(bool nullToAbsent) {
    return LocalMeasurementUnitsCompanion(
      id: Value(id),
      name: Value(name),
      abbreviation: Value(abbreviation),
      syncedAt: Value(syncedAt),
    );
  }

  factory MeasurementUnitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementUnitRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      abbreviation: serializer.fromJson<String>(json['abbreviation']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'abbreviation': serializer.toJson<String>(abbreviation),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MeasurementUnitRow copyWith({
    String? id,
    String? name,
    String? abbreviation,
    DateTime? syncedAt,
  }) => MeasurementUnitRow(
    id: id ?? this.id,
    name: name ?? this.name,
    abbreviation: abbreviation ?? this.abbreviation,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MeasurementUnitRow copyWithCompanion(LocalMeasurementUnitsCompanion data) {
    return MeasurementUnitRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      abbreviation: data.abbreviation.present
          ? data.abbreviation.value
          : this.abbreviation,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementUnitRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbreviation: $abbreviation, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, abbreviation, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementUnitRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbreviation == this.abbreviation &&
          other.syncedAt == this.syncedAt);
}

class LocalMeasurementUnitsCompanion
    extends UpdateCompanion<MeasurementUnitRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> abbreviation;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalMeasurementUnitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.abbreviation = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMeasurementUnitsCompanion.insert({
    required String id,
    required String name,
    required String abbreviation,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       abbreviation = Value(abbreviation),
       syncedAt = Value(syncedAt);
  static Insertable<MeasurementUnitRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? abbreviation,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (abbreviation != null) 'abbreviation': abbreviation,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMeasurementUnitsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? abbreviation,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalMeasurementUnitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (abbreviation.present) {
      map['abbreviation'] = Variable<String>(abbreviation.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeasurementUnitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbreviation: $abbreviation, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fullName, phone, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final String id;
  final String? fullName;
  final String? phone;
  final DateTime syncedAt;
  const ProfileRow({
    required this.id,
    this.fullName,
    this.phone,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      id: Value(id),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      syncedAt: Value(syncedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      phone: serializer.fromJson<String?>(json['phone']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String?>(fullName),
      'phone': serializer.toJson<String?>(phone),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  ProfileRow copyWith({
    String? id,
    Value<String?> fullName = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    DateTime? syncedAt,
  }) => ProfileRow(
    id: id ?? this.id,
    fullName: fullName.present ? fullName.value : this.fullName,
    phone: phone.present ? phone.value : this.phone,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  ProfileRow copyWithCompanion(LocalProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phone: data.phone.present ? data.phone.value : this.phone,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fullName, phone, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.phone == this.phone &&
          other.syncedAt == this.syncedAt);
}

class LocalProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<String?> fullName;
  final Value<String?> phone;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalProfilesCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    required String id,
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       syncedAt = Value(syncedAt);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? phone,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? fullName,
    Value<String?>? phone,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalProfilesCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExpenseCategoriesTable extends LocalExpenseCategories
    with TableInfo<$LocalExpenseCategoriesTable, ExpenseCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExpenseCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<String> shopId = GeneratedColumn<String>(
    'shop_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, shopId, name, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_expense_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalExpenseCategoriesTable createAlias(String alias) {
    return $LocalExpenseCategoriesTable(attachedDatabase, alias);
  }
}

class ExpenseCategoryRow extends DataClass
    implements Insertable<ExpenseCategoryRow> {
  final String id;
  final String? shopId;
  final String name;
  final DateTime syncedAt;
  const ExpenseCategoryRow({
    required this.id,
    this.shopId,
    required this.name,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || shopId != null) {
      map['shop_id'] = Variable<String>(shopId);
    }
    map['name'] = Variable<String>(name);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalExpenseCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalExpenseCategoriesCompanion(
      id: Value(id),
      shopId: shopId == null && nullToAbsent
          ? const Value.absent()
          : Value(shopId),
      name: Value(name),
      syncedAt: Value(syncedAt),
    );
  }

  factory ExpenseCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      shopId: serializer.fromJson<String?>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shopId': serializer.toJson<String?>(shopId),
      'name': serializer.toJson<String>(name),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  ExpenseCategoryRow copyWith({
    String? id,
    Value<String?> shopId = const Value.absent(),
    String? name,
    DateTime? syncedAt,
  }) => ExpenseCategoryRow(
    id: id ?? this.id,
    shopId: shopId.present ? shopId.value : this.shopId,
    name: name ?? this.name,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  ExpenseCategoryRow copyWithCompanion(LocalExpenseCategoriesCompanion data) {
    return ExpenseCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseCategoryRow(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shopId, name, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseCategoryRow &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.syncedAt == this.syncedAt);
}

class LocalExpenseCategoriesCompanion
    extends UpdateCompanion<ExpenseCategoryRow> {
  final Value<String> id;
  final Value<String?> shopId;
  final Value<String> name;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalExpenseCategoriesCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExpenseCategoriesCompanion.insert({
    required String id,
    this.shopId = const Value.absent(),
    required String name,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       syncedAt = Value(syncedAt);
  static Insertable<ExpenseCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? shopId,
    Expression<String>? name,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExpenseCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? shopId,
    Value<String>? name,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalExpenseCategoriesCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<String>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpenseCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCreditPaymentsTable extends LocalCreditPayments
    with TableInfo<$LocalCreditPaymentsTable, CreditPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCreditPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> amount =
      GeneratedColumn<String>(
        'amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($LocalCreditPaymentsTable.$converteramount);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    customerId,
    amount,
    method,
    notes,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_credit_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      amount: $LocalCreditPaymentsTable.$converteramount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount'],
        )!,
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $LocalCreditPaymentsTable createAlias(String alias) {
    return $LocalCreditPaymentsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converteramount = const _Dec();
}

class CreditPaymentRow extends DataClass
    implements Insertable<CreditPaymentRow> {
  final String id;
  final String saleId;
  final String? customerId;
  final Decimal amount;
  final String method;
  final String? notes;
  final DateTime createdAt;
  final DateTime syncedAt;
  const CreditPaymentRow({
    required this.id,
    required this.saleId,
    this.customerId,
    required this.amount,
    required this.method,
    this.notes,
    required this.createdAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    {
      map['amount'] = Variable<String>(
        $LocalCreditPaymentsTable.$converteramount.toSql(amount),
      );
    }
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalCreditPaymentsCompanion toCompanion(bool nullToAbsent) {
    return LocalCreditPaymentsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      amount: Value(amount),
      method: Value(method),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory CreditPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      amount: serializer.fromJson<Decimal>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'customerId': serializer.toJson<String?>(customerId),
      'amount': serializer.toJson<Decimal>(amount),
      'method': serializer.toJson<String>(method),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CreditPaymentRow copyWith({
    String? id,
    String? saleId,
    Value<String?> customerId = const Value.absent(),
    Decimal? amount,
    String? method,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? syncedAt,
  }) => CreditPaymentRow(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    customerId: customerId.present ? customerId.value : this.customerId,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CreditPaymentRow copyWithCompanion(LocalCreditPaymentsCompanion data) {
    return CreditPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditPaymentRow(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    customerId,
    amount,
    method,
    notes,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditPaymentRow &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.customerId == this.customerId &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class LocalCreditPaymentsCompanion extends UpdateCompanion<CreditPaymentRow> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String?> customerId;
  final Value<Decimal> amount;
  final Value<String> method;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalCreditPaymentsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCreditPaymentsCompanion.insert({
    required String id,
    required String saleId,
    this.customerId = const Value.absent(),
    required Decimal amount,
    required String method,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       amount = Value(amount),
       method = Value(method),
       createdAt = Value(createdAt),
       syncedAt = Value(syncedAt);
  static Insertable<CreditPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? customerId,
    Expression<String>? amount,
    Expression<String>? method,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (customerId != null) 'customer_id': customerId,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCreditPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String?>? customerId,
    Value<Decimal>? amount,
    Value<String>? method,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalCreditPaymentsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(
        $LocalCreditPaymentsTable.$converteramount.toSql(amount.value),
      );
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCreditPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalStockTable localStock = $LocalStockTable(this);
  late final $LocalSalesTable localSales = $LocalSalesTable(this);
  late final $LocalSaleItemsTable localSaleItems = $LocalSaleItemsTable(this);
  late final $LocalCustomersTable localCustomers = $LocalCustomersTable(this);
  late final $LocalExpensesTable localExpenses = $LocalExpensesTable(this);
  late final $LocalInventoryAdjustmentsTable localInventoryAdjustments =
      $LocalInventoryAdjustmentsTable(this);
  late final $LocalShopsTable localShops = $LocalShopsTable(this);
  late final $LocalBranchesTable localBranches = $LocalBranchesTable(this);
  late final $LocalShopSettingsTable localShopSettings =
      $LocalShopSettingsTable(this);
  late final $LocalPaymentMethodsTable localPaymentMethods =
      $LocalPaymentMethodsTable(this);
  late final $LocalProductCategoriesTable localProductCategories =
      $LocalProductCategoriesTable(this);
  late final $LocalMeasurementUnitsTable localMeasurementUnits =
      $LocalMeasurementUnitsTable(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $LocalExpenseCategoriesTable localExpenseCategories =
      $LocalExpenseCategoriesTable(this);
  late final $LocalCreditPaymentsTable localCreditPayments =
      $LocalCreditPaymentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProducts,
    localStock,
    localSales,
    localSaleItems,
    localCustomers,
    localExpenses,
    localInventoryAdjustments,
    localShops,
    localBranches,
    localShopSettings,
    localPaymentMethods,
    localProductCategories,
    localMeasurementUnits,
    localProfiles,
    localExpenseCategories,
    localCreditPayments,
  ];
}

typedef $$LocalProductsTableCreateCompanionBuilder =
    LocalProductsCompanion Function({
      required String id,
      required String shopId,
      required String name,
      Value<String?> categoryId,
      Value<String?> description,
      required String measurementUnitId,
      required String measurementUnitAbbr,
      required Decimal lowStockThreshold,
      Value<Decimal?> sellingPrice,
      Value<Decimal?> costPrice,
      required bool isActive,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalProductsTableUpdateCompanionBuilder =
    LocalProductsCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> name,
      Value<String?> categoryId,
      Value<String?> description,
      Value<String> measurementUnitId,
      Value<String> measurementUnitAbbr,
      Value<Decimal> lowStockThreshold,
      Value<Decimal?> sellingPrice,
      Value<Decimal?> costPrice,
      Value<bool> isActive,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
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

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementUnitId => $composableBuilder(
    column: $table.measurementUnitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementUnitAbbr => $composableBuilder(
    column: $table.measurementUnitAbbr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String>
  get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get sellingPrice =>
      $composableBuilder(
        column: $table.sellingPrice,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get costPrice =>
      $composableBuilder(
        column: $table.costPrice,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
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

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementUnitId => $composableBuilder(
    column: $table.measurementUnitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementUnitAbbr => $composableBuilder(
    column: $table.measurementUnitAbbr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementUnitId => $composableBuilder(
    column: $table.measurementUnitId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementUnitAbbr => $composableBuilder(
    column: $table.measurementUnitAbbr,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get lowStockThreshold =>
      $composableBuilder(
        column: $table.lowStockThreshold,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal?, String> get sellingPrice =>
      $composableBuilder(
        column: $table.sellingPrice,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal?, String> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductsTable,
          ProductRow,
          $$LocalProductsTableFilterComposer,
          $$LocalProductsTableOrderingComposer,
          $$LocalProductsTableAnnotationComposer,
          $$LocalProductsTableCreateCompanionBuilder,
          $$LocalProductsTableUpdateCompanionBuilder,
          (
            ProductRow,
            BaseReferences<_$AppDatabase, $LocalProductsTable, ProductRow>,
          ),
          ProductRow,
          PrefetchHooks Function()
        > {
  $$LocalProductsTableTableManager(_$AppDatabase db, $LocalProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> measurementUnitId = const Value.absent(),
                Value<String> measurementUnitAbbr = const Value.absent(),
                Value<Decimal> lowStockThreshold = const Value.absent(),
                Value<Decimal?> sellingPrice = const Value.absent(),
                Value<Decimal?> costPrice = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion(
                id: id,
                shopId: shopId,
                name: name,
                categoryId: categoryId,
                description: description,
                measurementUnitId: measurementUnitId,
                measurementUnitAbbr: measurementUnitAbbr,
                lowStockThreshold: lowStockThreshold,
                sellingPrice: sellingPrice,
                costPrice: costPrice,
                isActive: isActive,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String name,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required String measurementUnitId,
                required String measurementUnitAbbr,
                required Decimal lowStockThreshold,
                Value<Decimal?> sellingPrice = const Value.absent(),
                Value<Decimal?> costPrice = const Value.absent(),
                required bool isActive,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                categoryId: categoryId,
                description: description,
                measurementUnitId: measurementUnitId,
                measurementUnitAbbr: measurementUnitAbbr,
                lowStockThreshold: lowStockThreshold,
                sellingPrice: sellingPrice,
                costPrice: costPrice,
                isActive: isActive,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductsTable,
      ProductRow,
      $$LocalProductsTableFilterComposer,
      $$LocalProductsTableOrderingComposer,
      $$LocalProductsTableAnnotationComposer,
      $$LocalProductsTableCreateCompanionBuilder,
      $$LocalProductsTableUpdateCompanionBuilder,
      (
        ProductRow,
        BaseReferences<_$AppDatabase, $LocalProductsTable, ProductRow>,
      ),
      ProductRow,
      PrefetchHooks Function()
    >;
typedef $$LocalStockTableCreateCompanionBuilder =
    LocalStockCompanion Function({
      required String productId,
      required String branchId,
      required Decimal quantity,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalStockTableUpdateCompanionBuilder =
    LocalStockCompanion Function({
      Value<String> productId,
      Value<String> branchId,
      Value<Decimal> quantity,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalStockTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStockTable> {
  $$LocalStockTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get quantity =>
      $composableBuilder(
        column: $table.quantity,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStockTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStockTable> {
  $$LocalStockTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStockTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStockTable> {
  $$LocalStockTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalStockTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStockTable,
          StockRow,
          $$LocalStockTableFilterComposer,
          $$LocalStockTableOrderingComposer,
          $$LocalStockTableAnnotationComposer,
          $$LocalStockTableCreateCompanionBuilder,
          $$LocalStockTableUpdateCompanionBuilder,
          (StockRow, BaseReferences<_$AppDatabase, $LocalStockTable, StockRow>),
          StockRow,
          PrefetchHooks Function()
        > {
  $$LocalStockTableTableManager(_$AppDatabase db, $LocalStockTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStockTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStockTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStockTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<Decimal> quantity = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStockCompanion(
                productId: productId,
                branchId: branchId,
                quantity: quantity,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String branchId,
                required Decimal quantity,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalStockCompanion.insert(
                productId: productId,
                branchId: branchId,
                quantity: quantity,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStockTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStockTable,
      StockRow,
      $$LocalStockTableFilterComposer,
      $$LocalStockTableOrderingComposer,
      $$LocalStockTableAnnotationComposer,
      $$LocalStockTableCreateCompanionBuilder,
      $$LocalStockTableUpdateCompanionBuilder,
      (StockRow, BaseReferences<_$AppDatabase, $LocalStockTable, StockRow>),
      StockRow,
      PrefetchHooks Function()
    >;
typedef $$LocalSalesTableCreateCompanionBuilder =
    LocalSalesCompanion Function({
      required String id,
      required String branchId,
      Value<String?> customerId,
      required String cashierId,
      required String paymentMethodId,
      required Decimal subtotal,
      required Decimal discountAmount,
      required Decimal total,
      required String status,
      Value<String?> voidReason,
      Value<String?> voidedBy,
      Value<DateTime?> voidedAt,
      required bool isCredit,
      Value<String?> notes,
      required DateTime createdAt,
      Value<DateTime?> creditSettledAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$LocalSalesTableUpdateCompanionBuilder =
    LocalSalesCompanion Function({
      Value<String> id,
      Value<String> branchId,
      Value<String?> customerId,
      Value<String> cashierId,
      Value<String> paymentMethodId,
      Value<Decimal> subtotal,
      Value<Decimal> discountAmount,
      Value<Decimal> total,
      Value<String> status,
      Value<String?> voidReason,
      Value<String?> voidedBy,
      Value<DateTime?> voidedAt,
      Value<bool> isCredit,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> creditSettledAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$LocalSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableFilterComposer({
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

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethodId => $composableBuilder(
    column: $table.paymentMethodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get subtotal =>
      $composableBuilder(
        column: $table.subtotal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get total =>
      $composableBuilder(
        column: $table.total,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidedBy => $composableBuilder(
    column: $table.voidedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
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

  ColumnFilters<DateTime> get creditSettledAt => $composableBuilder(
    column: $table.creditSettledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableOrderingComposer({
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

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethodId => $composableBuilder(
    column: $table.paymentMethodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidedBy => $composableBuilder(
    column: $table.voidedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
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

  ColumnOrderings<DateTime> get creditSettledAt => $composableBuilder(
    column: $table.creditSettledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get paymentMethodId => $composableBuilder(
    column: $table.paymentMethodId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidedBy =>
      $composableBuilder(column: $table.voidedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCredit =>
      $composableBuilder(column: $table.isCredit, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get creditSettledAt => $composableBuilder(
    column: $table.creditSettledAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSalesTable,
          SaleRow,
          $$LocalSalesTableFilterComposer,
          $$LocalSalesTableOrderingComposer,
          $$LocalSalesTableAnnotationComposer,
          $$LocalSalesTableCreateCompanionBuilder,
          $$LocalSalesTableUpdateCompanionBuilder,
          (SaleRow, BaseReferences<_$AppDatabase, $LocalSalesTable, SaleRow>),
          SaleRow,
          PrefetchHooks Function()
        > {
  $$LocalSalesTableTableManager(_$AppDatabase db, $LocalSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String> paymentMethodId = const Value.absent(),
                Value<Decimal> subtotal = const Value.absent(),
                Value<Decimal> discountAmount = const Value.absent(),
                Value<Decimal> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidedBy = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<bool> isCredit = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> creditSettledAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion(
                id: id,
                branchId: branchId,
                customerId: customerId,
                cashierId: cashierId,
                paymentMethodId: paymentMethodId,
                subtotal: subtotal,
                discountAmount: discountAmount,
                total: total,
                status: status,
                voidReason: voidReason,
                voidedBy: voidedBy,
                voidedAt: voidedAt,
                isCredit: isCredit,
                notes: notes,
                createdAt: createdAt,
                creditSettledAt: creditSettledAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String branchId,
                Value<String?> customerId = const Value.absent(),
                required String cashierId,
                required String paymentMethodId,
                required Decimal subtotal,
                required Decimal discountAmount,
                required Decimal total,
                required String status,
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidedBy = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                required bool isCredit,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> creditSettledAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion.insert(
                id: id,
                branchId: branchId,
                customerId: customerId,
                cashierId: cashierId,
                paymentMethodId: paymentMethodId,
                subtotal: subtotal,
                discountAmount: discountAmount,
                total: total,
                status: status,
                voidReason: voidReason,
                voidedBy: voidedBy,
                voidedAt: voidedAt,
                isCredit: isCredit,
                notes: notes,
                createdAt: createdAt,
                creditSettledAt: creditSettledAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSalesTable,
      SaleRow,
      $$LocalSalesTableFilterComposer,
      $$LocalSalesTableOrderingComposer,
      $$LocalSalesTableAnnotationComposer,
      $$LocalSalesTableCreateCompanionBuilder,
      $$LocalSalesTableUpdateCompanionBuilder,
      (SaleRow, BaseReferences<_$AppDatabase, $LocalSalesTable, SaleRow>),
      SaleRow,
      PrefetchHooks Function()
    >;
typedef $$LocalSaleItemsTableCreateCompanionBuilder =
    LocalSaleItemsCompanion Function({
      required String id,
      required String saleId,
      Value<String?> productId,
      required String productNameSnapshot,
      Value<String?> measurementUnitId,
      required Decimal quantity,
      required Decimal unitPrice,
      required Decimal discountAmount,
      required Decimal total,
      required String inventoryStatus,
      Value<Decimal?> costPriceSnapshot,
      Value<int> rowid,
    });
typedef $$LocalSaleItemsTableUpdateCompanionBuilder =
    LocalSaleItemsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String?> productId,
      Value<String> productNameSnapshot,
      Value<String?> measurementUnitId,
      Value<Decimal> quantity,
      Value<Decimal> unitPrice,
      Value<Decimal> discountAmount,
      Value<Decimal> total,
      Value<String> inventoryStatus,
      Value<Decimal?> costPriceSnapshot,
      Value<int> rowid,
    });

class $$LocalSaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableFilterComposer({
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

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementUnitId => $composableBuilder(
    column: $table.measurementUnitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get quantity =>
      $composableBuilder(
        column: $table.quantity,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get unitPrice =>
      $composableBuilder(
        column: $table.unitPrice,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get total =>
      $composableBuilder(
        column: $table.total,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get inventoryStatus => $composableBuilder(
    column: $table.inventoryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String>
  get costPriceSnapshot => $composableBuilder(
    column: $table.costPriceSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$LocalSaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableOrderingComposer({
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

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementUnitId => $composableBuilder(
    column: $table.measurementUnitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryStatus => $composableBuilder(
    column: $table.inventoryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costPriceSnapshot => $composableBuilder(
    column: $table.costPriceSnapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementUnitId => $composableBuilder(
    column: $table.measurementUnitId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get inventoryStatus => $composableBuilder(
    column: $table.inventoryStatus,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal?, String> get costPriceSnapshot =>
      $composableBuilder(
        column: $table.costPriceSnapshot,
        builder: (column) => column,
      );
}

class $$LocalSaleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSaleItemsTable,
          SaleItemRow,
          $$LocalSaleItemsTableFilterComposer,
          $$LocalSaleItemsTableOrderingComposer,
          $$LocalSaleItemsTableAnnotationComposer,
          $$LocalSaleItemsTableCreateCompanionBuilder,
          $$LocalSaleItemsTableUpdateCompanionBuilder,
          (
            SaleItemRow,
            BaseReferences<_$AppDatabase, $LocalSaleItemsTable, SaleItemRow>,
          ),
          SaleItemRow,
          PrefetchHooks Function()
        > {
  $$LocalSaleItemsTableTableManager(
    _$AppDatabase db,
    $LocalSaleItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> productNameSnapshot = const Value.absent(),
                Value<String?> measurementUnitId = const Value.absent(),
                Value<Decimal> quantity = const Value.absent(),
                Value<Decimal> unitPrice = const Value.absent(),
                Value<Decimal> discountAmount = const Value.absent(),
                Value<Decimal> total = const Value.absent(),
                Value<String> inventoryStatus = const Value.absent(),
                Value<Decimal?> costPriceSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSaleItemsCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                measurementUnitId: measurementUnitId,
                quantity: quantity,
                unitPrice: unitPrice,
                discountAmount: discountAmount,
                total: total,
                inventoryStatus: inventoryStatus,
                costPriceSnapshot: costPriceSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                Value<String?> productId = const Value.absent(),
                required String productNameSnapshot,
                Value<String?> measurementUnitId = const Value.absent(),
                required Decimal quantity,
                required Decimal unitPrice,
                required Decimal discountAmount,
                required Decimal total,
                required String inventoryStatus,
                Value<Decimal?> costPriceSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSaleItemsCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                measurementUnitId: measurementUnitId,
                quantity: quantity,
                unitPrice: unitPrice,
                discountAmount: discountAmount,
                total: total,
                inventoryStatus: inventoryStatus,
                costPriceSnapshot: costPriceSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSaleItemsTable,
      SaleItemRow,
      $$LocalSaleItemsTableFilterComposer,
      $$LocalSaleItemsTableOrderingComposer,
      $$LocalSaleItemsTableAnnotationComposer,
      $$LocalSaleItemsTableCreateCompanionBuilder,
      $$LocalSaleItemsTableUpdateCompanionBuilder,
      (
        SaleItemRow,
        BaseReferences<_$AppDatabase, $LocalSaleItemsTable, SaleItemRow>,
      ),
      SaleItemRow,
      PrefetchHooks Function()
    >;
typedef $$LocalCustomersTableCreateCompanionBuilder =
    LocalCustomersCompanion Function({
      required String id,
      required String shopId,
      required String name,
      Value<String?> phone,
      required Decimal creditBalance,
      required DateTime updatedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$LocalCustomersTableUpdateCompanionBuilder =
    LocalCustomersCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> name,
      Value<String?> phone,
      Value<Decimal> creditBalance,
      Value<DateTime> updatedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$LocalCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableFilterComposer({
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

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get creditBalance =>
      $composableBuilder(
        column: $table.creditBalance,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableOrderingComposer({
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

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditBalance => $composableBuilder(
    column: $table.creditBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get creditBalance =>
      $composableBuilder(
        column: $table.creditBalance,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalCustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCustomersTable,
          CustomerRow,
          $$LocalCustomersTableFilterComposer,
          $$LocalCustomersTableOrderingComposer,
          $$LocalCustomersTableAnnotationComposer,
          $$LocalCustomersTableCreateCompanionBuilder,
          $$LocalCustomersTableUpdateCompanionBuilder,
          (
            CustomerRow,
            BaseReferences<_$AppDatabase, $LocalCustomersTable, CustomerRow>,
          ),
          CustomerRow,
          PrefetchHooks Function()
        > {
  $$LocalCustomersTableTableManager(
    _$AppDatabase db,
    $LocalCustomersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<Decimal> creditBalance = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion(
                id: id,
                shopId: shopId,
                name: name,
                phone: phone,
                creditBalance: creditBalance,
                updatedAt: updatedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String name,
                Value<String?> phone = const Value.absent(),
                required Decimal creditBalance,
                required DateTime updatedAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                phone: phone,
                creditBalance: creditBalance,
                updatedAt: updatedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCustomersTable,
      CustomerRow,
      $$LocalCustomersTableFilterComposer,
      $$LocalCustomersTableOrderingComposer,
      $$LocalCustomersTableAnnotationComposer,
      $$LocalCustomersTableCreateCompanionBuilder,
      $$LocalCustomersTableUpdateCompanionBuilder,
      (
        CustomerRow,
        BaseReferences<_$AppDatabase, $LocalCustomersTable, CustomerRow>,
      ),
      CustomerRow,
      PrefetchHooks Function()
    >;
typedef $$LocalExpensesTableCreateCompanionBuilder =
    LocalExpensesCompanion Function({
      required String id,
      required String branchId,
      required String categoryId,
      required String categoryName,
      required Decimal amount,
      Value<String?> description,
      required String recordedBy,
      required DateTime date,
      required DateTime createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$LocalExpensesTableUpdateCompanionBuilder =
    LocalExpensesCompanion Function({
      Value<String> id,
      Value<String> branchId,
      Value<String> categoryId,
      Value<String> categoryName,
      Value<Decimal> amount,
      Value<String?> description,
      Value<String> recordedBy,
      Value<DateTime> date,
      Value<DateTime> createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$LocalExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableFilterComposer({
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

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get amount =>
      $composableBuilder(
        column: $table.amount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExpensesTable,
          ExpenseRow,
          $$LocalExpensesTableFilterComposer,
          $$LocalExpensesTableOrderingComposer,
          $$LocalExpensesTableAnnotationComposer,
          $$LocalExpensesTableCreateCompanionBuilder,
          $$LocalExpensesTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $LocalExpensesTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$LocalExpensesTableTableManager(_$AppDatabase db, $LocalExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<Decimal> amount = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpensesCompanion(
                id: id,
                branchId: branchId,
                categoryId: categoryId,
                categoryName: categoryName,
                amount: amount,
                description: description,
                recordedBy: recordedBy,
                date: date,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String branchId,
                required String categoryId,
                required String categoryName,
                required Decimal amount,
                Value<String?> description = const Value.absent(),
                required String recordedBy,
                required DateTime date,
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpensesCompanion.insert(
                id: id,
                branchId: branchId,
                categoryId: categoryId,
                categoryName: categoryName,
                amount: amount,
                description: description,
                recordedBy: recordedBy,
                date: date,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExpensesTable,
      ExpenseRow,
      $$LocalExpensesTableFilterComposer,
      $$LocalExpensesTableOrderingComposer,
      $$LocalExpensesTableAnnotationComposer,
      $$LocalExpensesTableCreateCompanionBuilder,
      $$LocalExpensesTableUpdateCompanionBuilder,
      (
        ExpenseRow,
        BaseReferences<_$AppDatabase, $LocalExpensesTable, ExpenseRow>,
      ),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryAdjustmentsTableCreateCompanionBuilder =
    LocalInventoryAdjustmentsCompanion Function({
      required String id,
      required String branchId,
      required String productId,
      required String type,
      required Decimal quantityBefore,
      required Decimal quantityAfter,
      required String adjustedBy,
      Value<String?> notes,
      Value<DateTime?> expiryDate,
      required DateTime createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$LocalInventoryAdjustmentsTableUpdateCompanionBuilder =
    LocalInventoryAdjustmentsCompanion Function({
      Value<String> id,
      Value<String> branchId,
      Value<String> productId,
      Value<String> type,
      Value<Decimal> quantityBefore,
      Value<Decimal> quantityAfter,
      Value<String> adjustedBy,
      Value<String?> notes,
      Value<DateTime?> expiryDate,
      Value<DateTime> createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$LocalInventoryAdjustmentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalInventoryAdjustmentsTable> {
  $$LocalInventoryAdjustmentsTableFilterComposer({
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

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get quantityBefore =>
      $composableBuilder(
        column: $table.quantityBefore,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get quantityAfter =>
      $composableBuilder(
        column: $table.quantityAfter,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get adjustedBy => $composableBuilder(
    column: $table.adjustedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryAdjustmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalInventoryAdjustmentsTable> {
  $$LocalInventoryAdjustmentsTableOrderingComposer({
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

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityBefore => $composableBuilder(
    column: $table.quantityBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityAfter => $composableBuilder(
    column: $table.quantityAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adjustedBy => $composableBuilder(
    column: $table.adjustedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryAdjustmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalInventoryAdjustmentsTable> {
  $$LocalInventoryAdjustmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get quantityBefore =>
      $composableBuilder(
        column: $table.quantityBefore,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get quantityAfter =>
      $composableBuilder(
        column: $table.quantityAfter,
        builder: (column) => column,
      );

  GeneratedColumn<String> get adjustedBy => $composableBuilder(
    column: $table.adjustedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalInventoryAdjustmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalInventoryAdjustmentsTable,
          InventoryAdjustmentRow,
          $$LocalInventoryAdjustmentsTableFilterComposer,
          $$LocalInventoryAdjustmentsTableOrderingComposer,
          $$LocalInventoryAdjustmentsTableAnnotationComposer,
          $$LocalInventoryAdjustmentsTableCreateCompanionBuilder,
          $$LocalInventoryAdjustmentsTableUpdateCompanionBuilder,
          (
            InventoryAdjustmentRow,
            BaseReferences<
              _$AppDatabase,
              $LocalInventoryAdjustmentsTable,
              InventoryAdjustmentRow
            >,
          ),
          InventoryAdjustmentRow,
          PrefetchHooks Function()
        > {
  $$LocalInventoryAdjustmentsTableTableManager(
    _$AppDatabase db,
    $LocalInventoryAdjustmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryAdjustmentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalInventoryAdjustmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryAdjustmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<Decimal> quantityBefore = const Value.absent(),
                Value<Decimal> quantityAfter = const Value.absent(),
                Value<String> adjustedBy = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryAdjustmentsCompanion(
                id: id,
                branchId: branchId,
                productId: productId,
                type: type,
                quantityBefore: quantityBefore,
                quantityAfter: quantityAfter,
                adjustedBy: adjustedBy,
                notes: notes,
                expiryDate: expiryDate,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String branchId,
                required String productId,
                required String type,
                required Decimal quantityBefore,
                required Decimal quantityAfter,
                required String adjustedBy,
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryAdjustmentsCompanion.insert(
                id: id,
                branchId: branchId,
                productId: productId,
                type: type,
                quantityBefore: quantityBefore,
                quantityAfter: quantityAfter,
                adjustedBy: adjustedBy,
                notes: notes,
                expiryDate: expiryDate,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryAdjustmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalInventoryAdjustmentsTable,
      InventoryAdjustmentRow,
      $$LocalInventoryAdjustmentsTableFilterComposer,
      $$LocalInventoryAdjustmentsTableOrderingComposer,
      $$LocalInventoryAdjustmentsTableAnnotationComposer,
      $$LocalInventoryAdjustmentsTableCreateCompanionBuilder,
      $$LocalInventoryAdjustmentsTableUpdateCompanionBuilder,
      (
        InventoryAdjustmentRow,
        BaseReferences<
          _$AppDatabase,
          $LocalInventoryAdjustmentsTable,
          InventoryAdjustmentRow
        >,
      ),
      InventoryAdjustmentRow,
      PrefetchHooks Function()
    >;
typedef $$LocalShopsTableCreateCompanionBuilder =
    LocalShopsCompanion Function({
      required String id,
      required String name,
      Value<String> config,
      required DateTime createdAt,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalShopsTableUpdateCompanionBuilder =
    LocalShopsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> config,
      Value<DateTime> createdAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalShopsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShopsTable> {
  $$LocalShopsTableFilterComposer({
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

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShopsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShopsTable> {
  $$LocalShopsTableOrderingComposer({
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

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShopsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShopsTable> {
  $$LocalShopsTableAnnotationComposer({
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

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalShopsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShopsTable,
          ShopRow,
          $$LocalShopsTableFilterComposer,
          $$LocalShopsTableOrderingComposer,
          $$LocalShopsTableAnnotationComposer,
          $$LocalShopsTableCreateCompanionBuilder,
          $$LocalShopsTableUpdateCompanionBuilder,
          (ShopRow, BaseReferences<_$AppDatabase, $LocalShopsTable, ShopRow>),
          ShopRow,
          PrefetchHooks Function()
        > {
  $$LocalShopsTableTableManager(_$AppDatabase db, $LocalShopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> config = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShopsCompanion(
                id: id,
                name: name,
                config: config,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> config = const Value.absent(),
                required DateTime createdAt,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalShopsCompanion.insert(
                id: id,
                name: name,
                config: config,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShopsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShopsTable,
      ShopRow,
      $$LocalShopsTableFilterComposer,
      $$LocalShopsTableOrderingComposer,
      $$LocalShopsTableAnnotationComposer,
      $$LocalShopsTableCreateCompanionBuilder,
      $$LocalShopsTableUpdateCompanionBuilder,
      (ShopRow, BaseReferences<_$AppDatabase, $LocalShopsTable, ShopRow>),
      ShopRow,
      PrefetchHooks Function()
    >;
typedef $$LocalBranchesTableCreateCompanionBuilder =
    LocalBranchesCompanion Function({
      required String id,
      required String shopId,
      required String name,
      Value<String?> address,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalBranchesTableUpdateCompanionBuilder =
    LocalBranchesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> name,
      Value<String?> address,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalBranchesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalBranchesTable> {
  $$LocalBranchesTableFilterComposer({
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

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalBranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalBranchesTable> {
  $$LocalBranchesTableOrderingComposer({
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

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalBranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalBranchesTable> {
  $$LocalBranchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalBranchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalBranchesTable,
          BranchRow,
          $$LocalBranchesTableFilterComposer,
          $$LocalBranchesTableOrderingComposer,
          $$LocalBranchesTableAnnotationComposer,
          $$LocalBranchesTableCreateCompanionBuilder,
          $$LocalBranchesTableUpdateCompanionBuilder,
          (
            BranchRow,
            BaseReferences<_$AppDatabase, $LocalBranchesTable, BranchRow>,
          ),
          BranchRow,
          PrefetchHooks Function()
        > {
  $$LocalBranchesTableTableManager(_$AppDatabase db, $LocalBranchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalBranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalBranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalBranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalBranchesCompanion(
                id: id,
                shopId: shopId,
                name: name,
                address: address,
                isActive: isActive,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalBranchesCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                address: address,
                isActive: isActive,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalBranchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalBranchesTable,
      BranchRow,
      $$LocalBranchesTableFilterComposer,
      $$LocalBranchesTableOrderingComposer,
      $$LocalBranchesTableAnnotationComposer,
      $$LocalBranchesTableCreateCompanionBuilder,
      $$LocalBranchesTableUpdateCompanionBuilder,
      (
        BranchRow,
        BaseReferences<_$AppDatabase, $LocalBranchesTable, BranchRow>,
      ),
      BranchRow,
      PrefetchHooks Function()
    >;
typedef $$LocalShopSettingsTableCreateCompanionBuilder =
    LocalShopSettingsCompanion Function({
      required String shopId,
      required String key,
      required String value,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalShopSettingsTableUpdateCompanionBuilder =
    LocalShopSettingsCompanion Function({
      Value<String> shopId,
      Value<String> key,
      Value<String> value,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalShopSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShopSettingsTable> {
  $$LocalShopSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShopSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShopSettingsTable> {
  $$LocalShopSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShopSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShopSettingsTable> {
  $$LocalShopSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalShopSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShopSettingsTable,
          SettingRow,
          $$LocalShopSettingsTableFilterComposer,
          $$LocalShopSettingsTableOrderingComposer,
          $$LocalShopSettingsTableAnnotationComposer,
          $$LocalShopSettingsTableCreateCompanionBuilder,
          $$LocalShopSettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $LocalShopSettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$LocalShopSettingsTableTableManager(
    _$AppDatabase db,
    $LocalShopSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShopSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShopSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShopSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> shopId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShopSettingsCompanion(
                shopId: shopId,
                key: key,
                value: value,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String shopId,
                required String key,
                required String value,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalShopSettingsCompanion.insert(
                shopId: shopId,
                key: key,
                value: value,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShopSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShopSettingsTable,
      SettingRow,
      $$LocalShopSettingsTableFilterComposer,
      $$LocalShopSettingsTableOrderingComposer,
      $$LocalShopSettingsTableAnnotationComposer,
      $$LocalShopSettingsTableCreateCompanionBuilder,
      $$LocalShopSettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $LocalShopSettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$LocalPaymentMethodsTableCreateCompanionBuilder =
    LocalPaymentMethodsCompanion Function({
      required String id,
      required String name,
      required String code,
      Value<bool> isActive,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalPaymentMethodsTableUpdateCompanionBuilder =
    LocalPaymentMethodsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> code,
      Value<bool> isActive,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalPaymentMethodsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPaymentMethodsTable> {
  $$LocalPaymentMethodsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPaymentMethodsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPaymentMethodsTable> {
  $$LocalPaymentMethodsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPaymentMethodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPaymentMethodsTable> {
  $$LocalPaymentMethodsTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalPaymentMethodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPaymentMethodsTable,
          PaymentMethodRow,
          $$LocalPaymentMethodsTableFilterComposer,
          $$LocalPaymentMethodsTableOrderingComposer,
          $$LocalPaymentMethodsTableAnnotationComposer,
          $$LocalPaymentMethodsTableCreateCompanionBuilder,
          $$LocalPaymentMethodsTableUpdateCompanionBuilder,
          (
            PaymentMethodRow,
            BaseReferences<
              _$AppDatabase,
              $LocalPaymentMethodsTable,
              PaymentMethodRow
            >,
          ),
          PaymentMethodRow,
          PrefetchHooks Function()
        > {
  $$LocalPaymentMethodsTableTableManager(
    _$AppDatabase db,
    $LocalPaymentMethodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPaymentMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPaymentMethodsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPaymentMethodsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPaymentMethodsCompanion(
                id: id,
                name: name,
                code: code,
                isActive: isActive,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String code,
                Value<bool> isActive = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalPaymentMethodsCompanion.insert(
                id: id,
                name: name,
                code: code,
                isActive: isActive,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPaymentMethodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPaymentMethodsTable,
      PaymentMethodRow,
      $$LocalPaymentMethodsTableFilterComposer,
      $$LocalPaymentMethodsTableOrderingComposer,
      $$LocalPaymentMethodsTableAnnotationComposer,
      $$LocalPaymentMethodsTableCreateCompanionBuilder,
      $$LocalPaymentMethodsTableUpdateCompanionBuilder,
      (
        PaymentMethodRow,
        BaseReferences<
          _$AppDatabase,
          $LocalPaymentMethodsTable,
          PaymentMethodRow
        >,
      ),
      PaymentMethodRow,
      PrefetchHooks Function()
    >;
typedef $$LocalProductCategoriesTableCreateCompanionBuilder =
    LocalProductCategoriesCompanion Function({
      required String id,
      required String shopId,
      required String name,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalProductCategoriesTableUpdateCompanionBuilder =
    LocalProductCategoriesCompanion Function({
      Value<String> id,
      Value<String> shopId,
      Value<String> name,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalProductCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductCategoriesTable> {
  $$LocalProductCategoriesTableFilterComposer({
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

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductCategoriesTable> {
  $$LocalProductCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductCategoriesTable> {
  $$LocalProductCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalProductCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductCategoriesTable,
          ProductCategoryRow,
          $$LocalProductCategoriesTableFilterComposer,
          $$LocalProductCategoriesTableOrderingComposer,
          $$LocalProductCategoriesTableAnnotationComposer,
          $$LocalProductCategoriesTableCreateCompanionBuilder,
          $$LocalProductCategoriesTableUpdateCompanionBuilder,
          (
            ProductCategoryRow,
            BaseReferences<
              _$AppDatabase,
              $LocalProductCategoriesTable,
              ProductCategoryRow
            >,
          ),
          ProductCategoryRow,
          PrefetchHooks Function()
        > {
  $$LocalProductCategoriesTableTableManager(
    _$AppDatabase db,
    $LocalProductCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductCategoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalProductCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalProductCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductCategoriesCompanion(
                id: id,
                shopId: shopId,
                name: name,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shopId,
                required String name,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProductCategoriesCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductCategoriesTable,
      ProductCategoryRow,
      $$LocalProductCategoriesTableFilterComposer,
      $$LocalProductCategoriesTableOrderingComposer,
      $$LocalProductCategoriesTableAnnotationComposer,
      $$LocalProductCategoriesTableCreateCompanionBuilder,
      $$LocalProductCategoriesTableUpdateCompanionBuilder,
      (
        ProductCategoryRow,
        BaseReferences<
          _$AppDatabase,
          $LocalProductCategoriesTable,
          ProductCategoryRow
        >,
      ),
      ProductCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMeasurementUnitsTableCreateCompanionBuilder =
    LocalMeasurementUnitsCompanion Function({
      required String id,
      required String name,
      required String abbreviation,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalMeasurementUnitsTableUpdateCompanionBuilder =
    LocalMeasurementUnitsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> abbreviation,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalMeasurementUnitsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMeasurementUnitsTable> {
  $$LocalMeasurementUnitsTableFilterComposer({
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

  ColumnFilters<String> get abbreviation => $composableBuilder(
    column: $table.abbreviation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMeasurementUnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMeasurementUnitsTable> {
  $$LocalMeasurementUnitsTableOrderingComposer({
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

  ColumnOrderings<String> get abbreviation => $composableBuilder(
    column: $table.abbreviation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMeasurementUnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMeasurementUnitsTable> {
  $$LocalMeasurementUnitsTableAnnotationComposer({
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

  GeneratedColumn<String> get abbreviation => $composableBuilder(
    column: $table.abbreviation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalMeasurementUnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMeasurementUnitsTable,
          MeasurementUnitRow,
          $$LocalMeasurementUnitsTableFilterComposer,
          $$LocalMeasurementUnitsTableOrderingComposer,
          $$LocalMeasurementUnitsTableAnnotationComposer,
          $$LocalMeasurementUnitsTableCreateCompanionBuilder,
          $$LocalMeasurementUnitsTableUpdateCompanionBuilder,
          (
            MeasurementUnitRow,
            BaseReferences<
              _$AppDatabase,
              $LocalMeasurementUnitsTable,
              MeasurementUnitRow
            >,
          ),
          MeasurementUnitRow,
          PrefetchHooks Function()
        > {
  $$LocalMeasurementUnitsTableTableManager(
    _$AppDatabase db,
    $LocalMeasurementUnitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMeasurementUnitsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalMeasurementUnitsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalMeasurementUnitsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> abbreviation = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMeasurementUnitsCompanion(
                id: id,
                name: name,
                abbreviation: abbreviation,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String abbreviation,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalMeasurementUnitsCompanion.insert(
                id: id,
                name: name,
                abbreviation: abbreviation,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMeasurementUnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMeasurementUnitsTable,
      MeasurementUnitRow,
      $$LocalMeasurementUnitsTableFilterComposer,
      $$LocalMeasurementUnitsTableOrderingComposer,
      $$LocalMeasurementUnitsTableAnnotationComposer,
      $$LocalMeasurementUnitsTableCreateCompanionBuilder,
      $$LocalMeasurementUnitsTableUpdateCompanionBuilder,
      (
        MeasurementUnitRow,
        BaseReferences<
          _$AppDatabase,
          $LocalMeasurementUnitsTable,
          MeasurementUnitRow
        >,
      ),
      MeasurementUnitRow,
      PrefetchHooks Function()
    >;
typedef $$LocalProfilesTableCreateCompanionBuilder =
    LocalProfilesCompanion Function({
      required String id,
      Value<String?> fullName,
      Value<String?> phone,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalProfilesTableUpdateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<String> id,
      Value<String?> fullName,
      Value<String?> phone,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProfilesTable,
          ProfileRow,
          $$LocalProfilesTableFilterComposer,
          $$LocalProfilesTableOrderingComposer,
          $$LocalProfilesTableAnnotationComposer,
          $$LocalProfilesTableCreateCompanionBuilder,
          $$LocalProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $LocalProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$LocalProfilesTableTableManager(_$AppDatabase db, $LocalProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion(
                id: id,
                fullName: fullName,
                phone: phone,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> fullName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion.insert(
                id: id,
                fullName: fullName,
                phone: phone,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProfilesTable,
      ProfileRow,
      $$LocalProfilesTableFilterComposer,
      $$LocalProfilesTableOrderingComposer,
      $$LocalProfilesTableAnnotationComposer,
      $$LocalProfilesTableCreateCompanionBuilder,
      $$LocalProfilesTableUpdateCompanionBuilder,
      (
        ProfileRow,
        BaseReferences<_$AppDatabase, $LocalProfilesTable, ProfileRow>,
      ),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$LocalExpenseCategoriesTableCreateCompanionBuilder =
    LocalExpenseCategoriesCompanion Function({
      required String id,
      Value<String?> shopId,
      required String name,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalExpenseCategoriesTableUpdateCompanionBuilder =
    LocalExpenseCategoriesCompanion Function({
      Value<String> id,
      Value<String?> shopId,
      Value<String> name,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalExpenseCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExpenseCategoriesTable> {
  $$LocalExpenseCategoriesTableFilterComposer({
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

  ColumnFilters<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalExpenseCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExpenseCategoriesTable> {
  $$LocalExpenseCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalExpenseCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExpenseCategoriesTable> {
  $$LocalExpenseCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalExpenseCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExpenseCategoriesTable,
          ExpenseCategoryRow,
          $$LocalExpenseCategoriesTableFilterComposer,
          $$LocalExpenseCategoriesTableOrderingComposer,
          $$LocalExpenseCategoriesTableAnnotationComposer,
          $$LocalExpenseCategoriesTableCreateCompanionBuilder,
          $$LocalExpenseCategoriesTableUpdateCompanionBuilder,
          (
            ExpenseCategoryRow,
            BaseReferences<
              _$AppDatabase,
              $LocalExpenseCategoriesTable,
              ExpenseCategoryRow
            >,
          ),
          ExpenseCategoryRow,
          PrefetchHooks Function()
        > {
  $$LocalExpenseCategoriesTableTableManager(
    _$AppDatabase db,
    $LocalExpenseCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExpenseCategoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalExpenseCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalExpenseCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpenseCategoriesCompanion(
                id: id,
                shopId: shopId,
                name: name,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> shopId = const Value.absent(),
                required String name,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalExpenseCategoriesCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalExpenseCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExpenseCategoriesTable,
      ExpenseCategoryRow,
      $$LocalExpenseCategoriesTableFilterComposer,
      $$LocalExpenseCategoriesTableOrderingComposer,
      $$LocalExpenseCategoriesTableAnnotationComposer,
      $$LocalExpenseCategoriesTableCreateCompanionBuilder,
      $$LocalExpenseCategoriesTableUpdateCompanionBuilder,
      (
        ExpenseCategoryRow,
        BaseReferences<
          _$AppDatabase,
          $LocalExpenseCategoriesTable,
          ExpenseCategoryRow
        >,
      ),
      ExpenseCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$LocalCreditPaymentsTableCreateCompanionBuilder =
    LocalCreditPaymentsCompanion Function({
      required String id,
      required String saleId,
      Value<String?> customerId,
      required Decimal amount,
      required String method,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalCreditPaymentsTableUpdateCompanionBuilder =
    LocalCreditPaymentsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String?> customerId,
      Value<Decimal> amount,
      Value<String> method,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalCreditPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCreditPaymentsTable> {
  $$LocalCreditPaymentsTableFilterComposer({
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

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get amount =>
      $composableBuilder(
        column: $table.amount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCreditPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCreditPaymentsTable> {
  $$LocalCreditPaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCreditPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCreditPaymentsTable> {
  $$LocalCreditPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalCreditPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCreditPaymentsTable,
          CreditPaymentRow,
          $$LocalCreditPaymentsTableFilterComposer,
          $$LocalCreditPaymentsTableOrderingComposer,
          $$LocalCreditPaymentsTableAnnotationComposer,
          $$LocalCreditPaymentsTableCreateCompanionBuilder,
          $$LocalCreditPaymentsTableUpdateCompanionBuilder,
          (
            CreditPaymentRow,
            BaseReferences<
              _$AppDatabase,
              $LocalCreditPaymentsTable,
              CreditPaymentRow
            >,
          ),
          CreditPaymentRow,
          PrefetchHooks Function()
        > {
  $$LocalCreditPaymentsTableTableManager(
    _$AppDatabase db,
    $LocalCreditPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCreditPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCreditPaymentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCreditPaymentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<Decimal> amount = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCreditPaymentsCompanion(
                id: id,
                saleId: saleId,
                customerId: customerId,
                amount: amount,
                method: method,
                notes: notes,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                Value<String?> customerId = const Value.absent(),
                required Decimal amount,
                required String method,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCreditPaymentsCompanion.insert(
                id: id,
                saleId: saleId,
                customerId: customerId,
                amount: amount,
                method: method,
                notes: notes,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCreditPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCreditPaymentsTable,
      CreditPaymentRow,
      $$LocalCreditPaymentsTableFilterComposer,
      $$LocalCreditPaymentsTableOrderingComposer,
      $$LocalCreditPaymentsTableAnnotationComposer,
      $$LocalCreditPaymentsTableCreateCompanionBuilder,
      $$LocalCreditPaymentsTableUpdateCompanionBuilder,
      (
        CreditPaymentRow,
        BaseReferences<
          _$AppDatabase,
          $LocalCreditPaymentsTable,
          CreditPaymentRow
        >,
      ),
      CreditPaymentRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalStockTableTableManager get localStock =>
      $$LocalStockTableTableManager(_db, _db.localStock);
  $$LocalSalesTableTableManager get localSales =>
      $$LocalSalesTableTableManager(_db, _db.localSales);
  $$LocalSaleItemsTableTableManager get localSaleItems =>
      $$LocalSaleItemsTableTableManager(_db, _db.localSaleItems);
  $$LocalCustomersTableTableManager get localCustomers =>
      $$LocalCustomersTableTableManager(_db, _db.localCustomers);
  $$LocalExpensesTableTableManager get localExpenses =>
      $$LocalExpensesTableTableManager(_db, _db.localExpenses);
  $$LocalInventoryAdjustmentsTableTableManager get localInventoryAdjustments =>
      $$LocalInventoryAdjustmentsTableTableManager(
        _db,
        _db.localInventoryAdjustments,
      );
  $$LocalShopsTableTableManager get localShops =>
      $$LocalShopsTableTableManager(_db, _db.localShops);
  $$LocalBranchesTableTableManager get localBranches =>
      $$LocalBranchesTableTableManager(_db, _db.localBranches);
  $$LocalShopSettingsTableTableManager get localShopSettings =>
      $$LocalShopSettingsTableTableManager(_db, _db.localShopSettings);
  $$LocalPaymentMethodsTableTableManager get localPaymentMethods =>
      $$LocalPaymentMethodsTableTableManager(_db, _db.localPaymentMethods);
  $$LocalProductCategoriesTableTableManager get localProductCategories =>
      $$LocalProductCategoriesTableTableManager(
        _db,
        _db.localProductCategories,
      );
  $$LocalMeasurementUnitsTableTableManager get localMeasurementUnits =>
      $$LocalMeasurementUnitsTableTableManager(_db, _db.localMeasurementUnits);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$LocalExpenseCategoriesTableTableManager get localExpenseCategories =>
      $$LocalExpenseCategoriesTableTableManager(
        _db,
        _db.localExpenseCategories,
      );
  $$LocalCreditPaymentsTableTableManager get localCreditPayments =>
      $$LocalCreditPaymentsTableTableManager(_db, _db.localCreditPayments);
}
