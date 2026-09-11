import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// IMPORTANT: part directive MUST be before any declarations.
part 'app_database.g.dart';

// ────────────────────────────────────────────────────────────────────────────
// Tables
// ────────────────────────────────────────────────────────────────────────────

/// Products table — id, name, and default sellingPrice stored; derived fields computed from batches.
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get sellingPrice =>
      real().withDefault(const Constant(0.0)).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Each restock is a separate batch (lot) with its own cost price.
@DataClassName('CapitalBatch')
class CapitalBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantityAdded => real()();
  RealColumn get remainingQuantity => real()();
  RealColumn get costPrice => real()();
  TextColumn get source => textEnum<BatchSource>()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// Source of a capital batch.
enum BatchSource { manual, scannedReceipt }

/// A single sell transaction header.
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantitySold => real()();
  RealColumn get sellPrice => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// One row per batch consumed by a sale (FIFO allocation).
class SaleAllocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get batchId =>
      integer().references(CapitalBatches, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantityConsumed => real()();
  RealColumn get costPriceAtConsumption => real()();
}

// ────────────────────────────────────────────────────────────────────────────
// Data transfer objects
// ────────────────────────────────────────────────────────────────────────────

class InventorySummary {
  const InventorySummary({
    required this.product,
    required this.totalQuantity,
    required this.latestCostPrice,
    required this.batches,
  });
  final Product product;
  final double totalQuantity;
  final double latestCostPrice;
  final List<CapitalBatch> batches;
}

class SaleStats {
  const SaleStats({required this.totalSold, required this.totalProfit});
  final double totalSold;
  final double totalProfit;
}

