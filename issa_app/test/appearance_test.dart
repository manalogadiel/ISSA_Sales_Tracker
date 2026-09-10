// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:issa_app/providers/product_appearance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductAppearance and Color Presets', () {
    test('defaultForProduct generates stable color for same id and name', () {
      final color1 = ProductColorPresets.defaultForProduct(1, 'Beef');
      final color2 = ProductColorPresets.defaultForProduct(1, 'Beef');
      expect(color1.value, equals(color2.value));
      expect(ProductColorPresets.palette.contains(color1), isTrue);
    });

    test('ProductAppearance JSON serialization roundtrip', () {
      final appearance = ProductAppearance(
        colorValue: Colors.deepPurple.value,
        imagePath: '/path/to/img.png',
      );
      final json = appearance.toJson();
      final restored = ProductAppearance.fromJson(json);

      expect(restored.colorValue, equals(Colors.deepPurple.value));
      expect(restored.imagePath, equals('/path/to/img.png'));
    });

    test('ProductAppearance copyWith works as expected', () {
      final appearance = ProductAppearance(
        colorValue: Colors.teal.value,
        imagePath: '/old/path.jpg',
      );
      final updated = appearance.copyWith(imagePath: '/new/path.jpg');
      expect(updated.colorValue, equals(Colors.teal.value));
      expect(updated.imagePath, equals('/new/path.jpg'));

      final cleared = updated.copyWith(clearColor: true, clearImage: true);
      expect(cleared.colorValue, isNull);
      expect(cleared.imagePath, isNull);
    });
  });
}
