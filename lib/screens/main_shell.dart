import 'package:flutter/material.dart';

import 'akun_screen.dart';
import 'dashboard_screen.dart';
import 'notifikasi_screen.dart';
import 'riwayat_screen.dart';

/// Warna mengikuti web ParkVisi (sama dengan layar login dan beranda).
class _Warna {
  static const navy = Color(0xFF0B1D33);
  static const tealSoft = Color(0xFFD9F5F0);
  static const paper = Color(0xFFF4F6F8);
  static const muted = Color(0xFF5B6B7A);
}

/// Kerangka utama setelah login: bottom bar dengan 4 tab.
/// Tab Beranda memakai DashboardScreen yang sudah ada.
class MainShell extends StatefulWidget {
  final Map<String, dynamic> user;
  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _tabs = [
    DashboardScreen(user: widget.user),
    const RiwayatScreen(),
    const NotifikasiScreen(),
    const AkunScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Warna.paper,
      // IndexedStack menjaga isi tiap tab tetap hidup saat pindah tab
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _BarBawah(
        index: _index,
        onPilih: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ───────────────────────────── Bottom bar ─────────────────────────────

class _BarBawah extends StatelessWidget {
  final int index;
  final ValueChanged<int> onPilih;
  const _BarBawah({required this.index, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(24));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0B1D33),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        // Gaya hanya berlaku untuk bar ini, tidak memengaruhi layar lain.
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 66,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: _Warna.tealSoft,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final aktif = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                color: aktif ? _Warna.navy : _Warna.muted,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final aktif = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: aktif ? _Warna.navy : _Warna.muted,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onPilih,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Notifikasi',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Akun',
              ),
            ],
          ),
        ),
      ),
    );
  }
}