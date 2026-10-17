import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/models.dart';

class ApiError implements Exception {
  final String message;
  final int? status;
  final String? code;
  final dynamic details;
  final String? method, path;
  const ApiError(
    this.message, [
    this.status,
    this.code,
    this.details,
    this.method,
    this.path,
  ]);
  @override
  String toString() => message;
}

class ApiService {
  final http.Client client;
  final String baseUrl;
  final Duration requestTimeout;
  String? token;
  Future<void> Function()? onUnauthorized;
  // Only method/path/status or an error category; never payloads or headers.
  void _trace(String method, String path, String outcome) {
    if (kDebugMode) debugPrint('[TTTP API] $method $path -> $outcome');
  }

  ApiService({
    http.Client? client,
    this.baseUrl = apiBaseUrl,
    this.requestTimeout = const Duration(seconds: 20),
  }) : client = client ?? http.Client() {
    if (kDebugMode) debugPrint('[TTTP API] baseUrl=$baseUrl');
  }
  Future<dynamic> request(
    String method,
    String path, {
    Json? body,
    Json? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);
    late final http.Response response;
    try {
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout);
    } on TimeoutException {
      _trace(method, path, 'TIMEOUT (no HTTP status)');
      throw ApiError(
        method == 'GET' || path.startsWith('/auth/')
            ? 'Kết nối quá thời gian. Vui lòng thử lại.'
            : 'Chưa xác định kết quả gửi. Hãy làm mới danh sách trước khi gửi lại.',
        null,
        'TIMEOUT',
        null,
        method,
        path,
      );
    } on http.ClientException {
      _trace(method, path, 'TRANSPORT_ERROR (no HTTP status)');
      throw ApiError(
        method == 'GET' || path.startsWith('/auth/')
            ? 'Không kết nối được máy chủ. Kiểm tra địa chỉ API và mạng.'
            : 'Kết nối bị gián đoạn, chưa xác định kết quả. Hãy làm mới danh sách trước khi gửi lại.',
        null,
        'TRANSPORT_ERROR',
        null,
        method,
        path,
      );
    }
    _trace(method, path, 'HTTP ${response.statusCode}');
    // Decoding and session callbacks must not be classified as transport errors.
    return _decode(response, method: method, path: path);
  }

  Future<dynamic> upload(String path, List<int> bytes, String name) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    try {
      return await _decode(
        await client
            .send(req)
            .then(http.Response.fromStream)
            .timeout(const Duration(seconds: 30)),
      );
    } on TimeoutException {
      throw const ApiError(
        'Chưa xác định kết quả tải ảnh. Hãy làm mới trước khi thử lại.',
      );
    } on http.ClientException {
      throw const ApiError(
        'Mất kết nối khi tải ảnh. Hãy làm mới trước khi thử lại.',
      );
    }
  }

  Future<dynamic> _decode(
    http.Response response, {
    String? method,
    String? path,
  }) async {
    final status = response.statusCode;
    if (status == 401 && token != null) {
      try {
        await onUnauthorized?.call();
      } catch (_) {
        _trace(method ?? 'HTTP', path ?? '/session', 'SESSION_CLEANUP_ERROR');
      }
    }
    dynamic data;
    try {
      data = response.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiError(
        status >= 400
            ? 'Máy chủ trả lỗi HTTP $status. Vui lòng thử lại.'
            : 'Máy chủ trả dữ liệu không hợp lệ.',
        status,
        status >= 400 ? 'HTTP_ERROR' : 'INVALID_RESPONSE',
        null,
        method,
        path,
      );
    }
    if (status >= 400) {
      final error = data is Map && data['error'] is Map
          ? data['error'] as Map
          : null;
      final message = error?['message'];
      final code = error?['code'];
      throw ApiError(
        message is String
            ? message
            : 'Máy chủ trả lỗi HTTP $status. Vui lòng thử lại.',
        status,
        code is String ? code : 'HTTP_ERROR',
        error?['details'],
        method,
        path,
      );
    }
    return data;
  }

  String imageUrl(String path) => Uri.parse(baseUrl).resolve(path).toString();
  Future<List<int>> download(String path, Json query) async {
    try {
      final response = await client
          .get(
            Uri.parse(
              '$baseUrl$path',
            ).replace(queryParameters: query.map((k, v) => MapEntry(k, '$v'))),
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          )
          .timeout(requestTimeout);
      if (response.statusCode >= 400) {
        await _decode(response);
      }
      return response.bodyBytes;
    } on TimeoutException {
      throw const ApiError('Xuất báo cáo quá thời gian. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiError('Không tải được file báo cáo. Kiểm tra kết nối.');
    }
  }
}
