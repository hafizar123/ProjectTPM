import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 1. ZHANGG! Import abang kurir lu di mari
import '../services/auth_service.dart'; 
import 'home_page.dart'; 
import 'register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);

  // 2. LOGIC LOGIN PAKE AUTH SERVICE YANG UDEH LU BIKIN
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Isi dulu email sama passwordnye Mon!', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    // Manggil fungsi login dari AuthService
    final result = await AuthService().login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 200) {
      final username = result['body']['user']['username'];
      
      // ZHANGG! Simpen nama user ke brankas lokal pak!
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setBool('is_logged_in', true);

      _showSnackBar('BHAP! Berhasil Masuk, Halo $username!', toscaMedium);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                const SizedBox(height: 80),
                const Icon(Icons.cleaning_services_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Selamat Datang',
                  style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Masuk ke akun Bersih.In lu sekarang',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 60),
                
                // Form Inputan Email
                _buildTextField(
                  controller: _emailController, 
                  hint: 'Email Aktif', 
                  icon: Icons.email_outlined, 
                  isPassword: false, 
                  isObscure: false,
                ),
                const SizedBox(height: 18),
                
                // Form Inputan Password
                _buildTextField(
                  controller: _passwordController, 
                  hint: 'Kata Sandi', 
                  icon: Icons.lock_outline, 
                  isPassword: true, 
                  isObscure: _isPasswordHidden,
                  onToggleVisibility: () {
                    setState(() => _isPasswordHidden = !_isPasswordHidden);
                  }
                ),
                
                const SizedBox(height: 40),
                
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
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('MASUK SEKARANG', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun? ', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                      },
                      child: Text(
                        'Daftar di sini',
                        style: GoogleFonts.outfit(color: toscaDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    required bool isPassword, 
    required bool isObscure,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: hint.contains('Email') ? TextInputType.emailAddress : TextInputType.text,
        style: GoogleFonts.outfit(fontSize: 15, color: toscaDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: toscaMedium, size: 22),
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 22),
                  onPressed: onToggleVisibility,
                ) 
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}