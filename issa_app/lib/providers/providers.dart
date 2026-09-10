import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';

export '../db/app_database.dart';

/// Singleton database provider.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() async => db.close());
  return db;
});

/// Inventory DAO provider.
final inventoryDaoProvider = Provider<InventoryDao>((ref) {
  return ref.watch(databaseProvider).inventoryDao;
});

/// Sales DAO provider.
final salesDaoProvider = Provider<SalesDao>((ref) {
  return ref.watch(databaseProvider).salesDao;
});

// ── Inventory streams ──────────────────────────────────────────────────────

final inventorySummariesProvider =
    StreamProvider<List<InventorySummary>>((ref) {
  return ref.watch(inventoryDaoProvider).watchInventorySummaries();
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(inventoryDaoProvider).watchAllProducts();
});

// ── Sales streams ──────────────────────────────────────────────────────────

final allSalesProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(salesDaoProvider).watchAllSales();
});

final saleStatsProvider = StreamProvider<SaleStats>((ref) {
  return ref.watch(salesDaoProvider).watchStats();
});

// ── Total capital (derived from inventory) ─────────────────────────────────

final totalCapitalProvider = FutureProvider<double>((ref) async {
  // Re-derive whenever inventory changes
  ref.watch(inventorySummariesProvider);
  return ref.read(inventoryDaoProvider).totalCapital();
});

// ── Daily profits for chart ────────────────────────────────────────────────

final dailyProfitsProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) async {
  ref.watch(allSalesProvider);
  return ref.read(salesDaoProvider).dailyProfits(days: 30);
});

// ── Batches per product ────────────────────────────────────────────────────

final batchesForProductProvider =
    StreamProvider.family<List<CapitalBatch>, int>((ref, productId) {
  return ref.watch(inventoryDaoProvider).watchBatchesForProduct(productId);
});
