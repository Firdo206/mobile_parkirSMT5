/// Kendaraan milik member di layar Akun.
class KendaraanProfil {
  final int id;
  final String plat;
  final String? jenis; // 'motor' | 'mobil'

  KendaraanProfil({required this.id, required this.plat, required this.jenis});

  bool get motor => jenis == 'motor';

  factory KendaraanProfil.fromJson(Map<String, dynamic> j) => KendaraanProfil(
        id: (j['id'] as num).toInt(),
        plat: j['plat']?.toString() ?? '-',
        jenis: j['jenis']?.toString(),
      );
}

/// Data dari GET /api/profil (hanya baca).
class ProfilData {
  final String nama;
  final String phone;
  final String? email;
  final bool aktif;
  final DateTime? terdaftarSejak;

  final bool wajahTerdaftar;

  /// Penanda cache foto: berubah kalau petugas mengganti foto wajah.
  final int? wajahVersi;

  final List<KendaraanProfil> kendaraan;

  /// Sudah dalam format wa.me (mis. 6281335757219), null kalau belum diatur.
  final String? whatsapp;
  final String? telepon;

  ProfilData({
    required this.nama,
    required this.phone,
    required this.email,
    required this.aktif,
    required this.terdaftarSejak,
    required this.wajahTerdaftar,
    required this.wajahVersi,
    required this.kendaraan,
    required this.whatsapp,
    required this.telepon,
  });

  factory ProfilData.fromJson(Map<String, dynamic> body) {
    final d = (body['data'] as Map<String, dynamic>?) ?? body;
    final wajah = (d['wajah'] as Map<String, dynamic>?) ?? const {};
    final kontak = (d['kontak_petugas'] as Map<String, dynamic>?) ?? const {};

    String? teksAtauNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return ProfilData(
      nama: d['nama']?.toString() ?? '-',
      phone: d['phone']?.toString() ?? '-',
      email: teksAtauNull(d['email']),
      aktif: d['aktif'] == true,
      terdaftarSejak: d['terdaftar_sejak'] == null
          ? null
          : DateTime.parse(d['terdaftar_sejak'].toString()).toLocal(),
      wajahTerdaftar: wajah['terdaftar'] == true,
      wajahVersi: (wajah['versi'] as num?)?.toInt(),
      kendaraan: ((d['kendaraan'] as List<dynamic>?) ?? const [])
          .map((e) => KendaraanProfil.fromJson(e as Map<String, dynamic>))
          .toList(),
      whatsapp: teksAtauNull(kontak['whatsapp']),
      telepon: teksAtauNull(kontak['telepon']),
    );
  }
}