import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';
import 'package:mobile_parkir/screens/login_screen.dart';
import 'package:mobile_parkir/screens/main_shell.dart';

/// Layar pertama saat aplikasi dibuka. Mengecek token tersimpan ke server:
/// - token valid            -> langsung masuk (tanpa login ulang)
/// - masih wajib ganti sandi -> layar ganti password
/// - tidak ada / tidak valid -> layar login
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Map<String, dynamic>?> _future = AuthService.me();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const LoginScreen();

        if (user['must_change_password'] == true) {
          return ChangePasswordScreen(user: user, wajib: true);
        }
        return MainShell(user: user);
      },
    );
  }
}