import 'package:flutter_test/flutter_test.dart';
import 'package:issa_app/services/receipt_ai_service.dart';

void main() {
  group('ReceiptAiItem JSON parsing', () {
    test('parses valid JSON array properly', () {
      final json = {
        'productName': 'Garlic Pork Longganisa',
        'quantity': 5.0,
        'costPrice': 235.0,
      };

      final item = ReceiptAiItem.fromJson(json);
      expect(item.productName, equals('Garlic Pork Longganisa'));
      expect(item.quantity, equals(5.0));
      expect(item.costPrice, equals(235.0));
    });

    test('handles missing or zero quantity gracefully (defaults to 1.0)', () {
      final json = {
        'productName': 'Chicken Hamonado',
        'quantity': 0,
        'costPrice': 195.5,
      };

      final item = ReceiptAiItem.fromJson(json);
      expect(item.productName, equals('Chicken Hamonado'));
      expect(item.quantity, equals(1.0));
      expect(item.costPrice, equals(195.5));
    });

    test('handles string and null safely', () {
      final json = <String, dynamic>{
        'productName': '   Pork Tapa   ',
        'quantity': 2.5,
        'costPrice': null,
      };

      final item = ReceiptAiItem.fromJson(json);
      expect(item.productName, equals('Pork Tapa'));
      expect(item.quantity, equals(2.5));
      expect(item.costPrice, equals(0.0));
    });

    test('toJson produces expected structure', () {
      const item = ReceiptAiItem(
        productName: 'Pork Tocino',
        quantity: 3.0,
        costPrice: 210.0,
      );

      final json = item.toJson();
      expect(json['productName'], equals('Pork Tocino'));
      expect(json['quantity'], equals(3.0));
      expect(json['costPrice'], equals(210.0));
    });
  });
}
