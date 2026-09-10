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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Dashboard options',
              onSelected: (val) async {
                if (val == 'edit') {
                  _showEditDashboardDialog(context, ref);
                } else if (val == 'reset') {
                  final proceed = await _showResetWarningDialog(context);
                  if (proceed == true && context.mounted) {
                    _showResetDashboardDialog(context, ref);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 20, color: AppColors.primaryDeep),
                      SizedBox(width: 12),
                      Text('Edit Dashboard'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt_rounded,
                          size: 20, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Reset Dashboard',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
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

  Future<void> _showEditDashboardDialog(
      BuildContext context, WidgetRef ref) async {
    final current = ref.read(dashboardSettingsProvider);
    final statsAsync = ref.read(saleStatsProvider);
    final capitalAsync = ref.read(totalCapitalProvider);

    final titleCtrl = TextEditingController(text: current.welcomeTitle);
    final subtitleCtrl = TextEditingController(text: current.welcomeSubtitle);
    int selectedDays = current.chartDays;
    bool showBanner = current.showWelcomeBanner;
    bool showCapital = current.showCapitalTile;
    bool showSold = current.showSoldTile;
    bool showProfit = current.showProfitTile;
    bool showChart = current.showProfitChart;
    bool showSales = current.showRecentSales;
    bool showFutureBanner = current.showFutureBanner;
    bool showFutureBreakdown = current.showFutureBreakdown;

    final autoCapital = capitalAsync.asData?.value ?? 0.0;
    final autoSold = statsAsync.asData?.value.totalSold ?? 0.0;
    final autoProfit = statsAsync.asData?.value.totalProfit ?? 0.0;

    final capitalOverrideCtrl = TextEditingController(
      text: current.manualCapital != null
          ? current.manualCapital!.toStringAsFixed(2)
          : '',
    );
    final soldOverrideCtrl = TextEditingController(
      text: current.manualSold != null
          ? current.manualSold!.toStringAsFixed(2)
          : '',
    );
    final profitOverrideCtrl = TextEditingController(
      text: current.manualProfit != null
          ? current.manualProfit!.toStringAsFixed(2)
          : '',
    );

    final capitalTitleCtrl =
        TextEditingController(text: current.capitalTitle ?? 'Total Capital');
    final soldTitleCtrl =
        TextEditingController(text: current.soldTitle ?? 'Total Sold');
    final profitTitleCtrl =
        TextEditingController(text: current.profitTitle ?? 'Total Profit');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: AppColors.primaryDeep, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Customize Dashboard',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      // Section 1: Greeting & Store Title
                      const SectionHeader(title: 'GREETING & STORE TITLE'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Greeting Title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subtitleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                          prefixIcon: Icon(Icons.subtitles_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Manual Card Values & Custom Titles
                      const SectionHeader(title: 'MANUAL CARD VALUES & TITLES'),
                      const SizedBox(height: 4),
                      Text(
                        'Override card amounts manually or customize labels. Leave amount empty for auto calculation.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Capital
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: capitalTitleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Capital Title',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: capitalOverrideCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Capital (₱)',
                                prefixText: '₱ ',
                                hintText: 'Auto (${formatPeso(autoCapital)})',
                                isDense: true,
                                suffixIcon: capitalOverrideCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () => setModalState(
                                            () => capitalOverrideCtrl.clear()),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Sold
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: soldTitleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Sold Title',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: soldOverrideCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Sold (₱)',
                                prefixText: '₱ ',
                                hintText: 'Auto (${formatPeso(autoSold)})',
                                isDense: true,
                                suffixIcon: soldOverrideCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () => setModalState(
                                            () => soldOverrideCtrl.clear()),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Profit
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: profitTitleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Profit Title',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: profitOverrideCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Profit (₱)',
                                prefixText: '₱ ',
                                hintText: 'Auto (${formatPeso(autoProfit)})',
                                isDense: true,
                                suffixIcon: profitOverrideCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () => setModalState(
                                            () => profitOverrideCtrl.clear()),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.exposure_zero_rounded,
                                size: 16),
                            label: const Text('Set All to ₱0.00'),
                            onPressed: () {
                              setModalState(() {
                                capitalOverrideCtrl.text = '0.00';
                                soldOverrideCtrl.text = '0.00';
                                profitOverrideCtrl.text = '0.00';
                              });
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.auto_mode_rounded, size: 16),
                            label: const Text('Clear Overrides (Auto)'),
                            onPressed: () {
                              setModalState(() {
                                capitalOverrideCtrl.clear();
                                soldOverrideCtrl.clear();
                                profitOverrideCtrl.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Profit Chart Timeframe
                      const SectionHeader(title: 'PROFIT CHART TIMEFRAME'),
                      const SizedBox(height: 8),
                      Row(
                        children: [7, 14, 30, 60].map((days) {
                          final isSelected = selectedDays == days;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text('$days D'),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() => selectedDays = days);
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Section 4: Visible Cards (Overview)
                      const SectionHeader(title: 'OVERVIEW CARDS VISIBILITY'),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        title: const Text('Welcome Banner',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Top greeting banner with business snapshot',
                            style: TextStyle(fontSize: 12)),
                        value: showBanner,
                        onChanged: (val) =>
                            setModalState(() => showBanner = val),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Total Capital Card',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text('Total capital in stock',
                            style: TextStyle(fontSize: 12)),
                        value: showCapital,
                        onChanged: (val) =>
                            setModalState(() => showCapital = val),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Total Sold Card',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text('All-time gross sales',
                            style: TextStyle(fontSize: 12)),
                        value: showSold,
                        onChanged: (val) => setModalState(() => showSold = val),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Total Profit Card',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text('All-time net profit',
                            style: TextStyle(fontSize: 12)),
                        value: showProfit,
                        onChanged: (val) =>
                            setModalState(() => showProfit = val),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Profit Chart',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text('Daily profit trends graph',
                            style: TextStyle(fontSize: 12)),
                        value: showChart,
                        onChanged: (val) =>
                            setModalState(() => showChart = val),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Recent Sales List',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text('Latest sales transactions',
                            style: TextStyle(fontSize: 12)),
                        value: showSales,
                        onChanged: (val) =>
                            setModalState(() => showSales = val),
                      ),
                      const SizedBox(height: 20),

                      // Section 5: Future Metrics Tab Visibility
                      const SectionHeader(title: 'FUTURE METRICS CARDS'),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        title: const Text('Projections Summary Banner',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Estimated total value, profit & margin',
                            style: TextStyle(fontSize: 12)),
                        value: showFutureBanner,
                        onChanged: (val) =>
                            setModalState(() => showFutureBanner = val),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Product Breakdown List',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Individual product projection breakdowns',
                            style: TextStyle(fontSize: 12)),
                        value: showFutureBreakdown,
                        onChanged: (val) =>
                            setModalState(() => showFutureBreakdown = val),
                      ),
                    ],
                  ),
                ),
                // Bottom Save Bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              final manualCap = capitalOverrideCtrl.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : cleanParseNumber(capitalOverrideCtrl.text);
                              final manualSld =
                                  soldOverrideCtrl.text.trim().isEmpty
                                      ? null
                                      : cleanParseNumber(soldOverrideCtrl.text);
                              final manualPrf = profitOverrideCtrl.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : cleanParseNumber(profitOverrideCtrl.text);

                              final capTitle =
                                  capitalTitleCtrl.text.trim().isNotEmpty
                                      ? capitalTitleCtrl.text.trim()
                                      : null;
                              final sldTitle =
                                  soldTitleCtrl.text.trim().isNotEmpty
                                      ? soldTitleCtrl.text.trim()
                                      : null;
                              final prfTitle =
                                  profitTitleCtrl.text.trim().isNotEmpty
                                      ? profitTitleCtrl.text.trim()
                                      : null;

                              ref
                                  .read(dashboardSettingsProvider.notifier)
                                  .updateSettings(
                                    DashboardSettings(
                                      welcomeTitle: titleCtrl.text.trim().isNotEmpty
                                          ? titleCtrl.text.trim()
                                          : 'Welcome back! 👋',
                                      welcomeSubtitle:
                                          subtitleCtrl.text.trim().isNotEmpty
                                              ? subtitleCtrl.text.trim()
                                              : "Here's your business snapshot.",
                                      chartDays: selectedDays,
                                      showWelcomeBanner: showBanner,
                                      showCapitalTile: showCapital,
                                      showSoldTile: showSold,
                                      showProfitTile: showProfit,
                                      showProfitChart: showChart,
                                      showRecentSales: showSales,
                                      showFutureBanner: showFutureBanner,
                                      showFutureBreakdown: showFutureBreakdown,
                                      manualCapital: manualCap,
                                      manualSold: manualSld,
                                      manualProfit: manualPrf,
                                      capitalTitle: capTitle,
                                      soldTitle: sldTitle,
                                      profitTitle: prfTitle,
                                    ),
                                  );
                              ref.invalidate(dailyProfitsProvider);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dashboard preferences saved'),
                                  backgroundColor: AppColors.success,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDashboardDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.restart_alt_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reset Dashboard'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose what you would like to reset:',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Option 1: Set All Cards to ₱0.00 (Display override)
              Card(
                elevation: 0,
                color: AppColors.accentLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryDeep,
                    child: Icon(Icons.exposure_zero_rounded,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('Set All Dashboard Cards to ₱0.00',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: const Text(
                      'Instantly sets Total Capital, Sold, and Profit cards to ₱0.00.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                  onTap: () {
                    ref
                        .read(dashboardSettingsProvider.notifier)
                        .resetMetricsToZero();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All dashboard cards set to ₱0.00'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Reset Inventory Capital to ₱0.00 (Database batches)
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6B4FB8),
                    child: Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('Reset Inventory Capital to ₱0.00',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: const Text(
                      'Zeros out all stock batch quantities in database. Capital becomes ₱0.00.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmResetCapitalData(context, ref);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Option 3: Clear Sales History
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error.withAlpha(30),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppColors.error, size: 20),
                  ),
                  title: const Text('Clear All Sales History',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.error)),
                  subtitle: const Text(
                      'Resets sales metrics to 0 and restores all inventory stock.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmClearSalesData(context, ref);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Option 4: Full Reset (Wipe Sales & Capital Batches)
              Card(
                elevation: 0,
                color: AppColors.error.withAlpha(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.error.withAlpha(60)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Colors.white, size: 20),
                  ),
                  title: const Text('Full Reset (Sales & Batches)',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.error)),
                  subtitle: const Text(
                      'Wipes all sales records and inventory batches to ₱0.00.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmResetAllData(context, ref);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Option 5: Revert Overrides & Reset Layout
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accentLight,
                    child: Icon(Icons.refresh_rounded,
                        color: AppColors.primaryDeep, size: 20),
                  ),
                  title: const Text('Revert to Auto & Reset Layout',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: const Text(
                      'Removes manual overrides and restores auto database values.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                  onTap: () {
                    ref
                        .read(dashboardSettingsProvider.notifier)
                        .resetToDefaults();
                    ref.invalidate(dailyProfitsProvider);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Dashboard layout and metrics restored to auto defaults'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetCapitalData(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.inventory_2_outlined, color: Color(0xFF6B4FB8)),
            SizedBox(width: 8),
            Text('Reset Inventory Capital?'),
          ],
        ),
        content: const Text(
          'This will set all inventory batch remaining quantities to 0.0 kg in the database.\n\nTotal Capital will reset to ₱0.00 while preserving your product catalog.\n\nAre you sure you want to proceed?',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B4FB8)),
            child: const Text('Yes, Reset Capital to ₱0.00'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(inventoryDaoProvider).resetAllBatchQuantities();
        ref.read(dashboardSettingsProvider.notifier).setManualCapital(null);
        ref.invalidate(totalCapitalProvider);
        ref.invalidate(inventorySummariesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inventory capital has been reset to ₱0.00'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting capital: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmClearSalesData(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Clear Sales History?'),
          ],
        ),
        content: const Text(
          'This will delete all recorded sales and restore previously sold quantities back to their capital batches. Past revenue and profit will be reset to ₱0.00.\n\nThis action cannot be undone.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Reset Sales'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(salesDaoProvider).resetAllSales();
        ref.read(dashboardSettingsProvider.notifier).setManualSold(null);
        ref.read(dashboardSettingsProvider.notifier).setManualProfit(null);
        ref.invalidate(saleStatsProvider);
        ref.invalidate(totalCapitalProvider);
        ref.invalidate(dailyProfitsProvider);
        ref.invalidate(inventorySummariesProvider);
        ref.invalidate(allSalesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('All sales data has been reset and stock restored'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting sales data: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmResetAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Full Clean Start?'),
          ],
        ),
        content: const Text(
          'This will delete all sales records, sale allocations, and inventory stock batches.\n\nTotal Capital, Total Sold, and Total Profit will all reset to ₱0.00.\n\nThis action cannot be undone.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Wipe Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(inventoryDaoProvider).resetAllData();
        ref.read(dashboardSettingsProvider.notifier).revertAllToAuto();
        ref.invalidate(saleStatsProvider);
        ref.invalidate(totalCapitalProvider);
        ref.invalidate(dailyProfitsProvider);
        ref.invalidate(inventorySummariesProvider);
        ref.invalidate(allSalesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('All sales and stock batches have been wiped to ₱0.00'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error wiping data: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Single Card Value Editor Dialog
// ────────────────────────────────────────────────────────────────────────────

Future<void> _showEditCardValueDialog(
  BuildContext context,
  WidgetRef ref,
  String cardType, // 'capital' | 'sold' | 'profit'
) async {
  final settings = ref.read(dashboardSettingsProvider);
  final capitalAsync = ref.read(totalCapitalProvider);
  final statsAsync = ref.read(saleStatsProvider);

  String defaultLabel;
  String currentTitle;
  double? currentManual;
  double autoValue;
  IconData icon;
  List<Color> gradient;

  switch (cardType) {
    case 'capital':
      defaultLabel = 'Total Capital';
      currentTitle = settings.capitalTitle ?? defaultLabel;
      currentManual = settings.manualCapital;
      autoValue = capitalAsync.asData?.value ?? 0.0;
      icon = Icons.account_balance_wallet_rounded;
      gradient = AppColors.capitalGradient;
      break;
    case 'sold':
      defaultLabel = 'Total Sold';
      currentTitle = settings.soldTitle ?? defaultLabel;
      currentManual = settings.manualSold;
      autoValue = statsAsync.asData?.value.totalSold ?? 0.0;
      icon = Icons.shopping_bag_rounded;
      gradient = AppColors.soldGradient;
      break;
    case 'profit':
    default:
      defaultLabel = 'Total Profit';
      currentTitle = settings.profitTitle ?? defaultLabel;
      currentManual = settings.manualProfit;
      autoValue = statsAsync.asData?.value.totalProfit ?? 0.0;
      icon = Icons.trending_up_rounded;
      gradient = AppColors.profitGradient;
      break;
  }

  final valCtrl = TextEditingController(
    text: currentManual != null
        ? currentManual.toStringAsFixed(2)
        : autoValue.toStringAsFixed(2),
  );
  final titleCtrl = TextEditingController(text: currentTitle);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Edit $defaultLabel',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primaryDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Auto-calculated: ${formatPeso(autoValue)}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Card Title / Label',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: valCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Card Value (₱)',
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 12),
            // Quick action chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.exposure_zero_rounded, size: 16),
                  label: const Text('₱0.00'),
                  backgroundColor: AppColors.accentLight,
                  onPressed: () => valCtrl.text = '0.00',
                ),
                ActionChip(
                  avatar: const Icon(Icons.auto_mode_rounded, size: 16),
                  label: const Text('Use Auto DB Value'),
                  backgroundColor: AppColors.accentLight,
                  onPressed: () => valCtrl.text = autoValue.toStringAsFixed(2),
                ),
                if (currentManual != null)
                  ActionChip(
                    avatar: const Icon(Icons.undo_rounded,
                        size: 16, color: AppColors.primary),
                    label: const Text('Revert to Auto'),
                    onPressed: () {
                      final notifier =
                          ref.read(dashboardSettingsProvider.notifier);
                      switch (cardType) {
                        case 'capital':
                          notifier.setManualCapital(null,
                              title: titleCtrl.text.trim());
                          break;
                        case 'sold':
                          notifier.setManualSold(null,
                              title: titleCtrl.text.trim());
                          break;
                        case 'profit':
                          notifier.setManualProfit(null,
                              title: titleCtrl.text.trim());
                          break;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('$defaultLabel reverted to auto calculation'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsedVal = cleanParseNumber(valCtrl.text);
            final title = titleCtrl.text.trim().isNotEmpty
                ? titleCtrl.text.trim()
                : defaultLabel;
            final notifier = ref.read(dashboardSettingsProvider.notifier);

            switch (cardType) {
              case 'capital':
                notifier.setManualCapital(parsedVal, title: title);
                break;
              case 'sold':
                notifier.setManualSold(parsedVal, title: title);
                break;
              case 'profit':
                notifier.setManualProfit(parsedVal, title: title);
                break;
            }

            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '$title updated to ${formatPeso(parsedVal ?? autoValue)}'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(dashboardSettingsProvider);
    final statsAsync = ref.watch(saleStatsProvider);
    final capitalAsync = ref.watch(totalCapitalProvider);
    final dailyAsync = ref.watch(dailyProfitsProvider);

    final allOverviewHidden = !settings.showWelcomeBanner &&
        !settings.showCapitalTile &&
        !settings.showSoldTile &&
        !settings.showProfitTile &&
        !settings.showProfitChart &&
        !settings.showRecentSales;

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
          if (settings.showWelcomeBanner) ...[
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
                        Text(
                          settings.welcomeTitle,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.welcomeSubtitle,
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
          ],

          if (allOverviewHidden) ...[
            const SizedBox(height: 40),
            const EmptyState(
              icon: Icons.dashboard_customize_outlined,
              title: 'Overview cards hidden',
              subtitle:
                  'All overview cards are currently hidden. Tap the menu (...) in the top right and select "Edit Dashboard" to enable cards.',
            ),
          ],

          // ── Stat tiles ───────────────────────────────────────────────────
          if (settings.showCapitalTile ||
              settings.showSoldTile ||
              settings.showProfitTile) ...[
            const SectionHeader(title: 'OVERVIEW'),
            const SizedBox(height: 12),
          ],

          // Capital tile
          if (settings.showCapitalTile) ...[
            Builder(
              builder: (ctx) {
                final isManual = settings.manualCapital != null;
                final displayLabel = settings.capitalTitle ?? 'Total Capital';
                if (isManual) {
                  return StatTile(
                    label: displayLabel,
                    value: formatPeso(settings.manualCapital!),
                    gradient: AppColors.capitalGradient,
                    icon: Icons.account_balance_wallet_rounded,
                    subtitle: 'Manual override (Tap to edit)',
                    isManual: true,
                    onEdit: () =>
                        _showEditCardValueDialog(context, ref, 'capital'),
                    onTap: () =>
                        _showEditCardValueDialog(context, ref, 'capital'),
                  );
                }
                return capitalAsync.when(
                  loading: () => _LoadingTile(),
                  error: (e, _) => const _ErrorTile(label: 'Capital'),
                  data: (capital) => StatTile(
                    label: displayLabel,
                    value: formatPeso(capital),
                    gradient: AppColors.capitalGradient,
                    icon: Icons.account_balance_wallet_rounded,
                    subtitle: 'Current inventory value',
                    isManual: false,
                    onEdit: () =>
                        _showEditCardValueDialog(context, ref, 'capital'),
                    onTap: () =>
                        _showEditCardValueDialog(context, ref, 'capital'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          if (settings.showSoldTile || settings.showProfitTile) ...[
            Builder(
              builder: (ctx) {
                final isSoldManual = settings.manualSold != null;
                final isProfitManual = settings.manualProfit != null;
                final soldLabel = settings.soldTitle ?? 'Total Sold';
                final profitLabel = settings.profitTitle ?? 'Total Profit';

                return statsAsync.when(
                  loading: () => Column(
                    children: [
                      if (settings.showSoldTile) ...[
                        if (isSoldManual)
                          StatTile(
                            label: soldLabel,
                            value: formatPeso(settings.manualSold!),
                            gradient: AppColors.soldGradient,
                            icon: Icons.shopping_bag_rounded,
                            subtitle: 'Manual override (Tap to edit)',
                            isManual: true,
                            onEdit: () =>
                                _showEditCardValueDialog(context, ref, 'sold'),
                            onTap: () =>
                                _showEditCardValueDialog(context, ref, 'sold'),
                          )
                        else
                          _LoadingTile(),
                        if (settings.showProfitTile) const SizedBox(height: 12),
                      ],
                      if (settings.showProfitTile) ...[
                        if (isProfitManual)
                          StatTile(
                            label: profitLabel,
                            value: formatPeso(settings.manualProfit!),
                            gradient: settings.manualProfit! >= 0
                                ? AppColors.profitGradient
                                : [AppColors.error, const Color(0xFFB23636)],
                            icon: Icons.trending_up_rounded,
                            subtitle: 'Manual override (Tap to edit)',
                            isManual: true,
                            onEdit: () => _showEditCardValueDialog(
                                context, ref, 'profit'),
                            onTap: () => _showEditCardValueDialog(
                                context, ref, 'profit'),
                          )
                        else
                          _LoadingTile(),
                      ],
                    ],
                  ),
                  error: (e, _) => const _ErrorTile(label: 'Stats'),
                  data: (stats) => Column(
                    children: [
                      if (settings.showSoldTile) ...[
                        StatTile(
                          label: soldLabel,
                          value: isSoldManual
                              ? formatPeso(settings.manualSold!)
                              : formatPeso(stats.totalSold),
                          gradient: AppColors.soldGradient,
                          icon: Icons.shopping_bag_rounded,
                          subtitle: isSoldManual
                              ? 'Manual override (Tap to edit)'
                              : 'All-time revenue',
                          isManual: isSoldManual,
                          onEdit: () =>
                              _showEditCardValueDialog(context, ref, 'sold'),
                          onTap: () =>
                              _showEditCardValueDialog(context, ref, 'sold'),
                        ),
                        if (settings.showProfitTile) const SizedBox(height: 12),
                      ],
                      if (settings.showProfitTile)
                        StatTile(
                          label: profitLabel,
                          value: isProfitManual
                              ? formatPeso(settings.manualProfit!)
                              : formatPeso(stats.totalProfit),
                          gradient: (isProfitManual
                                      ? settings.manualProfit!
                                      : stats.totalProfit) >=
                                  0
                              ? AppColors.profitGradient
                              : [AppColors.error, const Color(0xFFB23636)],
                          icon: Icons.trending_up_rounded,
                          subtitle: isProfitManual
                              ? 'Manual override (Tap to edit)'
                              : 'Based on snapshotted cost prices',
                          isManual: isProfitManual,
                          onEdit: () =>
                              _showEditCardValueDialog(context, ref, 'profit'),
                          onTap: () =>
                              _showEditCardValueDialog(context, ref, 'profit'),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // ── Profit chart ─────────────────────────────────────────────────
          if (settings.showProfitChart) ...[
            SectionHeader(title: 'PROFIT (LAST ${settings.chartDays} DAYS)'),
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
          ],

          // ── Recent sales list ────────────────────────────────────────────
          if (settings.showRecentSales) ...[
            const SectionHeader(title: 'RECENT SALES'),
            const SizedBox(height: 12),
            _RecentSalesList(),
          ],
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
    final settings = ref.watch(dashboardSettingsProvider);
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
            final hasSellPrice = s.product.effectiveSellingPrice > 0;
            if (!hasSellPrice) unsetSellPriceCount++;

            final effSellPrice =
                hasSellPrice ? s.product.effectiveSellingPrice : s.latestCostPrice;
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
              if (!settings.showFutureBanner &&
                  !settings.showFutureBreakdown) ...[
                const SizedBox(height: 40),
                const EmptyState(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Future metric cards hidden',
                  subtitle:
                      'All future projection cards are currently hidden. Tap the menu (...) in the top right and select "Edit Dashboard" to enable cards.',
                ),
              ],
              // ── Future projections hero banner ─────────────────────────────
              if (settings.showFutureBanner) ...[
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
              ],

              const SizedBox(height: 24),

              // ── Product-by-Product Breakdown ──────────────────────────────
              if (settings.showFutureBreakdown) ...[
                const SectionHeader(title: 'PRODUCT-BY-PRODUCT PROJECTIONS'),
                const SizedBox(height: 12),

              ...inStockSummaries.map((s) {
                final hasSellPrice = s.product.effectiveSellingPrice > 0;
                final effSellPrice =
                    hasSellPrice ? s.product.effectiveSellingPrice : s.latestCostPrice;
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
                            'Sell: ${hasSellPrice ? formatPeso(s.product.effectiveSellingPrice) : 'Unset'} / kg',
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
