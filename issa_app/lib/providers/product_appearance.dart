import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Available preset colors for product containers.
class ProductColorPresets {
  static const List<Color> palette = [
    Color(0xFFE63946), // Coral Crimson
    Color(0xFFF77F00), // Amber Sunset
    Color(0xFFFCBF49), // Honey Gold
    Color(0xFF2A9D8F), // Teal Emerald
    Color(0xFF264653), // Deep Sea
    Color(0xFF4361EE), // Royal Blue
    Color(0xFF7209B7), // Vivid Purple
    Color(0xFFE05780), // Rose Pink
    Color(0xFF588157), // Forest Olive
    Color(0xFF6C757D), // Slate Grey
  ];

  /// Pick a consistent default color for a product if none is manually chosen.
  static Color defaultForProduct(int id, String name) {
    final hash = (name.codeUnits.fold<int>(id, (a, b) => a + b)).abs();
    return palette[hash % palette.length];
  }
}

class ProductAppearance {
  const ProductAppearance({
    this.colorValue,
    this.imagePath,
  });

  final int? colorValue;
  final String? imagePath;

  Color? get color => colorValue != null ? Color(colorValue!) : null;

  ProductAppearance copyWith({
    int? colorValue,
    bool clearColor = false,
    String? imagePath,
    bool clearImage = false,
  }) {
    return ProductAppearance(
      colorValue: clearColor ? null : (colorValue ?? this.colorValue),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toJson() => {
        if (colorValue != null) 'colorValue': colorValue,
        if (imagePath != null) 'imagePath': imagePath,
      };

  factory ProductAppearance.fromJson(Map<String, dynamic> json) {
    return ProductAppearance(
      colorValue: json['colorValue'] as int?,
      imagePath: json['imagePath'] as String?,
    );
  }
}

class ProductAppearanceNotifier
    extends StateNotifier<Map<int, ProductAppearance>> {
  ProductAppearanceNotifier() : super({}) {
    _loadFromDisk();
  }

  File? _cacheFile;

  Future<File> _getFile() async {
    if (_cacheFile != null) return _cacheFile!;
    final dir = await getApplicationDocumentsDirectory();
    _cacheFile = File('${dir.path}/product_appearance.json');
    return _cacheFile!;
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final result = <int, ProductAppearance>{};
        jsonMap.forEach((key, val) {
          final id = int.tryParse(key);
          if (id != null && val is Map<String, dynamic>) {
            result[id] = ProductAppearance.fromJson(val);
          }
        });
        state = result;
      }
    } catch (_) {
      // Ignore disk load errors and proceed with in-memory map
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getFile();
      final mapToSave = <String, dynamic>{
        for (final entry in state.entries) entry.key.toString(): entry.value.toJson(),
      };
      await file.writeAsString(jsonEncode(mapToSave));
    } catch (_) {}
  }

  Future<void> setColor(int productId, Color? color) async {
    final current = state[productId] ?? const ProductAppearance();
    final updated = color != null
        ? current.copyWith(colorValue: color.toARGB32(), clearColor: false)
        : current.copyWith(clearColor: true);

    state = {...state, productId: updated};
    await _saveToDisk();
  }

  Future<void> setImage(int productId, String? imagePath) async {
    final current = state[productId] ?? const ProductAppearance();
    final updated = imagePath != null
        ? current.copyWith(imagePath: imagePath, clearImage: false)
        : current.copyWith(clearImage: true);

    state = {...state, productId: updated};
    await _saveToDisk();
  }

  Future<void> resetAppearance(int productId) async {
    final newState = Map<int, ProductAppearance>.from(state)..remove(productId);
    state = newState;
    await _saveToDisk();
  }
}

final productAppearanceProvider = StateNotifierProvider<
    ProductAppearanceNotifier, Map<int, ProductAppearance>>((ref) {
  return ProductAppearanceNotifier();
});
