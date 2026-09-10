import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

enum _SortBy { name, costPrice, sellingPrice, stock }
enum _SortDir { asc, desc }

class CostTableScreen extends ConsumerStatefulWidget {
  const CostTableScreen({super.key});

  @override
  ConsumerState<CostTableScreen> createState() => _CostTableScreenState();
}

class _CostTableScreenState extends ConsumerState<CostTableScreen> {
  _SortBy _sortBy = _SortBy.name;
  _SortDir _sortDir = _SortDir.asc;

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
                  helperText: 'Default price when selling (leave empty or 0 to unset)',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = cleanParseNumber(v);
                  if (n == null || n < 0) return 'Invalid price (e.g. 250.00)';
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
              final price = cleanParseNumber(ctrl.text) ?? 0.0;
              try {
                await ref
                    .read(inventoryDaoProvider)
                    .updateProductSellingPrice(
                      id: product.id,
                      sellingPrice: price,
                    );
                ref.invalidate(inventorySummariesProvider);
                ref.invalidate(allProductsProvider);
                ref.invalidate(totalCapitalProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        price > 0
                            ? 'Selling price for ${product.name} saved (${formatPeso(price)}/kg)'
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

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(inventorySummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prices & Cost Table'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (v) {
              setState(() {
                switch (v) {
                  case 'name_asc':
                    _sortBy = _SortBy.name;
                    _sortDir = _SortDir.asc;
                  case 'name_desc':
                    _sortBy = _SortBy.name;
                    _sortDir = _SortDir.desc;
                  case 'cost_asc':
                    _sortBy = _SortBy.costPrice;
                    _sortDir = _SortDir.asc;
                  case 'cost_desc':
                    _sortBy = _SortBy.costPrice;
                    _sortDir = _SortDir.desc;
                  case 'sell_asc':
                    _sortBy = _SortBy.sellingPrice;
                    _sortDir = _SortDir.asc;
                  case 'sell_desc':
                    _sortBy = _SortBy.sellingPrice;
                    _sortDir = _SortDir.desc;
                  case 'stock_asc':
                    _sortBy = _SortBy.stock;
                    _sortDir = _SortDir.asc;
                  case 'stock_desc':
                    _sortBy = _SortBy.stock;
                    _sortDir = _SortDir.desc;
                }
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name_asc', child: Text('Name A→Z')),
              PopupMenuItem(value: 'name_desc', child: Text('Name Z→A')),
              PopupMenuItem(value: 'cost_asc', child: Text('Cost Low→High')),
              PopupMenuItem(value: 'cost_desc', child: Text('Cost High→Low')),
              PopupMenuItem(value: 'sell_asc', child: Text('Sell Low→High')),
              PopupMenuItem(value: 'sell_desc', child: Text('Sell High→Low')),
              PopupMenuItem(value: 'stock_asc', child: Text('Stock Low→High')),
              PopupMenuItem(value: 'stock_desc', child: Text('Stock High→Low')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: summaries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.table_chart_outlined,
              title: 'No products',
              subtitle: 'Add products in the Inventory tab first.',
            );
          }

          // Sort
          final sorted = [...list];
          sorted.sort((a, b) {
            int cmp;
            if (_sortBy == _SortBy.name) {
              cmp = a.product.name.compareTo(b.product.name);
            } else if (_sortBy == _SortBy.costPrice) {
              cmp = a.latestCostPrice.compareTo(b.latestCostPrice);
            } else if (_sortBy == _SortBy.sellingPrice) {
              cmp = a.product.effectiveSellingPrice
                  .compareTo(b.product.effectiveSellingPrice);
            } else {
              cmp = a.totalQuantity.compareTo(b.totalQuantity);
            }
            return _sortDir == _SortDir.asc ? cmp : -cmp;
          });

          return Column(
            children: [
              // Header row
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 12,
                      child: _HeaderCell(
                        label: 'Product',
                        active: _sortBy == _SortBy.name,
                        dir: _sortDir,
                        onTap: () => setState(() {
                          if (_sortBy == _SortBy.name) {
                            _sortDir = _sortDir == _SortDir.asc
                                ? _SortDir.desc
                                : _SortDir.asc;
                          } else {
                            _sortBy = _SortBy.name;
                            _sortDir = _SortDir.asc;
                          }
                        }),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _HeaderCell(
                          label: 'Cost/kg',
                          active: _sortBy == _SortBy.costPrice,
                          dir: _sortDir,
                          onTap: () => setState(() {
                            if (_sortBy == _SortBy.costPrice) {
                              _sortDir = _sortDir == _SortDir.asc
                                  ? _SortDir.desc
                                  : _SortDir.asc;
                            } else {
                              _sortBy = _SortBy.costPrice;
                              _sortDir = _SortDir.asc;
                            }
                          }),
                          align: TextAlign.right,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 9,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _HeaderCell(
                          label: 'Sell/kg',
                          active: _sortBy == _SortBy.sellingPrice,
                          dir: _sortDir,
                          onTap: () => setState(() {
                            if (_sortBy == _SortBy.sellingPrice) {
                              _sortDir = _sortDir == _SortDir.asc
                                  ? _SortDir.desc
                                  : _SortDir.asc;
                            } else {
                              _sortBy = _SortBy.sellingPrice;
                              _sortDir = _SortDir.asc;
                            }
                          }),
                          align: TextAlign.right,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _HeaderCell(
                          label: 'Stock',
                          active: _sortBy == _SortBy.stock,
                          dir: _sortDir,
                          onTap: () => setState(() {
                            if (_sortBy == _SortBy.stock) {
                              _sortDir = _sortDir == _SortDir.asc
                                  ? _SortDir.desc
                                  : _SortDir.asc;
                            } else {
                              _sortBy = _SortBy.stock;
                              _sortDir = _SortDir.asc;
                            }
                          }),
                          align: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table rows
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14)),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = sorted[i];
                      final isLow = s.totalQuantity < 1.0;
                      return Container(
                        color: i.isEven ? AppColors.background : AppColors.surface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Product Name
                            Expanded(
                              flex: 12,
                              child: Text(
                                s.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Cost / kg
                            Expanded(
                              flex: 7,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    formatPeso(s.latestCostPrice),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Sell / kg (Editable)
                            Expanded(
                              flex: 9,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () => _showEditSellingPriceDialog(
                                        context, s.product),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 2),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              s.product.effectiveSellingPrice > 0
                                                  ? formatPeso(s.product.effectiveSellingPrice)
                                                  : 'Set ₱',
                                              maxLines: 1,
                                              softWrap: false,
                                              style: TextStyle(
                                                fontFamily: 'Nunito',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: s.product.effectiveSellingPrice > 0
                                                    ? AppColors.success
                                                    : AppColors.warning,
                                                decoration:
                                                    s.product.effectiveSellingPrice == 0
                                                        ? TextDecoration.underline
                                                        : null,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 13,
                                              color: s.product.effectiveSellingPrice > 0
                                                  ? AppColors.success.withAlpha(160)
                                                  : AppColors.warning,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // In Stock
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    formatKg(s.totalQuantity),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isLow
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.active,
    required this.dir,
    required this.onTap,
    this.align = TextAlign.left,
  });

  final String label;
  final bool active;
  final _SortDir dir;
  final VoidCallback onTap;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: align == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.white70,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(
                dir == _SortDir.asc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 13,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
