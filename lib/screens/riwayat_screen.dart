import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/riwayat_data.dart';
import '../services/auth_service.dart';
import '../services/riwayat_service.dart';
import 'login_screen.dart';

/// Warna mengikuti web ParkVisi (sama dengan login dan beranda).
class _Warna {
  static const navy = Color(0xFF0B1D33);
  static const navy2 = Color(0xFF132A47);
  static const teal = Color(0xFF00C2A8);
  static const tealGelap = Color(0xFF00857A);
  static const tealSoft = Color(0xFFD9F5F0);
  static const amber = Color(0xFFFFB100);
  static const amberGelap = Color(0xFF8A5A00);
  static const amberSoft = Color(0xFFFFF3D6);
  static const paper = Color(0xFFF4F6F8);
  static const garis = Color(0xFFE4E9EE);
  static const muted = Color(0xFF5B6B7A);
  static const merah = Color(0xFFB42318);
  static const merahSoft = Color(0xFFFDECEC);
}

// ───────────────────────────── Helper tampilan ─────────────────────────────

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

bool _hariSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _labelHari(DateTime t) {
  final now = DateTime.now();
  if (_hariSama(t, now)) return 'Hari ini';
  if (_hariSama(t, now.subtract(const Duration(days: 1)))) return 'Kemarin';
  return '${t.day} ${_bulan[t.month - 1]} ${t.year}';
}

String _jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

/// Jam saja kalau di hari yang sama dengan [acuan], selain itu ditambah tanggal.
String _waktuRingkas(DateTime t, DateTime acuan) =>
    _hariSama(t, acuan) ? _jam(t) : '${t.day} ${_bulan[t.month - 1]}, ${_jam(t)}';

String _durasiMenit(int menit) {
  final j = menit ~/ 60;
  final m = menit % 60;
  return j > 0 ? '${j}j ${m}m' : '${m}m';
}

Widget _cahaya(double ukuran, Color warna) => Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
    );

