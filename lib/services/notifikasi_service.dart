import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notifikasi_data.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotifikasiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil pesan dari body JSON. Kalau server membalas selain JSON
  /// (misalnya halaman galat), pakai [cadangan].
  static String _pesan(http.Response res, String cadangan) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return cadangan;
  }

  static Future<NotifikasiResult> fetch() async {
    final res = await http
        .get(Uri.parse(ApiService.notifikasi), headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat notifikasi (${res.statusCode}).');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['data'] as List)
        .map((e) => NotifikasiItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return NotifikasiResult((body['pending_count'] ?? 0) as int, list);
  }

  static Future<String> respond(int id, {required bool approve}) async {
    final res = await http
        .post(
          Uri.parse(ApiService.notifikasiRespon(id)),
          headers: await _headers(),
          body: jsonEncode({'decision': approve ? 'approve' : 'reject'}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) return _pesan(res, 'Berhasil.');
    throw Exception(_pesan(res, 'Gagal mengirim respons (${res.statusCode}).'));
  }

  /// Nyalakan buzzer di gerbang. Server membatasi lama menyala dan jedanya.
  static Future<String> buzzer(int id) async {
    final res = await http
        .post(
          Uri.parse(ApiService.notifikasiBuzzer(id)),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) return _pesan(res, 'Buzzer dinyalakan.');
    throw Exception(
        _pesan(res, 'Gagal menyalakan buzzer (${res.statusCode}).'));
  }
}