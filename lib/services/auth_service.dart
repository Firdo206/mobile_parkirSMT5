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

/// Dilempar saat server menolak token (401/403): sesi habis atau akun
/// dinonaktifkan. Layar yang menangkapnya sebaiknya kembali ke Login.
class SesiBerakhirException implements Exception {
  const SesiBerakhirException();
  @override
  String toString() => 'Sesi berakhir. Silakan masuk lagi.';
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
      // 401 = token tidak valid, 403 = akun dinonaktifkan admin.
      if (res.statusCode == 401 || res.statusCode == 403) {
        await _storage.delete(key: 'token');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ganti password. Dipakai saat wajib ganti (must_change_password) maupun
  /// ganti biasa dari menu Akun. Return data user terbaru.
  static Future<Map<String, dynamic>> changePassword({
    required String current,
    required String password,
    required String confirmation,
  }) async {
    final token = await getToken();
    if (token == null) throw const SesiBerakhirException();

    try {
      final res = await http
          .post(
            Uri.parse(ApiService.passwordChange),
            headers: {..._headers, 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'current_password': current,
              'password': password,
              'password_confirmation': confirmation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return body['user'] as Map<String, dynamic>;
      }
      if (res.statusCode == 401) {
        await _storage.delete(key: 'token');
        throw const SesiBerakhirException();
      }
      throw AuthException(_pesanGalat(body, 'Gagal mengganti password.'));
    } on AuthException {
      rethrow;
    } on SesiBerakhirException {
      rethrow;
    } catch (_) {
      throw AuthException('Tidak bisa terhubung ke server. Coba lagi.');
    }
  }

  /// Ambil pesan galat paling spesifik dari respons validasi Laravel.
  static String _pesanGalat(Map<String, dynamic> body, String bawaan) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final pertama = errors.values.first;
      if (pertama is List && pertama.isNotEmpty) return pertama.first.toString();
    }
    return body['message']?.toString() ?? bawaan;
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