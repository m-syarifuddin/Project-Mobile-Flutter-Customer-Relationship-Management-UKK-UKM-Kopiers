
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

static final ApiClient instance = ApiClient._();

static String get defaultBaseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');

  if (configuredUrl.isNotEmpty) {
    return normalizeBaseUrl(configuredUrl);
  }

  if (kIsWeb) {
    return 'http://localhost:3000/api';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:3000/api';

    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return 'http://localhost:3000/api';

    default:
      return 'http://localhost:3000/api';
  }
}

static const _baseUrlPreferenceKey = 'kopiers_api_base_url';

static String _baseUrl = 'http://localhost:3000/api';

static String get baseUrl => _baseUrl;

String? _token;

Future<void> restore() async {
  final preferences = await SharedPreferences.getInstance();

  // Gunakan URL otomatis berdasarkan platform.
  _baseUrl = defaultBaseUrl;

  // URL yang sebelumnya dipilih pengguna tetap diprioritaskan.
  final savedBaseUrl = preferences.getString(_baseUrlPreferenceKey);

  if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
    _baseUrl = normalizeBaseUrl(savedBaseUrl);
  }

  _token =
      preferences.getString('kopiers_token') ??
      preferences.getString('kopiers_admin_token') ??
      preferences.getString('kopiers_customer_token');

  if (_token != null) {
    await preferences.setString('kopiers_token', _token!);
  }
}

