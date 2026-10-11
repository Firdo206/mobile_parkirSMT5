import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/riwayat_data.dart';
import 'api_service.dart';
import 'auth_service.dart';

class RiwayatService {
  /// GET /api/riwayat?filter=&vehicle_id=&page=
  ///
  /// [filter]: 'kunjungan' atau 'perhatian'.
  /// - Token ditolak (401/403) -> [SesiBerakhirException], layar kembali ke Login.
  /// - Jaringan/server bermasalah -> Exception biasa, layar menampilkan "Coba lagi".
  static Future<RiwayatHalaman> ambil({
    required String filter,
    int? vehicleId,
    required int page,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw const SesiBerakhirException();

    final uri = Uri.parse(ApiService.riwayat).replace(queryParameters: {
      'filter': filter,
      'page': '$page',
      if (vehicleId != null) 'vehicle_id': '$vehicleId',
    });

    final http.Response res;
    try {
      res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('Tidak bisa terhubung ke server.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw const SesiBerakhirException();
    }
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat riwayat (${res.statusCode}).');
    }

    return RiwayatHalaman.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}