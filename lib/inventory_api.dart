import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// pick the right base for each platform
String get _baseHost {
  if (kIsWeb) {
    return 'http://localhost:8000/api';
  }
  if (Platform.isAndroid) {
    // Physical device on same Wi-Fi
    // return 'http://142.232.152.31:8000/api';
    return 'https://f88f-142-232-152-31.ngrok-free.app/api'; // ngrok URL, might change
  }
  // iOS simulator, desktop, etc.
  return 'http://localhost:8000/api';
}

class InventoryApi {
  final Dio _dio;

  InventoryApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseHost,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
              // Allow status codes < 500 (so 404 returns a Response instead of throwing)
              validateStatus: (status) => status != null && status < 500,
            ),
          ) {
    // 1) built-in request/response logger
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );

    // 2) extra onError to print socket / timeout errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) {
          print('🔴 DioError: ${err.error}');
          if (err.response != null) {
            print(
              '   → HTTP ${err.response?.statusCode} ${err.response?.data}',
            );
          }
          handler.next(err);
        },
      ),
    );

    // 3) sanity‐check
    print('🔌 InventoryApi.baseUrl = ${_dio.options.baseUrl}');
  }

  /// debug helper: ping the inventory list
  Future<void> ping() async {
    try {
      final r = await _dio.get('/inventory');
      print('🟢 Ping /inventory → ${r.statusCode}');
    } catch (e) {
      print('🔴 Ping failed: $e');
    }
  }

  Future<Response> getItem(String skuId) {
    print('➡️ GET /inventory/$skuId');
    return _dio.get('/inventory/$skuId');
  }

  Future<Response> getAllItems() {
    print('➡️ GET /inventory');
    return _dio.get('/inventory');
  }

  Future<Response> addItem({
    required String sku,
    required String name,
    required int quantity,
  }) {
    print('POST /inventory  {sku: $sku, name: $name, qty: $quantity}');
    return _dio.post(
      '/inventory',
      data: {'sku': sku, 'name': name, 'quantity': quantity},
    );
  }

  Future<Response> updateItem({
    required String skuId,
    required String name,
    required int quantity,
  }) {
    print('PUT /inventory/$skuId  {name: $name, qty: $quantity}');
    return _dio.put(
      '/inventory/$skuId',
      data: {'name': name, 'quantity': quantity},
    );
  }

  Future<Response> deleteItem(String skuId) {
    print('DELETE /inventory/$skuId');
    return _dio.delete('/inventory/$skuId');
  }
}
