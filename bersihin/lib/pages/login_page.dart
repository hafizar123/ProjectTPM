import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ZHANGG! Pastiin ini nyambung ke file AuthService lu ye pak
import '../services/auth_service.dart'; 
import 'home_page.dart';

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

  // Palet Warna Futuristik Bersih.In
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  // ==========================================
  // LOGIKA LOGIN DENGAN ERROR HANDLING BAKU
  // ==========================================
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackbar('Mohon isi email dan kata sandi Anda.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().login(
        _emailController.text.trim(), 
        _passwordController.text
      );

      setState(() => _isLoading = false);

      if (result['statusCode'] == 200) {
        // ZHANGG! Kalo sukses masuk brankas lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', result['username'] ?? 'Pengguna');
        await prefs.setString('saved_email', _emailController.text);
        await prefs.setBool('is_logged_in', true);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autentikasi Berhasil. Selamat Datang!', style: GoogleFonts.poppins()),
            backgroundColor: toscaMedium,
          ),
        );

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomePage())
        );
      } else if (result['statusCode'] == 401) {
        _showErrorSnackbar('Login Gagal. Email atau kata sandi salah.');
      } else {
        _showErrorSnackbar('Terjadi kesalahan pada sistem. Silakan coba lagi nanti.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Koneksi gagal. Pastikan server aktif dan terhubung.');
    }
  }

  // WIDGET SNACKBAR FUTURISTIK BUAT ERROR
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, toscaLight.withOpacity(0.05)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / Ikon Bersih.In
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: toscaDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: toscaMedium.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                        ]
                      ),
                      child: const Icon(Icons.cleaning_services_rounded, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Teks Sambutan
                  Text('Selamat Datang', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 5),
                  Text('Silakan masuk ke akun Anda untuk melanjutkan.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 40),

                  // Form Email
                  _buildLabel('Alamat Email'),
                  _buildTextField(
                    controller: _emailController, 
                    hint: 'Masukkan email Anda', 
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Form Password
                  _buildLabel('Kata Sandi'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: toscaMedium),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        hintText: 'Masukkan kata sandi',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                  
                  // Lupa Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Lupa Kata Sandi?', style: GoogleFonts.poppins(color: toscaMedium, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Login
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: toscaDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: toscaMedium.withOpacity(0.5),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('MASUK', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Tombol Biometric (Opsional sesuai kriteria lu)
                  Center(
                    child: IconButton(
                      icon: Icon(Icons.fingerprint_rounded, size: 50, color: toscaMedium),
                      onPressed: () {
                        // Fitur Biometric lu bisa tancepin di mari pak
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fitur Biometrik sedang dalam pengembangan.', style: GoogleFonts.poppins()))
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: toscaDark)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: toscaMedium),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}