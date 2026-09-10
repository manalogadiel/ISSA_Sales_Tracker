import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

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
      final items = _parseOcrText(recognized.text);
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

  /// Parse OCR text into candidate line items.
  /// Supports:
  /// - 2-line format: Product name line followed by "[Qty] x [Unit Cost]" line
  /// - Inline format: "Product Name [Qty] x [Unit Cost]"
  /// - Trailing Qty + Price: "Product Name [Qty] [Unit Cost]"
  /// - Trailing Price: "Product Name [Price]" (Qty defaults to 1)
  /// Automatically filters out headers, metadata, totals, cash/payment, and tax lines.
  List<_OcrLineItem> _parseOcrText(String text) {
    final rawLines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Filter out obvious metadata, headers, totals, and dividers
    final lines = rawLines.where((l) => !_isIgnoreLine(l)).toList();

    final items = <_OcrLineItem>[];
    int i = 0;

    final qtyPriceRegex = RegExp(
      r'^\s*(\d+(?:\.\d+)?)\s*(?:kg|kilos|kilo|pcs|pc|packs|pack)?\s*[xX@*]\s*(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)',
      caseSensitive: false,
    );

    final inlineQtyPriceRegex = RegExp(
      r'^(.*?)\s+(\d+(?:\.\d+)?)\s*(?:kg|kilos|kilo|pcs|pc|packs|pack)?\s*[xX@*]\s*(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)',
      caseSensitive: false,
    );

    final trailingQtyPriceRegex = RegExp(
      r'^(.*?)\s+(\d+(?:\.\d+)?)\s*(?:kg|kilos|kilo|pcs|pc)?\s+(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*$',
      caseSensitive: false,
    );

    final trailingPriceRegex = RegExp(
      r'^(.*?)\s+(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*$',
      caseSensitive: false,
    );

    while (i < lines.length) {
      final cur = lines[i];

      // Case A: 2-line pattern (Line i is Name; Line i+1 is "Qty x UnitPrice")
      if (i + 1 < lines.length) {
        final next = lines[i + 1];
        final m = qtyPriceRegex.firstMatch(next);
        if (m != null) {
          final q = double.tryParse(m.group(1)!) ?? 1.0;
          final p = _parsePrice(m.group(2)!) ?? 0.0;
          final name = _cleanProductName(cur);
          if (name.isNotEmpty && name.length >= 2) {
            items.add(_OcrLineItem(
              rawText: '$cur\n$next',
              productName: name,
              quantity: q,
              costPrice: p,
              confirmed: true,
            ));
            i += 2;
            continue;
          }
        }
      }

      // Case B: Inline Qty x Price ("Pork Tapa 5.000 x 310.00")
      final inlineM = inlineQtyPriceRegex.firstMatch(cur);
      if (inlineM != null) {
        final name = _cleanProductName(inlineM.group(1)!);
        final q = double.tryParse(inlineM.group(2)!) ?? 1.0;
        final p = _parsePrice(inlineM.group(3)!) ?? 0.0;
        if (name.isNotEmpty && name.length >= 2) {
          items.add(_OcrLineItem(
            rawText: cur,
            productName: name,
            quantity: q,
            costPrice: p,
            confirmed: true,
          ));
          i++;
          continue;
        }
      }

      // Case C: Trailing Qty + Price ("Pork Tapa 5.0 310.00")
      final trailingM = trailingQtyPriceRegex.firstMatch(cur);
      if (trailingM != null) {
        final name = _cleanProductName(trailingM.group(1)!);
        final q = double.tryParse(trailingM.group(2)!) ?? 1.0;
        final p = _parsePrice(trailingM.group(3)!) ?? 0.0;
        if (name.isNotEmpty && name.length >= 2) {
          items.add(_OcrLineItem(
            rawText: cur,
            productName: name,
            quantity: q,
            costPrice: p,
            confirmed: true,
          ));
          i++;
          continue;
        }
      }

      // Case D: Trailing Price only (defaults Qty to 1.0 kg)
      final priceM = trailingPriceRegex.firstMatch(cur);
      if (priceM != null) {
        final name = _cleanProductName(priceM.group(1)!);
        final p = _parsePrice(priceM.group(2)!) ?? 0.0;
        if (name.isNotEmpty && name.length >= 2 && p > 0) {
          items.add(_OcrLineItem(
            rawText: cur,
            productName: name,
            quantity: 1.0,
            costPrice: p,
            confirmed: true,
          ));
          i++;
          continue;
        }
      }

      i++;
    }

    return items;
  }

  bool _isIgnoreLine(String line) {
    final lower = line.toLowerCase().trim();
    if (lower.isEmpty) return true;
    if (RegExp(r'^[-=_.*#~]{3,}$').hasMatch(lower)) return true;
    if (RegExp(r'^\(?\d+\)?$').hasMatch(lower)) return true; // e.g. (7)
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(lower)) return true;
    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(lower)) return true;
    if (RegExp(r'^(?:#|or#|si#|inv#|trans#|ref#)\s*[\w-]+').hasMatch(lower)) return true;

    const ignoreKeywords = [
      'total', 'subtotal', 'sub-total', 'grand total', 'net total', 'amount due',
      'cash', 'change', 'tendered', 'payment', 'card', 'gcash', 'maya',
      'employee', 'pos:', 'pos 1', 'pos 2', 'cashier', 'terminal',
      'meat processing', 'store', 'branch', 'official receipt', 'sales invoice',
      'vat', 'tax', 'vatable', 'zero rated', 'exempt', 'tin:',
    ];

    for (final kw in ignoreKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  double? _parsePrice(String s) {
    final cleaned = s
        .replaceAll(RegExp(r'[₱PpPp\s,]'), '')
        .replaceAll(RegExp(r'PHP', caseSensitive: false), '');
    return double.tryParse(cleaned);
  }

  String _cleanProductName(String line) {
    // Strip trailing line total price if attached, e.g. "₱1,175.00" or "1,175.00"
    var name = line.replaceFirst(
      RegExp(r'\s+(?:[₱Pp]?(?:HP)?\.?\s*)?\d{1,3}(?:,\d{3})*(?:\.\d+)?\s*$',
          caseSensitive: false),
      '',
    );
    name = name
        .replaceAll(RegExp(r"[^\w\s'-]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return _toTitleCase(name);
  }

  String _toTitleCase(String s) => s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

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
    required this.onCommit,
    required this.isCommitting,
  });

  final List<_OcrLineItem> items;
  final void Function(int, _OcrLineItem) onItemChanged;
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

        const SizedBox(height: 8),

        // Item list
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No text detected',
                  subtitle: 'Try scanning a clearer photo of the receipt.',
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReviewItemCard(
                    item: items[i],
                    onChanged: (updated) => onItemChanged(i, updated),
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
  const _ReviewItemCard({required this.item, required this.onChanged});
  final _OcrLineItem item;
  final ValueChanged<_OcrLineItem> onChanged;

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
                Expanded(
                  child: CheckboxListTile(
                    value: item.confirmed,
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
                    title: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    activeColor: AppColors.success,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
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
                    item.excluded ? Icons.undo_rounded : Icons.delete_outline_rounded,
                    size: 16,
                  ),
                  label: Text(item.excluded ? 'Undo' : 'Exclude'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        item.excluded ? AppColors.primaryDeep : AppColors.error,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
