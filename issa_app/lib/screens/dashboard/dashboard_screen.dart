import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(saleStatsProvider);
                ref.invalidate(totalCapitalProvider);
                ref.invalidate(dailyProfitsProvider);
                ref.invalidate(inventorySummariesProvider);
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primaryDeep,
            indicatorWeight: 3,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_outlined, size: 20),
                text: 'Overview',
              ),
              Tab(
                icon: Icon(Icons.auto_graph_rounded, size: 20),
                text: 'Future Metrics',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _FutureMetricsTab(),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(saleStatsProvider);
    final capitalAsync = ref.watch(totalCapitalProvider);
    final dailyAsync = ref.watch(dailyProfitsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(saleStatsProvider);
        ref.invalidate(totalCapitalProvider);
        ref.invalidate(dailyProfitsProvider);
        ref.invalidate(inventorySummariesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Welcome section ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB79CED), Color(0xFF9B87C4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back! 👋',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s your business snapshot.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.storefront_rounded,
                    color: Colors.white54, size: 48),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Stat tiles ───────────────────────────────────────────────────
          const SectionHeader(title: 'OVERVIEW'),
          const SizedBox(height: 12),

          // Capital tile
          capitalAsync.when(
            loading: () => _LoadingTile(),
            error: (e, _) => const _ErrorTile(label: 'Capital'),
            data: (capital) => StatTile(
              label: 'Total Capital',
              value: formatPeso(capital),
              gradient: AppColors.capitalGradient,
              icon: Icons.account_balance_wallet_rounded,
              subtitle: 'Current inventory value',
            ),
          ),

          const SizedBox(height: 12),

          statsAsync.when(
            loading: () => Column(
              children: [
                _LoadingTile(),
                const SizedBox(height: 12),
                _LoadingTile(),
              ],
            ),
            error: (e, _) => const _ErrorTile(label: 'Stats'),
            data: (stats) => Column(
              children: [
                StatTile(
                  label: 'Total Sold',
                  value: formatPeso(stats.totalSold),
                  gradient: AppColors.soldGradient,
                  icon: Icons.shopping_bag_rounded,
                  subtitle: 'All-time revenue',
                ),
                const SizedBox(height: 12),
                StatTile(
                  label: 'Total Profit',
                  value: formatPeso(stats.totalProfit),
                  gradient: stats.totalProfit >= 0
                      ? AppColors.profitGradient
                      : [AppColors.error, const Color(0xFFB23636)],
                  icon: Icons.trending_up_rounded,
                  subtitle: 'Based on snapshotted cost prices',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Profit chart ─────────────────────────────────────────────────
          const SectionHeader(title: 'PROFIT (LAST 30 DAYS)'),
          const SizedBox(height: 12),

          dailyAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const _ErrorTile(label: 'Chart'),
            data: (points) => points.isEmpty
                ? Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Center(
                      child: Text(
                        'No sales yet — chart will appear here.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  )
                : _ProfitChart(points: points),
          ),

          const SizedBox(height: 24),

          // ── Recent sales list ────────────────────────────────────────────
          const SectionHeader(title: 'RECENT SALES'),
          const SizedBox(height: 12),
          _RecentSalesList(),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Future Metrics Tab
// ────────────────────────────────────────────────────────────────────────────

class _FutureMetricsTab extends ConsumerWidget {
  const _FutureMetricsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(inventorySummariesProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(inventorySummariesProvider);
        ref.invalidate(totalCapitalProvider);
      },
      child: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (summaries) {
          final inStockSummaries =
              summaries.where((s) => s.totalQuantity > 0).toList();

          if (inStockSummaries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No inventory in stock',
                  subtitle:
                      'Add products and restock batches in the Inventory tab to see future profit and value metrics.',
                ),
              ],
            );
          }

          double totalProjectedRevenue = 0.0;
          double totalRemainingCapital = 0.0;
          int unsetSellPriceCount = 0;

          for (final s in inStockSummaries) {
            final hasSellPrice = s.product.sellingPrice > 0;
            if (!hasSellPrice) unsetSellPriceCount++;

            final effSellPrice =
                hasSellPrice ? s.product.sellingPrice : s.latestCostPrice;
            final prodRevenue = s.totalQuantity * effSellPrice;
            final prodCapital = s.batches.fold<double>(
                0.0, (acc, b) => acc + (b.remainingQuantity * b.costPrice));

            totalProjectedRevenue += prodRevenue;
            totalRemainingCapital += prodCapital;
          }

          final totalProjectedProfit =
              totalProjectedRevenue - totalRemainingCapital;
          final projectedMargin = totalProjectedRevenue > 0
              ? (totalProjectedProfit / totalProjectedRevenue) * 100
              : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // ── Future projections hero banner ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8F6CC9), Color(0xFF6B4FB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8F6CC9).withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Future Projections 🔮',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimated total value and profit if all stock currently in inventory is sold.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(210),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.auto_graph_rounded,
                        color: Colors.white54, size: 44),
                  ],
                ),
              ),

              // Unset selling price notification banner
              if (unsetSellPriceCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$unsetSellPriceCount product(s) have unset selling prices (using cost price as fallback). Set selling prices in Inventory or Prices table for exact metrics.',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Projected Stat Tiles ───────────────────────────────────────
              const SectionHeader(title: 'PROJECTED TOTALS IF SOLD'),
              const SizedBox(height: 12),

              // Total value if everything is sold
              StatTile(
                label: 'Total Value if Sold',
                value: formatPeso(totalProjectedRevenue),
                gradient: const [Color(0xFF5B8ED9), Color(0xFF456DB0)],
                icon: Icons.payments_rounded,
                subtitle: 'Gross revenue from selling 100% current inventory',
              ),
              const SizedBox(height: 12),

              // Total profit if everything is sold
              StatTile(
                label: 'Total Profit if Sold',
                value: formatPeso(totalProjectedProfit),
                gradient: totalProjectedProfit >= 0
                    ? AppColors.profitGradient
                    : [AppColors.error, const Color(0xFFB23636)],
                icon: Icons.trending_up_rounded,
                subtitle: 'Estimated net profit after deducting capital costs',
              ),
              const SizedBox(height: 12),

              // Projected margin & stock capital
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.pie_chart_rounded,
                                  size: 16, color: AppColors.primaryDeep),
                              SizedBox(width: 6),
                              Text(
                                'Est. Margin',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${projectedMargin.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Profit / Revenue',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.inventory_2_outlined,
                                  size: 16, color: AppColors.primaryDeep),
                              SizedBox(width: 6),
                              Text(
                                'Stock Capital',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatPeso(totalRemainingCapital),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Cost of goods in stock',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Product-by-Product Breakdown ──────────────────────────────
              const SectionHeader(title: 'PRODUCT-BY-PRODUCT PROJECTIONS'),
              const SizedBox(height: 12),

              ...inStockSummaries.map((s) {
                final hasSellPrice = s.product.sellingPrice > 0;
                final effSellPrice =
                    hasSellPrice ? s.product.sellingPrice : s.latestCostPrice;
                final prodRevenue = s.totalQuantity * effSellPrice;
                final prodCapital = s.batches.fold<double>(
                    0.0, (acc, b) => acc + (b.remainingQuantity * b.costPrice));
                final prodProfit = prodRevenue - prodCapital;
                final prodMargin = prodRevenue > 0
                    ? (prodProfit / prodRevenue) * 100
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product header with stock pill
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.product.name,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              formatKg(s.totalQuantity),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Price details
                      Row(
                        children: [
                          Text(
                            'Sell: ${hasSellPrice ? formatPeso(s.product.sellingPrice) : 'Unset'} / kg',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasSellPrice
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·  Cost: ${formatPeso(s.latestCostPrice)} / kg',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Financial breakdown card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Est. Revenue',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatPeso(prodRevenue),
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Est. Profit',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatPeso(prodProfit),
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: prodProfit >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Margin',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${prodMargin >= 0 ? '+' : ''}${prodMargin.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: prodMargin >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Common Dashboard Subcomponents
// ────────────────────────────────────────────────────────────────────────────

class _LoadingTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Center(
        child: Text('Could not load $label',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _ProfitChart extends StatelessWidget {
  const _ProfitChart({required this.points});
  final List<MapEntry<DateTime, double>> points;

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final maxY =
        (points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.3)
            .ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY > 0 ? maxY : 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, _) => Text(
                  '₱${v.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox();
                  if (idx % (points.length <= 7 ? 1 : 3) != 0) {
                    return const SizedBox();
                  }
                  final d = points[idx].key;
                  return Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: points.length <= 14,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(77),
                    AppColors.primary.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSalesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(allSalesProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return salesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (sales) {
        if (sales.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text('No sales recorded yet.',
                  style: TextStyle(color: AppColors.textHint)),
            ),
          );
        }
        final recent = sales.take(10).toList();
        return productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox(),
          data: (products) {
            final prodMap = {for (final p in products) p.id: p.name};
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final sale = recent[i];
                  final name =
                      prodMap[sale.productId] ?? 'Unknown Product';
                  final revenue = sale.sellPrice * sale.quantitySold;
                  final dateStr =
                      '${sale.timestamp.month}/${sale.timestamp.day}';
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    title: Text(name),
                    subtitle: Text(
                        '${formatKg(sale.quantitySold)} · ${formatPeso(sale.sellPrice)}/kg · $dateStr'),
                    trailing: Text(
                      formatPeso(revenue),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
