import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_data.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DashboardService {
  /// Ambil data Beranda dari Laravel (GET /api/beranda).
  ///
  /// - Token ditolak (401/403) -> [SesiBerakhirException], layar kembali ke Login.
  /// - Jaringan/server bermasalah -> Exception biasa, layar menampilkan "Coba lagi".
  static Future<DashboardData> ambil() async {
    final token = await AuthService.getToken();
    if (token == null) throw const SesiBerakhirException();

    final http.Response res;
    try {
      res = await http.get(
        Uri.parse(ApiService.beranda),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('Tidak bisa terhubung ke server.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw const SesiBerakhirException();
    }
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat data (${res.statusCode}).');
    }

    return DashboardData.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}