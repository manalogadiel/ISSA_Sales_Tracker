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

final totalCapitalProvider = StreamProvider<double>((ref) {
  return ref.watch(inventoryDaoProvider).watchTotalCapital();
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

  // Manual overrides for card values (null = auto-calculate from database)
  final double? manualCapital;
  final double? manualSold;
  final double? manualProfit;

  // Custom titles for cards (null = default)
  final String? capitalTitle;
  final String? soldTitle;
  final String? profitTitle;

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
    this.manualCapital,
    this.manualSold,
    this.manualProfit,
    this.capitalTitle,
    this.soldTitle,
    this.profitTitle,
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
    double? manualCapital,
    bool clearManualCapital = false,
    double? manualSold,
    bool clearManualSold = false,
    double? manualProfit,
    bool clearManualProfit = false,
    String? capitalTitle,
    bool clearCapitalTitle = false,
    String? soldTitle,
    bool clearSoldTitle = false,
    String? profitTitle,
    bool clearProfitTitle = false,
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
      manualCapital: clearManualCapital
          ? null
          : (manualCapital ?? this.manualCapital),
      manualSold: clearManualSold ? null : (manualSold ?? this.manualSold),
      manualProfit:
          clearManualProfit ? null : (manualProfit ?? this.manualProfit),
      capitalTitle:
          clearCapitalTitle ? null : (capitalTitle ?? this.capitalTitle),
      soldTitle: clearSoldTitle ? null : (soldTitle ?? this.soldTitle),
      profitTitle: clearProfitTitle ? null : (profitTitle ?? this.profitTitle),
    );
  }
}

class DashboardSettingsNotifier extends StateNotifier<DashboardSettings> {
  DashboardSettingsNotifier() : super(const DashboardSettings());

  void updateSettings(DashboardSettings settings) {
    state = settings;
  }

  void setManualCapital(double? value, {String? title}) {
    state = state.copyWith(
      manualCapital: value,
      clearManualCapital: value == null,
      capitalTitle: title,
      clearCapitalTitle: title == null,
    );
  }

  void setManualSold(double? value, {String? title}) {
    state = state.copyWith(
      manualSold: value,
      clearManualSold: value == null,
      soldTitle: title,
      clearSoldTitle: title == null,
    );
  }

  void setManualProfit(double? value, {String? title}) {
    state = state.copyWith(
      manualProfit: value,
      clearManualProfit: value == null,
      profitTitle: title,
      clearProfitTitle: title == null,
    );
  }

  void resetMetricsToZero() {
    state = state.copyWith(
      manualCapital: 0.0,
      manualSold: 0.0,
      manualProfit: 0.0,
    );
  }

  void revertAllToAuto() {
    state = state.copyWith(
      clearManualCapital: true,
      clearManualSold: true,
      clearManualProfit: true,
      clearCapitalTitle: true,
      clearSoldTitle: true,
      clearProfitTitle: true,
    );
  }

  /// Called when stock is restocked or added (via scan or manual entry).
  /// If manualCapital is active, increments it by the added capital cost.
  void onStockAdded(double amount) {
    if (state.manualCapital != null) {
      state = state.copyWith(
        manualCapital: (state.manualCapital ?? 0.0) + amount,
      );
    }
  }

  /// Called when stock or batch is removed/deleted.
  /// If manualCapital is active, decrements it by the removed value.
  void onStockRemoved(double amount) {
    if (state.manualCapital != null) {
      final current = state.manualCapital ?? 0.0;
      state = state.copyWith(
        manualCapital: (current - amount).clamp(0.0, double.infinity),
      );
    }
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

