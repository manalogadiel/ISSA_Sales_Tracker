import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses meat processing multi-line receipt accurately', () {
    const sampleText = '''
LOLOPEL 9/8/26 10 kilos
AC'S Meat Processing
Employee: Owner
POS: POS 1
----------------------------------------
Garlic Pork Longganisa ₱1,175.00
5.000 x ₱235.00
Pork Tapa ₱1,550.00
5.000 x ₱310.00
Pork Hamonado ₱205.00
1.000 x ₱205.00
----------------------------------------
Total ₱2,930.00
Cash ₱2,930.00
----------------------------------------
9/8/26 11:32 AM #1-11869
(7)
''';

    final items = testParseOcrText(sampleText);

    expect(items.length, 3);

    expect(items[0].productName, 'Garlic Pork Longganisa');
    expect(items[0].quantity, 5.0);
    expect(items[0].costPrice, 235.0);

    expect(items[1].productName, 'Pork Tapa');
    expect(items[1].quantity, 5.0);
    expect(items[1].costPrice, 310.0);

    expect(items[2].productName, 'Pork Hamonado');
    expect(items[2].quantity, 1.0);
    expect(items[2].costPrice, 205.0);
  });
}

class TestOcrItem {
  TestOcrItem(this.productName, this.quantity, this.costPrice);
  final String productName;
  final double quantity;
  final double costPrice;
}

bool _isIgnoreLine(String line) {
  final lower = line.toLowerCase().trim();
  if (lower.isEmpty) return true;
  if (RegExp(r'^[-=_.*#~]{3,}$').hasMatch(lower)) return true;
  if (RegExp(r'^\(?\d+\)?$').hasMatch(lower)) return true;
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
  var name = line.replaceFirst(
    RegExp(r'\s+(?:[₱Pp]?(?:HP)?\.?\s*)?\d{1,3}(?:,\d{3})*(?:\.\d+)?\s*$', caseSensitive: false),
    '',
  );
  name = name.replaceAll(RegExp(r"[^\w\s'-]"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return name.split(' ').where((w) => w.isNotEmpty).map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
}

List<TestOcrItem> testParseOcrText(String text) {
  final rawLines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  final lines = rawLines.where((l) => !_isIgnoreLine(l)).toList();

  final items = <TestOcrItem>[];
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

    if (i + 1 < lines.length) {
      final next = lines[i + 1];
      final m = qtyPriceRegex.firstMatch(next);
      if (m != null) {
        final q = double.tryParse(m.group(1)!) ?? 1.0;
        final p = _parsePrice(m.group(2)!) ?? 0.0;
        final name = _cleanProductName(cur);
        if (name.isNotEmpty && name.length >= 2) {
          items.add(TestOcrItem(name, q, p));
          i += 2;
          continue;
        }
      }
    }

    final inlineM = inlineQtyPriceRegex.firstMatch(cur);
    if (inlineM != null) {
      final name = _cleanProductName(inlineM.group(1)!);
      final q = double.tryParse(inlineM.group(2)!) ?? 1.0;
      final p = _parsePrice(inlineM.group(3)!) ?? 0.0;
      if (name.isNotEmpty && name.length >= 2) {
        items.add(TestOcrItem(name, q, p));
        i++;
        continue;
      }
    }

    final trailingM = trailingQtyPriceRegex.firstMatch(cur);
    if (trailingM != null) {
      final name = _cleanProductName(trailingM.group(1)!);
      final q = double.tryParse(trailingM.group(2)!) ?? 1.0;
      final p = _parsePrice(trailingM.group(3)!) ?? 0.0;
      if (name.isNotEmpty && name.length >= 2) {
        items.add(TestOcrItem(name, q, p));
        i++;
        continue;
      }
    }

    final priceM = trailingPriceRegex.firstMatch(cur);
    if (priceM != null) {
      final name = _cleanProductName(priceM.group(1)!);
      final p = _parsePrice(priceM.group(2)!) ?? 0.0;
      if (name.isNotEmpty && name.length >= 2 && p > 0) {
        items.add(TestOcrItem(name, 1.0, p));
        i++;
        continue;
      }
    }

    i++;
  }

  return items;
}
