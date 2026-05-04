import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);

  final AuthController _authController = AuthController();

  void _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Harap isi semua data', Colors.redAccent);
      return;
    }

    // Validasi format email
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnackBar('Format email tidak valid. Contoh: nama@email.com', Colors.redAccent);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Konfirmasi kata sandi tidak cocok', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authController.register(
      _emailController.text,
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 201) {
      await _authController.saveSession(_emailController.text, _usernameController.text);
      _showSnackBar('Pendaftaran berhasil, silakan masuk', toscaMedium);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      _showSnackBar(result['body']['message'] ?? 'Pendaftaran gagal', Colors.redAccent);
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
                    const SizedBox(height: 70),
                    Text(
                      'Daftar Akun',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Alamat Email',
                      icon: Icons.email_outlined,
                      isPassword: false,
                      isObscure: false,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'Nama Pengguna',
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
                      onToggleVisibility: () =>
                          setState(() => _isPasswordHidden = !_isPasswordHidden),
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Konfirmasi Kata Sandi',
                      icon: Icons.lock_reset_outlined,
                      isPassword: true,
                      isObscure: _isConfirmPasswordHidden,
                      onToggleVisibility: () => setState(
                          () => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: toscaDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                'DAFTAR SEKARANG',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Sudah punya akun? ",
                            style: GoogleFonts.outfit(
                                color: Colors.grey.shade600, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          ),
                          child: Text(
                            "Masuk di sini",
                            style: GoogleFonts.outfit(
                                color: toscaDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ],
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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8))
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
                      isObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 22),
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
