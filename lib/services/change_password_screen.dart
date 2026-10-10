import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:mobile_parkir/screens/login_screen.dart';
import 'package:mobile_parkir/screens/main_shell.dart';

/// [wajib] = true saat member baru di-reset admin (must_change_password).
/// Pada mode wajib tombol kembali dimatikan; satu-satunya jalan keluar
/// selain mengganti password adalah tombol "Keluar".
class ChangePasswordScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool wajib;

  const ChangePasswordScreen({
    super.key,
    required this.user,
    this.wajib = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _keLogin() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty || _password.text.isEmpty || _confirm.text.isEmpty) {
      setState(() => _error = 'Semua kolom wajib diisi.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Password baru minimal 8 karakter.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Konfirmasi password tidak sama.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.changePassword(
        current: _current.text,
        password: _password.text,
        confirmation: _confirm.text,
      );
      if (!mounted) return;

      if (widget.wajib) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(user: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diganti.')),
        );
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SesiBerakhirException {
      await _keLogin();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _kolom({
    required TextEditingController controller,
    required String label,
    TextInputAction aksi = TextInputAction.next,
    VoidCallback? onSubmit,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: _hide,
      textInputAction: aksi,
      onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (widget.user['name'] ?? '').toString();

    return PopScope(
      canPop: !widget.wajib,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.wajib ? 'Buat Password Baru' : 'Ganti Password'),
          automaticallyImplyLeading: !widget.wajib,
          actions: [
            if (widget.wajib)
              TextButton(onPressed: _keLogin, child: const Text('Keluar')),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.wajib) ...[
                Text(
                  nama.isEmpty ? 'Selamat datang' : 'Halo, $nama',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Demi keamanan, ganti password sementara dari petugas '
                  'dengan password baru milik Anda sebelum memakai aplikasi.',
                ),
                const SizedBox(height: 24),
              ],
              _kolom(
                controller: _current,
                label: widget.wajib ? 'Password sementara' : 'Password saat ini',
                suffix: IconButton(
                  icon: Icon(_hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              const SizedBox(height: 16),
              _kolom(controller: _password, label: 'Password baru (min. 8 karakter)'),
              const SizedBox(height: 16),
              _kolom(
                controller: _confirm,
                label: 'Ulangi password baru',
                aksi: TextInputAction.done,
                onSubmit: _loading ? null : _submit,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}