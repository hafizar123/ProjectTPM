import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Variabel buat ngatur mata kebuka/ketutup ye Mon
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  
  // Palette Hijau Tosca Premium
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  void _handleRegister() {
    if (_usernameController.text.isNotEmpty && 
        _passwordController.text.isNotEmpty && 
        _passwordController.text == _confirmPasswordController.text) {
      
      var box = Hive.box('userBox');
      
      box.put('saved_username', _usernameController.text);
      String encryptedPassword = "ENCRYPTED_" + _passwordController.text + "_bersihin_secret"; 
      box.put('saved_password', encryptedPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi Berhasil! Silakan Masuk.', style: GoogleFonts.outfit()),
          backgroundColor: toscaMedium,
        ),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pastikan data terisi dan kata sandi cocok.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
              colors: [toscaDark, toscaMedium.withOpacity(0.1), Colors.white],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text(
                  'Daftar Akun',
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bergabung dengan Bersih.In sekarang',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 50),
                
                // Form Inputan Username (Kaga pake icon mata)
                _buildTextField(
                  controller: _usernameController, 
                  hint: 'Nama Pengguna Baru', 
                  icon: Icons.person_add_alt_1_outlined, 
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
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  }
                ),
                const SizedBox(height: 18),
                
                // Form Inputan Konfirmasi Password
                _buildTextField(
                  controller: _confirmPasswordController, 
                  hint: 'Konfirmasi Kata Sandi', 
                  icon: Icons.lock_reset_outlined, 
                  isPassword: true, 
                  isObscure: _isConfirmPasswordHidden,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                    });
                  }
                ),
                
                const SizedBox(height: 35),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: toscaDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                      shadowColor: toscaDark.withOpacity(0.4),
                    ),
                    child: Text(
                      'DAFTAR SEKARANG',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah memiliki akun? ', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Masuk di sini',
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

  // Widget TextField yang udeh di-upgrade bisa nerima Suffix Icon
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.outfit(fontSize: 15, color: toscaDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: toscaMedium, size: 22),
          // Logika buat nampilin icon mata khusus yang isPassword-nye true
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
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