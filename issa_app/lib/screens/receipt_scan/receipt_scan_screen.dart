import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'receipt_ocr_parser.dart';

/// A candidate line item parsed from OCR output.
class _OcrLineItem {
  _OcrLineItem({
    required this.rawText,
    this.productName = '',
    this.quantity = 0.0,
    this.costPrice = 0.0,
    this.confirmed = true,
  });

  final String rawText;
  String productName;
  double quantity;
  double costPrice;
  bool confirmed;
  bool excluded = false;
}

class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() =>
      _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  File? _imageFile;
  bool _isScanning = false;
  bool _isCommitting = false;
  List<_OcrLineItem> _lineItems = [];
  bool _showReview = false;

  final _picker = ImagePicker();
  final _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scan'),
        actions: [
          if (_showReview)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('New Scan'),
            ),
          const SizedBox(width:8),
        ],
      ),
      body: _showReview
          ? _ReviewBody(
              items: _lineItems,
              onItemChanged: (i, item) =>
                  setState(() => _lineItems[i] = item),
              onItemDeleted: (i) =>
                  setState(() => _lineItems.removeAt(i)),
              onAddItem: _showManualAddItemDialog,
              onCommit: _commitConfirmed,
              isCommitting: _isCommitting,
            )
          : _ScanBody(
              imageFile: _imageFile,
              isScanning: _isScanning,
              onPickCamera: () => _pickImage(ImageSource.camera),
              onPickGallery: () => _pickImage(ImageSource.gallery),
            ),
    );
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _lineItems = [];
      _showReview = false;
      _isScanning = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
        source: source, imageQuality: 90, maxWidth: 1600);
    if (xFile == null) return;

    final file = File(xFile.path);
    setState(() {
      _imageFile = file;
      _isScanning = true;
    });

    try {
      final inputImage = InputImage.fromFile(file);
      final recognized = await _textRecognizer.processImage(inputImage);
      final existingProducts =
          ref.read(allProductsProvider).valueOrNull?.map((p) => p.name).toList();
      final parser = ReceiptOcrParser(customProducts: existingProducts);
      final parsedItems = parser.parseRecognizedText(recognized);
      final items = parsedItems
          .map((p) => _OcrLineItem(
                rawText: p.rawText,
                productName: p.productName,
                quantity: p.quantity,
                costPrice: p.costPrice,
                confirmed: true,
              ))
          .toList();

      setState(() {
        _lineItems = items;
        _isScanning = false;
        _showReview = true;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR error: $e')),
        );
      }
    }
  }

  /// Commit only the confirmed, non-excluded items.
  Future<void> _commitConfirmed() async {
    final confirmed =
        _lineItems.where((i) => i.confirmed && !i.excluded).toList();

    if (confirmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No items confirmed — nothing was saved.')),
      );
      return;
    }

    setState(() => _isCommitting = true);

    try {
      final invDao = ref.read(inventoryDaoProvider);
      final products = await invDao.watchAllProducts().first;
      final Map<String, int> productMap = {
        for (final p in products) p.name.toLowerCase(): p.id,
      };

      double totalAddedCapital = 0.0;

      for (final item in confirmed) {
        final cleanName = item.productName.trim();
        if (cleanName.isEmpty) continue;

        final key = cleanName.toLowerCase();
        int? productId = productMap[key];

        if (productId == null) {
          final found = await invDao.findProductByNameCaseInsensitive(cleanName);
          if (found != null) {
            productId = found.id;
          } else {
            productId = await invDao.insertProduct(
              ProductsCompanion.insert(name: cleanName),
            );
          }
          productMap[key] = productId;
        }

        final qty = item.quantity > 0 ? item.quantity : 1.0;
        totalAddedCapital += qty * item.costPrice;
        await invDao.insertBatch(
          CapitalBatchesCompanion.insert(
            productId: productId,
            quantityAdded: qty,
            remainingQuantity: qty,
            costPrice: item.costPrice,
            source: BatchSource.scannedReceipt,
          ),
        );
      }

      ref.read(dashboardSettingsProvider.notifier).onStockAdded(totalAddedCapital);
      ref.invalidate(inventorySummariesProvider);
      ref.invalidate(allProductsProvider);
      ref.invalidate(totalCapitalProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${confirmed.length} item(s) added to inventory (+${formatPeso(totalAddedCapital)} capital).'),
            backgroundColor: AppColors.success,
          ),
        );
        _reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCommitting = false);
    }
  }

  void _showManualAddItemDialog() {
    final summaries = ref.read(inventorySummariesProvider).valueOrNull ?? [];
    final dbProducts =
        ref.read(allProductsProvider).valueOrNull?.map((p) => p.name).toList() ??
            [];

    // All available product names: core 9 + DB products
    final allNames = <String>[...ReceiptOcrParser.kDefaultCatalogProducts];
    for (final p in dbProducts) {
      if (!allNames.any((e) => e.toLowerCase() == p.toLowerCase())) {
        allNames.add(p);
      }
    }

    String selectedProduct = allNames.first;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    void updatePriceFor(String prodName) {
      final s = summaries
          .where((item) =>
              item.product.name.toLowerCase() == prodName.toLowerCase())
          .firstOrNull;
      if (s != null && s.latestCostPrice > 0) {
        priceCtrl.text =
            s.latestCostPrice.truncateToDouble() == s.latestCostPrice
                ? s.latestCostPrice.toInt().toString()
                : s.latestCostPrice.toStringAsFixed(2);
      } else {
        priceCtrl.clear();
      }
    }

    updatePriceFor(selectedProduct);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add Item to Scan'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Product:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: allNames.contains(selectedProduct)
                        ? selectedProduct
                        : (allNames.isNotEmpty ? allNames.first : null),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      isDense: true,
                    ),
                    items: allNames.map((name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name,
                            style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedProduct = val;
                          updatePriceFor(val);
                        });
                      }
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (kg)',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.scale_outlined),
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cost price per kg (₱)',
                    prefixText: '₱ ',
                    prefixIcon: Icon(Icons.price_change_outlined),
                    isDense: true,
                    helperText:
                        'Autofilled from inventory if available (editable)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
              onPressed: () {
                final q = double.tryParse(qtyCtrl.text) ?? 1.0;
                final p = double.tryParse(priceCtrl.text) ?? 0.0;
                setState(() {
                  _lineItems.add(_OcrLineItem(
                    rawText: 'Manually Added',
                    productName: selectedProduct,
                    quantity: q > 0 ? q : 1.0,
                    costPrice: p >= 0 ? p : 0.0,
                    confirmed: true,
                  ));
                });
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Add to Scanned List'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan body ─────────────────────────────────────────────────────────────────

class _ScanBody extends StatelessWidget {
  const _ScanBody({
    required this.imageFile,
    required this.isScanning,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  final File? imageFile;
  final bool isScanning;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Preview area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accent, width: 2),
              ),
              child: isScanning
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Scanning receipt…',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(imageFile!,
                              fit: BoxFit.contain),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.document_scanner_outlined,
                              size: 72,
                              color: AppColors.primary.withAlpha(179),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Scan a receipt to add\nrestock capital',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isScanning ? null : onPickCamera,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isScanning ? null : onPickGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Review body ───────────────────────────────────────────────────────────────

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.items,
    required this.onItemChanged,
    required this.onItemDeleted,
    required this.onAddItem,
    required this.onCommit,
    required this.isCommitting,
  });

  final List<_OcrLineItem> items;
  final void Function(int, _OcrLineItem) onItemChanged;
  final void Function(int) onItemDeleted;
  final VoidCallback onAddItem;
  final VoidCallback onCommit;
  final bool isCommitting;

  @override
  Widget build(BuildContext context) {
    final confirmedCount = items.where((i) => i.confirmed && !i.excluded).length;

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withAlpha(77)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryDeep, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Review each item carefully. Edit and check items before confirming. Nothing is saved until you tap "Commit Confirmed Items".',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items counter & manual Add Item button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} item(s) in review',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Item'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Item list
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching inventory items found',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Add Item" above to add items manually.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: onAddItem,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Item Manually'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReviewItemCard(
                    item: items[i],
                    onChanged: (updated) => onItemChanged(i, updated),
                    onDelete: () => onItemDeleted(i),
                  ),
                ),
        ),

        // Commit bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Text(
                  '$confirmedCount item(s) selected',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed:
                      confirmedCount == 0 || isCommitting ? null : onCommit,
                  icon: isCommitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('Commit Confirmed Items'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewItemCard extends StatefulWidget {
  const _ReviewItemCard({
    required this.item,
    required this.onChanged,
    this.onDelete,
  });

  final _OcrLineItem item;
  final ValueChanged<_OcrLineItem> onChanged;
  final VoidCallback? onDelete;

  @override
  State<_ReviewItemCard> createState() => _ReviewItemCardState();
}

class _ReviewItemCardState extends State<_ReviewItemCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.productName);
    _qtyCtrl = TextEditingController(
        text: widget.item.quantity > 0
            ? widget.item.quantity.toString()
            : '1');
    _priceCtrl = TextEditingController(
        text: widget.item.costPrice > 0
            ? widget.item.costPrice.toString()
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(_OcrLineItem(
      rawText: widget.item.rawText,
      productName: _nameCtrl.text,
      quantity: double.tryParse(_qtyCtrl.text) ?? 1,
      costPrice: double.tryParse(_priceCtrl.text) ?? 0,
    )
      ..confirmed = widget.item.confirmed
      ..excluded = widget.item.excluded);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: item.excluded ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.confirmed
              ? AppColors.success.withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.confirmed
                ? AppColors.success.withAlpha(100)
                : AppColors.divider,
            width: item.confirmed ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Raw OCR hint
            Text(
              'OCR: "${item.rawText}"',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Fields
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Product name',
                isDense: true,
                prefixIcon:
                    Icon(Icons.label_outline_rounded, size: 18),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _notifyChange(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Qty (kg)',
                      suffixText: 'kg',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _notifyChange(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cost (₱/kg)',
                      prefixText: '₱ ',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _notifyChange(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Confirm / Exclude row
            Row(
              children: [
                InkWell(
                  onTap: () {
                    widget.onChanged(_OcrLineItem(
                      rawText: item.rawText,
                      productName: _nameCtrl.text,
                      quantity: double.tryParse(_qtyCtrl.text) ?? 1,
                      costPrice: double.tryParse(_priceCtrl.text) ?? 0,
                    )
                      ..confirmed = !item.confirmed
                      ..excluded = item.excluded);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: item.confirmed,
                            activeColor: AppColors.success,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) {
                              widget.onChanged(_OcrLineItem(
                                rawText: item.rawText,
                                productName: _nameCtrl.text,
                                quantity: double.tryParse(_qtyCtrl.text) ?? 1,
                                costPrice:
                                    double.tryParse(_priceCtrl.text) ?? 0,
                              )
                                ..confirmed = v ?? false
                                ..excluded = item.excluded);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Confirm',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    widget.onChanged(_OcrLineItem(
                      rawText: item.rawText,
                      productName: item.productName,
                      quantity: item.quantity,
                      costPrice: item.costPrice,
                    )
                      ..confirmed = false
                      ..excluded = !item.excluded);
                  },
                  icon: Icon(
                    item.excluded ? Icons.undo_rounded : Icons.block_rounded,
                    size: 16,
                  ),
                  label: Text(item.excluded ? 'Undo' : 'Exclude'),
                  style: TextButton.styleFrom(
                    foregroundColor: item.excluded
                        ? AppColors.primaryDeep
                        : AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
                    tooltip: 'Remove from list',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
