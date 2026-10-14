import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/notifikasi_data.dart';
import '../services/notifikasi_service.dart';

/// Warna mengikuti dashboard_screen.dart.
class _Warna {
  static const navy = Color(0xFF0B1D33);
  static const navy2 = Color(0xFF132A47);
  static const teal = Color(0xFF00C2A8);
  static const tealGelap = Color(0xFF00857A);
  static const tealSoft = Color(0xFFD9F5F0);
  static const amber = Color(0xFFFFB100);
  static const amberSoft = Color(0xFFFFF3D6);
  static const paper = Color(0xFFF4F6F8);
  static const garis = Color(0xFFE4E9EE);
  static const muted = Color(0xFF5B6B7A);
  static const merah = Color(0xFFB42318);
  static const merahSoft = Color(0xFFFDE8E6);
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _waktu(DateTime d) {
  String dua(int v) => v.toString().padLeft(2, '0');
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}, ${dua(d.hour)}.${dua(d.minute)}';
}

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  // Harus sama dengan BUZZER_DETIK dan BUZZER_JEDA di NotifikasiController.
  // Server tetap yang memutuskan; angka ini hanya untuk tampilan hitung mundur.
  static const _buzzerDetik = 10;
  static const _buzzerJeda = 15;

  List<NotifikasiItem> _items = [];
  bool _loading = true;
  String? _error;
  int? _busyId;
  int? _buzzerSibukId;
  final Map<int, DateTime> _buzzerMulai = {};
  DateTime _diambil = DateTime.now();
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    // Ambil data baru tiap 5 detik
    _poll = Timer.periodic(
        const Duration(seconds: 5), (_) => _load(silent: true));
    // Hitung mundur lokal tiap detik (permintaan menunggu atau buzzer berjalan)
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _buzzerMulai.removeWhere((_, mulai) =>
          DateTime.now().difference(mulai).inSeconds >=
          _buzzerDetik + _buzzerJeda);
      if (_items.any((e) => e.needsAction) || _buzzerMulai.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await NotifikasiService.fetch();
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _diambil = DateTime.now();
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent || _items.isEmpty) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  int _sisaDetik(NotifikasiItem n) {
    final lewat = DateTime.now().difference(_diambil).inSeconds;
    final sisa = n.secondsLeft - lewat;
    return sisa < 0 ? 0 : sisa;
  }

  /// Keterangan di tombol buzzer, atau null kalau tombol siap ditekan.
  String? _keteranganBuzzer(int id) {
    final mulai = _buzzerMulai[id];
    if (mulai == null) return null;
    final lewat = DateTime.now().difference(mulai).inSeconds;
    if (lewat < _buzzerDetik) {
      return 'Buzzer menyala · ${_buzzerDetik - lewat} dtk';
    }
    if (lewat < _buzzerDetik + _buzzerJeda) {
      return 'Tunggu ${_buzzerDetik + _buzzerJeda - lewat} dtk';
    }
    return null;
  }

  void _snack(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  String _galat(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _respond(NotifikasiItem item, bool approve) async {
    if (!approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tolak akses?'),
          content: Text(
              'Kendaraan ${item.plate} akan ditolak dan laporan keamanan akan dibuat.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tolak',
                  style: TextStyle(color: _Warna.merah)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busyId = item.id);
    try {
      final msg = await NotifikasiService.respond(item.id, approve: approve);
      if (!mounted) return;
      // Server mematikan buzzer saat akses diizinkan.
      if (approve) _buzzerMulai.remove(item.id);
      _snack(msg);
    } catch (e) {
      if (!mounted) return;
      _snack(_galat(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
      _load(silent: true);
    }
  }

  Future<void> _buzzer(NotifikasiItem item) async {
    setState(() => _buzzerSibukId = item.id);
    try {
      final msg = await NotifikasiService.buzzer(item.id);
      if (!mounted) return;
      setState(() => _buzzerMulai[item.id] = DateTime.now());
      _snack(msg);
    } catch (e) {
      if (!mounted) return;
      _snack(_galat(e));
    } finally {
      if (mounted) setState(() => _buzzerSibukId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    final perluRespons = _items.where((e) => e.needsAction).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Warna.paper,
        body: RefreshIndicator(
          color: _Warna.tealGelap,
          edgeOffset: atas,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _Kepala(atas: atas, perluRespons: perluRespons),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: _isi(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _isi() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: _Warna.teal),
        ),
      );
    }

    if (_error != null && _items.isEmpty) {
      return _Pesan(
        ikon: Icons.cloud_off,
        teks: 'Notifikasi tidak bisa dimuat.\n$_error',
        tombol: 'Coba lagi',
        onTombol: _load,
      );
    }

    if (_items.isEmpty) {
      return const _Pesan(
        ikon: Icons.notifications_none_rounded,
        teks:
            'Belum ada notifikasi.\nPermintaan akses kendaraan akan muncul di sini.',
      );
    }

    return Column(
      children: [
        for (final n in _items)
          _KartuNotif(
            item: n,
            sisa: _sisaDetik(n),
            sibuk: _busyId == n.id,
            buzzerSibuk: _buzzerSibukId == n.id,
            buzzerKeterangan: _keteranganBuzzer(n.id),
            onTolak: () => _respond(n, false),
            onIzinkan: () => _respond(n, true),
            onBuzzer: () => _buzzer(n),
          ),
      ],
    );
  }
}

// ───────────────────────────── Header navy ─────────────────────────────

class _Kepala extends StatelessWidget {
  final double atas;
  final int perluRespons;
  const _Kepala({required this.atas, required this.perluRespons});

  @override
  Widget build(BuildContext context) {
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
            child: _cahaya(220, const Color(0x2600C2A8)),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _cahaya(180, const Color(0x14FFB100)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, atas + 20, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        perluRespons > 0
                            ? '$perluRespons permintaan menunggu respons Anda'
                            : 'Tidak ada permintaan yang menunggu',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                if (perluRespons > 0)
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _Warna.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$perluRespons',
                      style: const TextStyle(
                        color: _Warna.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cahaya(double ukuran, Color warna) => Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
      );
}

// ───────────────────────────── Kartu notifikasi ─────────────────────────────

class _KartuNotif extends StatelessWidget {
  final NotifikasiItem item;
  final int sisa;
  final bool sibuk;
  final bool buzzerSibuk;
  final String? buzzerKeterangan;
  final VoidCallback onTolak;
  final VoidCallback onIzinkan;
  final VoidCallback onBuzzer;

  const _KartuNotif({
    required this.item,
    required this.sisa,
    required this.sibuk,
    required this.buzzerSibuk,
    required this.buzzerKeterangan,
    required this.onTolak,
    required this.onIzinkan,
    required this.onBuzzer,
  });

  (IconData, Color, Color) get _gaya => switch (item.status) {
        'pending' => (Icons.shield_outlined, _Warna.amber, _Warna.amberSoft),
        'approved_by_member' =>
          (Icons.check_circle_outline, _Warna.tealGelap, _Warna.tealSoft),
        'rejected_by_member' =>
          (Icons.block_rounded, _Warna.merah, _Warna.merahSoft),
        'timeout' => (Icons.timer_off_outlined, _Warna.muted, _Warna.paper),
        _ => (Icons.cancel_outlined, _Warna.merah, _Warna.merahSoft),
      };

  Widget _chip(String teks) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: _Warna.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _Warna.garis),
        ),
        child: Text(
          teks,
          style: const TextStyle(
            color: _Warna.navy,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final (ikon, warnaIkon, latar) = _gaya;
    final n = item;
    final tombolUtama = n.bisaTolak || n.bisaIzinkan;
    final buzzerMati = buzzerSibuk || buzzerKeterangan != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: n.needsAction ? _Warna.amber : _Warna.garis,
          width: n.needsAction ? 1.6 : 1,
        ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: latar,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(ikon, color: warnaIkon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: const TextStyle(
                        color: _Warna.navy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: const TextStyle(
                        color: _Warna.muted,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 6,
                      children: [
                        if (n.plate.isNotEmpty) _chip(n.plate),
                        if (n.direction != null)
                          _chip(n.direction == 'exit' ? 'KELUAR' : 'MASUK'),
                        Text(
                          _waktu(n.requestedAt),
                          style: const TextStyle(
                              color: _Warna.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tombolUtama) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (n.bisaTolak)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: sibuk ? null : onTolak,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Warna.merah,
                        side: const BorderSide(color: _Warna.merah),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                if (n.bisaTolak && n.bisaIzinkan) const SizedBox(width: 10),
                if (n.bisaIzinkan)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: sibuk ? null : onIzinkan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Warna.teal,
                        foregroundColor: _Warna.navy,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: sibuk
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: _Warna.navy),
                            )
                          : const Text('Izinkan'),
                    ),
                  ),
              ],
            ),
          ],
          if (n.bisaBuzzer) ...[
            SizedBox(height: tombolUtama ? 10 : 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: buzzerMati ? null : onBuzzer,
                icon: buzzerSibuk
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _Warna.navy),
                      )
                    : const Icon(Icons.campaign_outlined, size: 22),
                label: Text(buzzerKeterangan ?? 'Bunyikan buzzer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Warna.navy,
                  disabledForegroundColor: _Warna.muted,
                  side: BorderSide(
                    color: buzzerMati ? _Warna.garis : _Warna.amber,
                    width: 1.4,
                  ),
                  backgroundColor:
                      buzzerMati ? null : _Warna.amberSoft.withOpacity(0.6),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (n.needsAction) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 15, color: _Warna.muted),
                const SizedBox(width: 5),
                Text(
                  sisa > 0
                      ? 'Sisa waktu $sisa detik'
                      : 'Waktu habis, menunggu pembaruan...',
                  style: const TextStyle(color: _Warna.muted, fontSize: 12.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Kosong / galat ─────────────────────────────

class _Pesan extends StatelessWidget {
  final IconData ikon;
  final String teks;
  final String? tombol;
  final VoidCallback? onTombol;

  const _Pesan({
    required this.ikon,
    required this.teks,
    this.tombol,
    this.onTombol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _Warna.garis,
              shape: BoxShape.circle,
            ),
            child: Icon(ikon, size: 34, color: _Warna.muted),
          ),
          const SizedBox(height: 16),
          Text(
            teks,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _Warna.navy, fontSize: 15, height: 1.4),
          ),
          if (tombol != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onTombol,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Warna.amber,
                foregroundColor: _Warna.navy,
                minimumSize: const Size(170, 48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: Text(tombol!),
            ),
          ],
        ],
      ),
    );
  }
}