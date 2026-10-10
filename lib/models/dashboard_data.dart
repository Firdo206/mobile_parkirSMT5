/// Respons `GET /api/beranda` dari Laravel:
///
/// ```json
/// {
///   "paket": { "nama": "...", "mulai": "2026-10-01", "berakhir": "2026-10-31", "status": "aktif" },
///   "kendaraan": [
///     { "id": 1, "plat": "P 1234 AB", "jenis": "mobil", "masuk_sejak": "2026-10-10T07:52:00+07:00" }
///   ]
/// }
/// ```
/// `paket` bisa `null`, `masuk_sejak` bisa `null` (kendaraan di luar).
class DashboardData {
  final PaketAktif? paket;
  final List<KendaraanStatus> kendaraan;

  const DashboardData({required this.paket, required this.kendaraan});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final p = json['paket'];
    final daftar = json['kendaraan'];

    return DashboardData(
      paket: p is Map<String, dynamic> ? PaketAktif.dariJson(p) : null,
      kendaraan: daftar is List
          ? daftar
              .whereType<Map<String, dynamic>>()
              .map(KendaraanStatus.fromJson)
              .toList()
          : const [],
    );
  }
}

class PaketAktif {
  final String nama;
  final DateTime? mulai;
  final DateTime berakhir;

  /// Teks status dari server: `aktif` atau `tidak_aktif`.
  final String status;

  const PaketAktif({
    required this.nama,
    required this.mulai,
    required this.berakhir,
    required this.status,
  });

  /// `null` kalau tanggal berakhir tidak ada atau formatnya tidak terbaca,
  /// supaya layar menampilkan "Belum ada paket aktif" dan bukan error.
  static PaketAktif? dariJson(Map<String, dynamic> json) {
    final berakhir = _tanggalSaja(json['berakhir']);
    if (berakhir == null) return null;

    return PaketAktif(
      nama: (json['nama'] ?? '-').toString(),
      mulai: _tanggalSaja(json['mulai']),
      berakhir: berakhir,
      status: (json['status'] ?? '').toString(),
    );
  }

  /// Sisa hari sampai tanggal berakhir, dihitung per tanggal (jam diabaikan).
  /// `0` = hari terakhir, negatif = sudah kedaluwarsa.
  int get sisaHari {
    final sekarang = DateTime.now();
    final hariIni = DateTime.utc(sekarang.year, sekarang.month, sekarang.day);
    final akhir = DateTime.utc(berakhir.year, berakhir.month, berakhir.day);
    return akhir.difference(hariIni).inDays;
  }

  /// Porsi masa berlaku yang sudah terpakai (0.0 sampai 1.0).
  /// `null` kalau tanggal mulai tidak diketahui.
  double? get progres {
    final awal = mulai;
    if (awal == null) return null;

    final sekarang = DateTime.now();
    final hariIni = DateTime.utc(sekarang.year, sekarang.month, sekarang.day);
    final dari = DateTime.utc(awal.year, awal.month, awal.day);
    final sampai = DateTime.utc(berakhir.year, berakhir.month, berakhir.day);

    final total = sampai.difference(dari).inDays;
    if (total <= 0) return null;

    final terpakai = hariIni.difference(dari).inDays;
    return (terpakai / total).clamp(0.0, 1.0);
  }
}

class KendaraanStatus {
  final int? id;
  final String plat;
  final String jenis;

  /// Waktu masuk (zona waktu perangkat). `null` berarti kendaraan di luar.
  final DateTime? masukSejak;

  const KendaraanStatus({
    required this.id,
    required this.plat,
    required this.jenis,
    required this.masukSejak,
  });

  factory KendaraanStatus.fromJson(Map<String, dynamic> json) {
    final masuk = json['masuk_sejak'];

    return KendaraanStatus(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      plat: (json['plat'] ?? '').toString(),
      jenis: (json['jenis'] ?? '').toString(),
      // Server mengirim ISO 8601 beserta offset. toLocal() penting supaya jam
      // yang tampil sesuai jam di HP, bukan UTC.
      masukSejak: masuk is String ? DateTime.tryParse(masuk)?.toLocal() : null,
    );
  }

  bool get motor => jenis.toLowerCase() == 'motor';
  bool get didalam => masukSejak != null;
}

/// Tanggal `YYYY-MM-DD` dari Laravel -> DateTime, atau `null` kalau tidak valid.
DateTime? _tanggalSaja(Object? nilai) {
  if (nilai is! String || nilai.isEmpty) return null;
  return DateTime.tryParse(nilai);
}