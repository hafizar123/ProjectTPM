import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _imagePath;
  String _username = "Tamu";
  
  // Palette Tosca Premium
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load data dari Hive pas halaman dibuka
  void _loadProfileData() {
    var box = Hive.box('userBox');
    setState(() {
      _username = box.get('active_user') ?? "Simon Pulung";
      _imagePath = box.get('profile_image'); // Ambil foto kalo udeh ada
    });
  }

  // Fungsi milih foto (Kamera / Galeri)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      // ZHANGG! Langsung simpen path gambarnye ke Hive
      var box = Hive.box('userBox');
      box.put('profile_image', pickedFile.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto profil lu berhasil di-update pak!', style: GoogleFonts.outfit()), 
          backgroundColor: toscaMedium
        ),
      );
    }
  }

  // Pop-up milih sumber gambar
  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: toscaDark),
                title: Text('Ambil dari Galeri', style: GoogleFonts.outfit()),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: toscaDark),
                title: Text('Jepret pake Kamera', style: GoogleFonts.outfit()),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: toscaDark,
        elevation: 0,
        title: Text('Profil Saya', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile dengan Gradient Tosca
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [toscaDark, toscaMedium.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                )
              ),
              child: Column(
                children: [
                  // Avatar Area (Bisa diklik buat ganti foto)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                          ]
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: toscaLight.withOpacity(0.2),
                          // Nampilin foto kalo ada, kalo kaga ada pake icon default
                          backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                          child: _imagePath == null 
                              ? Icon(Icons.person_outline, size: 60, color: toscaDark)
                              : null,
                        ),
                      ),
                      // Ikon Kamera kecil
                      GestureDetector(
                        onTap: () => _showPicker(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
                          ),
                          child: Icon(Icons.camera_alt, color: toscaDark, size: 20),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _username,
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Mahasiswa UPNYK ALIAS Bos Bersih.In',
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Menu-menu dummy biar kaga kosong amat
            _buildMenuOption(Icons.settings_outlined, 'Pengaturan Akun'),
            _buildMenuOption(Icons.history_outlined, 'Riwayat Pesanan'),
            _buildMenuOption(Icons.help_outline, 'Bantuan & Dukungan'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: ListTile(
          leading: Icon(icon, color: toscaMedium),
          title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {},
        ),
      ),
    );
  }
}