import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A candidate line item parsed from OCR output.
class ParsedOcrItem {
  ParsedOcrItem({
    required this.rawText,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    this.lineTotal,
    this.isCatalogMatch = false,
  });

  final String rawText;
  final String productName;
  final double quantity;
  final double costPrice;
  final double? lineTotal;
  final bool isCatalogMatch;

  @override
  String toString() =>
      'ParsedOcrItem($productName, qty: $quantity, unitCost: ₱$costPrice, total: $lineTotal)';
}

/// Robust parser for retail & POS receipts (specifically multi-line meat processing / grocery receipts).
class ReceiptOcrParser {
  ReceiptOcrParser({List<String>? customProducts}) {
    final list = <String>[...kDefaultCatalogProducts];
    if (customProducts != null) {
      for (final p in customProducts) {
        final trimmed = p.trim();
        if (trimmed.isNotEmpty && !list.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
          list.add(trimmed);
        }
      }
    }
    _catalog = list;
  }

  /// Default 9 store products requested by the business.
  static const List<String> kDefaultCatalogProducts = [
    'Garlic Pork Longganisa',
    'Sweet Pork Longganisa',
    'Sweet & Spicy Pork Longganisa',
    'Chicken Longganisa',
    'Spicy Chicken Longganisa',
    'Chicken Hamonado',
    'Pork Tapa',
    'Pork Hamonado',
    'Pork Tocino',
  ];

  late final List<String> _catalog;
  List<String> get catalog => List.unmodifiable(_catalog);

  /// Parse directly from Google ML Kit [RecognizedText].
  /// Spatially groups lines by vertical position to fix column-splitting bugs.
  List<ParsedOcrItem> parseRecognizedText(RecognizedText recognized) {
    if (recognized.blocks.isEmpty) {
      return parseText(recognized.text);
    }

    final allLines = <TextLine>[];
    for (final block in recognized.blocks) {
      allLines.addAll(block.lines);
    }

    if (allLines.isEmpty) {
      return parseText(recognized.text);
    }

    // Sort lines top to bottom by boundingBox.top
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Group lines that share the same horizontal band
    final lineBands = <List<TextLine>>[];
    for (final line in allLines) {
      final lineBox = line.boundingBox;
      final lineMidY = lineBox.top + lineBox.height / 2.0;

      List<TextLine>? matchedBand;
      for (final band in lineBands) {
        final bandBox = band.first.boundingBox;
        final bandMidY = bandBox.top + bandBox.height / 2.0;
        final threshold = math.max(14.0, bandBox.height * 0.7);

        if ((lineMidY - bandMidY).abs() <= threshold) {
          matchedBand = band;
          break;
        }
      }

      if (matchedBand != null) {
        matchedBand.add(line);
      } else {
        lineBands.add([line]);
      }
    }

    // For each band, sort left-to-right and join with a space
    final reconstructedLines = <String>[];
    for (final band in lineBands) {
      band.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      final merged = band.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join(' ');
      if (merged.isNotEmpty) {
        reconstructedLines.add(merged);
      }
    }

    return parseLines(reconstructedLines);
  }

  /// Parse from raw string text (used in unit tests or fallback).
  List<ParsedOcrItem> parseText(String text) {
    final rawLines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return parseLines(rawLines);
  }

