// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductsTable get products => attachedDatabase.products;
  $CapitalBatchesTable get capitalBatches => attachedDatabase.capitalBatches;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$CapitalBatchesTableTableManager get capitalBatches =>
      $$CapitalBatchesTableTableManager(
        _db.attachedDatabase,
        _db.capitalBatches,
      );
}

mixin _$SalesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductsTable get products => attachedDatabase.products;
  $SalesTable get sales => attachedDatabase.sales;
  $CapitalBatchesTable get capitalBatches => attachedDatabase.capitalBatches;
  $SaleAllocationsTable get saleAllocations => attachedDatabase.saleAllocations;
  SalesDaoManager get managers => SalesDaoManager(this);
}

class SalesDaoManager {
  final _$SalesDaoMixin _db;
  SalesDaoManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$CapitalBatchesTableTableManager get capitalBatches =>
      $$CapitalBatchesTableTableManager(
        _db.attachedDatabase,
        _db.capitalBatches,
      );
  $$SaleAllocationsTableTableManager get saleAllocations =>
      $$SaleAllocationsTableTableManager(
        _db.attachedDatabase,
        _db.saleAllocations,
      );
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
    'selling_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
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
  List<GeneratedColumn> get $columns => [id, name, sellingPrice, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
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
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}selling_price'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final double? sellingPrice;
  final DateTime createdAt;
  const Product({
    required this.id,
    required this.name,
    this.sellingPrice,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sellingPrice != null) {
      map['selling_price'] = Variable<double>(sellingPrice);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      sellingPrice: sellingPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(sellingPrice),
      createdAt: Value(createdAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sellingPrice: serializer.fromJson<double?>(json['sellingPrice']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sellingPrice': serializer.toJson<double?>(sellingPrice),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    Value<double?> sellingPrice = const Value.absent(),
    DateTime? createdAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    sellingPrice: sellingPrice.present ? sellingPrice.value : this.sellingPrice,
    createdAt: createdAt ?? this.createdAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sellingPrice, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.sellingPrice == this.sellingPrice &&
          other.createdAt == this.createdAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> sellingPrice;
  final Value<DateTime> createdAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sellingPrice = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? sellingPrice,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double?>? sellingPrice,
    Value<DateTime>? createdAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CapitalBatchesTable extends CapitalBatches
    with TableInfo<$CapitalBatchesTable, CapitalBatch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapitalBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _quantityAddedMeta = const VerificationMeta(
    'quantityAdded',
  );
  @override
  late final GeneratedColumn<double> quantityAdded = GeneratedColumn<double>(
    'quantity_added',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remainingQuantityMeta = const VerificationMeta(
    'remainingQuantity',
  );
  @override
  late final GeneratedColumn<double> remainingQuantity =
      GeneratedColumn<double>(
        'remaining_quantity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BatchSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BatchSource>($CapitalBatchesTable.$convertersource);
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    quantityAdded,
    remainingQuantity,
    costPrice,
    source,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'capital_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CapitalBatch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_added')) {
      context.handle(
        _quantityAddedMeta,
        quantityAdded.isAcceptableOrUnknown(
          data['quantity_added']!,
          _quantityAddedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityAddedMeta);
    }
    if (data.containsKey('remaining_quantity')) {
      context.handle(
        _remainingQuantityMeta,
        remainingQuantity.isAcceptableOrUnknown(
          data['remaining_quantity']!,
          _remainingQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remainingQuantityMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_costPriceMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CapitalBatch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CapitalBatch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      quantityAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_added'],
      )!,
      remainingQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_quantity'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price'],
      )!,
      source: $CapitalBatchesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $CapitalBatchesTable createAlias(String alias) {
    return $CapitalBatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BatchSource, String, String> $convertersource =
      const EnumNameConverter<BatchSource>(BatchSource.values);
}

class CapitalBatch extends DataClass implements Insertable<CapitalBatch> {
  final int id;
  final int productId;
  final double quantityAdded;
  final double remainingQuantity;
  final double costPrice;
  final BatchSource source;
  final DateTime timestamp;
  const CapitalBatch({
    required this.id,
    required this.productId,
    required this.quantityAdded,
    required this.remainingQuantity,
    required this.costPrice,
    required this.source,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['quantity_added'] = Variable<double>(quantityAdded);
    map['remaining_quantity'] = Variable<double>(remainingQuantity);
    map['cost_price'] = Variable<double>(costPrice);
    {
      map['source'] = Variable<String>(
        $CapitalBatchesTable.$convertersource.toSql(source),
      );
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  CapitalBatchesCompanion toCompanion(bool nullToAbsent) {
    return CapitalBatchesCompanion(
      id: Value(id),
      productId: Value(productId),
      quantityAdded: Value(quantityAdded),
      remainingQuantity: Value(remainingQuantity),
      costPrice: Value(costPrice),
      source: Value(source),
      timestamp: Value(timestamp),
    );
  }

  factory CapitalBatch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CapitalBatch(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      quantityAdded: serializer.fromJson<double>(json['quantityAdded']),
      remainingQuantity: serializer.fromJson<double>(json['remainingQuantity']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      source: $CapitalBatchesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'quantityAdded': serializer.toJson<double>(quantityAdded),
      'remainingQuantity': serializer.toJson<double>(remainingQuantity),
      'costPrice': serializer.toJson<double>(costPrice),
      'source': serializer.toJson<String>(
        $CapitalBatchesTable.$convertersource.toJson(source),
      ),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  CapitalBatch copyWith({
    int? id,
    int? productId,
    double? quantityAdded,
    double? remainingQuantity,
    double? costPrice,
    BatchSource? source,
    DateTime? timestamp,
  }) => CapitalBatch(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    quantityAdded: quantityAdded ?? this.quantityAdded,
    remainingQuantity: remainingQuantity ?? this.remainingQuantity,
    costPrice: costPrice ?? this.costPrice,
    source: source ?? this.source,
    timestamp: timestamp ?? this.timestamp,
  );
  CapitalBatch copyWithCompanion(CapitalBatchesCompanion data) {
    return CapitalBatch(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityAdded: data.quantityAdded.present
          ? data.quantityAdded.value
          : this.quantityAdded,
      remainingQuantity: data.remainingQuantity.present
          ? data.remainingQuantity.value
          : this.remainingQuantity,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      source: data.source.present ? data.source.value : this.source,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CapitalBatch(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantityAdded: $quantityAdded, ')
          ..write('remainingQuantity: $remainingQuantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('source: $source, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    quantityAdded,
    remainingQuantity,
    costPrice,
    source,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CapitalBatch &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.quantityAdded == this.quantityAdded &&
          other.remainingQuantity == this.remainingQuantity &&
          other.costPrice == this.costPrice &&
          other.source == this.source &&
          other.timestamp == this.timestamp);
}

class CapitalBatchesCompanion extends UpdateCompanion<CapitalBatch> {
  final Value<int> id;
  final Value<int> productId;
  final Value<double> quantityAdded;
  final Value<double> remainingQuantity;
  final Value<double> costPrice;
  final Value<BatchSource> source;
  final Value<DateTime> timestamp;
  const CapitalBatchesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityAdded = const Value.absent(),
    this.remainingQuantity = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.source = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  CapitalBatchesCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required double quantityAdded,
    required double remainingQuantity,
    required double costPrice,
    required BatchSource source,
    this.timestamp = const Value.absent(),
  }) : productId = Value(productId),
       quantityAdded = Value(quantityAdded),
       remainingQuantity = Value(remainingQuantity),
       costPrice = Value(costPrice),
       source = Value(source);
  static Insertable<CapitalBatch> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<double>? quantityAdded,
    Expression<double>? remainingQuantity,
    Expression<double>? costPrice,
    Expression<String>? source,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (quantityAdded != null) 'quantity_added': quantityAdded,
      if (remainingQuantity != null) 'remaining_quantity': remainingQuantity,
      if (costPrice != null) 'cost_price': costPrice,
      if (source != null) 'source': source,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  CapitalBatchesCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<double>? quantityAdded,
    Value<double>? remainingQuantity,
    Value<double>? costPrice,
    Value<BatchSource>? source,
    Value<DateTime>? timestamp,
  }) {
    return CapitalBatchesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityAdded: quantityAdded ?? this.quantityAdded,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      costPrice: costPrice ?? this.costPrice,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (quantityAdded.present) {
      map['quantity_added'] = Variable<double>(quantityAdded.value);
    }
    if (remainingQuantity.present) {
      map['remaining_quantity'] = Variable<double>(remainingQuantity.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CapitalBatchesTable.$convertersource.toSql(source.value),
      );
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapitalBatchesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantityAdded: $quantityAdded, ')
          ..write('remainingQuantity: $remainingQuantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('source: $source, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _quantitySoldMeta = const VerificationMeta(
    'quantitySold',
  );
  @override
  late final GeneratedColumn<double> quantitySold = GeneratedColumn<double>(
    'quantity_sold',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<double> sellPrice = GeneratedColumn<double>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    quantitySold,
    sellPrice,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_sold')) {
      context.handle(
        _quantitySoldMeta,
        quantitySold.isAcceptableOrUnknown(
          data['quantity_sold']!,
          _quantitySoldMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantitySoldMeta);
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_sellPriceMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      quantitySold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_sold'],
      )!,
      sellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final int id;
  final int productId;
  final double quantitySold;
  final double sellPrice;
  final DateTime timestamp;
  const Sale({
    required this.id,
    required this.productId,
    required this.quantitySold,
    required this.sellPrice,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['quantity_sold'] = Variable<double>(quantitySold);
    map['sell_price'] = Variable<double>(sellPrice);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      productId: Value(productId),
      quantitySold: Value(quantitySold),
      sellPrice: Value(sellPrice),
      timestamp: Value(timestamp),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      quantitySold: serializer.fromJson<double>(json['quantitySold']),
      sellPrice: serializer.fromJson<double>(json['sellPrice']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'quantitySold': serializer.toJson<double>(quantitySold),
      'sellPrice': serializer.toJson<double>(sellPrice),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  Sale copyWith({
    int? id,
    int? productId,
    double? quantitySold,
    double? sellPrice,
    DateTime? timestamp,
  }) => Sale(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    quantitySold: quantitySold ?? this.quantitySold,
    sellPrice: sellPrice ?? this.sellPrice,
    timestamp: timestamp ?? this.timestamp,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantitySold: data.quantitySold.present
          ? data.quantitySold.value
          : this.quantitySold,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantitySold: $quantitySold, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, quantitySold, sellPrice, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.quantitySold == this.quantitySold &&
          other.sellPrice == this.sellPrice &&
          other.timestamp == this.timestamp);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<int> id;
  final Value<int> productId;
  final Value<double> quantitySold;
  final Value<double> sellPrice;
  final Value<DateTime> timestamp;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantitySold = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SalesCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required double quantitySold,
    required double sellPrice,
    this.timestamp = const Value.absent(),
  }) : productId = Value(productId),
       quantitySold = Value(quantitySold),
       sellPrice = Value(sellPrice);
  static Insertable<Sale> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<double>? quantitySold,
    Expression<double>? sellPrice,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (quantitySold != null) 'quantity_sold': quantitySold,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SalesCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<double>? quantitySold,
    Value<double>? sellPrice,
    Value<DateTime>? timestamp,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantitySold: quantitySold ?? this.quantitySold,
      sellPrice: sellPrice ?? this.sellPrice,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (quantitySold.present) {
      map['quantity_sold'] = Variable<double>(quantitySold.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<double>(sellPrice.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantitySold: $quantitySold, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $SaleAllocationsTable extends SaleAllocations
    with TableInfo<$SaleAllocationsTable, SaleAllocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<int> batchId = GeneratedColumn<int>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES capital_batches (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _quantityConsumedMeta = const VerificationMeta(
    'quantityConsumed',
  );
  @override
  late final GeneratedColumn<double> quantityConsumed = GeneratedColumn<double>(
    'quantity_consumed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceAtConsumptionMeta =
      const VerificationMeta('costPriceAtConsumption');
  @override
  late final GeneratedColumn<double> costPriceAtConsumption =
      GeneratedColumn<double>(
        'cost_price_at_consumption',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    batchId,
    quantityConsumed,
    costPriceAtConsumption,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_allocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleAllocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('quantity_consumed')) {
      context.handle(
        _quantityConsumedMeta,
        quantityConsumed.isAcceptableOrUnknown(
          data['quantity_consumed']!,
          _quantityConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityConsumedMeta);
    }
    if (data.containsKey('cost_price_at_consumption')) {
      context.handle(
        _costPriceAtConsumptionMeta,
        costPriceAtConsumption.isAcceptableOrUnknown(
          data['cost_price_at_consumption']!,
          _costPriceAtConsumptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costPriceAtConsumptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleAllocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleAllocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_id'],
      )!,
      quantityConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_consumed'],
      )!,
      costPriceAtConsumption: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price_at_consumption'],
      )!,
    );
  }

  @override
  $SaleAllocationsTable createAlias(String alias) {
    return $SaleAllocationsTable(attachedDatabase, alias);
  }
}

class SaleAllocation extends DataClass implements Insertable<SaleAllocation> {
  final int id;
  final int saleId;
  final int batchId;
  final double quantityConsumed;
  final double costPriceAtConsumption;
  const SaleAllocation({
    required this.id,
    required this.saleId,
    required this.batchId,
    required this.quantityConsumed,
    required this.costPriceAtConsumption,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['batch_id'] = Variable<int>(batchId);
    map['quantity_consumed'] = Variable<double>(quantityConsumed);
    map['cost_price_at_consumption'] = Variable<double>(costPriceAtConsumption);
    return map;
  }

  SaleAllocationsCompanion toCompanion(bool nullToAbsent) {
    return SaleAllocationsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      batchId: Value(batchId),
      quantityConsumed: Value(quantityConsumed),
      costPriceAtConsumption: Value(costPriceAtConsumption),
    );
  }

  factory SaleAllocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleAllocation(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      batchId: serializer.fromJson<int>(json['batchId']),
      quantityConsumed: serializer.fromJson<double>(json['quantityConsumed']),
      costPriceAtConsumption: serializer.fromJson<double>(
        json['costPriceAtConsumption'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'batchId': serializer.toJson<int>(batchId),
      'quantityConsumed': serializer.toJson<double>(quantityConsumed),
      'costPriceAtConsumption': serializer.toJson<double>(
        costPriceAtConsumption,
      ),
    };
  }

  SaleAllocation copyWith({
    int? id,
    int? saleId,
    int? batchId,
    double? quantityConsumed,
    double? costPriceAtConsumption,
  }) => SaleAllocation(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    batchId: batchId ?? this.batchId,
    quantityConsumed: quantityConsumed ?? this.quantityConsumed,
    costPriceAtConsumption:
        costPriceAtConsumption ?? this.costPriceAtConsumption,
  );
  SaleAllocation copyWithCompanion(SaleAllocationsCompanion data) {
    return SaleAllocation(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      quantityConsumed: data.quantityConsumed.present
          ? data.quantityConsumed.value
          : this.quantityConsumed,
      costPriceAtConsumption: data.costPriceAtConsumption.present
          ? data.costPriceAtConsumption.value
          : this.costPriceAtConsumption,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleAllocation(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('batchId: $batchId, ')
          ..write('quantityConsumed: $quantityConsumed, ')
          ..write('costPriceAtConsumption: $costPriceAtConsumption')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    batchId,
    quantityConsumed,
    costPriceAtConsumption,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleAllocation &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.batchId == this.batchId &&
          other.quantityConsumed == this.quantityConsumed &&
          other.costPriceAtConsumption == this.costPriceAtConsumption);
}

class SaleAllocationsCompanion extends UpdateCompanion<SaleAllocation> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<int> batchId;
  final Value<double> quantityConsumed;
  final Value<double> costPriceAtConsumption;
  const SaleAllocationsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.quantityConsumed = const Value.absent(),
    this.costPriceAtConsumption = const Value.absent(),
  });
  SaleAllocationsCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required int batchId,
    required double quantityConsumed,
    required double costPriceAtConsumption,
  }) : saleId = Value(saleId),
       batchId = Value(batchId),
       quantityConsumed = Value(quantityConsumed),
       costPriceAtConsumption = Value(costPriceAtConsumption);
  static Insertable<SaleAllocation> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<int>? batchId,
    Expression<double>? quantityConsumed,
    Expression<double>? costPriceAtConsumption,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (batchId != null) 'batch_id': batchId,
      if (quantityConsumed != null) 'quantity_consumed': quantityConsumed,
      if (costPriceAtConsumption != null)
        'cost_price_at_consumption': costPriceAtConsumption,
    });
  }

  SaleAllocationsCompanion copyWith({
    Value<int>? id,
    Value<int>? saleId,
    Value<int>? batchId,
    Value<double>? quantityConsumed,
    Value<double>? costPriceAtConsumption,
  }) {
    return SaleAllocationsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      batchId: batchId ?? this.batchId,
      quantityConsumed: quantityConsumed ?? this.quantityConsumed,
      costPriceAtConsumption:
          costPriceAtConsumption ?? this.costPriceAtConsumption,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<int>(batchId.value);
    }
    if (quantityConsumed.present) {
      map['quantity_consumed'] = Variable<double>(quantityConsumed.value);
    }
    if (costPriceAtConsumption.present) {
      map['cost_price_at_consumption'] = Variable<double>(
        costPriceAtConsumption.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleAllocationsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('batchId: $batchId, ')
          ..write('quantityConsumed: $quantityConsumed, ')
          ..write('costPriceAtConsumption: $costPriceAtConsumption')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $CapitalBatchesTable capitalBatches = $CapitalBatchesTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleAllocationsTable saleAllocations = $SaleAllocationsTable(
    this,
  );
  late final InventoryDao inventoryDao = InventoryDao(this as AppDatabase);
  late final SalesDao salesDao = SalesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    capitalBatches,
    sales,
    saleAllocations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('capital_batches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sale_allocations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String name,
  Value<double?> sellingPrice,
  Value<DateTime> createdAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double?> sellingPrice,
  Value<DateTime> createdAt,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CapitalBatchesTable, List<CapitalBatch>>
  _capitalBatchesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.capitalBatches,
    aliasName: 'products__id__capital_batches__product_id',
  );

  $$CapitalBatchesTableProcessedTableManager get capitalBatchesRefs {
    final manager = $$CapitalBatchesTableTableManager(
      $_db,
      $_db.capitalBatches,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_capitalBatchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sales,
    aliasName: 'products__id__sales__product_id',
  );

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> capitalBatchesRefs(
    Expression<bool> Function($$CapitalBatchesTableFilterComposer f) f,
  ) {
    final $$CapitalBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.capitalBatches,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapitalBatchesTableFilterComposer(
            $db: $db,
            $table: $db.capitalBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> salesRefs(
    Expression<bool> Function($$SalesTableFilterComposer f) f,
  ) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> capitalBatchesRefs<T extends Object>(
    Expression<T> Function($$CapitalBatchesTableAnnotationComposer a) f,
  ) {
    final $$CapitalBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.capitalBatches,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapitalBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.capitalBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
    Expression<T> Function($$SalesTableAnnotationComposer a) f,
  ) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool capitalBatchesRefs, bool salesRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> sellingPrice = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                sellingPrice: sellingPrice,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<double?> sellingPrice = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                sellingPrice: sellingPrice,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({capitalBatchesRefs = false, salesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (capitalBatchesRefs) db.capitalBatches,
                    if (salesRefs) db.sales,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (capitalBatchesRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          CapitalBatch
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._capitalBatchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).capitalBatchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (salesRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          Sale
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._salesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).salesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
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

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool capitalBatchesRefs, bool salesRefs})
    >;
typedef $$CapitalBatchesTableCreateCompanionBuilder =
    CapitalBatchesCompanion Function({
      Value<int> id,
      required int productId,
      required double quantityAdded,
      required double remainingQuantity,
      required double costPrice,
      required BatchSource source,
      Value<DateTime> timestamp,
    });
typedef $$CapitalBatchesTableUpdateCompanionBuilder =
    CapitalBatchesCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<double> quantityAdded,
      Value<double> remainingQuantity,
      Value<double> costPrice,
      Value<BatchSource> source,
      Value<DateTime> timestamp,
    });

final class $$CapitalBatchesTableReferences
    extends BaseReferences<_$AppDatabase, $CapitalBatchesTable, CapitalBatch> {
  $$CapitalBatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('capital_batches__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SaleAllocationsTable, List<SaleAllocation>>
  _saleAllocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleAllocations,
    aliasName: 'capital_batches__id__sale_allocations__batch_id',
  );

  $$SaleAllocationsTableProcessedTableManager get saleAllocationsRefs {
    final manager = $$SaleAllocationsTableTableManager(
      $_db,
      $_db.saleAllocations,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _saleAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CapitalBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $CapitalBatchesTable> {
  $$CapitalBatchesTableFilterComposer({
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

  ColumnFilters<double> get quantityAdded => $composableBuilder(
    column: $table.quantityAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingQuantity => $composableBuilder(
    column: $table.remainingQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BatchSource, BatchSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> saleAllocationsRefs(
    Expression<bool> Function($$SaleAllocationsTableFilterComposer f) f,
  ) {
    final $$SaleAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleAllocations,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.saleAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CapitalBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $CapitalBatchesTable> {
  $$CapitalBatchesTableOrderingComposer({
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

  ColumnOrderings<double> get quantityAdded => $composableBuilder(
    column: $table.quantityAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingQuantity => $composableBuilder(
    column: $table.remainingQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CapitalBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapitalBatchesTable> {
  $$CapitalBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantityAdded => $composableBuilder(
    column: $table.quantityAdded,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingQuantity => $composableBuilder(
    column: $table.remainingQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BatchSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> saleAllocationsRefs<T extends Object>(
    Expression<T> Function($$SaleAllocationsTableAnnotationComposer a) f,
  ) {
    final $$SaleAllocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleAllocations,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleAllocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CapitalBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapitalBatchesTable,
          CapitalBatch,
          $$CapitalBatchesTableFilterComposer,
          $$CapitalBatchesTableOrderingComposer,
          $$CapitalBatchesTableAnnotationComposer,
          $$CapitalBatchesTableCreateCompanionBuilder,
          $$CapitalBatchesTableUpdateCompanionBuilder,
          (CapitalBatch, $$CapitalBatchesTableReferences),
          CapitalBatch,
          PrefetchHooks Function({bool productId, bool saleAllocationsRefs})
        > {
  $$CapitalBatchesTableTableManager(
    _$AppDatabase db,
    $CapitalBatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapitalBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapitalBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapitalBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<double> quantityAdded = const Value.absent(),
                Value<double> remainingQuantity = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<BatchSource> source = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => CapitalBatchesCompanion(
                id: id,
                productId: productId,
                quantityAdded: quantityAdded,
                remainingQuantity: remainingQuantity,
                costPrice: costPrice,
                source: source,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required double quantityAdded,
                required double remainingQuantity,
                required double costPrice,
                required BatchSource source,
                Value<DateTime> timestamp = const Value.absent(),
              }) => CapitalBatchesCompanion.insert(
                id: id,
                productId: productId,
                quantityAdded: quantityAdded,
                remainingQuantity: remainingQuantity,
                costPrice: costPrice,
                source: source,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CapitalBatchesTable, CapitalBatch>(table),
                  $$CapitalBatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({productId = false, saleAllocationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (saleAllocationsRefs) db.saleAllocations,
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
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$CapitalBatchesTableReferences
                                ._productIdTable(db),
                            referencedColumn: $$CapitalBatchesTableReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (saleAllocationsRefs)
                        await $_getPrefetchedData<
                          CapitalBatch,
                          $CapitalBatchesTable,
                          SaleAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$CapitalBatchesTableReferences
                              ._saleAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CapitalBatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).saleAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.id,
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

typedef $$CapitalBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapitalBatchesTable,
      CapitalBatch,
      $$CapitalBatchesTableFilterComposer,
      $$CapitalBatchesTableOrderingComposer,
      $$CapitalBatchesTableAnnotationComposer,
      $$CapitalBatchesTableCreateCompanionBuilder,
      $$CapitalBatchesTableUpdateCompanionBuilder,
      (CapitalBatch, $$CapitalBatchesTableReferences),
      CapitalBatch,
      PrefetchHooks Function({bool productId, bool saleAllocationsRefs})
    >;
typedef $$SalesTableCreateCompanionBuilder = SalesCompanion Function({
  Value<int> id,
  required int productId,
  required double quantitySold,
  required double sellPrice,
  Value<DateTime> timestamp,
});
typedef $$SalesTableUpdateCompanionBuilder = SalesCompanion Function({
  Value<int> id,
  Value<int> productId,
  Value<double> quantitySold,
  Value<double> sellPrice,
  Value<DateTime> timestamp,
});

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('sales__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SaleAllocationsTable, List<SaleAllocation>>
  _saleAllocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleAllocations,
    aliasName: 'sales__id__sale_allocations__sale_id',
  );

  $$SaleAllocationsTableProcessedTableManager get saleAllocationsRefs {
    final manager = $$SaleAllocationsTableTableManager(
      $_db,
      $_db.saleAllocations,
    ).filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _saleAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
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

  ColumnFilters<double> get quantitySold => $composableBuilder(
    column: $table.quantitySold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> saleAllocationsRefs(
    Expression<bool> Function($$SaleAllocationsTableFilterComposer f) f,
  ) {
    final $$SaleAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleAllocations,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.saleAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
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

  ColumnOrderings<double> get quantitySold => $composableBuilder(
    column: $table.quantitySold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantitySold => $composableBuilder(
    column: $table.quantitySold,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> saleAllocationsRefs<T extends Object>(
    Expression<T> Function($$SaleAllocationsTableAnnotationComposer a) f,
  ) {
    final $$SaleAllocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.saleAllocations,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleAllocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, $$SalesTableReferences),
          Sale,
          PrefetchHooks Function({bool productId, bool saleAllocationsRefs})
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<double> quantitySold = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                productId: productId,
                quantitySold: quantitySold,
                sellPrice: sellPrice,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required double quantitySold,
                required double sellPrice,
                Value<DateTime> timestamp = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                productId: productId,
                quantitySold: quantitySold,
                sellPrice: sellPrice,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SalesTable, Sale>(table),
                  $$SalesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({productId = false, saleAllocationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (saleAllocationsRefs) db.saleAllocations,
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
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$SalesTableReferences
                                ._productIdTable(db),
                            referencedColumn: $$SalesTableReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (saleAllocationsRefs)
                        await $_getPrefetchedData<
                          Sale,
                          $SalesTable,
                          SaleAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$SalesTableReferences
                              ._saleAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SalesTableReferences(
                                db,
                                table,
                                p0,
                              ).saleAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.id,
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

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, $$SalesTableReferences),
      Sale,
      PrefetchHooks Function({bool productId, bool saleAllocationsRefs})
    >;
typedef $$SaleAllocationsTableCreateCompanionBuilder =
    SaleAllocationsCompanion Function({
      Value<int> id,
      required int saleId,
      required int batchId,
      required double quantityConsumed,
      required double costPriceAtConsumption,
    });
typedef $$SaleAllocationsTableUpdateCompanionBuilder =
    SaleAllocationsCompanion Function({
      Value<int> id,
      Value<int> saleId,
      Value<int> batchId,
      Value<double> quantityConsumed,
      Value<double> costPriceAtConsumption,
    });

final class $$SaleAllocationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SaleAllocationsTable, SaleAllocation> {
  $$SaleAllocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SalesTable _saleIdTable(_$AppDatabase db) =>
      db.sales.createAlias('sale_allocations__sale_id__sales__id');

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableManager(
      $_db,
      $_db.sales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CapitalBatchesTable _batchIdTable(_$AppDatabase db) => db
      .capitalBatches
      .createAlias('sale_allocations__batch_id__capital_batches__id');

  $$CapitalBatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<int>('batch_id')!;

    final manager = $$CapitalBatchesTableTableManager(
      $_db,
      $_db.capitalBatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleAllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleAllocationsTable> {
  $$SaleAllocationsTableFilterComposer({
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

  ColumnFilters<double> get quantityConsumed => $composableBuilder(
    column: $table.quantityConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPriceAtConsumption => $composableBuilder(
    column: $table.costPriceAtConsumption,
    builder: (column) => ColumnFilters(column),
  );

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CapitalBatchesTableFilterComposer get batchId {
    final $$CapitalBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.capitalBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapitalBatchesTableFilterComposer(
            $db: $db,
            $table: $db.capitalBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleAllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleAllocationsTable> {
  $$SaleAllocationsTableOrderingComposer({
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

  ColumnOrderings<double> get quantityConsumed => $composableBuilder(
    column: $table.quantityConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPriceAtConsumption => $composableBuilder(
    column: $table.costPriceAtConsumption,
    builder: (column) => ColumnOrderings(column),
  );

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableOrderingComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CapitalBatchesTableOrderingComposer get batchId {
    final $$CapitalBatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.capitalBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapitalBatchesTableOrderingComposer(
            $db: $db,
            $table: $db.capitalBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleAllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleAllocationsTable> {
  $$SaleAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantityConsumed => $composableBuilder(
    column: $table.quantityConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costPriceAtConsumption => $composableBuilder(
    column: $table.costPriceAtConsumption,
    builder: (column) => column,
  );

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CapitalBatchesTableAnnotationComposer get batchId {
    final $$CapitalBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.capitalBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapitalBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.capitalBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleAllocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleAllocationsTable,
          SaleAllocation,
          $$SaleAllocationsTableFilterComposer,
          $$SaleAllocationsTableOrderingComposer,
          $$SaleAllocationsTableAnnotationComposer,
          $$SaleAllocationsTableCreateCompanionBuilder,
          $$SaleAllocationsTableUpdateCompanionBuilder,
          (SaleAllocation, $$SaleAllocationsTableReferences),
          SaleAllocation,
          PrefetchHooks Function({bool saleId, bool batchId})
        > {
  $$SaleAllocationsTableTableManager(
    _$AppDatabase db,
    $SaleAllocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleAllocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleAllocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleAllocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> saleId = const Value.absent(),
                Value<int> batchId = const Value.absent(),
                Value<double> quantityConsumed = const Value.absent(),
                Value<double> costPriceAtConsumption = const Value.absent(),
              }) => SaleAllocationsCompanion(
                id: id,
                saleId: saleId,
                batchId: batchId,
                quantityConsumed: quantityConsumed,
                costPriceAtConsumption: costPriceAtConsumption,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int saleId,
                required int batchId,
                required double quantityConsumed,
                required double costPriceAtConsumption,
              }) => SaleAllocationsCompanion.insert(
                id: id,
                saleId: saleId,
                batchId: batchId,
                quantityConsumed: quantityConsumed,
                costPriceAtConsumption: costPriceAtConsumption,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SaleAllocationsTable, SaleAllocation>(table),
                  $$SaleAllocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false, batchId = false}) {
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
                    if (saleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.saleId,
                        referencedTable: $$SaleAllocationsTableReferences
                            ._saleIdTable(db),
                        referencedColumn: $$SaleAllocationsTableReferences
                            ._saleIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (batchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.batchId,
                        referencedTable: $$SaleAllocationsTableReferences
                            ._batchIdTable(db),
                        referencedColumn: $$SaleAllocationsTableReferences
                            ._batchIdTable(db)
                            .id,
                      ) as T;
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

typedef $$SaleAllocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleAllocationsTable,
      SaleAllocation,
      $$SaleAllocationsTableFilterComposer,
      $$SaleAllocationsTableOrderingComposer,
      $$SaleAllocationsTableAnnotationComposer,
      $$SaleAllocationsTableCreateCompanionBuilder,
      $$SaleAllocationsTableUpdateCompanionBuilder,
      (SaleAllocation, $$SaleAllocationsTableReferences),
      SaleAllocation,
      PrefetchHooks Function({bool saleId, bool batchId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$CapitalBatchesTableTableManager get capitalBatches =>
      $$CapitalBatchesTableTableManager(_db, _db.capitalBatches);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleAllocationsTableTableManager get saleAllocations =>
      $$SaleAllocationsTableTableManager(_db, _db.saleAllocations);
}
