import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profil_data.dart';
import '../services/auth_service.dart';
import '../services/change_password_screen.dart';
import '../services/profil_service.dart';
import 'login_screen.dart';

/// Warna mengikuti web ParkVisi (sama dengan login, beranda, dan riwayat).
class _Warna {
  static const navy = Color(0xFF0B1D33);
  static const navy2 = Color(0xFF132A47);
  static const teal = Color(0xFF00C2A8);
  static const tealGelap = Color(0xFF00857A);
  static const tealSoft = Color(0xFFD9F5F0);
  static const amber = Color(0xFFFFB100);
  static const paper = Color(0xFFF4F6F8);
  static const garis = Color(0xFFE4E9EE);
  static const muted = Color(0xFF5B6B7A);
  static const merah = Color(0xFFB42318);
  static const merahSoft = Color(0xFFFDECEC);
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

Widget _cahaya(double ukuran, Color warna) => Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
    );

// ───────────────────────────── Layar utama ─────────────────────────────

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  late Future<ProfilData> _future;
  String? _token; // dipakai Image.network untuk mengambil foto wajah
  bool _sedangKeluar = false;

  @override
  void initState() {
    super.initState();
    _future = ProfilService.ambil();
    AuthService.getToken().then((t) {
      if (mounted) setState(() => _token = t);
    });
  }

  Future<void> _muatUlang() async {
    final baru = ProfilService.ambil();
    setState(() => _future = baru);
    try {
      await baru;
    } catch (_) {
      // Galat ditampilkan oleh FutureBuilder, di sini cukup menutup spinner.
    }
  }

  /// Dipakai tombol Keluar dan saat server menolak token (sesi habis).
  Future<void> _keLogin() async {
    if (_sedangKeluar) return;
    _sedangKeluar = true;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _konfirmasiKeluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(color: _Warna.navy, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Anda harus masuk kembali untuk memakai aplikasi.',
          style: TextStyle(color: _Warna.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: _Warna.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: _Warna.merah,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (yakin == true) await _keLogin();
  }

  void _gantiPassword(ProfilData p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          user: {'name': p.nama, 'phone': p.phone},
        ),
      ),
    );
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _buka(Uri uri, String pesanGagal) async {
    try {
      final berhasil =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!berhasil && mounted) _snack(pesanGagal);
    } catch (_) {
      if (mounted) _snack(pesanGagal);
    }
  }

  void _bukaWhatsApp(ProfilData p) {
    _buka(
      Uri.https('wa.me', '/${p.whatsapp}', {
        'text': 'Halo petugas ParkVisi, saya ${p.nama}.',
      }),
      'WhatsApp tidak bisa dibuka di perangkat ini.',
    );
  }

  void _telepon(ProfilData p) {
    final nomor = p.telepon!.replaceAll(RegExp(r'[^0-9+]'), '');
    _buka(
      Uri(scheme: 'tel', path: nomor),
      'Aplikasi telepon tidak bisa dibuka di perangkat ini.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Warna.paper,
        body: RefreshIndicator(
          color: _Warna.tealGelap,
          edgeOffset: atas,
          onRefresh: _muatUlang,
          child: FutureBuilder<ProfilData>(
            future: _future,
            builder: (context, snap) {
              Widget halaman(ProfilData? data, List<Widget> anak) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _Kepala(data: data, token: _token, atas: atas),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: anak,
                      ),
                    ),
                  ],
                );
              }

              const memuat = SizedBox(
                height: 220,
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: _Warna.tealGelap,
                    ),
                  ),
                ),
              );

              if (snap.connectionState != ConnectionState.done) {
                return halaman(null, const [memuat]);
              }

              if (snap.hasError) {
                if (snap.error is SesiBerakhirException) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _keLogin());
                  return halaman(null, const [memuat]);
                }
                return halaman(null, [_Galat(onUlang: _muatUlang)]);
              }

              final p = snap.requireData;
              return halaman(p, [
                _KartuDataDiri(data: p),
                const SizedBox(height: 16),
                _KartuKendaraan(kendaraan: p.kendaraan),
                const SizedBox(height: 16),
                _KartuKeamanan(onGantiPassword: () => _gantiPassword(p)),
                const SizedBox(height: 16),
                _KartuPetugas(
                  adaWhatsapp: p.whatsapp != null,
                  adaTelepon: p.telepon != null,
                  onWhatsapp: () => _bukaWhatsApp(p),
                  onTelepon: () => _telepon(p),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _konfirmasiKeluar,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _Warna.merah,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFF1C4C0)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Header profil ─────────────────────────────

class _Kepala extends StatelessWidget {
  final ProfilData? data;
  final String? token;
  final double atas;
  const _Kepala({required this.data, required this.token, required this.atas});

  @override
  Widget build(BuildContext context) {
    final p = data;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Warna.navy, _Warna.navy2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _cahaya(240, const Color(0x2600C2A8)),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _cahaya(200, const Color(0x14FFB100)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, atas + 20, 20, 26),
            child: SizedBox(
              width: double.infinity,
              child: p == null ? _isiMemuat() : _isiData(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _isiMemuat() {
    return const Column(
      children: [
        SizedBox(height: 40),
        Text(
          'Akun',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Memuat profil...',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        SizedBox(height: 40),
      ],
    );
  }

  Widget _isiData(ProfilData p) {
    return Column(
      children: [
        _Avatar(data: p, token: token),
        const SizedBox(height: 14),
        Text(
          p.nama,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          p.phone,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pil(
              ikon: p.aktif ? Icons.check_circle_rounded : Icons.cancel_rounded,
              warna: p.aktif ? _Warna.teal : const Color(0xFFFF9A9A),
              teks: p.aktif ? 'Akun aktif' : 'Akun nonaktif',
            ),
            _Pil(
              ikon: p.wajahTerdaftar
                  ? Icons.face_rounded
                  : Icons.error_outline_rounded,
              warna: p.wajahTerdaftar ? _Warna.teal : _Warna.amber,
              teks: p.wajahTerdaftar
                  ? 'Wajah terdaftar'
                  : 'Wajah belum terdaftar',
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final ProfilData data;
  final String? token;
  const _Avatar({required this.data, required this.token});

  @override
  Widget build(BuildContext context) {
    final inisial = data.nama.isEmpty ? '?' : data.nama[0].toUpperCase();

    final cadangan = Container(
      color: _Warna.navy2,
      alignment: Alignment.center,
      child: Text(
        inisial,
        style: const TextStyle(
          color: _Warna.teal,
          fontSize: 36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    Widget isi = cadangan;
    if (data.wajahTerdaftar && token != null) {
      isi = Image.network(
        ProfilService.fotoUrl(data),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'image/*'},
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Selama memuat atau kalau gagal, tampilkan huruf inisial.
        loadingBuilder: (context, child, progres) =>
            progres == null ? child : cadangan,
        errorBuilder: (context, error, stackTrace) => cadangan,
      );
    }

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _Warna.teal, width: 2.5),
      ),
      child: ClipOval(child: SizedBox.expand(child: isi)),
    );
  }
}

class _Pil extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final String teks;
  const _Pil({required this.ikon, required this.warna, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 15, color: warna),
          const SizedBox(width: 6),
          Text(
            teks,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Kartu-kartu ─────────────────────────────

class _Kartu extends StatelessWidget {
  final String judul;
  final Widget child;
  const _Kartu({required this.judul, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              color: _Warna.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _KotakIkon extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final Color latar;
  const _KotakIkon({
    required this.ikon,
    this.warna = _Warna.muted,
    this.latar = _Warna.paper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(ikon, size: 20, color: warna),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;
  const _BarisInfo({
    required this.ikon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KotakIkon(ikon: ikon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _Warna.muted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                nilai,
                style: const TextStyle(
                  color: _Warna.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KartuDataDiri extends StatelessWidget {
  final ProfilData data;
  const _KartuDataDiri({required this.data});

  @override
  Widget build(BuildContext context) {
    const pemisah = Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: _Warna.garis),
    );

    return _Kartu(
      judul: 'Data diri',
      child: Column(
        children: [
          _BarisInfo(
            ikon: Icons.phone_iphone_rounded,
            label: 'No. HP',
            nilai: data.phone,
          ),
          pemisah,
          _BarisInfo(
            ikon: Icons.mail_outline_rounded,
            label: 'Email',
            nilai: data.email ?? '-',
          ),
          pemisah,
          _BarisInfo(
            ikon: Icons.event_available_outlined,
            label: 'Terdaftar sejak',
            nilai: data.terdaftarSejak == null
                ? '-'
                : _tanggal(data.terdaftarSejak!),
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: _Warna.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data diri, kendaraan, dan foto wajah hanya bisa diubah oleh petugas.',
                  style: TextStyle(
                    color: _Warna.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KartuKendaraan extends StatelessWidget {
  final List<KendaraanProfil> kendaraan;
  const _KartuKendaraan({required this.kendaraan});

  @override
  Widget build(BuildContext context) {
    return _Kartu(
      judul: 'Kendaraan terdaftar',
      child: kendaraan.isEmpty
          ? const Text(
              'Belum ada kendaraan terdaftar. Hubungi petugas untuk mendaftarkan.',
              style: TextStyle(color: _Warna.muted, fontSize: 14, height: 1.4),
            )
          : Column(
              children: [
                for (var i = 0; i < kendaraan.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: _Warna.garis),
                    ),
                  Row(
                    children: [
                      _KotakIkon(
                        ikon: kendaraan[i].motor
                            ? Icons.two_wheeler
                            : Icons.directions_car,
                        warna: _Warna.tealGelap,
                        latar: _Warna.tealSoft,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kendaraan[i].plat,
                              style: const TextStyle(
                                color: _Warna.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kendaraan[i].motor ? 'Motor' : 'Mobil',
                              style: const TextStyle(
                                color: _Warna.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _KartuKeamanan extends StatelessWidget {
  final VoidCallback onGantiPassword;
  const _KartuKeamanan({required this.onGantiPassword});

  @override
  Widget build(BuildContext context) {
    return _Kartu(
      judul: 'Keamanan',
      child: InkWell(
        onTap: onGantiPassword,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            const _KotakIkon(ikon: Icons.lock_outline_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ganti password',
                style: TextStyle(
                  color: _Warna.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _Warna.muted),
          ],
        ),
      ),
    );
  }
}

class _KartuPetugas extends StatelessWidget {
  final bool adaWhatsapp;
  final bool adaTelepon;
  final VoidCallback onWhatsapp;
  final VoidCallback onTelepon;
  const _KartuPetugas({
    required this.adaWhatsapp,
    required this.adaTelepon,
    required this.onWhatsapp,
    required this.onTelepon,
  });

  @override
  Widget build(BuildContext context) {
    final bentukTombol = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return _Kartu(
      judul: 'Hubungi petugas',
      child: (!adaWhatsapp && !adaTelepon)
          ? const Text(
              'Kontak petugas belum tersedia.',
              style: TextStyle(color: _Warna.muted, fontSize: 14),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lupa password, wajah tidak dikenali, atau ada kendala di gerbang? Hubungi pos petugas.',
                  style: TextStyle(
                    color: _Warna.muted,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (adaWhatsapp)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onWhatsapp,
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 18),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Warna.amber,
                            foregroundColor: _Warna.navy,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: bentukTombol,
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (adaWhatsapp && adaTelepon) const SizedBox(width: 10),
                    if (adaTelepon)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onTelepon,
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('Telepon'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _Warna.navy,
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: _Warna.garis),
                            shape: bentukTombol,
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ───────────────────────────── Galat memuat ─────────────────────────────

class _Galat extends StatelessWidget {
  final VoidCallback onUlang;
  const _Galat({required this.onUlang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
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
          const Text(
            'Profil tidak bisa dimuat.\nPeriksa sambungan Anda lalu coba lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _Warna.navy, fontSize: 15, height: 1.4),
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