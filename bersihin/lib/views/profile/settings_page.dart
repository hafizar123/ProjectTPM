import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../services/biometric_service.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _imagePath;
  String? _imageBase64;
  String _oldEmail = "";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled   = false;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final prefs     = await SharedPreferences.getInstance();
    final email     = prefs.getString('saved_email') ?? '';
    final enabled   = await BiometricService.isEnabledForAccount(email);
    if (mounted) setState(() {
      _biometricAvailable = available;
      _biometricEnabled   = enabled;
    });
  }

  Future<void> _toggleBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';

    if (_biometricEnabled) {
      // Nonaktifkan untuk akun ini saja
      await BiometricService.disableForAccount(email);
      setState(() => _biometricEnabled = false);
      _snack('Biometrik berhasil dinonaktifkan');
    } else {
      // Aktifkan — gunakan password tersimpan, atau string kosong sebagai placeholder
      // (biometrik hanya butuh verifikasi sidik jari, password disimpan untuk auto-login)
      final savedPass = prefs.getString('saved_password') ?? '';
      final enrolled = await BiometricService.enroll(
        email: email,
        password: savedPass,
      );
      if (enrolled) {
        setState(() => _biometricEnabled = true);
        _snack('Biometrik berhasil diaktifkan');
      } else {
        _snack('Pendaftaran biometrik dibatalkan', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent.shade400 : toscaMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  Future<void> _loadAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';

    setState(() {
      _usernameController.text = prefs.getString('saved_username') ?? '';
      _emailController.text = savedEmail;
      _oldEmail = savedEmail;
      _imagePath = prefs.getString('profile_image');
      _imageBase64 = prefs.getString('profile_base64');
    });

    // Ambil foto terbaru dari server jika sudah login
    if (savedEmail.isNotEmpty) {
      final user = await _authController.fetchAndCacheProfile(savedEmail);
      if (user != null && mounted) {
        setState(() {
          _usernameController.text = user.username;
          if (user.avatarBase64 != null && user.avatarBase64!.isNotEmpty) {
            _imageBase64 = user.avatarBase64;
            _imagePath = null; // Prioritaskan foto dari server
          }
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await _authController.pickImage(source);
    if (path != null) {
      // Langsung konversi ke Base64 untuk preview
      final base64 = await _authController.imageToBase64(path);
      setState(() {
        _imagePath = path;
        _imageBase64 = base64; // Update preview langsung
      });
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: toscaDark),
              title: Text('Ambil dari Galeri', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: toscaDark),
              title: Text('Jepret Kamera', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpdate() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data tidak boleh kosong')));
      return;
    }

    // Validasi konfirmasi password jika diisi
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      _snack('Konfirmasi kata sandi tidak cocok', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authController.updateProfile(
      oldEmail: _oldEmail,
      newEmail: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      imagePath: _imagePath,
    );

    setState(() => _isLoading = false);

    if (result['statusCode'] == 200) {
      // Simpan password baru ke prefs agar bisa dipakai biometrik
      if (_passwordController.text.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_password', _passwordController.text);
        // Update kredensial biometrik per-akun jika sudah aktif
        await BiometricService.updatePassword(
          email: _emailController.text,
          newPassword: _passwordController.text,
        );
      }
      _oldEmail = _emailController.text;
      _passwordController.clear();
      _confirmPasswordController.clear();
      await _loadAllUserData();
      if (!mounted) return;
      _snack('Data berhasil disimpan');
    } else {
      _snack('Gagal menyimpan: ${result['body']['message'] ?? 'Terjadi kesalahan'}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Pengaturan Akun', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: toscaDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              decoration: BoxDecoration(
                color: toscaDark,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          // Prioritaskan Base64 (mencakup foto baru & foto dari server)
                          backgroundImage: _imageBase64 != null
                              ? MemoryImage(base64Decode(_imageBase64!))
                              : (_imagePath != null ? FileImage(File(_imagePath!)) : null) as ImageProvider?,
                          child: (_imageBase64 == null && _imagePath == null)
                              ? Icon(Icons.person, size: 60, color: toscaDark)
                              : null,
                        ),
                      ),
                      // ZHANGG! INI OBAT ERROR BORDER KEMAREN PAK!
                      GestureDetector(
                        onTap: () => _showImagePicker(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: toscaDark, width: 2), // Border legal di Container ye!
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: toscaMedium,
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Perbarui identitas Anda di sini', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Username'),
                  _buildInput(_usernameController, Icons.person_outline_rounded),
                  const SizedBox(height: 20),
                  _buildLabel('Email Address'),
                  _buildInput(_emailController, Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildLabel('Password Baru'),
                  _buildPasswordInput(
                    controller: _passwordController,
                    hint: 'Kosongkan jika tidak ingin mengubah',
                    isObscure: _obscurePassword,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Konfirmasi Password Baru'),
                  _buildPasswordInput(
                    controller: _confirmPasswordController,
                    hint: 'Ulangi kata sandi baru',
                    isObscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 28),

                  // ── Toggle Biometrik ──────────────────────────
                  if (_biometricAvailable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: _biometricEnabled
                            ? toscaLight.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _biometricEnabled
                              ? toscaMedium.withOpacity(0.4)
                              : Colors.grey.shade200,
                          width: _biometricEnabled ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _biometricEnabled
                                ? toscaDark
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: _biometricEnabled ? Colors.white : Colors.grey.shade500,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Login Biometrik',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87)),
                            Text(
                              _biometricEnabled ? 'Aktif — sidik jari / wajah' : 'Nonaktif',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: _biometricEnabled
                                      ? toscaMedium
                                      : Colors.grey.shade500),
                            ),
                          ],
                        )),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: (_) => _toggleBiometric(),
                          activeColor: toscaDark,
                          activeTrackColor: toscaLight.withOpacity(0.4),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),
                  ],

                  GestureDetector(
                    onTap: _isLoading ? null : _handleUpdate,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [toscaMedium, toscaDark]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('SIMPAN PERUBAHAN',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Hapus Akun ────────────────────────────────
                  GestureDetector(
                    onTap: _isLoading ? null : _showDeleteAccountDialog,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever_rounded,
                              color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Hapus Akun',
                              style: GoogleFonts.outfit(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(Icons.delete_forever_rounded,
                    color: Colors.red.shade600, size: 36),
              ),
              const SizedBox(height: 18),
              Text('Hapus Akun?',
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.red.shade700)),
              const SizedBox(height: 10),
              Text(
                'Tindakan ini tidak dapat dibatalkan.\nSeluruh data akun, pesanan, dan alamat tersimpan akan dihapus secara permanen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('YA, HAPUS AKUN SAYA',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Batal',
                      style: GoogleFonts.outfit(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final result = await _authController.deleteAccount(_oldEmail);
    setState(() => _isLoading = false);

    if (result['statusCode'] == 200) {
      // Hapus semua data lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      _snack('Gagal menghapus akun. Silakan coba lagi', isError: true);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    );
  }

  Widget _buildInput(TextEditingController controller, IconData icon, {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, color: toscaMedium),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: toscaMedium),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}