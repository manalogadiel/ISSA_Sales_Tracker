import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A candidate product extracted by Gemini AI Vision.
class ReceiptAiItem {
  const ReceiptAiItem({
    required this.productName,
    required this.quantity,
    required this.costPrice,
  });

  final String productName;
  final double quantity;
  final double costPrice;

  factory ReceiptAiItem.fromJson(Map<String, dynamic> json) {
    final name = (json['productName'] as String?)?.trim() ?? '';
    final qty = (json['quantity'] as num?)?.toDouble() ?? 1.0;
    final price = (json['costPrice'] as num?)?.toDouble() ?? 0.0;

    return ReceiptAiItem(
      productName: name,
      quantity: qty > 0 ? qty : 1.0,
      costPrice: price >= 0 ? price : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'quantity': quantity,
        'costPrice': costPrice,
      };
}

/// Manages Cloudflare Worker Proxy configuration and communication.
class ReceiptAiService {
  ReceiptAiService._();
  static final ReceiptAiService instance = ReceiptAiService._();

  static const String _kConfigFileName = 'ai_scanner_config.json';
  static const String _kDefaultProxyUrl = 'https://issa-receipt-scanner.gadielmanalo19.workers.dev/';
  String _proxyUrl = _kDefaultProxyUrl;


  String get proxyUrl => _proxyUrl;
  bool get hasProxyConfigured => _proxyUrl.trim().isNotEmpty;

  /// Loads stored proxy configuration from local app documents.
  Future<void> init() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final saved = (data['proxyUrl'] as String?)?.trim() ?? '';
        if (saved.isNotEmpty) {
          _proxyUrl = saved;
        }
      }
    } catch (e) {
      debugPrint('[ReceiptAiService] Error loading config: $e');
    }
  }

  /// Updates and persists the Cloudflare Worker proxy URL.
  Future<void> setProxyUrl(String url) async {
    _proxyUrl = url.trim();
    try {
      final file = await _getConfigFile();
      await file.writeAsString(jsonEncode({'proxyUrl': _proxyUrl}));
    } catch (e) {
      debugPrint('[ReceiptAiService] Error saving config: $e');
    }
  }

  Future<File> _getConfigFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_kConfigFileName');
  }

  /// Tests connectivity to the Cloudflare Worker proxy.
  Future<bool> testProxyConnection(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return false;

    HttpClient? client;
    try {
      final uri = Uri.parse(cleanUrl);
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.openUrl('OPTIONS', uri);
      request.headers.set('Content-Type', 'application/json');
      final response = await request.close();
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      // If OPTIONS isn't handled or returns 405, test with a dummy POST
      try {
        if (client == null) return false;
        final uri = Uri.parse(cleanUrl);
        final postReq = await client.postUrl(uri);
        postReq.headers.set('Content-Type', 'application/json');
        postReq.write(jsonEncode({'test': true}));
        final postRes = await postReq.close();
        return postRes.statusCode != 404 && postRes.statusCode != 502;
      } catch (e) {
        return false;
      }
    } finally {
      client?.close(force: true);
    }
  }

  /// Sends a receipt photo to the Gemini Cloudflare Worker proxy.
  ///
  /// Throws an [Exception] if network fails, proxy is unreachable,
  /// or Gemini returns an error, allowing callers to fall back to offline OCR.
  Future<List<ReceiptAiItem>> scanWithAi({
    required File imageFile,
    required List<String> catalog,
    String? overrideUrl,
  }) async {
    final targetUrl = (overrideUrl ?? _proxyUrl).trim();
    if (targetUrl.isEmpty) {
      throw Exception('No AI proxy URL configured. Use Settings to set up.');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final payload = {
      'imageBase64': base64Image,
      'mimeType': _detectMimeType(imageFile.path),
      'catalog': catalog,
    };

    final uri = Uri.parse(targetUrl);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);

    try {
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(payload));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
            'Proxy error (HTTP ${response.statusCode}): $responseBody');
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>?;

      if (rawItems == null) {
        throw Exception('Invalid response: missing items list');
      }

      return rawItems
          .map((item) =>
              ReceiptAiItem.fromJson(item as Map<String, dynamic>))
          .where((item) => item.productName.isNotEmpty)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
