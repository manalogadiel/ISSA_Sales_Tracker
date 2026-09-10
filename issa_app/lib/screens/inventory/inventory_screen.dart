import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'package:drift/drift.dart' show Value;
import '../../widgets/common_widgets.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(inventorySummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.primary,
            iconSize: 28,
            tooltip: 'Add product',
            onPressed: () => _showAddProductDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: summaries.when(
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
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _ProductCard(summary: list[i]),
          );
        },
      ),
    );
  }

  Future<void> _showAddProductDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final costPriceCtrl = TextEditingController();
    final sellingPriceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
                    final n = double.tryParse(v.trim());
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
              final dao = ref.read(inventoryDaoProvider);
              final trimmedName = nameCtrl.text.trim();
              final existing =
                  await dao.findProductByNameCaseInsensitive(trimmedName);

              final sellPrice =
                  double.tryParse(sellingPriceCtrl.text.trim()) ?? 0.0;

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

              await dao.insertBatch(
                CapitalBatchesCompanion.insert(
                  productId: productId,
                  quantityAdded: double.parse(qtyCtrl.text.trim()),
                  remainingQuantity: double.parse(qtyCtrl.text.trim()),
                  costPrice: double.parse(costPriceCtrl.text.trim()),
                  source: BatchSource.manual,
                ),
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.summary});
  final InventorySummary summary;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final isLowStock = s.totalQuantity < 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock ? AppColors.warning.withAlpha(128) : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Product avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.category_rounded,
                        color: AppColors.primaryDeep, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? AppColors.warning.withAlpha(30)
                                    : AppColors.accentLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formatKg(s.totalQuantity),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isLowStock
                                      ? AppColors.warning
                                      : AppColors.primaryDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sell: ${s.product.sellingPrice > 0 ? formatPeso(s.product.sellingPrice) : 'Unset'} · Cost: ${formatPeso(s.latestCostPrice)}/kg',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  IconButton(
                    icon: const Icon(Icons.sell_outlined),
                    color: s.product.sellingPrice > 0
                        ? AppColors.primaryDeep
                        : AppColors.warning,
                    tooltip: 'Set selling price',
                    onPressed: () =>
                        _showEditSellingPriceDialog(context, s.product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box_outlined),
                    color: AppColors.primaryDeep,
                    tooltip: 'Add restock batch',
                    onPressed: () =>
                        _showAddBatchDialog(context, s.product.id),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded batch list
          if (_expanded) ...[
            const Divider(height: 1),
            ...s.batches.map(
              (batch) => _BatchTile(batch: batch, productName: s.product.name),
            ),
            // Add restock button at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton.icon(
                onPressed: () => _showAddBatchDialog(context, s.product.id),
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

  Future<void> _showAddBatchDialog(BuildContext context, int productId) async {
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Restock Batch'),
        content: Form(
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
              await dao.insertBatch(
                CapitalBatchesCompanion.insert(
                  productId: productId,
                  quantityAdded: qty,
                  remainingQuantity: qty,
                  costPrice: double.parse(priceCtrl.text),
                  source: BatchSource.manual,
                ),
              );
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
      text: product.sellingPrice > 0
          ? product.sellingPrice.toStringAsFixed(2)
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
                  helperText: 'Default price when selling this item',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter valid selling price';
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
              final val = double.parse(ctrl.text.trim());
              await ref.read(inventoryDaoProvider).updateProductSellingPrice(
                    id: product.id,
                    sellingPrice: val,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BatchTile extends ConsumerWidget {
  const _BatchTile({required this.batch, required this.productName});
  final CapitalBatch batch;
  final String productName;

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
            color:
                isExhausted ? AppColors.textHint : AppColors.textPrimary,
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
        trailing: isExhausted
            ? null
            : IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primaryDeep),
                tooltip: 'Edit batch',
                onPressed: () =>
                    _showEditBatchDialog(context, ref, batch),
              ),
      ),
    );
  }

  Future<void> _showEditBatchDialog(
      BuildContext context, WidgetRef ref, CapitalBatch batch) async {
    final qtyCtrl = TextEditingController(
        text: batch.remainingQuantity.toString());
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
                  border: Border.all(
                      color: AppColors.warning.withAlpha(77)),
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
              await ref.read(inventoryDaoProvider).patchBatch(
                    batchId: batch.id,
                    remainingQuantity: double.parse(qtyCtrl.text),
                    costPrice: double.parse(priceCtrl.text),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Save'),
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
