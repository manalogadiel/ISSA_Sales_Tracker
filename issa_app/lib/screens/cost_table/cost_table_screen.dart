import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

enum _SortBy { name, price }
enum _SortDir { asc, desc }

class CostTableScreen extends ConsumerStatefulWidget {
  const CostTableScreen({super.key});

  @override
  ConsumerState<CostTableScreen> createState() => _CostTableScreenState();
}

class _CostTableScreenState extends ConsumerState<CostTableScreen> {
  _SortBy _sortBy = _SortBy.name;
  _SortDir _sortDir = _SortDir.asc;

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(inventorySummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cost Price Table'),
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
                  case 'price_asc':
                    _sortBy = _SortBy.price;
                    _sortDir = _SortDir.asc;
                  case 'price_desc':
                    _sortBy = _SortBy.price;
                    _sortDir = _SortDir.desc;
                }
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name_asc', child: Text('Name A→Z')),
              PopupMenuItem(value: 'name_desc', child: Text('Name Z→A')),
              PopupMenuItem(value: 'price_asc', child: Text('Price Low→High')),
              PopupMenuItem(value: 'price_desc', child: Text('Price High→Low')),
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
            } else {
              cmp = a.latestCostPrice.compareTo(b.latestCostPrice);
            }
            return _sortDir == _SortDir.asc ? cmp : -cmp;
          });

          return Column(
            children: [
              // Header row
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
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
                      flex: 2,
                      child: _HeaderCell(
                        label: 'Latest Price',
                        active: _sortBy == _SortBy.price,
                        dir: _sortDir,
                        onTap: () => setState(() {
                          if (_sortBy == _SortBy.price) {
                            _sortDir = _sortDir == _SortDir.asc
                                ? _SortDir.desc
                                : _SortDir.asc;
                          } else {
                            _sortBy = _SortBy.price;
                            _sortDir = _SortDir.asc;
                          }
                        }),
                        align: TextAlign.right,
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'In Stock',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                s.product.name,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                formatPeso(s.latestCostPrice),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                formatKg(s.totalQuantity),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isLow
                                      ? AppColors.error
                                      : AppColors.textSecondary,
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
      child: Row(
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
            const SizedBox(width: 4),
            Icon(
              dir == _SortDir.asc
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}