  /// Parse a pre-split list of text lines.
  List<ParsedOcrItem> parseLines(List<String> rawLines) {
    // 1. Filter out obvious metadata, headers, totals, and dividers
    final lines = rawLines.where((l) => !_isIgnoreLine(l)).toList();
    final items = <ParsedOcrItem>[];
    int i = 0;

    while (i < lines.length) {
      final cur = lines[i];

      // If cur is a stray multiplier line (e.g. "2.000 x ₱205.00"), skip it. It cannot be a product name!
      if (_isMultiplierOrPriceOnly(cur)) {
        i++;
        continue;
      }

      // Check if cur matches an inventory product:
      final candidateName = _extractCandidateName(cur);
      final catalogMatch = _matchCatalog(candidateName);

      // Check inline patterns
      final inlineM = _inlineQtyPriceRegex.firstMatch(cur);
      final inlineCatalogMatch =
          inlineM != null ? _matchCatalog(inlineM.group(1)!) : null;

      final trailingQM = _trailingQtyPriceRegex.firstMatch(cur);
      final trailingQMCatalogMatch =
          trailingQM != null ? _matchCatalog(trailingQM.group(1)!) : null;

      final priceM = _trailingPriceRegex.firstMatch(cur);
      final priceMCatalogMatch =
          (priceM != null && !_isMultiplierOrPriceOnly(priceM.group(1)!))
              ? _matchCatalog(priceM.group(1)!)
              : null;

      // STRICT INVENTORY CHECK:
      // If it doesn't match any inventory product, discard it completely!
      if (catalogMatch == null &&
          inlineCatalogMatch == null &&
          trailingQMCatalogMatch == null &&
          priceMCatalogMatch == null) {
        i++;
        continue;
      }

      // ── Priority 1: Direct Catalog Match on Line Header ───────────────────
      if (catalogMatch != null) {
        // Pattern A1: Line i+1 is "Qty x UnitPrice" (e.g. "5.000 x ₱235.00")
        if (i + 1 < lines.length) {
          final next1 = lines[i + 1];
          final qp1 = _matchQtyAndPrice(next1);
          if (qp1 != null) {
            items.add(ParsedOcrItem(
              rawText: '$cur\n$next1',
              productName: catalogMatch,
              quantity: qp1.quantity,
              costPrice: qp1.costPrice,
              lineTotal: _extractTrailingPrice(cur),
              isCatalogMatch: true,
            ));
            i += 2;
            continue;
          }

          // Pattern A2: Line i+1 is line total (e.g. "₱600.00") and Line i+2 is "Qty x UnitPrice"
          if (i + 2 < lines.length && _isPriceOnly(next1)) {
            final next2 = lines[i + 2];
            final qp2 = _matchQtyAndPrice(next2);
            if (qp2 != null) {
              items.add(ParsedOcrItem(
                rawText: '$cur\n$next1\n$next2',
                productName: catalogMatch,
                quantity: qp2.quantity,
                costPrice: qp2.costPrice,
                lineTotal: _parsePrice(next1),
                isCatalogMatch: true,
              ));
              i += 3;
              continue;
            }
          }
        }

        // Pattern A3: Trailing price on the same line (e.g. "Pork Tapa ₱310.00")
        if (priceM != null) {
          final p = _parsePrice(priceM.group(2)!) ?? 0.0;
          if (p > 0) {
            items.add(ParsedOcrItem(
              rawText: cur,
              productName: catalogMatch,
              quantity: 1.0,
              costPrice: p,
              isCatalogMatch: true,
            ));
            i++;
            continue;
          }
        }

        // Fallback for catalog match with no price detected yet
        items.add(ParsedOcrItem(
          rawText: cur,
          productName: catalogMatch,
          quantity: 1.0,
          costPrice: 0.0,
          isCatalogMatch: true,
        ));
        i++;
        continue;
      }

      // ── Priority 2: Inline Qty x Price ────────────────────────────────────
      if (inlineCatalogMatch != null && inlineM != null) {
        final q = _parseQuantity(inlineM.group(2)!);
        final p = _parsePrice(inlineM.group(3)!) ?? 0.0;
        items.add(ParsedOcrItem(
          rawText: cur,
          productName: inlineCatalogMatch,
          quantity: q,
          costPrice: p,
          isCatalogMatch: true,
        ));
        i++;
        continue;
      }

      // ── Priority 3: Trailing Qty + Price ──────────────────────────────────
      if (trailingQMCatalogMatch != null && trailingQM != null) {
        final q = _parseQuantity(trailingQM.group(2)!);
        final p = _parsePrice(trailingQM.group(3)!) ?? 0.0;
        items.add(ParsedOcrItem(
          rawText: cur,
          productName: trailingQMCatalogMatch,
          quantity: q,
          costPrice: p,
          isCatalogMatch: true,
        ));
        i++;
        continue;
      }

      // ── Priority 4: Trailing Price Only ───────────────────────────────────
      if (priceMCatalogMatch != null && priceM != null) {
        final p = _parsePrice(priceM.group(2)!) ?? 0.0;
        if (p > 0) {
          items.add(ParsedOcrItem(
            rawText: cur,
            productName: priceMCatalogMatch,
            quantity: 1.0,
            costPrice: p,
            isCatalogMatch: true,
          ));
          i++;
          continue;
        }
      }

      i++;
    }

    return items;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Regex Patterns
  // ──────────────────────────────────────────────────────────────────────────

  static final RegExp _qtyPriceRegex = RegExp(
    r'^\s*(\d+(?:[\s.,]\d+)?)\s*(?:kg|kilos|kilo|pcs|pc|packs|pack)?\s*[xX@*]\s*(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)',
    caseSensitive: false,
  );

  static final RegExp _inlineQtyPriceRegex = RegExp(
    r'^(.*?)\s+(\d+(?:[\s.,]\d+)?)\s*(?:kg|kilos|kilo|pcs|pc|packs|pack)?\s*[xX@*]\s*(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)',
    caseSensitive: false,
  );

  static final RegExp _trailingQtyPriceRegex = RegExp(
    r'^(.*?)\s+(\d+(?:[\s.,]\d+)?)\s*(?:kg|kilos|kilo|pcs|pc)?\s+(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*$',
    caseSensitive: false,
  );

  static final RegExp _trailingPriceRegex = RegExp(
    r'^(.*?)\s+(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*$',
    caseSensitive: false,
  );

  static final RegExp _priceOnlyRegex = RegExp(
    r'^\s*(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+\.\d{2})\s*$',
    caseSensitive: false,
  );

  static final RegExp _multiplierStartRegex = RegExp(
    r'^\s*\d+(?:[\s.,]\d+)?\s*[xX@*]',
    caseSensitive: false,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ──────────────────────────────────────────────────────────────────────────

  _QtyPrice? _matchQtyAndPrice(String line) {
    final m = _qtyPriceRegex.firstMatch(line);
    if (m == null) return null;
    final q = _parseQuantity(m.group(1)!);
    final p = _parsePrice(m.group(2)!) ?? 0.0;
    if (p <= 0) return null;
    return _QtyPrice(q, p);
  }

  bool _isPriceOnly(String line) {
    return _priceOnlyRegex.hasMatch(line.trim());
  }

  bool _isMultiplierOrPriceOnly(String line) {
    final trimmed = line.trim();
    if (_priceOnlyRegex.hasMatch(trimmed)) return true;
    if (_multiplierStartRegex.hasMatch(trimmed)) return true;

    // Has no alphabetic characters other than 'x' or 'p'/'php' (currency)
    final letters = trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    final nonMultiplierLetters = letters.replaceAll(RegExp(r'[xXpP]'), '');
    return nonMultiplierLetters.isEmpty;
  }

  String _extractCandidateName(String line) {
    // If line has a trailing line-total like "₱1,175.00" or "₱600.00", strip it
    var name = line.replaceFirst(
      RegExp(r'\s+(?:[₱Pp]?(?:HP)?\.?\s*)?\d{1,3}(?:,\d{3})*(?:\.\d+)?\s*$', caseSensitive: false),
      '',
    );
    return name.trim();
  }

  double? _extractTrailingPrice(String line) {
    final m = RegExp(
      r'(?:[₱Pp]?(?:HP)?\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+\.\d{2})\s*$',
      caseSensitive: false,
    ).firstMatch(line.trim());
    if (m != null) {
      return _parsePrice(m.group(1)!);
    }
    return null;
  }

  double _parseQuantity(String raw) {
    var s = raw.trim();

    // Check for space instead of decimal, e.g. "3 000" -> "3.000"
    if (RegExp(r'^\d+\s+\d{3}$').hasMatch(s)) {
      s = s.replaceFirst(RegExp(r'\s+'), '.');
    } else {
      s = s.replaceAll(' ', '');
    }

    // Comma as decimal
    if (s.contains(',') && !s.contains('.')) {
      s = s.replaceAll(',', '.');
    } else if (s.contains(',') && s.contains('.')) {
      // Thousands separator
      s = s.replaceAll(',', '');
    }

    double val = double.tryParse(s) ?? 1.0;

    // If thermal printer dropped the decimal point, e.g. "3000" -> 3.0, "1000" -> 1.0, "4000" -> 4.0
    // Meat processing orders are under 100 kg. If integer >= 100 and multiple of 100 or 1000:
    if (val >= 500 && val % 1000 == 0) {
      val = val / 1000.0;
    } else if (val >= 100 && val <= 999 && val % 100 == 0) {
      val = val / 100.0;
    }

    return val > 0 ? val : 1.0;
  }

  double? _parsePrice(String s) {
    final cleaned = s
        .replaceAll(RegExp(r'[₱Pp\s,]'), '')
        .replaceAll(RegExp(r'PHP', caseSensitive: false), '');
    return double.tryParse(cleaned);
  }

  bool _isIgnoreLine(String line) {
    final lower = line.toLowerCase().trim();
    if (lower.isEmpty) return true;
    if (RegExp(r'^[-=_.*#~]{3,}$').hasMatch(lower)) return true;
    if (RegExp(r'^\(?\d+\)?$').hasMatch(lower)) return true; // e.g. (7) or (4) or (6)
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(lower)) return true; // dates
    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(lower)) return true; // time
    if (RegExp(r'^(?:#|or#|si#|inv#|trans#|ref#)\s*[\w-]+').hasMatch(lower)) return true;

    const ignoreKeywords = [
      'total', 'subtotal', 'sub-total', 'grand total', 'net total', 'amount due',
      'cash', 'change', 'tendered', 'payment', 'card', 'gcash', 'maya',
      'employee', 'pos:', 'pos 1', 'pos 2', 'cashier', 'terminal',
      'meat processing', 'store', 'branch', 'official receipt', 'sales invoice',
      'vat', 'tax', 'vatable', 'zero rated', 'exempt', 'tin:',
      'sobra', 'lolopel', 'kilos', 'owner'
    ];

    for (final kw in ignoreKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Catalog matching with fuzzy typo tolerance.
  String? _matchCatalog(String text) {
    final inputLower = text.toLowerCase().trim();
    if (inputLower.isEmpty) return null;

    // 1. Direct exact match (case-insensitive)
    for (final prod in _catalog) {
      if (prod.toLowerCase() == inputLower) {
        return prod;
      }
    }

    // 2. Normalized keywords match for known 9 products
    final normalized = inputLower
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r"[^\w\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final hasLongganisa = normalized.contains('longganisa') ||
        normalized.contains('longanisa') ||
        normalized.contains('longganissa') ||
        normalized.contains('longanissa') ||
        normalized.contains('longan sa') ||
        normalized.contains('longgan sa');

    final hasHamonado = normalized.contains('hamonado') ||
        normalized.contains('hamonada') ||
        normalized.contains('hamorado');

    final hasTapa = normalized.contains('tapa') ||
        normalized.contains(' apa') ||
        normalized.endsWith('apa') ||
        normalized.contains('1apa');

    final hasTocino = normalized.contains('tocino') || normalized.contains('tosino');

    // ─────────────────────────────────────────────
    // Categorize by protein and style
    // ─────────────────────────────────────────────

    if (hasLongganisa) {
      if (normalized.contains('garlic')) {
        return 'Garlic Pork Longganisa';
      }
      if (normalized.contains('sweet') && (normalized.contains('spicy') || normalized.contains('and spicy') || normalized.contains('& spicy'))) {
        return 'Sweet & Spicy Pork Longganisa';
      }
      if (normalized.contains('sweet')) {
        return 'Sweet Pork Longganisa';
      }
      if (normalized.contains('spicy') && normalized.contains('chicken')) {
        return 'Spicy Chicken Longganisa';
      }
      if (normalized.contains('chicken')) {
        return 'Chicken Longganisa';
      }
      if (normalized.contains('pork')) {
        return 'Garlic Pork Longganisa'; // Default pork longganisa if unspecified
      }
    }

    if (hasHamonado) {
      if (normalized.contains('chicken')) {
        return 'Chicken Hamonado';
      }
      if (normalized.contains('pork')) {
        return 'Pork Hamonado';
      }
    }

    if (hasTapa) {
      return 'Pork Tapa';
    }

    if (hasTocino) {
      return 'Pork Tocino';
    }

    // 3. Fallback: Word overlap matching against all custom products in catalog
    String? bestProduct;
    int maxMatches = 0;
    final inputTokens = normalized.split(' ').where((w) => w.length >= 3).toSet();

    for (final prod in _catalog) {
      final prodTokens = prod
          .toLowerCase()
          .replaceAll('&', ' and ')
          .replaceAll(RegExp(r"[^\w\s]"), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 3)
          .toSet();

      final matches = inputTokens.intersection(prodTokens).length;
      if (matches >= 2 && matches > maxMatches) {
        maxMatches = matches;
        bestProduct = prod;
      }
    }

    return bestProduct;
  }
}

class _QtyPrice {
  _QtyPrice(this.quantity, this.costPrice);
  final double quantity;
  final double costPrice;
}
