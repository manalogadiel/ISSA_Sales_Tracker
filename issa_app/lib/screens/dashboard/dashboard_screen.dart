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
    final statsAsync = ref.watch(saleStatsProvider);
    final capitalAsync = ref.watch(totalCapitalProvider);
    final dailyAsync = ref.watch(dailyProfitsProvider);

    return Scaffold(
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
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(saleStatsProvider);
          ref.invalidate(totalCapitalProvider);
          ref.invalidate(dailyProfitsProvider);
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
              error: (e, _) => _ErrorTile(label: 'Capital'),
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
      ),
    );
  }
}

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
