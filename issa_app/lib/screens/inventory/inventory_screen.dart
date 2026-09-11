import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isDeleteMode = false;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(inventorySummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.primary,
            iconSize: 28,
            tooltip: 'Add product',
            onPressed: () => _showAddProductDialog(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Inventory options',
            onSelected: (val) {
              if (val == 'toggle_delete') {
                setState(() => _isDeleteMode = !_isDeleteMode);
              } else if (val == 'toggle_view') {
                setState(() => _isGridView = !_isGridView);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle_delete',
                child: Row(
                  children: [
                    Icon(
                      _isDeleteMode
                          ? Icons.check_circle_outline_rounded
                          : Icons.delete_outline_rounded,
                      size: 20,
                      color: _isDeleteMode ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isDeleteMode ? 'Exit Delete Mode' : 'Delete Mode',
                      style: TextStyle(
                        color:
                            _isDeleteMode ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_view',
                child: Row(
                  children: [
                    Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      size: 20,
                      color: AppColors.primaryDeep,
                    ),
                    const SizedBox(width: 12),
                    Text(
                        _isGridView ? 'Top-to-Down View' : 'Grid View (2-Col)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Banner when Delete Mode is Active
          if (_isDeleteMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.error.withAlpha(25),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Delete Mode Active — tap trash icons to delete items',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isDeleteMode = false),
                    child: const Text('Done',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

          // Main Inventory Content
          Expanded(
            child: summaries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products yet',
                    subtitle: 'Add your first product to get started.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddProductDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Product'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48)),
                    ),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _ProductGridCard(
                      summary: list[i],
                      isDeleteMode: _isDeleteMode,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ProductCard(
                    summary: list[i],
                    isDeleteMode: _isDeleteMode,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProductDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final costPriceCtrl = TextEditingController();
    final sellingPriceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final summaries = ref.read(inventorySummariesProvider).valueOrNull ?? [];
    nameCtrl.addListener(() {
      final input = nameCtrl.text.trim().toLowerCase();
      final match = summaries.where((s) => s.product.name.trim().toLowerCase() == input).firstOrNull;
      if (match != null) {
        if (costPriceCtrl.text.isEmpty && match.latestCostPrice > 0) {
          costPriceCtrl.text = match.latestCostPrice.truncateToDouble() == match.latestCostPrice
              ? match.latestCostPrice.toInt().toString()
              : match.latestCostPrice.toStringAsFixed(2);
        }
        if (sellingPriceCtrl.text.isEmpty && match.product.effectiveSellingPrice > 0) {
          sellingPriceCtrl.text = match.product.effectiveSellingPrice.truncateToDouble() == match.product.effectiveSellingPrice
              ? match.product.effectiveSellingPrice.toInt().toString()
              : match.product.effectiveSellingPrice.toStringAsFixed(2);
        }
      }
    });

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Product / Restock'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                    helperText: 'Case-insensitive (matches existing item)',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (kg)',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.scale_outlined),
                    helperText: 'Enter 0 to add product without initial stock',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter valid quantity';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: costPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cost price per kg (₱)',
                    prefixIcon: Icon(Icons.price_change_outlined),
                    prefixText: '₱ ',
                    helperText: 'Your purchase/capital cost',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter valid cost price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sellingPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Selling price per kg (₱)',
                    prefixIcon: Icon(Icons.sell_outlined),
                    prefixText: '₱ ',
                    helperText: 'Default price when selling (optional)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = cleanParseNumber(v);
                    if (n == null || n < 0) return 'Enter valid selling price';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final dao = ref.read(inventoryDaoProvider);
                final trimmedName = nameCtrl.text.trim();
                final existing =
                    await dao.findProductByNameCaseInsensitive(trimmedName);

                final sellPrice =
                    cleanParseNumber(sellingPriceCtrl.text) ?? 0.0;

                int productId;
                if (existing != null) {
                  productId = existing.id;
                  if (sellPrice > 0) {
                    await dao.updateProductSellingPrice(
                      id: productId,
                      sellingPrice: sellPrice,
                    );
                  }
                } else {
                  productId = await dao.insertProduct(
                    ProductsCompanion.insert(
                      name: trimmedName,
                      sellingPrice: Value(sellPrice),
                    ),
                  );
                }

                final qty = cleanParseNumber(qtyCtrl.text) ?? 1.0;
                final costPrice = cleanParseNumber(costPriceCtrl.text) ?? 0.0;

                if (qty > 0) {
                  await dao.insertBatch(
                    CapitalBatchesCompanion.insert(
                      productId: productId,
                      quantityAdded: qty,
                      remainingQuantity: qty,
                      costPrice: costPrice,
                      source: BatchSource.manual,
                    ),
                  );

                  ref
                      .read(dashboardSettingsProvider.notifier)
                      .onStockAdded(qty * costPrice);
                }
                ref.invalidate(inventorySummariesProvider);
                ref.invalidate(allProductsProvider);
                ref.invalidate(totalCapitalProvider);

                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving product: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// List View Card
// ────────────────────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({
    required this.summary,
    required this.isDeleteMode,
  });

  final InventorySummary summary;
  final bool isDeleteMode;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final isLowStock = s.totalQuantity < 1.0;
    final appearanceMap = ref.watch(productAppearanceProvider);
    final appearance = appearanceMap[s.product.id];
    final defaultColor =
        ProductColorPresets.defaultForProduct(s.product.id, s.product.name);
    final displayColor = appearance?.color ?? defaultColor;
    final hasImage = appearance?.imagePath != null &&
        File(appearance!.imagePath!).existsSync();

    final sellPrice = s.product.effectiveSellingPrice;
    final costPrice = s.latestCostPrice;
    final hasProfit = sellPrice > 0;
    final profitDiff = sellPrice - costPrice;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock
              ? AppColors.warning.withAlpha(128)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Avatar + Product Name + Stock Badge + Chevron
                  Row(
                    children: [
                      // Product Avatar / Photo Thumbnail
                      GestureDetector(
                        onTap: () => _showCustomizeAppearanceDialog(
                            context, ref, s.product),
                        child: Tooltip(
                          message: 'Tap to change color or photo',
                          child: Stack(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: displayColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.black12, width: 1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasImage
                                    ? Image.file(
                                        File(appearance.imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          s.product.name.isNotEmpty
                                              ? s.product.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black26, blurRadius: 2)
                                    ],
                                  ),
                                  child: const Icon(Icons.palette_rounded,
                                      size: 11, color: AppColors.primaryDeep),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name and Stock badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.product.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? AppColors.warning.withAlpha(25)
                                    : AppColors.accentLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isLowStock
                                      ? AppColors.warning.withAlpha(80)
                                      : AppColors.divider,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 13,
                                    color: isLowStock
                                        ? AppColors.warning
                                        : AppColors.primaryDeep,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${formatKg(s.totalQuantity)} in stock',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isLowStock
                                          ? AppColors.warning
                                          : AppColors.primaryDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron indicator
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Row 2: Detail chips (Sell Price, Cost Price, Profit)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Selling price chip
                      InkWell(
                        onTap: () =>
                            _showEditSellingPriceDialog(context, s.product),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sellPrice > 0
                                ? AppColors.success.withAlpha(20)
                                : AppColors.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sellPrice > 0
                                  ? AppColors.success.withAlpha(80)
                                  : AppColors.warning.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sell_outlined,
                                size: 13,
                                color: sellPrice > 0
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sellPrice > 0
                                    ? 'Sell: ${formatPeso(sellPrice)}'
                                    : 'Sell: Set ₱',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: sellPrice > 0
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.edit_outlined,
                                size: 11,
                                color: sellPrice > 0
                                    ? AppColors.success.withAlpha(180)
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cost price chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.price_change_outlined,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Cost: ${formatPeso(costPrice)}/kg',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profit spread chip
                      if (hasProfit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: profitDiff >= 0
                                ? Colors.green.withAlpha(20)
                                : AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profitDiff >= 0
                                ? '+${formatPeso(profitDiff)} profit/kg'
                                : '${formatPeso(profitDiff)} loss/kg',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: profitDiff >= 0
                                  ? Colors.green.shade800
                                  : AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Row 3: Action Buttons (Add batch, Color picker, Delete if mode active)
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _showCustomizeAppearanceDialog(context, ref, s.product),
                        icon: const Icon(Icons.palette_outlined, size: 16),
                        label: const Text('Color / Photo',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () =>
                            _showAddBatchDialog(context, s.product.id, s.latestCostPrice),
                        icon: const Icon(Icons.add_box_outlined, size: 16),
                        label: const Text('Add Restock',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      // DELETE BUTTON ONLY IN DELETE MODE
                      if (widget.isDeleteMode) ...[
                        const SizedBox(width: 4),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              _showDeleteProductDialog(context, s),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.error),
                          label: const Text('Delete',
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error.withAlpha(30),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded batch list
          if (_expanded) ...[
            const Divider(height: 1),
            ...s.batches.map(
              (batch) => _BatchTile(
                batch: batch,
                productName: s.product.name,
                isDeleteMode: widget.isDeleteMode,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showAddBatchDialog(context, s.product.id, s.latestCostPrice),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Restock Batch'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddBatchDialog(BuildContext context, int productId,
      [double? defaultCostPrice]) async {
    final qtyCtrl = TextEditingController(text: '1');
    final initialPrice = (defaultCostPrice != null && defaultCostPrice > 0)
        ? (defaultCostPrice.truncateToDouble() == defaultCostPrice
            ? defaultCostPrice.toInt().toString()
            : defaultCostPrice.toStringAsFixed(2))
        : '';
    final priceCtrl = TextEditingController(text: initialPrice);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Restock Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity added (kg)',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter valid quantity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cost price per kg (₱)',
                      prefixText: '₱ ',
                      prefixIcon: Icon(Icons.price_change_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final dao = ref.read(inventoryDaoProvider);
              final qty = double.parse(qtyCtrl.text);
              final price = double.parse(priceCtrl.text);
              await dao.insertBatch(
                CapitalBatchesCompanion.insert(
                  productId: productId,
                  quantityAdded: qty,
                  remainingQuantity: qty,
                  costPrice: price,
                  source: BatchSource.manual,
                ),
              );
              ref
                  .read(dashboardSettingsProvider.notifier)
                  .onStockAdded(qty * price);
              ref.invalidate(inventorySummariesProvider);
              ref.invalidate(totalCapitalProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSellingPriceDialog(
      BuildContext context, Product product) async {
    final ctrl = TextEditingController(
      text: product.effectiveSellingPrice > 0
          ? product.effectiveSellingPrice.toStringAsFixed(2)
          : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Selling Price: ${product.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Selling price per kg (₱)',
                  prefixText: '₱ ',
                  prefixIcon: Icon(Icons.sell_outlined),
                  helperText:
                      'Default price when selling (leave empty or 0 to unset)',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = cleanParseNumber(v);
                  if (n == null || n < 0) {
                    return 'Enter valid selling price (e.g. 250.00)';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final val = cleanParseNumber(ctrl.text) ?? 0.0;
              try {
                await ref.read(inventoryDaoProvider).updateProductSellingPrice(
                      id: product.id,
                      sellingPrice: val,
                    );
                ref.invalidate(inventorySummariesProvider);
                ref.invalidate(allProductsProvider);
                ref.invalidate(totalCapitalProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val > 0
                            ? 'Selling price for ${product.name} saved (${formatPeso(val)}/kg)'
                            : 'Selling price for ${product.name} unset',
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save selling price: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteProductDialog(
      BuildContext context, InventorySummary s) async {
    final dao = ref.read(inventoryDaoProvider);
    final salesCount = await dao.salesCountForProduct(s.product.id);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${s.product.name}"?',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            if (s.totalQuantity > 0)
              Text(
                '• Current inventory of ${formatKg(s.totalQuantity)} (${s.batches.length} batch${s.batches.length == 1 ? '' : 'es'}) will be removed.',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            if (salesCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This product has $salesCount recorded sale${salesCount == 1 ? '' : 's'}. Deleting it will also remove its sales history.',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final productVal = s.batches.fold<double>(
                  0.0, (acc, b) => acc + b.remainingQuantity * b.costPrice);
              if (salesCount > 0) {
                await dao.deleteProductCascade(s.product.id);
              } else {
                await dao.deleteProduct(s.product.id);
              }
              ref
                  .read(dashboardSettingsProvider.notifier)
                  .onStockRemoved(productVal);
              ref.invalidate(inventorySummariesProvider);
              ref.invalidate(allProductsProvider);
              ref.invalidate(totalCapitalProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('"${s.product.name}" deleted from inventory.'),
                    backgroundColor: AppColors.textPrimary,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 2-Column Grid View Card
// ────────────────────────────────────────────────────────────────────────────

class _ProductGridCard extends ConsumerWidget {
  const _ProductGridCard({
    required this.summary,
    required this.isDeleteMode,
  });

  final InventorySummary summary;
  final bool isDeleteMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final isLowStock = s.totalQuantity < 1.0;
    final appearanceMap = ref.watch(productAppearanceProvider);
    final appearance = appearanceMap[s.product.id];
    final defaultColor =
        ProductColorPresets.defaultForProduct(s.product.id, s.product.name);
    final displayColor = appearance?.color ?? defaultColor;
    final hasImage = appearance?.imagePath != null &&
        File(appearance!.imagePath!).existsSync();

    final sellPrice = s.product.effectiveSellingPrice;
    final costPrice = s.latestCostPrice;

    return InkWell(
      onTap: () => _showBatchDetailsModal(context, ref, s, isDeleteMode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowStock
                ? AppColors.warning.withAlpha(128)
                : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Color Header Banner
            Stack(
              children: [
                Container(
                  height: 72,
                  width: double.infinity,
                  color: displayColor,
                  child: hasImage
                      ? Image.file(
                          File(appearance.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            s.product.name.isNotEmpty
                                ? s.product.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                          ),
                        ),
                ),
                // Color customization icon button on banner
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(90),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.palette_rounded,
                          size: 14, color: Colors.white),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Color / Photo',
                      onPressed: () => _showCustomizeAppearanceDialog(
                          context, ref, s.product),
                    ),
                  ),
                ),
                // Delete button in top left if Delete Mode is active
                if (isDeleteMode)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 14, color: Colors.white),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete Product',
                        onPressed: () =>
                            _showDeleteProductDialog(context, ref, s),
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.product.name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Stock chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? AppColors.warning.withAlpha(25)
                            : AppColors.accentLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatKg(s.totalQuantity),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isLowStock
                              ? AppColors.warning
                              : AppColors.primaryDeep,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Price Chips
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sellPrice > 0 ? formatPeso(sellPrice) : 'No price',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: sellPrice > 0
                                  ? AppColors.success
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                        Text(
                          '${formatPeso(costPrice)}c',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Card bottom action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showAddBatchDialog(
                                context, ref, s.product.id, s.latestCostPrice),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 28),
                            ),
                            child: const Text('+ Restock',
                                style: TextStyle(fontSize: 11)),
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

  void _showBatchDetailsModal(BuildContext context, WidgetRef ref,
      InventorySummary s, bool isDeleteMode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.product.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${formatKg(s.totalQuantity)} in stock',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Sell: ${s.product.effectiveSellingPrice > 0 ? formatPeso(s.product.effectiveSellingPrice) : 'Unset'} · Cost: ${formatPeso(s.latestCostPrice)}/kg',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'INVENTORY BATCHES',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            if (s.batches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No batches found for this product.',
                       style: TextStyle(color: AppColors.textHint)),
                ),
              )
            else
              ...s.batches.map(
                (batch) => _BatchTile(
                  batch: batch,
                  productName: s.product.name,
                  isDeleteMode: isDeleteMode,
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddBatchDialog(context, ref, s.product.id, s.latestCostPrice);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Restock Batch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBatchDialog(
      BuildContext context, WidgetRef ref, int productId,
      [double? defaultCostPrice]) async {
    final qtyCtrl = TextEditingController(text: '1');
    final initialPrice = (defaultCostPrice != null && defaultCostPrice > 0)
        ? (defaultCostPrice.truncateToDouble() == defaultCostPrice
            ? defaultCostPrice.toInt().toString()
            : defaultCostPrice.toStringAsFixed(2))
        : '';
    final priceCtrl = TextEditingController(text: initialPrice);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Restock Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity added (kg)',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter valid quantity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cost price per kg (₱)',
                      prefixText: '₱ ',
                      prefixIcon: Icon(Icons.price_change_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final dao = ref.read(inventoryDaoProvider);
              final qty = double.parse(qtyCtrl.text);
              final price = double.parse(priceCtrl.text);
              await dao.insertBatch(
                CapitalBatchesCompanion.insert(
                  productId: productId,
                  quantityAdded: qty,
                  remainingQuantity: qty,
                  costPrice: price,
                  source: BatchSource.manual,
                ),
              );
              ref
                  .read(dashboardSettingsProvider.notifier)
                  .onStockAdded(qty * price);
              ref.invalidate(inventorySummariesProvider);
              ref.invalidate(totalCapitalProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteProductDialog(
      BuildContext context, WidgetRef ref, InventorySummary s) async {
    final dao = ref.read(inventoryDaoProvider);
    final salesCount = await dao.salesCountForProduct(s.product.id);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${s.product.name}"?',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            if (s.totalQuantity > 0)
              Text(
                '• Current inventory of ${formatKg(s.totalQuantity)} (${s.batches.length} batch${s.batches.length == 1 ? '' : 'es'}) will be removed.',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            if (salesCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This product has $salesCount recorded sale${salesCount == 1 ? '' : 's'}. Deleting it will also remove its sales history.',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final productVal = s.batches.fold<double>(
                  0.0, (acc, b) => acc + b.remainingQuantity * b.costPrice);
              if (salesCount > 0) {
                await dao.deleteProductCascade(s.product.id);
              } else {
                await dao.deleteProduct(s.product.id);
              }
              ref
                  .read(dashboardSettingsProvider.notifier)
                  .onStockRemoved(productVal);
              ref.invalidate(inventorySummariesProvider);
              ref.invalidate(allProductsProvider);
              ref.invalidate(totalCapitalProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('"${s.product.name}" deleted from inventory.'),
                    backgroundColor: AppColors.textPrimary,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sub-container (Batch Tile)
// ────────────────────────────────────────────────────────────────────────────

class _BatchTile extends ConsumerWidget {
  const _BatchTile({
    required this.batch,
    required this.productName,
    required this.isDeleteMode,
  });

  final CapitalBatch batch;
  final String productName;
  final bool isDeleteMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr =
        '${batch.timestamp.day} ${_monthName(batch.timestamp.month)} ${batch.timestamp.year}';
    final isExhausted = batch.remainingQuantity <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isExhausted
            ? AppColors.background
            : AppColors.accentLight.withAlpha(128),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isExhausted ? AppColors.textHint : AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          '${formatKg(batch.remainingQuantity)} remaining '
          '(${formatKg(batch.quantityAdded)} added)',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isExhausted ? AppColors.textHint : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${formatPeso(batch.costPrice)}/kg · $dateStr · ${batch.source.name}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isExhausted)
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primaryDeep),
                tooltip: 'Edit batch',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showEditBatchDialog(context, ref, batch),
              ),
            // DELETE BUTTON ONLY VISIBLE IN DELETE MODE
            if (isDeleteMode)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.error),
                tooltip: 'Delete batch',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showDeleteBatchDialog(context, ref, batch),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditBatchDialog(
      BuildContext context, WidgetRef ref, CapitalBatch batch) async {
    final qtyCtrl =
        TextEditingController(text: batch.remainingQuantity.toString());
    final priceCtrl =
        TextEditingController(text: batch.costPrice.toString());
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Batch'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withAlpha(77)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing a batch only affects this lot and future sales. Past sales are unaffected.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remaining quantity (kg)',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter valid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cost price per kg (₱)',
                  prefixText: '₱ ',
                  prefixIcon: Icon(Icons.price_change_outlined),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter valid price';
                  return null;
                },
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newQty = double.parse(qtyCtrl.text);
              final newPrice = double.parse(priceCtrl.text);
              final oldCapital = batch.remainingQuantity * batch.costPrice;
              final newCapital = newQty * newPrice;
              final diff = newCapital - oldCapital;

              await ref.read(inventoryDaoProvider).patchBatch(
                    batchId: batch.id,
                    remainingQuantity: newQty,
                    costPrice: newPrice,
                  );
              if (diff > 0) {
                ref.read(dashboardSettingsProvider.notifier).onStockAdded(diff);
              } else if (diff < 0) {
                ref.read(dashboardSettingsProvider.notifier).onStockRemoved(-diff);
              }
              ref.invalidate(inventorySummariesProvider);
              ref.invalidate(totalCapitalProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteBatchDialog(
      BuildContext context, WidgetRef ref, CapitalBatch batch) async {
    final dao = ref.read(inventoryDaoProvider);
    final allocCount = await dao.allocationsCountForBatch(batch.id);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Batch'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove this restock batch of ${formatKg(batch.quantityAdded)} (${formatKg(batch.remainingQuantity)} remaining @ ${formatPeso(batch.costPrice)}/kg)?',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            ),
            if (allocCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withAlpha(100)),
                ),
                child: const Text(
                  'Note: This batch has been partially or fully sold in past transactions. Deleting it will also remove its associated sale cost allocations.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final batchVal = batch.remainingQuantity * batch.costPrice;
              if (allocCount > 0) {
                await dao.deleteBatchCascade(batch.id);
              } else {
                await dao.deleteBatch(batch.id);
              }
              ref.read(dashboardSettingsProvider.notifier).onStockRemoved(batchVal);
              ref.invalidate(inventorySummariesProvider);
              ref.invalidate(totalCapitalProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restock batch removed.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}

// ────────────────────────────────────────────────────────────────────────────
// Appearance Customization Dialog (Color palette + Image upload)
// ────────────────────────────────────────────────────────────────────────────

Future<void> _showCustomizeAppearanceDialog(
    BuildContext context, WidgetRef ref, Product product) async {
  final defaultColor =
      ProductColorPresets.defaultForProduct(product.id, product.name);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final currentApp = ref.watch(productAppearanceProvider)[product.id];
        final displayColor = currentApp?.color ?? defaultColor;
        final hasImage = currentApp?.imagePath != null &&
            File(currentApp!.imagePath!).existsSync();

        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: displayColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.file(File(currentApp.imagePath!),
                            fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              product.name.isNotEmpty
                                  ? product.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pick a color or upload a product photo',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'COLOR PALETTE',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ProductColorPresets.palette.map((c) {
                  final isSelected = displayColor.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () async {
                      await ref
                          .read(productAppearanceProvider.notifier)
                          .setColor(product.id, c);
                      setModalState(() {});
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.black12,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withAlpha(120),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'PRODUCT PHOTO',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (img != null) {
                          await ref
                              .read(productAppearanceProvider.notifier)
                              .setImage(product.id, img.path);
                          setModalState(() {});
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (img != null) {
                          await ref
                              .read(productAppearanceProvider.notifier)
                              .setImage(product.id, img.path);
                          setModalState(() {});
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (hasImage) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(productAppearanceProvider.notifier)
                          .setImage(product.id, null);
                      setModalState(() {});
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.error),
                    label: const Text('Remove Photo',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