// ────────────────────────────────────────────────────────────────────────────
// DAOs
// ────────────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [Products, CapitalBatches, Sales, SaleAllocations])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  Stream<List<Product>> watchAllProducts() => select(products).watch();

  Future<int> insertProduct(ProductsCompanion companion) async {
    try {
      return await into(products).insert(companion);
    } catch (_) {
      try {
        await customStatement(
            'ALTER TABLE products ADD COLUMN selling_price REAL DEFAULT 0.0;');
      } catch (_) {}
      return await into(products).insert(companion);
    }
  }

  Future<Product?> findProductByNameCaseInsensitive(String name) async {
    final query = select(products)
      ..where((t) => t.name.lower().equals(name.trim().toLowerCase()));
    return query.getSingleOrNull();
  }

  Future<void> updateProductName({required int id, required String name}) =>
      (update(products)..where((t) => t.id.equals(id)))
          .write(ProductsCompanion(name: Value(name)));

  Future<void> updateProductSellingPrice({
    required int id,
    required double sellingPrice,
  }) async {
    try {
      await (update(products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(sellingPrice: Value(sellingPrice)),
      );
    } catch (_) {
      try {
        await customStatement(
            'ALTER TABLE products ADD COLUMN selling_price REAL DEFAULT 0.0;');
      } catch (_) {}
      try {
        await customStatement(
            'UPDATE products SET selling_price = 0.0 WHERE selling_price IS NULL;');
      } catch (_) {}
      await (update(products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(sellingPrice: Value(sellingPrice)),
      );
    }
  }

  Future<int> salesCountForProduct(int productId) async {
    final list = await (select(sales)..where((t) => t.productId.equals(productId))).get();
    return list.length;
  }

  Future<void> deleteProduct(int id) =>
      (delete(products)..where((t) => t.id.equals(id))).go();

  Future<void> deleteProductCascade(int productId) async {
    await transaction(() async {
      final productSales = await (select(sales)
            ..where((t) => t.productId.equals(productId)))
          .get();
      for (final s in productSales) {
        await (delete(sales)..where((t) => t.id.equals(s.id))).go();
      }
      await (delete(products)..where((t) => t.id.equals(productId))).go();
    });
  }

  Future<int> allocationsCountForBatch(int batchId) async {
    final list = await (select(saleAllocations)
          ..where((t) => t.batchId.equals(batchId)))
        .get();
    return list.length;
  }

  Future<void> deleteBatch(int batchId) =>
      (delete(capitalBatches)..where((t) => t.id.equals(batchId))).go();

  Future<void> deleteBatchCascade(int batchId) async {
    await transaction(() async {
      await (delete(saleAllocations)..where((t) => t.batchId.equals(batchId))).go();
      await (delete(capitalBatches)..where((t) => t.id.equals(batchId))).go();
    });
  }

  Future<List<CapitalBatch>> batchesForProduct(int productId) =>
      (select(capitalBatches)
            ..where((t) => t.productId.equals(productId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  Stream<List<CapitalBatch>> watchBatchesForProduct(int productId) =>
      (select(capitalBatches)
            ..where((t) => t.productId.equals(productId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .watch();

  Future<int> insertBatch(CapitalBatchesCompanion companion) =>
      into(capitalBatches).insert(companion);

  Future<void> patchBatch({
    required int batchId,
    double? remainingQuantity,
    double? costPrice,
  }) async {
    final current = await (select(capitalBatches)
          ..where((t) => t.id.equals(batchId)))
        .getSingle();
    await update(capitalBatches).replace(
      current.copyWith(
        remainingQuantity: remainingQuantity ?? current.remainingQuantity,
        costPrice: costPrice ?? current.costPrice,
      ),
    );
  }

  /// Watches real-time total capital in remaining inventory.
  Stream<double> watchTotalCapital() {
    return select(capitalBatches).watch().map((rows) {
      return rows.fold<double>(
          0.0, (acc, b) => acc + b.remainingQuantity * b.costPrice);
    });
  }

  Future<double> totalCapital() async {
    final rows = await select(capitalBatches).get();
    return rows.fold<double>(
        0, (acc, b) => acc + b.remainingQuantity * b.costPrice);
  }

  /// Sets remaining quantity of all batches to 0.0, resetting inventory capital to 0.
  Future<void> resetAllBatchQuantities() async {
    await (update(capitalBatches)).write(
      const CapitalBatchesCompanion(remainingQuantity: Value(0.0)),
    );
  }

  /// Deletes all batches and sale allocations.
  Future<void> clearAllBatches() async {
    await transaction(() async {
      await delete(saleAllocations).go();
      await delete(capitalBatches).go();
    });
  }

  /// Complete reset of all data (sales, batches, allocations).
  Future<void> resetAllData() async {
    await transaction(() async {
      await delete(saleAllocations).go();
      await delete(sales).go();
      await delete(capitalBatches).go();
    });
  }

  /// Watch inventory summaries reactively.
  /// Watches both Products and CapitalBatches via join so any batch deduction
  /// immediately triggers a stream update and updates the UI everywhere.
  Stream<List<InventorySummary>> watchInventorySummaries() {
    final query = select(products).join([
      leftOuterJoin(
        capitalBatches,
        capitalBatches.productId.equalsExp(products.id),
      ),
    ]);

    return query.watch().asyncMap((_) async {
      try {
        await customStatement(
            'ALTER TABLE products ADD COLUMN selling_price REAL DEFAULT 0.0;');
      } catch (_) {}
      try {
        await customStatement(
            'UPDATE products SET selling_price = 0.0 WHERE selling_price IS NULL;');
      } catch (_) {}
      final prods = await (select(products)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();
      final summaries = <InventorySummary>[];
      for (final prod in prods) {
        final batches = await batchesForProduct(prod.id);
        final active = batches.where((b) => b.remainingQuantity > 0).toList();
        final totalQty =
            active.fold<double>(0, (s, b) => s + b.remainingQuantity);
        final latestCost =
            batches.isNotEmpty ? batches.last.costPrice : 0.0;
        summaries.add(InventorySummary(
          product: prod,
          totalQuantity: totalQty,
          latestCostPrice: latestCost,
          batches: batches,
        ));
      }
      return summaries;
    });
  }
}

@DriftAccessor(tables: [Sales, SaleAllocations, CapitalBatches, Products])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Stream<List<Sale>> watchAllSales() =>
      (select(sales)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  Future<List<Sale>> allSales() =>
      (select(sales)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

  Future<List<SaleAllocation>> allocationsForSale(int saleId) =>
      (select(saleAllocations)..where((t) => t.saleId.equals(saleId))).get();

  /// Record a sale with FIFO allocation — atomic DB transaction.
  Future<int> recordSale({
    required int productId,
    required double quantitySold,
    required double sellPrice,
    required List<CapitalBatch> availableBatches,
  }) async {
    return await transaction(() async {
      final saleId = await into(sales).insert(
        SalesCompanion.insert(
          productId: productId,
          quantitySold: quantitySold,
          sellPrice: sellPrice,
        ),
      );

      var remaining = quantitySold;
      for (final batch in availableBatches) {
        if (remaining <= 0.0001) break;
        if (batch.remainingQuantity <= 0) continue;

        final consumed = remaining <= batch.remainingQuantity
            ? remaining
            : batch.remainingQuantity;

        await into(saleAllocations).insert(
          SaleAllocationsCompanion.insert(
            saleId: saleId,
            batchId: batch.id,
            quantityConsumed: consumed,
            costPriceAtConsumption: batch.costPrice,
          ),
        );

        await (update(capitalBatches)..where((t) => t.id.equals(batch.id)))
            .write(CapitalBatchesCompanion(
          remainingQuantity: Value(batch.remainingQuantity - consumed),
        ));

        remaining -= consumed;
      }

      if (remaining > 0.001) {
        throw Exception(
            'Insufficient stock: ${remaining.toStringAsFixed(2)} kg unfulfilled.');
      }
      return saleId;
    });
  }

  Stream<SaleStats> watchStats() =>
      watchAllSales().asyncMap((allSalesList) async {
        double totalSold = 0;
        double totalProfit = 0;
        for (final sale in allSalesList) {
          totalSold += sale.sellPrice * sale.quantitySold;
          final allocations = await allocationsForSale(sale.id);
          for (final alloc in allocations) {
            totalProfit +=
                (sale.sellPrice - alloc.costPriceAtConsumption) *
                    alloc.quantityConsumed;
          }
        }
        return SaleStats(totalSold: totalSold, totalProfit: totalProfit);
      });

  Future<List<MapEntry<DateTime, double>>> dailyProfits(
      {int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final allSalesList = await (select(sales)
          ..where((t) => t.timestamp.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();

    final map = <String, double>{};
    for (final sale in allSalesList) {
      final key =
          '${sale.timestamp.year}-${sale.timestamp.month.toString().padLeft(2, '0')}-${sale.timestamp.day.toString().padLeft(2, '0')}';
      final allocations = await allocationsForSale(sale.id);
      double profit = 0;
      for (final alloc in allocations) {
        profit += (sale.sellPrice - alloc.costPriceAtConsumption) *
            alloc.quantityConsumed;
      }
      map[key] = (map[key] ?? 0) + profit;
    }

    return map.entries
        .map((e) => MapEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Clears all sales and restores consumed batch quantities back to inventory.
  Future<void> resetAllSales() async {
    await transaction(() async {
      final allocations = await select(saleAllocations).get();
      for (final a in allocations) {
        final batch = await (select(capitalBatches)
              ..where((t) => t.id.equals(a.batchId)))
            .getSingleOrNull();
        if (batch != null) {
          await (update(capitalBatches)..where((t) => t.id.equals(a.batchId)))
              .write(
            CapitalBatchesCompanion(
              remainingQuantity:
                  Value(batch.remainingQuantity + a.quantityConsumed),
            ),
          );
        }
      }
      await delete(saleAllocations).go();
      await delete(sales).go();
    });
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Database
// ────────────────────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'issa.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [Products, CapitalBatches, Sales, SaleAllocations],
  daos: [InventoryDao, SalesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : isTesting = false,
        super(_openConnection());
  AppDatabase.forTesting(super.connection, {this.isTesting = true});

  final bool isTesting;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            try {
              await m.addColumn(products, products.sellingPrice);
            } catch (_) {}
            try {
              await customStatement(
                  'UPDATE products SET selling_price = 0.0 WHERE selling_price IS NULL;');
            } catch (_) {}
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          try {
            await customStatement(
                'ALTER TABLE products ADD COLUMN selling_price REAL DEFAULT 0.0;');
          } catch (_) {}
          try {
            await customStatement(
                'UPDATE products SET selling_price = 0.0 WHERE selling_price IS NULL;');
          } catch (_) {}
          if (!isTesting) {
            await seedCoreProductsIfEmpty();
          }
        },
      );

  static const List<String> kDefaultCoreProducts = [
    'Garlic Pork Longganisa',
    'Sweet Pork Longganisa',
    'Sweet & Spicy Pork Longganisa',
    'Chicken Longganisa',
    'Spicy Chicken Longganisa',
    'Chicken Hamonado',
    'Pork Tapa',
    'Pork Hamonado',
    'Pork Tocino',
  ];

  Future<void> seedCoreProductsIfEmpty() async {
    for (final name in kDefaultCoreProducts) {
      final existing = await (select(products)
            ..where((t) => t.name.lower().equals(name.toLowerCase())))
          .getSingleOrNull();
      if (existing == null) {
        await into(products).insert(
          ProductsCompanion.insert(
            name: name,
            sellingPrice: const Value(0.0),
          ),
        );
      }
    }
  }
}

extension ProductSafeSellingPrice on Product {
  double get effectiveSellingPrice => sellingPrice ?? 0.0;
}
