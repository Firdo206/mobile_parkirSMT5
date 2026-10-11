/// Satu baris di daftar riwayat. [waktu] dipakai untuk mengelompokkan per hari.
abstract class RiwayatItem {
  DateTime get waktu;
}

/// Satu kunjungan parkir (tab "Kunjungan").
class Kunjungan implements RiwayatItem {
  final int id;
  final String plat;
  final String? jenis; // 'motor' | 'mobil'
  final DateTime masuk;
  final DateTime? keluar; // null = belum keluar
  final int? durasiMenit;
  final bool diDalam;

  Kunjungan({
    required this.id,
    required this.plat,
    required this.jenis,
    required this.masuk,
    required this.keluar,
    required this.durasiMenit,
    required this.diDalam,
  });

  @override
  DateTime get waktu => masuk;

  bool get motor => jenis == 'motor';

  factory Kunjungan.fromJson(Map<String, dynamic> j) {
    final k = (j['kendaraan'] as Map<String, dynamic>?) ?? const {};
    return Kunjungan(
      id: (j['id'] as num).toInt(),
      plat: k['plat']?.toString() ?? '-',
      jenis: k['jenis']?.toString(),
      masuk: DateTime.parse(j['masuk'].toString()).toLocal(),
      keluar: j['keluar'] == null
          ? null
          : DateTime.parse(j['keluar'].toString()).toLocal(),
      durasiMenit: (j['durasi_menit'] as num?)?.toInt(),
      diDalam: j['di_dalam'] == true,
    );
  }
}

/// Satu percobaan akses yang tidak normal (tab "Perlu perhatian").
/// [hasil]: ditolak_pemilik | tidak_dijawab | menunggu | ditolak
class Percobaan implements RiwayatItem {
  final int id;
  @override
  final DateTime waktu;
  final String plat;
  final String hasil;

  Percobaan({
    required this.id,
    required this.waktu,
    required this.plat,
    required this.hasil,
  });

  factory Percobaan.fromJson(Map<String, dynamic> j) {
    return Percobaan(
      id: (j['id'] as num).toInt(),
      waktu: DateTime.parse(j['waktu'].toString()).toLocal(),
      plat: j['plat']?.toString() ?? '',
      hasil: j['hasil']?.toString() ?? 'ditolak',
    );
  }
}

/// Kendaraan untuk chip filter di layar Riwayat.
class KendaraanRiwayat {
  final int id;
  final String plat;
  final String? jenis;

  KendaraanRiwayat({required this.id, required this.plat, required this.jenis});

  factory KendaraanRiwayat.fromJson(Map<String, dynamic> j) => KendaraanRiwayat(
        id: (j['id'] as num).toInt(),
        plat: j['plat']?.toString() ?? '-',
        jenis: j['jenis']?.toString(),
      );
}

/// Satu halaman hasil dari GET /api/riwayat.
class RiwayatHalaman {
  final List<RiwayatItem> items;
  final List<KendaraanRiwayat> kendaraan;
  final int menunggu; // jumlah percobaan yang menunggu jawaban member
  final int? nextPage; // null = sudah halaman terakhir

  RiwayatHalaman({
    required this.items,
    required this.kendaraan,
    required this.menunggu,
    required this.nextPage,
  });

  factory RiwayatHalaman.fromJson(Map<String, dynamic> body) {
    final meta = (body['meta'] as Map<String, dynamic>?) ?? const {};
    final data = (body['data'] as List<dynamic>?) ?? const [];

    return RiwayatHalaman(
      items: data.map<RiwayatItem>((e) {
        final j = e as Map<String, dynamic>;
        return j['tipe'] == 'kunjungan'
            ? Kunjungan.fromJson(j)
            : Percobaan.fromJson(j);
      }).toList(),
      kendaraan: ((meta['kendaraan'] as List<dynamic>?) ?? const [])
          .map((e) => KendaraanRiwayat.fromJson(e as Map<String, dynamic>))
          .toList(),
      menunggu: (meta['menunggu'] as num?)?.toInt() ?? 0,
      nextPage: (meta['next_page'] as num?)?.toInt(),
    );
  }
}