static String normalizeBaseUrl(String value) {
  final uri = Uri.tryParse(value.trim());

  if (uri == null ||
      !uri.hasScheme ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException(
      'Masukkan URL API yang valid, contohnya '
      'http://localhost:3000/api.',
    );
  }

  var path = uri.path.replaceFirst(RegExp(r'/+$'), '');

  if (path.isEmpty) path = '/api';

  return uri.replace(path: path).toString();
}

  Future<void> setBaseUrl(String value) async {
    final newBaseUrl = normalizeBaseUrl(value);
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _baseUrlPreferenceKey,
      newBaseUrl,
    );

    if (_baseUrl != newBaseUrl) {
      _baseUrl = newBaseUrl;
      _token = null;

      await preferences.remove('kopiers_token');
      await preferences.remove('kopiers_admin_token');
      await preferences.remove('kopiers_customer_token');
    }
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> saveToken(String token) async {
    _token = token;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('kopiers_token', token);
    await preferences.remove('kopiers_admin_token');
    await preferences.remove('kopiers_customer_token');
  }

  Future<void> clearToken() async {
    _token = null;

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('kopiers_token');
    await preferences.remove('kopiers_admin_token');
    await preferences.remove('kopiers_customer_token');
  }

  Future<String?> _authorizationHeader() async {
    _token ??= (await SharedPreferences.getInstance()).getString(
      'kopiers_token',
    );

    if (_token == null || _token!.isEmpty) return null;

    return 'Bearer $_token';
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query,
    );

    final authorization = await _authorizationHeader();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authorization != null) {
      headers['Authorization'] = authorization;
    }

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (authorization == null &&
        path != '/auth/login' &&
        path != '/auth/register') {
      throw ApiException(
        'Sesi login tidak ditemukan. Silakan login kembali.',
        401,
      );
    }

    final request = http.Request(method, uri)
      ..headers.addAll(headers);

    if (body != null) {
      request.body = jsonEncode(body);
    }

    late http.Response response;

    try {
      response = await http.Response.fromStream(
        await request.send(),
      );
    } catch (_) {
      throw ApiException(
        'Tidak dapat menghubungi API di $baseUrl. '
        'Pastikan server berjalan dan alamat API dapat dijangkau.',
        0,
      );
    }

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'Respons API tidak dapat dibaca.',
          response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['error']?.toString() ??
              'Permintaan gagal (${response.statusCode}).')
          : 'Permintaan gagal (${response.statusCode}).';

      throw ApiException(message, response.statusCode);
    }

    return data;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) {
    return request(path, query: query);
  }

  Future<dynamic> post(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return request(
      path,
      method: 'POST',
      body: body,
    );
  }

  Future<dynamic> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return request(
      path,
      method: 'PATCH',
      body: body,
    );
  }

  Future<dynamic> put(
    String path, [
    Map<String, dynamic>? body,
  ]) {
    return request(
      path,
      method: 'PUT',
      body: body,
    );
  }

  
  Future<dynamic> delete(String path) {
    return request(
      path,
      method: 'DELETE',
    );
  }


  // ==========================================
  // VOUCHER QR
  // ==========================================

  Future<Map<String, dynamic>> validateVoucher(
    String code,
  ) async {
    final response = await post(
      '/vouchers/validate',
      {
        'code': code.trim(),
      },
    );

    if (response is! Map) {
      throw ApiException(
        'Respons validasi voucher tidak valid.',
        500,
      );
    }

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> redeemVoucher(
    String code,
  ) async {
    final response = await post(
      '/vouchers/redeem',
      {
        'code': code.trim(),
      },
    );

    if (response is! Map) {
      throw ApiException(
        'Respons penukaran voucher tidak valid.',
        500,
      );
    }

    return Map<String, dynamic>.from(response);
  }

  // ==========================================
  // DOWNLOAD LAMPIRAN
  // ==========================================

  Future<Uint8List> getBytes(String path) async {
    final authorization = await _authorizationHeader();

    if (authorization == null) {
      throw ApiException(
        'Sesi login tidak ditemukan. Silakan login kembali.',
        401,
      );
    }

    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl$path'),
    )..headers.addAll({
        'Accept': 'image/*',
        'Authorization': authorization,
      });

    late http.Response response;

    try {
      response = await http.Response.fromStream(
        await request.send(),
      );
    } catch (_) {
      throw ApiException(
        'Tidak dapat menghubungi API di $baseUrl. '
        'Pastikan server berjalan dan alamat API dapat dijangkau.',
        0,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        'Lampiran tidak dapat dimuat.',
        response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  // ==========================================
  // UNGGAH FOTO PENGADUAN
  // ==========================================

  Future<dynamic> uploadComplaintImage(
    Uint8List bytes,
    String contentType,
  ) async {
    final authorization = await _authorizationHeader();

    if (authorization == null) {
      throw ApiException(
        'Sesi login tidak ditemukan. Silakan login kembali.',
        401,
      );
    }

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/complaints/images'),
    )
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': contentType,
        'Authorization': authorization,
      })
      ..bodyBytes = bytes;

    late http.Response response;

    try {
      response = await http.Response.fromStream(
        await request.send(),
      );
    } catch (_) {
      throw ApiException(
        'Tidak dapat menghubungi API di $baseUrl. '
        'Pastikan server berjalan dan alamat API dapat dijangkau.',
        0,
      );
    }

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'Respons API tidak dapat dibaca.',
          response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = data is Map
          ? (data['error']?.toString() ??
              'Unggah foto gagal (${response.statusCode}).')
          : 'Unggah foto gagal (${response.statusCode}).';

      throw ApiException(message, response.statusCode);
    }

    return data;
  }

  // ==========================================
  // UNGGAH FOTO PRODUK
  // ==========================================

  Future<Map<String, dynamic>> uploadProductImage(
    Uint8List bytes,
    String contentType,
  ) async {
    final authorization = await _authorizationHeader();

    if (authorization == null) {
      throw ApiException(
        'Sesi login tidak ditemukan. Silakan login kembali.',
        401,
      );
    }

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/products/images'),
    )
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': contentType,
        'Authorization': authorization,
      })
      ..bodyBytes = bytes;

    late http.Response response;

    try {
      response = await http.Response.fromStream(
        await request.send(),
      );
    } catch (_) {
      throw ApiException(
        'Tidak dapat menghubungi API di $baseUrl. '
        'Pastikan server berjalan dan alamat API dapat dijangkau.',
        0,
      );
    }

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'Respons API tidak dapat dibaca.',
          response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = data is Map
          ? (data['error']?.toString() ??
              'Unggah foto gagal (${response.statusCode}).')
          : 'Unggah foto gagal (${response.statusCode}).';

      throw ApiException(message, response.statusCode);
    }

    if (data is! Map) {
      throw ApiException(
        'Respons unggah foto produk tidak valid.',
        500,
      );
    }

    return Map<String, dynamic>.from(data);
  }
}
