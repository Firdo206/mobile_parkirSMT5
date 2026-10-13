class ApiService {
  static const String serverIp = "192.168.1.240";
  static const String serverPort = "8000";
  // Emulator Android: ganti serverIp jadi "10.0.2.2"

  static const String baseUrl = "http://$serverIp:$serverPort/api";
  static const String storageUrl = "http://$serverIp:$serverPort";

  // Auth
  static const String login = "$baseUrl/login";
  static const String me = "$baseUrl/me";
  static const String logout = "$baseUrl/logout";
  static String get beranda => '$baseUrl/beranda';
  static String get passwordChange => '$baseUrl/password/change';
  static String get riwayat => '$baseUrl/riwayat';

  // Tambahkan endpoint lain di bawah sini, contoh:
    static String get notifikasi => '$baseUrl/notifikasi';
    static String notifikasiRespon(int id) => '$baseUrl/notifikasi/$id/respon';
  // static const String vehicles = "$baseUrl/vehicles";
}