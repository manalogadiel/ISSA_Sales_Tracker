import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  Product? _selectedProduct;
  double _quantity = 0.5;
  final _priceCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _isGridView = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(inventorySummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sell')),
      body: summaries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'No products',
              subtitle: 'Add products in the Inventory tab first.',
            );
          }

          final activeList =
              list.where((s) => s.totalQuantity > 0).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product picker
                SectionHeader(
                  title: 'SELECT PRODUCT',
                  trailing: IconButton(
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      size: 20,
                      color: AppColors.primaryDeep,
                    ),
                    tooltip: _isGridView ? 'List View' : 'Grid View',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ),
                const SizedBox(height: 10),
                if (activeList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Text(
                      'All products are out of stock.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else if (_isGridView)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                    children: activeList
                        .map((s) => _ProductGridOption(
                              summary: s,
                              selected: _selectedProduct?.id == s.product.id,
                              onTap: () => setState(() {
                                _selectedProduct = s.product;
                                _quantity = 0.5;
                                final defaultPrice =
                                    s.product.effectiveSellingPrice > 0
                                        ? s.product.effectiveSellingPrice
                                        : s.latestCostPrice;
                                _priceCtrl.text =
                                    defaultPrice.toStringAsFixed(2);
                              }),
                            ))
                        .toList(),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: activeList
                          .map((s) => _ProductOption(
                                summary: s,
                                selected: _selectedProduct?.id == s.product.id,
                                onTap: () => setState(() {
                                  _selectedProduct = s.product;
                                  _quantity = 0.5;
                                  final defaultPrice =
                                      s.product.effectiveSellingPrice > 0
                                          ? s.product.effectiveSellingPrice
                                          : s.latestCostPrice;
                                  _priceCtrl.text =
                                      defaultPrice.toStringAsFixed(2);
                                }),
                              ))
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 24),

                if (_selectedProduct != null) ...[
                  // Quantity stepper
                  const SectionHeader(title: 'QUANTITY TO SELL'),
                  const SizedBox(height: 10),
                  Center(
                    child: KgStepper(
                      value: _quantity,
                      onChanged: (v) => setState(() => _quantity = v),
                      max: _maxQty(list),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sell price
                  const SectionHeader(title: 'SELL PRICE (₱/KG)'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Sell price per kg',
                      prefixText: '₱ ',
                      prefixIcon: const Icon(Icons.sell_outlined),
                      helperText: _selectedProduct != null &&
                              _selectedProduct!.effectiveSellingPrice > 0
                          ? 'Pre-filled from set selling price — tap to edit'
                          : 'Auto-filled from latest cost price — tap to edit',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // Order summary card
                  _OrderSummaryCard(
                    product: _selectedProduct!,
                    quantity: _quantity,
                    sellPrice: double.tryParse(_priceCtrl.text) ?? 0,
                    latestCostPrice: list
                        .firstWhere((s) => s.product.id == _selectedProduct!.id)
                        .latestCostPrice,
                  ),

                  const SizedBox(height: 24),

                  // Confirm button
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : () => _confirmSale(list),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Confirm Sale'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  double _maxQty(List<InventorySummary> list) {
    if (_selectedProduct == null) return 999;
    final s =
        list.where((s) => s.product.id == _selectedProduct!.id).firstOrNull;
    return s?.totalQuantity ?? 0;
  }

  Future<void> _confirmSale(List<InventorySummary> list) async {
    final sellPrice = double.tryParse(_priceCtrl.text);
    if (_selectedProduct == null || sellPrice == null || sellPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid sell price.')),
      );
      return;
    }
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final invDao = ref.read(inventoryDaoProvider);
      final salesDao = ref.read(salesDaoProvider);
      final batches =
          await invDao.batchesForProduct(_selectedProduct!.id);
      final availableBatches =
          batches.where((b) => b.remainingQuantity > 0).toList();

      await salesDao.recordSale(
        productId: _selectedProduct!.id,
        quantitySold: _quantity,
        sellPrice: sellPrice,
        availableBatches: availableBatches,
      );

      if (mounted) {
        setState(() {
          _selectedProduct = null;
          _quantity = 0.5;
          _priceCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sale recorded: ${formatKg(_quantity)} sold.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _ProductOption extends ConsumerWidget {
  const _ProductOption({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final InventorySummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearanceMap = ref.watch(productAppearanceProvider);
    final appearance = appearanceMap[summary.product.id];
    final defaultColor = ProductColorPresets.defaultForProduct(
        summary.product.id, summary.product.name);
    final displayColor = appearance?.color ?? defaultColor;
    final hasImage = appearance?.imagePath != null &&
        File(appearance!.imagePath!).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: AppColors.primaryDeep, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.file(File(appearance.imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        summary.product.name.isNotEmpty
                            ? summary.product.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.product.name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${formatKg(summary.totalQuantity)} available · '
                    '${summary.product.effectiveSellingPrice > 0 ? "Sell: ${formatPeso(summary.product.effectiveSellingPrice)}" : "Cost: ${formatPeso(summary.latestCostPrice)}"}/kg',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ProductGridOption extends ConsumerWidget {
  const _ProductGridOption({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final InventorySummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearanceMap = ref.watch(productAppearanceProvider);
    final appearance = appearanceMap[summary.product.id];
    final defaultColor = ProductColorPresets.defaultForProduct(
        summary.product.id, summary.product.name);
    final displayColor = appearance?.color ?? defaultColor;
    final hasImage = appearance?.imagePath != null &&
        File(appearance!.imagePath!).existsSync();

    final sellPrice = summary.product.effectiveSellingPrice;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withAlpha(40)
                  : Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Color or Photo Banner
            Container(
              height: 44,
              width: double.infinity,
              color: displayColor,
              child: Stack(
                children: [
                  if (hasImage)
                    Positioned.fill(
                      child: Image.file(
                        File(appearance.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        summary.product.name.isNotEmpty
                            ? summary.product.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  if (selected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.product.name,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryDeep
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sellPrice > 0 ? formatPeso(sellPrice) : 'Set ₱',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: sellPrice > 0
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        Text(
                          formatKg(summary.totalQuantity),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.product,
    required this.quantity,
    required this.sellPrice,
    required this.latestCostPrice,
  });

  final Product product;
  final double quantity;
  final double sellPrice;
  final double latestCostPrice;

  @override
  Widget build(BuildContext context) {
    final revenue = quantity * sellPrice;
    final estimatedCost = quantity * latestCostPrice;
    final estimatedProfit = revenue - estimatedCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Product', value: product.name),
          _SummaryRow(
              label: 'Quantity', value: formatKg(quantity)),
          _SummaryRow(
              label: 'Sell Price',
              value: '${formatPeso(sellPrice)}/kg'),
          const Divider(height: 16),
          _SummaryRow(
              label: 'Total Revenue',
              value: formatPeso(revenue),
              bold: true),
          _SummaryRow(
              label: 'Est. Profit',
              value: formatPeso(estimatedProfit),
              bold: true,
              color: estimatedProfit >= 0
                  ? AppColors.success
                  : AppColors.error),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: color ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
