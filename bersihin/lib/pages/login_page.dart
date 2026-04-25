import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  
  // State buat toggle mata
  bool _isPasswordHidden = true;
  
  // Palette Hijau Tosca Premium
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  // Fungsi Login dengan Enkripsi Sederhana & Session
  void _handleLogin() {
    var box = Hive.box('userBox');
    String? savedUser = box.get('saved_username');
    String? savedPass = box.get('saved_password');
    
    // Enkripsi salt sederhana
    String inputEncrypted = "ENCRYPTED_" + _passwordController.text + "_bersihin_secret";

    if (_usernameController.text == savedUser && inputEncrypted == savedPass) {
      box.put('isLoggedIn', true);
      box.put('active_user', _usernameController.text);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(username: _usernameController.text)),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama pengguna atau kata sandi lu salah, Mon!', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Fungsi Login Biometrik
  Future<void> _handleBiometric() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Silakan pindai sidik jari Anda untuk masuk ke Bersih.In',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (authenticated) {
          var box = Hive.box('userBox');
          String? savedUser = box.get('saved_username') ?? "Simon Pulung";
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage(username: savedUser)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("Error Biometrik: $e");
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
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 55),
                ),
                const SizedBox(height: 25),
                Text(
                  'Bersih.In',
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 50),
                
                // Input Username
                _buildTextField(
                  controller: _usernameController,
                  hint: 'Nama Pengguna',
                  icon: Icons.person_outline,
                  isPassword: false,
                  isObscure: false,
                ),
                const SizedBox(height: 18),
                
                // Input Password dengan fitur Mata
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
                
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: toscaDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                    ),
                    child: Text(
                      'MASUK',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum memiliki akun? ', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Daftar Sekarang',
                        style: GoogleFonts.outfit(color: toscaDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 35),
                Text('Atau masuk menggunakan Biometrik', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 20),
                
                GestureDetector(
                  onTap: _handleBiometric,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: toscaMedium.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                      border: Border.all(color: toscaLight.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.fingerprint_rounded, color: toscaDark, size: 42),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget TextField udeh support ikon mata
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