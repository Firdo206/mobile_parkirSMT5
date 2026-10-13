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

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) return body['message']?.toString() ?? 'Berhasil.';
    throw Exception(body['message']?.toString() ?? 'Gagal mengirim respons.');
  }
}