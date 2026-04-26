import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 1. ZHANGG! Import service yang udeh lu bikin tadi
import '../services/auth_service.dart'; 
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 2. Tambahin controller buat Email pak!
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false; // Buat indikator loading
  
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);

  // 3. ZHANGG! Logic register baru pake AuthService
  void _handleRegister() async {
    // Validasi dasar dulu pak
    if (_emailController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      _showSnackBar('Isi semua datanya dong pak!', Colors.redAccent);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwordnye kaga cocok Mon!', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    // Manggil si abang kurir (AuthService)
    final result = await AuthService().register(
      _emailController.text,
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', _usernameController.text);
      await prefs.setString('saved_email', _emailController.text);
      _showSnackBar('ZHANGG! Berhasil Daftar, silakan masuk pak!', toscaMedium);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // Kalo email udeh dipake ato server meledak
      _showSnackBar(result['body']['message'] ?? 'Gagal daftar nih', Colors.redAccent);
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
                const SizedBox(height: 70),
                Text(
                  'Daftar Akun',
                  style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 50),
                
                // Form Email (WAJIB ADA PAK!)
                _buildTextField(
                  controller: _emailController, 
                  hint: 'Email Aktif', 
                  icon: Icons.email_outlined, 
                  isPassword: false, 
                  isObscure: false,
                ),
                const SizedBox(height: 18),
                
                _buildTextField(
                  controller: _usernameController, 
                  hint: 'Nama Pengguna Baru', 
                  icon: Icons.person_add_alt_1_outlined, 
                  isPassword: false, 
                  isObscure: false,
                ),
                const SizedBox(height: 18),
                
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
                const SizedBox(height: 18),
                
                _buildTextField(
                  controller: _confirmPasswordController, 
                  hint: 'Konfirmasi Kata Sandi', 
                  icon: Icons.lock_reset_outlined, 
                  isPassword: true, 
                  isObscure: _isConfirmPasswordHidden,
                  onToggleVisibility: () {
                    setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden);
                  }
                ),
                
                const SizedBox(height: 35),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: toscaDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('DAFTAR SEKARANG', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 25),
                // ... Sisa UI Login Link lu yang kemaren ...
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildTextField punya lu yang kemaren tetep dipake ye pak
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