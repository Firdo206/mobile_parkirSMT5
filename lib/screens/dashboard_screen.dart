import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import 'login_screen.dart';

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String _jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

String _durasi(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final j = d.inHours;
  final m = d.inMinutes % 60;
  return j > 0 ? '${j}j ${m}m' : '${m}m';
}

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.ambil();
  }

  Future<void> _muatUlang() async {
    final baru = DashboardService.ambil();
    setState(() => _future = baru);
    try {
      await baru;
    } catch (_) {
      // Galat ditampilkan oleh FutureBuilder, di sini cukup menutup spinner.
    }
  }

  bool _sedangKeluar = false;

  /// Dipakai tombol logout dan saat server menolak token (sesi habis).
  Future<void> _keLogin() async {
    if (_sedangKeluar) return;
    _sedangKeluar = true;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String get _nama =>
      (widget.user['name'] ?? widget.user['phone'] ?? '').toString();

  void _panggilPetugas() {
    // TODO: kirim plat, waktu, gerbang, dan foto kejadian ke pos petugas.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur panggil petugas belum tersambung.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _keLogin,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _panggilPetugas,
        icon: const Icon(Icons.support_agent),
        label: const Text('Panggil petugas'),
      ),
      body: RefreshIndicator(
        onRefresh: _muatUlang,
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _Memuat();
            }
            if (snap.hasError) {
              if (snap.error is SesiBerakhirException) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _keLogin());
                return const _Memuat();
              }
              return _Galat(onUlang: _muatUlang);
            }
            return _Isi(data: snap.requireData, nama: _nama);
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Keadaan: memuat & galat ─────────────────────────

class _Memuat extends StatelessWidget {
  const _Memuat();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _Galat extends StatelessWidget {
  final VoidCallback onUlang;
  const _Galat({required this.onUlang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off,
            size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(
          'Data tidak bisa dimuat.\nPeriksa sambungan Anda lalu coba lagi.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onUlang,
            child: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Isi Beranda ─────────────────────────────

class _Isi extends StatelessWidget {
  final DashboardData data;
  final String nama;
  const _Isi({required this.data, required this.nama});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final didalam = data.kendaraan.where((k) => k.didalam).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // bawah diberi ruang supaya tombol melayang tidak menutupi kartu terakhir
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('Halo, $nama', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          data.kendaraan.isEmpty
              ? 'Belum ada kendaraan terdaftar.'
              : '$didalam dari ${data.kendaraan.length} kendaraan sedang di dalam.',
          style: tema.textTheme.bodyMedium
              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _KartuPaket(paket: data.paket),
        const SizedBox(height: 24),
        Text('Kendaraan saya', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (data.kendaraan.isEmpty)
          const _KosongKendaraan()
        else
          for (final k in data.kendaraan) _KartuKendaraan(kendaraan: k),
      ],
    );
  }
}

// ───────────────────────────── Kartu paket ─────────────────────────────

class _KartuPaket extends StatelessWidget {
  final PaketAktif? paket;
  const _KartuPaket({required this.paket});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final p = paket;

    if (p == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: cs.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Belum ada paket aktif', style: tema.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Hubungi petugas untuk berlangganan.',
                      style: tema.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sisa = p.sisaHari;
    final habis = sisa < 0;
    final hampir = !habis && sisa <= 7;
    final latar = habis ? cs.errorContainer : cs.primaryContainer;
    final teks = habis ? cs.onErrorContainer : cs.onPrimaryContainer;

    return Card(
      color: latar,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paket', style: tema.textTheme.labelMedium?.copyWith(color: teks)),
                      const SizedBox(height: 2),
                      Text(
                        p.nama,
                        style: tema.textTheme.headlineSmall
                            ?.copyWith(color: teks, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habis
                            ? 'Berakhir ${_tanggal(p.berakhir)}'
                            : 'Berlaku sampai ${_tanggal(p.berakhir)}',
                        style: tema.textTheme.bodyMedium?.copyWith(color: teks),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (habis)
                      Text('Kedaluwarsa',
                          style: tema.textTheme.titleMedium
                              ?.copyWith(color: teks, fontWeight: FontWeight.w700))
                    else if (sisa == 0)
                      Text('Hari terakhir',
                          style: tema.textTheme.titleMedium
                              ?.copyWith(color: teks, fontWeight: FontWeight.w700))
                    else ...[
                      Text('$sisa',
                          style: tema.textTheme.displaySmall
                              ?.copyWith(color: teks, fontWeight: FontWeight.w700, height: 1)),
                      Text('hari lagi',
                          style: tema.textTheme.labelMedium?.copyWith(color: teks)),
                    ],
                  ],
                ),
              ],
            ),
            if (!habis && p.progres != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p.progres,
                  minHeight: 6,
                  backgroundColor: teks.withOpacity(0.18),
                  color: teks,
                ),
              ),
            ],
            if (habis || hampir) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: teks),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      habis
                          ? 'Paket sudah habis. Perpanjang di pos petugas.'
                          : 'Segera perpanjang di pos petugas.',
                      style: tema.textTheme.bodySmall?.copyWith(color: teks),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Kartu kendaraan ────────────────────────────

class _KartuKendaraan extends StatelessWidget {
  final KendaraanStatus kendaraan;
  const _KartuKendaraan({required this.kendaraan});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final k = kendaraan;
    final masuk = k.masukSejak;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
              child: Icon(k.motor ? Icons.two_wheeler : Icons.directions_car),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.plat,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    masuk == null
                        ? (k.motor ? 'Motor' : 'Mobil')
                        : '${k.motor ? 'Motor' : 'Mobil'} · masuk ${_jam(masuk)} · '
                            '${_durasi(DateTime.now().difference(masuk))}',
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _LencanaStatus(didalam: k.didalam),
          ],
        ),
      ),
    );
  }
}

class _LencanaStatus extends StatelessWidget {
  final bool didalam;
  const _LencanaStatus({required this.didalam});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warna = didalam ? Colors.green.shade700 : cs.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: didalam ? Colors.green.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: warna),
      ),
      child: Text(
        didalam ? 'Di dalam' : 'Di luar',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: didalam ? Colors.white : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _KosongKendaraan extends StatelessWidget {
  const _KosongKendaraan();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined,
                size: 36, color: tema.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              'Belum ada kendaraan terdaftar.\nDaftarkan kendaraan Anda di pos petugas.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}