// ───────────────────────────── Layar utama ─────────────────────────────

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _scroll = ScrollController();

  String _filter = 'kunjungan'; // 'kunjungan' | 'perhatian'
  int? _vehicleId;

  List<RiwayatItem> _items = [];
  List<KendaraanRiwayat> _kendaraan = [];
  int _menunggu = 0;
  int? _nextPage;

  bool _memuat = true;
  bool _memuatLagi = false;
  bool _galatLagi = false;
  String? _galat;

  int _permintaan = 0; // penanda permintaan terbaru, untuk mengabaikan respons basi
  bool _sedangKeluar = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _muat();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 300 && !_galatLagi) _muatLagi();
  }

  /// Dipakai saat server menolak token (sesi habis / akun dinonaktifkan).
  Future<void> _keLogin() async {
    if (_sedangKeluar) return;
    _sedangKeluar = true;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /// Muat halaman pertama. [spinner] = false untuk pull-to-refresh
  /// (isi lama tetap tampil sampai data baru datang).
  Future<void> _muat({bool spinner = true}) async {
    final id = ++_permintaan;
    setState(() {
      if (spinner) _memuat = true;
      _galat = null;
      _galatLagi = false;
      _memuatLagi = false;
    });

    try {
      final r = await RiwayatService.ambil(
        filter: _filter,
        vehicleId: _vehicleId,
        page: 1,
      );
      if (!mounted || id != _permintaan) return;
      setState(() {
        _items = r.items;
        _kendaraan = r.kendaraan;
        _menunggu = r.menunggu;
        _nextPage = r.nextPage;
        _memuat = false;
      });
    } on SesiBerakhirException {
      if (mounted && id == _permintaan) _keLogin();
    } catch (e) {
      if (!mounted || id != _permintaan) return;
      setState(() {
        _galat = e.toString().replaceFirst('Exception: ', '');
        _memuat = false;
      });
    }
  }

  Future<void> _muatLagi() async {
    final halaman = _nextPage;
    if (halaman == null || _memuatLagi || _memuat) return;

    final id = _permintaan;
    setState(() {
      _memuatLagi = true;
      _galatLagi = false;
    });

    try {
      final r = await RiwayatService.ambil(
        filter: _filter,
        vehicleId: _vehicleId,
        page: halaman,
      );
      if (!mounted || id != _permintaan) return;
      setState(() {
        _items = [..._items, ...r.items];
        _nextPage = r.nextPage;
        _menunggu = r.menunggu;
        _memuatLagi = false;
      });
    } on SesiBerakhirException {
      if (mounted) _keLogin();
    } catch (_) {
      if (!mounted || id != _permintaan) return;
      setState(() {
        _memuatLagi = false;
        _galatLagi = true;
      });
    }
  }

  void _gantiFilter(String filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _vehicleId = null;
      _items = [];
    });
    _muat();
  }

  void _pilihKendaraan(int? id) {
    if (id == _vehicleId) return;
    setState(() {
      _vehicleId = id;
      _items = [];
    });
    _muat();
  }

  /// Sisipkan judul hari di antara item yang tanggalnya berbeda.
  List<Object> _susun() {
    final hasil = <Object>[];
    String? terakhir;
    for (final item in _items) {
      final label = _labelHari(item.waktu);
      if (label != terakhir) {
        hasil.add(label);
        terakhir = label;
      }
      hasil.add(item);
    }
    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    final kunjungan = _filter == 'kunjungan';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Warna.paper,
        body: Column(
          children: [
            _Kepala(
              kunjungan: kunjungan,
              menunggu: _menunggu,
              onGanti: _gantiFilter,
            ),
            if (kunjungan && _kendaraan.length > 1)
              _BarisKendaraan(
                kendaraan: _kendaraan,
                terpilih: _vehicleId,
                onPilih: _pilihKendaraan,
              ),
            Expanded(
              child: RefreshIndicator(
                color: _Warna.tealGelap,
                onRefresh: () => _muat(spinner: false),
                child: _isi(kunjungan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _isi(bool kunjungan) {
    if (_memuat) {
      return const _Terpusat(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            color: _Warna.tealGelap,
          ),
        ),
      );
    }
    if (_galat != null) {
      return _Terpusat(child: _Galat(pesan: _galat!, onUlang: _muat));
    }
    if (_items.isEmpty) {
      return _Terpusat(child: _Kosong(kunjungan: kunjungan));
    }

    final baris = _susun();

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      itemCount: baris.length + 1,
      itemBuilder: (context, i) {
        if (i == baris.length) return _footer();

        final b = baris[i];
        if (b is String) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text(
              b,
              style: const TextStyle(
                color: _Warna.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          );
        }
        if (b is Kunjungan) return _KartuKunjungan(data: b);
        if (b is Percobaan) return _KartuPercobaan(data: b);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _footer() {
    if (_memuatLagi) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _Warna.tealGelap,
            ),
          ),
        ),
      );
    }
    if (_galatLagi) {
      return Center(
        child: TextButton(
          onPressed: _muatLagi,
          child: const Text(
            'Gagal memuat. Ketuk untuk coba lagi',
            style: TextStyle(color: _Warna.tealGelap),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

// ───────────────────────────── Header + tab ─────────────────────────────

class _Kepala extends StatelessWidget {
  final bool kunjungan;
  final int menunggu;
  final ValueChanged<String> onGanti;
  const _Kepala({
    required this.kunjungan,
    required this.menunggu,
    required this.onGanti,
  });

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Warna.navy, _Warna.navy2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _cahaya(220, const Color(0x2600C2A8)),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _cahaya(180, const Color(0x14FFB100)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, atas + 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masuk dan keluar kendaraan Anda',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabPil(
                          label: 'Kunjungan',
                          aktif: kunjungan,
                          onTap: () => onGanti('kunjungan'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _TabPil(
                          label: 'Perlu perhatian',
                          aktif: !kunjungan,
                          badge: menunggu,
                          onTap: () => onGanti('perhatian'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPil extends StatelessWidget {
  final String label;
  final bool aktif;
  final int badge;
  final VoidCallback onTap;
  const _TabPil({
    required this.label,
    required this.aktif,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? _Warna.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: aktif ? _Warna.navy : Colors.white70,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _Warna.amber,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _Warna.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Chip pilih kendaraan ─────────────────────────────

class _BarisKendaraan extends StatelessWidget {
  final List<KendaraanRiwayat> kendaraan;
  final int? terpilih;
  final ValueChanged<int?> onPilih;
  const _BarisKendaraan({
    required this.kendaraan,
    required this.terpilih,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
        children: [
          _Chip(
            label: 'Semua',
            aktif: terpilih == null,
            onTap: () => onPilih(null),
          ),
          for (final k in kendaraan)
            _Chip(
              label: k.plat,
              aktif: terpilih == k.id,
              onTap: () => onPilih(k.id),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? _Warna.navy : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: aktif ? _Warna.navy : _Warna.garis),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: aktif ? Colors.white : _Warna.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Kartu kunjungan ─────────────────────────────

BoxDecoration _dekorasiKartu() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _Warna.garis),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0B1D33),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    );

class _KartuKunjungan extends StatelessWidget {
  final Kunjungan data;
  const _KartuKunjungan({required this.data});

  @override
  Widget build(BuildContext context) {
    final k = data;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _dekorasiKartu(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: k.diDalam ? _Warna.tealSoft : _Warna.paper,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              k.motor ? Icons.two_wheeler : Icons.directions_car,
              color: k.diDalam ? _Warna.tealGelap : _Warna.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.plat,
                  style: const TextStyle(
                    color: _Warna.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _BarisWaktu(
                  ikon: Icons.south_west_rounded,
                  warna: _Warna.tealGelap,
                  teks: 'Masuk ${_waktuRingkas(k.masuk, k.masuk)}',
                ),
                if (k.keluar != null) ...[
                  const SizedBox(height: 4),
                  _BarisWaktu(
                    ikon: Icons.north_east_rounded,
                    warna: _Warna.muted,
                    teks: 'Keluar ${_waktuRingkas(k.keluar!, k.masuk)}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (k.diDalam)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: _Warna.teal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Di dalam',
                style: TextStyle(
                  color: _Warna.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  k.durasiMenit == null ? '-' : _durasiMenit(k.durasiMenit!),
                  style: const TextStyle(
                    color: _Warna.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'durasi',
                  style: TextStyle(color: _Warna.muted, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BarisWaktu extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final String teks;
  const _BarisWaktu({
    required this.ikon,
    required this.warna,
    required this.teks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 15, color: warna),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            teks,
            style: TextStyle(
              color: warna,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Kartu perlu perhatian ─────────────────────────────

class _InfoHasil {
  final String label;
  final Color warna;
  final Color latar;
  final IconData ikon;
  const _InfoHasil(this.label, this.warna, this.latar, this.ikon);
}

_InfoHasil _infoHasil(String hasil) {
  switch (hasil) {
    case 'ditolak_pemilik':
      return const _InfoHasil(
          'Anda menolak akses', _Warna.merah, _Warna.merahSoft, Icons.block);
    case 'tidak_dijawab':
      return const _InfoHasil('Tidak dijawab', _Warna.amberGelap,
          _Warna.amberSoft, Icons.timer_off_outlined);
    case 'menunggu':
      return const _InfoHasil('Menunggu jawaban Anda', _Warna.tealGelap,
          _Warna.tealSoft, Icons.hourglass_top_rounded);
    default:
      return const _InfoHasil('Akses ditolak', _Warna.merah, _Warna.merahSoft,
          Icons.gpp_bad_outlined);
  }
}

class _KartuPercobaan extends StatelessWidget {
  final Percobaan data;
  const _KartuPercobaan({required this.data});

  @override
  Widget build(BuildContext context) {
    final info = _infoHasil(data.hasil);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _dekorasiKartu(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: info.latar,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(info.ikon, color: info.warna),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.plat.isEmpty ? 'Plat tidak terbaca' : data.plat,
                  style: TextStyle(
                    color: _Warna.navy,
                    fontSize: data.plat.isEmpty ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: data.plat.isEmpty ? 0 : 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: info.latar,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    info.label,
                    style: TextStyle(
                      color: info.warna,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _jam(data.waktu),
            style: const TextStyle(
              color: _Warna.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Keadaan kosong / galat ─────────────────────────────

/// Membungkus isi di dalam ListView supaya pull-to-refresh tetap bisa dipakai.
class _Terpusat extends StatelessWidget {
  final Widget child;
  const _Terpusat({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 380, child: Center(child: child)),
      ],
    );
  }
}

class _Kosong extends StatelessWidget {
  final bool kunjungan;
  const _Kosong({required this.kunjungan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kunjungan ? _Warna.garis : _Warna.tealSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              kunjungan ? Icons.history : Icons.verified_user_outlined,
              size: 34,
              color: kunjungan ? _Warna.muted : _Warna.tealGelap,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            kunjungan ? 'Belum ada riwayat' : 'Semuanya aman',
            style: const TextStyle(
              color: _Warna.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kunjungan
                ? 'Kunjungan parkir Anda akan muncul di sini.'
                : 'Tidak ada percobaan akses yang perlu Anda cek.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: _Warna.muted, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Galat extends StatelessWidget {
  final String pesan;
  final VoidCallback onUlang;
  const _Galat({required this.pesan, required this.onUlang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _Warna.garis,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off, size: 34, color: _Warna.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '$pesan\nPeriksa sambungan Anda lalu coba lagi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _Warna.navy, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onUlang,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Warna.amber,
              foregroundColor: _Warna.navy,
              minimumSize: const Size(170, 48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}