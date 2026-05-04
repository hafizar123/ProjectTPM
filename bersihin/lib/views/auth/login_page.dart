import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../services/biometric_service.dart';
import '../../services/notification_service.dart';
import '../home/home_page.dart';
import '../admin/admin_dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;
  bool _biometricAvailable = false;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    // Tombol biometrik muncul selama device support — tidak perlu sudah daftar dulu
    final available = await BiometricService.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _handleBiometricLogin() async {
    // Cek apakah ada akun yang sudah daftarkan biometrik
    final hasAny = await BiometricService.hasAnyRegistered();
    if (!hasAny) {
      // Belum ada akun terdaftar — arahkan ke Settings
      _showBiometricNotRegisteredDialog();
      return;
    }

    final result = await BiometricService.authenticate();
    if (result == null) {
      _showNotif('Autentikasi biometrik gagal atau dibatalkan', isError: true);
      return;
    }

    // Selalu tampilkan dialog pilih akun setelah fingerprint berhasil
    final emails = result['emails']!.split(',');
    final chosen = await _showAccountPickerDialog(emails);
    if (chosen == null) return;
    final password = await BiometricService.getPasswordForAccount(chosen);
    if (password == null || password.isEmpty) {
      _showNotif('Data akun tidak ditemukan', isError: true);
      return;
    }
    await _loginWithCredentials(chosen, password);
  }

  Future<void> _loginWithCredentials(String email, String password) async {
    setState(() => _isLoading = true);
    final response = await _authController.login(email, password);
    setState(() => _isLoading = false);
    if (response['statusCode'] == 200) {
      // Gunakan email dari response server
      final returnedEmail = response['body']['user']?['email'] ?? email;
      final returnedUsername = response['body']['user']?['username'] ?? response['body']['username'] ?? '';
      await _authController.saveSession(returnedEmail, returnedUsername);
      await NotificationService().cancelGuestNotifications();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      _showNotif('Login biometrik gagal. Silakan login secara manual', isError: true);
    }
  }

  /// Dialog pilih akun jika lebih dari 1 akun terdaftar biometrik
  Future<String?> _showAccountPickerDialog(List<String> emails) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Pilih Akun',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
              ]),
              const SizedBox(height: 8),
              Text('Pilih akun yang ingin Anda masuki',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ...emails.map((email) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: toscaLight.withOpacity(0.2),
                  child: Icon(Icons.person_outline_rounded, color: toscaDark, size: 20),
                ),
                title: Text(email,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey.shade400),
                onTap: () => Navigator.pop(ctx, email),
              )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal',
                    style: GoogleFonts.outfit(color: Colors.grey.shade500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiometricNotRegisteredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade200, width: 2),
                ),
                child: Icon(Icons.fingerprint_rounded,
                    color: Colors.amber.shade700, size: 36),
              ),
              const SizedBox(height: 18),
              Text('Biometrik Belum Diaktifkan',
                  style: GoogleFonts.outfit(
                      fontSize: 17, fontWeight: FontWeight.bold, color: toscaDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              // Langkah-langkah
              _stepItem('1', 'Daftarkan sidik jari di perangkat',
                  'Pengaturan → Keamanan → Sidik Jari'),
              const SizedBox(height: 8),
              _stepItem('2', 'Login secara manual terlebih dahulu',
                  'Masuk menggunakan email dan kata sandi'),
              const SizedBox(height: 8),
              _stepItem('3', 'Aktifkan di Pengaturan Akun',
                  'Profil → Pengaturan Akun → aktifkan Login Biometrik'),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: toscaDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Mengerti',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepItem(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(num,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87)),
              Text(desc,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey.shade500, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    String inputText = _emailController.text.trim();
    String inputPassword = _passwordController.text.trim();

    if (inputText.isEmpty || inputPassword.isEmpty) {
      _showNotif('Harap isi semua data terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    if (inputText == 'admin') {
      final response = await _authController.loginAdmin(inputText, inputPassword);
      setState(() => _isLoading = false);

      if (response['statusCode'] == 200) {
        if (!mounted) return;
        _showNotif('Selamat datang, Admin', isError: false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else {
        _showNotif('Login admin gagal. Kata sandi salah', isError: true);
      }
    } else {
      final response = await _authController.login(inputText, inputPassword);
      setState(() => _isLoading = false);

      if (response['statusCode'] == 200) {
        // Gunakan email dari response server (bukan input, karena bisa jadi username)
        final returnedEmail = response['body']['user']?['email'] ?? inputText;
        final returnedUsername = response['body']['user']?['username'] ?? response['body']['username'] ?? '';
        await _authController.saveSession(returnedEmail, returnedUsername);
        // Batalkan notifikasi guest karena sudah login
        await NotificationService().cancelGuestNotifications();
        if (!mounted) return;
        _showNotif('Login berhasil', isError: false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        _showNotif('Email/username atau kata sandi salah', isError: true);
      }
    }
  }

  void _showNotif(String pesan, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent.shade400 : toscaMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [toscaDark, toscaMedium.withOpacity(0.1), Colors.white],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      'Bersih.In',
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke akun Anda',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 50),

                // Input Email
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email atau Nama Pengguna',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 18),

                // Input Password
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    style: GoogleFonts.outfit(fontSize: 15, color: toscaDark),
                    decoration: InputDecoration(
                      hintText: 'Kata Sandi',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: toscaMedium, size: 22),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: toscaDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'MASUK',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                // Divider "ATAU" + tombol biometrik
                if (_biometricAvailable) ...[
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('atau', style: GoogleFonts.outfit(
                          color: Colors.white60, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3), thickness: 1)),
                  ]),
                  const SizedBox(height: 20),

                  // Tombol fingerprint besar di tengah
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _handleBiometricLogin,
                      child: Column(children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: toscaMedium.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: toscaDark,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Masuk dengan Sidik Jari',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun? ",
                      style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      ),
                      child: Text(
                        "Daftar di sini",
                        style: GoogleFonts.outfit(
                          color: toscaDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),

          // ── TOMBOL BACK KE HOME (pojok kiri atas) ──────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const HomePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(fontSize: 15, color: toscaDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: toscaMedium, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
