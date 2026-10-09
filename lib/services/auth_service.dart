import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<String?> getToken() => _storage.read(key: 'token');

  /// Login pakai No. HP. Return data user, atau lempar AuthException.
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiService.login),
            headers: _headers,
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        await _storage.write(key: 'token', value: body['token']);
        return body['user'] as Map<String, dynamic>;
      }

      final msg = body['message']?.toString() ?? 'Login gagal.';
      throw AuthException(msg);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
          'Tidak bisa terhubung ke ${ApiService.baseUrl}. '
          'Cek koneksi WiFi dan IP server di api_service.dart.');
    }
  }

  /// Cek token tersimpan. Return data user, atau null kalau tidak valid.
  static Future<Map<String, dynamic>?> me() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse(ApiService.me),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as Map<String, dynamic>)['user'];
      }
      if (res.statusCode == 401) {
        await _storage.delete(key: 'token');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse(ApiService.logout),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
    await _storage.delete(key: 'token');
  }
}