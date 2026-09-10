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

// ── Dashboard settings ─────────────────────────────────────────────────────

class DashboardSettings {
  final String welcomeTitle;
  final String welcomeSubtitle;
  final int chartDays;
  final bool showWelcomeBanner;
  final bool showCapitalTile;
  final bool showSoldTile;
  final bool showProfitTile;
  final bool showProfitChart;
  final bool showRecentSales;
  final bool showFutureBanner;
  final bool showFutureBreakdown;

  const DashboardSettings({
    this.welcomeTitle = 'Welcome back! 👋',
    this.welcomeSubtitle = "Here's your business snapshot.",
    this.chartDays = 30,
    this.showWelcomeBanner = true,
    this.showCapitalTile = true,
    this.showSoldTile = true,
    this.showProfitTile = true,
    this.showProfitChart = true,
    this.showRecentSales = true,
    this.showFutureBanner = true,
    this.showFutureBreakdown = true,
  });

  DashboardSettings copyWith({
    String? welcomeTitle,
    String? welcomeSubtitle,
    int? chartDays,
    bool? showWelcomeBanner,
    bool? showCapitalTile,
    bool? showSoldTile,
    bool? showProfitTile,
    bool? showProfitChart,
    bool? showRecentSales,
    bool? showFutureBanner,
    bool? showFutureBreakdown,
  }) {
    return DashboardSettings(
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      welcomeSubtitle: welcomeSubtitle ?? this.welcomeSubtitle,
      chartDays: chartDays ?? this.chartDays,
      showWelcomeBanner: showWelcomeBanner ?? this.showWelcomeBanner,
      showCapitalTile: showCapitalTile ?? this.showCapitalTile,
      showSoldTile: showSoldTile ?? this.showSoldTile,
      showProfitTile: showProfitTile ?? this.showProfitTile,
      showProfitChart: showProfitChart ?? this.showProfitChart,
      showRecentSales: showRecentSales ?? this.showRecentSales,
      showFutureBanner: showFutureBanner ?? this.showFutureBanner,
      showFutureBreakdown: showFutureBreakdown ?? this.showFutureBreakdown,
    );
  }
}

class DashboardSettingsNotifier extends StateNotifier<DashboardSettings> {
  DashboardSettingsNotifier() : super(const DashboardSettings());

  void updateSettings(DashboardSettings settings) {
    state = settings;
  }

  void resetToDefaults() {
    state = const DashboardSettings();
  }
}

final dashboardSettingsProvider =
    StateNotifierProvider<DashboardSettingsNotifier, DashboardSettings>((ref) {
  return DashboardSettingsNotifier();
});

// ── Daily profits for chart ────────────────────────────────────────────────

final dailyProfitsProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) async {
  ref.watch(allSalesProvider);
  final days = ref.watch(dashboardSettingsProvider).chartDays;
  return ref.read(salesDaoProvider).dailyProfits(days: days);
});

// ── Batches per product ────────────────────────────────────────────────────

final batchesForProductProvider =
    StreamProvider.family<List<CapitalBatch>, int>((ref, productId) {
  return ref.watch(inventoryDaoProvider).watchBatchesForProduct(productId);
});

