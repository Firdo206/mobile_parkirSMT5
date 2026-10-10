import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/change_password_screen.dart';
import 'main_shell.dart';

/// Warna mengikuti web ParkVisi (navy, cyan, amber).
class _Warna {
  static const navy = Color(0xFF0B1D33);
  static const navy2 = Color(0xFF132A47);
  static const teal = Color(0xFF00C2A8);
  static const tealGelap = Color(0xFF00857A); // teal untuk teks kecil di atas putih
  static const amber = Color(0xFFFFB100);
  static const paper = Color(0xFFF4F6F8);
  static const garis = Color(0xFFE4E9EE);
  static const muted = Color(0xFF5B6B7A);
  static const merah = Color(0xFFB42318);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'No. HP dan password wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.login(_phone.text.trim(), _password.text);
      if (!mounted) return;

      // Member yang baru di-reset admin wajib mengganti password dulu.
      final Widget tujuan = user['must_change_password'] == true
          ? ChangePasswordScreen(user: user, wajib: true)
          : MainShell(user: user);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => tujuan),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tampilan (tidak ada logika di bagian bawah ini)
  // ---------------------------------------------------------------------------

  InputDecoration _dekorasi({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _Warna.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: _Warna.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: _Warna.muted),
      floatingLabelStyle: const TextStyle(color: _Warna.tealGelap),
      border: border(Colors.transparent),
      enabledBorder: border(_Warna.garis),
      focusedBorder: border(_Warna.teal, 1.8),
    );
  }

  Widget _cahaya(double ukuran, Color warna) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Warna.navy,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Warna.navy, _Warna.navy2],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: _cahaya(280, const Color(0x2600C2A8)),
              ),
              Positioned(
                bottom: -110,
                left: -90,
                child: _cahaya(260, const Color(0x14FFB100)),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(),
                          const SizedBox(height: 28),
                          _kartuForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _Warna.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'P',
                style: TextStyle(
                  color: _Warna.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ParkVisi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Parkir tanpa tiket.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cukup wajah dan plat nomor Anda.',
          style: TextStyle(
            color: _Warna.teal,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _kartuForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Masuk',
            style: TextStyle(
              color: _Warna.navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Masuk dengan No. HP yang didaftarkan admin',
            style: TextStyle(color: _Warna.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: _Warna.navy, fontSize: 16),
            decoration: _dekorasi(
              label: 'No. HP',
              hint: '0812xxxxxxx',
              icon: Icons.phone_iphone_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(color: _Warna.navy, fontSize: 16),
            decoration: _dekorasi(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _Warna.muted,
                ),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF5C2C0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 18, color: _Warna.merah),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: _Warna.merah,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Warna.amber,
              foregroundColor: _Warna.navy,
              disabledBackgroundColor: const Color(0xB3FFB100),
              disabledForegroundColor: _Warna.navy,
              minimumSize: const Size.fromHeight(54),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _Warna.navy,
                    ),
                  )
                : const Text('Masuk'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _Warna.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: _Warna.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lupa password? Hubungi petugas parkir, reset dilakukan oleh admin.',
                    style: TextStyle(
                      color: _Warna.muted,
                      fontSize: 13,
                      height: 1.4,
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
}