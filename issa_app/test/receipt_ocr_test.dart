import 'package:flutter_test/flutter_test.dart';
import 'package:issa_app/screens/receipt_scan/receipt_ocr_parser.dart';

void main() {
  late ReceiptOcrParser parser;

  setUp(() {
    parser = ReceiptOcrParser();
  });

  group('ReceiptOcrParser - Real Store Receipts', () {
    test('Receipt 1 (9/5/26): AC Meat Processing 7 items parsed accurately', () {
      const receipt1Text = '''
9/5/26 15+1 tapa 3,275
AC'S Meat Processing
Employee: Owner
POS: POS 1
----------------------------------------
Garlic Pork Longganisa ₱1,175.00
5.000 x ₱235.00
Sweet Pork Longganisa ₱600.00
3.000 x ₱200.00
Sweet & Spicy Pork Longganisa ₱410.00
2.000 x ₱205.00
Chicken Longganisa ₱380.00
2.000 x ₱190.00
Spicy Chicken Longganisa ₱200.00
1.000 x ₱200.00
Chicken Hamonado ₱200.00
1.000 x ₱200.00
Pork Tapa ₱310.00
1.000 x ₱310.00
+ 310w Sobra
Total ₱3,275.00
Cash ₱3,275.00
9/5/26 12:04 PM #1-11783
(6)
''';

      final items = parser.parseText(receipt1Text);

      expect(items.length, 7);

      expect(items[0].productName, 'Garlic Pork Longganisa');
      expect(items[0].quantity, 5.0);
      expect(items[0].costPrice, 235.0);

      expect(items[1].productName, 'Sweet Pork Longganisa');
      expect(items[1].quantity, 3.0);
      expect(items[1].costPrice, 200.0);

      expect(items[2].productName, 'Sweet & Spicy Pork Longganisa');
      expect(items[2].quantity, 2.0);
      expect(items[2].costPrice, 205.0);

      expect(items[3].productName, 'Chicken Longganisa');
      expect(items[3].quantity, 2.0);
      expect(items[3].costPrice, 190.0);

      expect(items[4].productName, 'Spicy Chicken Longganisa');
      expect(items[4].quantity, 1.0);
      expect(items[4].costPrice, 200.0);

      expect(items[5].productName, 'Chicken Hamonado');
      expect(items[5].quantity, 1.0);
      expect(items[5].costPrice, 200.0);

      expect(items[6].productName, 'Pork Tapa');
      expect(items[6].quantity, 1.0);
      expect(items[6].costPrice, 310.0);
    });

    test('Receipt 2 (8/31/26): AC Meat Processing 8 items with faint dots & spaces', () {
      const receipt2Text = '''
LOLOPEL 14 kilos 3,445
AC'S Meat Processing
Employee: Owner
POS: POS 1
----------------------------------------
Garlic Pork Longganisa ₱705.00
3 000 x ₱235.00
Chicken Hamonado ₱400.00
2 000 x ₱200.00
Pork Hamonado ₱205.00
1 000 x ₱205.00
Spicy Chicken Longganisa ₱200.00
1 000 x ₱200.00
Sweet Pork Longganisa ₱200.00
1.000 x ₱200.00
Sweet & Spicy Pork Longganisa ₱205.00
1.000 x ₱205.00
Pork Tapa ₱1,240.00
4.000 x ₱310.00
Pork Tocino ₱290.00
1.000 x ₱290.00
Total ₱3,445.00
Cash ₱3,445.00
8/31/26 12:22 PM #1-11645
9/1/26 7: Am (4)
''';

      final items = parser.parseText(receipt2Text);

      expect(items.length, 8);

      expect(items[0].productName, 'Garlic Pork Longganisa');
      expect(items[0].quantity, 3.0);
      expect(items[0].costPrice, 235.0);

      expect(items[1].productName, 'Chicken Hamonado');
      expect(items[1].quantity, 2.0);
      expect(items[1].costPrice, 200.0);

      expect(items[2].productName, 'Pork Hamonado');
      expect(items[2].quantity, 1.0);
      expect(items[2].costPrice, 205.0);

      expect(items[3].productName, 'Spicy Chicken Longganisa');
      expect(items[3].quantity, 1.0);
      expect(items[3].costPrice, 200.0);

      expect(items[4].productName, 'Sweet Pork Longganisa');
      expect(items[4].quantity, 1.0);
      expect(items[4].costPrice, 200.0);

      expect(items[5].productName, 'Sweet & Spicy Pork Longganisa');
      expect(items[5].quantity, 1.0);
      expect(items[5].costPrice, 205.0);

      expect(items[6].productName, 'Pork Tapa');
      expect(items[6].quantity, 4.0);
      expect(items[6].costPrice, 310.0);

      expect(items[7].productName, 'Pork Tocino');
      expect(items[7].quantity, 1.0);
      expect(items[7].costPrice, 290.0);
    });

    test('STRICT INVENTORY FILTER: Never outputs text not present in inventory catalog', () {
      const text = '''
AC'S Meat Processing
Cashier: Maria
Plastic Bag Large 10.00
Special Beef Patty 250.00
Unrelated Product 5.000 x 100.00
Garlic Pork Longganisa
5.000 x ₱235.00
''';

      final items = parser.parseText(text);

      // Only Garlic Pork Longganisa must be output. Unrelated items must be ignored!
      expect(items.length, 1);
      expect(items[0].productName, 'Garlic Pork Longganisa');
      expect(items[0].quantity, 5.0);
      expect(items[0].costPrice, 235.0);
    });

    test('DYNAMIC INVENTORY EXPANSION: Recognizes custom added items when in catalog', () {
      final customParser = ReceiptOcrParser(customProducts: ['Beef Tapa', 'Hungarian Sausage']);

      const text = '''
Beef Tapa
3.000 x ₱350.00
Hungarian Sausage
2.000 x ₱180.00
Random Not In Inventory
1.000 x ₱99.00
''';

      final items = customParser.parseText(text);

      expect(items.length, 2);
      expect(items[0].productName, 'Beef Tapa');
      expect(items[0].quantity, 3.0);
      expect(items[0].costPrice, 350.0);

      expect(items[1].productName, 'Hungarian Sausage');
      expect(items[1].quantity, 2.0);
      expect(items[1].costPrice, 180.0);
    });

    test('Never treats multiplier line like "2.000 x ₱205.00" as a product name', () {
      const text = '''
Garlic Pork Longganisa ₱1,175.00
5.000 x ₱235.00
₱600.00
Sweet Pork Longganisa
3.000 x ₱200.00
2.000 x ₱205.00
Sweet & Spicy Pork Longganisa
2.000 x ₱205.00
''';

      final items = parser.parseText(text);

      for (final item in items) {
        expect(item.productName.contains('2.000'), isFalse);
        expect(item.productName.contains('3.000'), isFalse);
        expect(item.productName.contains('x'), isFalse);
        expect(ReceiptOcrParser.kDefaultCatalogProducts.contains(item.productName), isTrue);
      }
    });

    test('Handles separate line totals between product name and quantity', () {
      const text = '''
Sweet Pork Longganisa
₱600.00
3.000 x ₱200.00
''';

      final items = parser.parseText(text);
      expect(items.length, 1);
      expect(items[0].productName, 'Sweet Pork Longganisa');
      expect(items[0].quantity, 3.0);
      expect(items[0].costPrice, 200.0);
    });

    test('Fuzzy matches fold creases and common OCR typos to the 9 products', () {
      const text = '''
Garlic Pork Longganissa ₱1,175.00
5.000 x ₱235.00
Pork I apa ₱310.00
1.000 x ₱310.00
Sweet & Spicy Pork Longanisa ₱410.00
2.000 x ₱205.00
Pork Tosino ₱290.00
1.000 x ₱290.00
''';

      final items = parser.parseText(text);
      expect(items.length, 4);
      expect(items[0].productName, 'Garlic Pork Longganisa');
      expect(items[1].productName, 'Pork Tapa');
      expect(items[2].productName, 'Sweet & Spicy Pork Longganisa');
      expect(items[3].productName, 'Pork Tocino');
    });

    test('Parses integer quantities without decimal dot (e.g. 3000 x 235.00)', () {
      const text = '''
Garlic Pork Longganisa
3000 x ₱235.00
Chicken Hamonado
1000 x ₱200.00
''';

      final items = parser.parseText(text);
      expect(items.length, 2);
      expect(items[0].quantity, 3.0);
      expect(items[0].costPrice, 235.0);
      expect(items[1].quantity, 1.0);
      expect(items[1].costPrice, 200.0);
    });
  });
}
