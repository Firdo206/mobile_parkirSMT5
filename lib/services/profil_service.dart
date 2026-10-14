import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profil_data.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ProfilService {
  /// GET /api/profil
  /// - Token ditolak (401/403) -> [SesiBerakhirException], layar kembali ke Login.
  /// - Jaringan/server bermasalah -> Exception biasa, layar menampilkan "Coba lagi".
  static Future<ProfilData> ambil() async {
    final token = await AuthService.getToken();
    if (token == null) throw const SesiBerakhirException();

    final http.Response res;
    try {
      res = await http.get(
        Uri.parse(ApiService.profil),
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
      throw Exception('Gagal memuat profil (${res.statusCode}).');
    }

    return ProfilData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// URL foto wajah milik member yang sedang login. Endpoint-nya butuh header
  /// `Authorization: Bearer <token>` (dipasang di Image.network). Parameter `v`
  /// hanya penanda cache: foto dimuat ulang kalau petugas menggantinya.
  static String fotoUrl(ProfilData p) =>
      '${ApiService.profilFoto}?v=${p.wajahVersi ?? 0}';
}