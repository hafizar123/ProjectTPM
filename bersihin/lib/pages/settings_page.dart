import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String? _imagePath;
  String _oldEmail = "";
  bool _isLoading = false;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('saved_username') ?? "";
      _emailController.text = prefs.getString('saved_email') ?? ""; 
      _oldEmail = _emailController.text;
      _imagePath = prefs.getString('profile_image');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', pickedFile.path);
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: toscaDark),
              title: Text('Ambil dari Galeri', style: GoogleFonts.outfit()),
              onTap: () { _pickImage(ImageSource.gallery); Navigator.pop(context); },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: toscaDark),
              title: Text('Jepret Kamera', style: GoogleFonts.outfit()),
              onTap: () { _pickImage(ImageSource.camera); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpdate() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data kaga boleh kosong pak!')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService().updateProfile(
      _oldEmail, _emailController.text, _usernameController.text, _passwordController.text
    );
    setState(() => _isLoading = false);

    if (result['statusCode'] == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', _usernameController.text);
      await prefs.setString('saved_email', _emailController.text);
      _oldEmail = _emailController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ZHANGG! Data lu udeh ganteng!', style: GoogleFonts.outfit()), backgroundColor: toscaMedium)
      );
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
                          backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                          child: _imagePath == null ? Icon(Icons.person, size: 60, color: toscaDark) : null,
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
                  Text('Update identitas lu di mari ye Mon', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
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
                  _buildInput(_passwordController, Icons.lock_outline_rounded, isPass: true, hint: 'Kosongkan jika tak diubah'),
                  const SizedBox(height: 40),
                  
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
                          : Text('SIMPAN PERUBAHAN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    );
  }

  Widget _buildInput(TextEditingController controller, IconData icon, {bool isPass = false, String? hint}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: toscaMedium),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}