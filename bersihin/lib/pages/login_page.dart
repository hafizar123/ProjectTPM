import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart'; 
import 'home_page.dart'; 
import 'admin_dashboard_page.dart'; 
import 'register_page.dart'; // ZHANGG! Wajib import halaman Regis pak!

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

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService(); 

  // ==========================================
  // LOGIKA LOGIN DENGAN ERROR HANDLING BAKU
  // ==========================================
  void _handleLogin() async {
    String inputText = _emailController.text.trim();
    String inputPassword = _passwordController.text.trim();

    if (inputText.isEmpty || inputPassword.isEmpty) {
      _showNotif('Isi dulu datanye pak bos!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    if (inputText == 'admin') {
      final response = await _authService.loginAdmin(inputText, inputPassword);
      
      setState(() => _isLoading = false);

      if (response['statusCode'] == 200) {
        if (!mounted) return;
        _showNotif('Selamat datang Bos Admin!', isError: false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else {
        _showNotif('Gagal login admin! Password lu salah pak.', isError: true);
      }

    } else {
      final response = await _authService.login(inputText, inputPassword);
      
      setState(() => _isLoading = false);

      if (response['statusCode'] == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', inputText);
        
        if (!mounted) return;
        _showNotif('Login berhasil! Asikin aje dah.', isError: false);
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()), 
          (route) => false, 
        );
      } else {
        _showNotif('Email atau password salah! Cek lagi pak.', isError: true);
      }
    }
  }

  void _showNotif(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade400 : toscaMedium,
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
      body: Stack(
        children: [
          SingleChildScrollView(
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

                      // Form Email / Username Admin
                      _buildLabel('Alamat Email / Username'),
                      _buildTextField(
                        controller: _emailController, 
                        hint: 'Masukkan email atau admin', 
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
                      
                      const SizedBox(height: 20),

                      // ZHANGG! Link buat nyambung ke Register pak!
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Belum punya akun? ", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                            },
                            child: Text(
                              "Daftar di sini",
                              style: GoogleFonts.poppins(color: toscaMedium, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Tombol Biometric
                      Center(
                        child: IconButton(
                          icon: Icon(Icons.fingerprint_rounded, size: 50, color: toscaMedium),
                          onPressed: () {
                            _showNotif('Fitur Biometrik sedang dalam pengembangan.', isError: false);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // ZHANGG! Tombol Back sakti di pojokan pak!
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
                  ]
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: toscaDark, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
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