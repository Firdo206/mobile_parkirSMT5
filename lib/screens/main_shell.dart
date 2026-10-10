import 'package:flutter/material.dart';

import 'akun_screen.dart';
import 'dashboard_screen.dart';
import 'notifikasi_screen.dart';
import 'riwayat_screen.dart';

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
      // IndexedStack menjaga isi tiap tab tetap hidup saat pindah tab
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}