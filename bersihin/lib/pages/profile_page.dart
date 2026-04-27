import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page.dart'; 
import 'login_page.dart';
import 'help_support_page.dart';
import 'custom_navbar.dart';
import '../services/auth_service.dart'; // ZHANGG! Jangan lupa impor senjata lu pak

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService(); // Panggil service-nye Mon
  
  String? _imagePath;
  String _username = "Memuat..."; // ZHANGG! Ganti jadi memuat dulu sebelum dapet dari DB
  String _email = "tamu@bersih.in"; 
  bool _isGuest = true;
  
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);
  final Color backgroundMint = const Color(0xFFDCF2ED); 

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // ==========================================
  // SEDOT DATA LIVE DARI DB XAMPP PAK!
  // ==========================================
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    String savedEmail = prefs.getString('saved_email') ?? "";
    bool isGuest = prefs.getBool('is_logged_in') == null || prefs.getBool('is_logged_in') == false;

    setState(() {
      _email = savedEmail.isNotEmpty ? savedEmail : "Silakan masuk untuk akses penuh";
      _isGuest = isGuest;
      _imagePath = prefs.getString('profile_image');
      if (isGuest) _username = "Tamu";
    });

    // Kalo dia login, tembak API buat dapet nama aslinye dari database!
    if (!isGuest && savedEmail.isNotEmpty) {
      final response = await _authService.getProfile(savedEmail);
      
      if (response['statusCode'] == 200) {
        if (mounted) {
          setState(() {
            _username = response['body']['user']['username'];
          });
        }
        // Update brankas lokal sekalian biar nyinkron
        await prefs.setString('saved_username', _username);
      } else {
        if (mounted) {
          setState(() {
            // Kalo server ngambek, pake nama sisaan di hape aje pak
            _username = prefs.getString('saved_username') ?? "Pengguna";
          });
        }
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: toscaDark),
            const SizedBox(width: 10),
            Text('Konfirmasi Keluar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Anda? Seluruh sesi aktif akan dihentikan.',
          style: GoogleFonts.outfit(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _handleLogout(); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('KELUAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), 
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundMint, 
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [toscaDark, toscaMedium.withOpacity(0.9)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: toscaMedium.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Profil Pengguna',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: backgroundMint,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
                      ]
                    ),
                    child: ClipOval(
                      child: _imagePath != null 
                        ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                        : Icon(Icons.person_outline_rounded, size: 60, color: toscaDark),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    _username,
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  
                  Text(
                    _email,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.9), letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuOption(
                    Icons.settings_outlined, 
                    'Pengaturan Akun', 
                    isDisabled: _isGuest,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      ).then((value) => _loadProfileData()); // ZHANGG! Kalo balik dari setting, otomatis nyedot DB lagi pak!
                    }
                  ),
                  _buildMenuOption(
                    Icons.history_outlined, 
                    'Riwayat Transaksi', 
                    isDisabled: _isGuest,
                    onTap: () {}
                  ),
                  _buildMenuOption(
                    Icons.help_outline, 
                    'Pusat Bantuan', 
                    isDisabled: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                      );
                    }
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (_isGuest) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                        } else {
                          _showLogoutDialog();
                        }
                      },
                      icon: Icon(_isGuest ? Icons.login_rounded : Icons.logout_rounded, color: Colors.redAccent.shade400),
                      label: Text(_isGuest ? 'MASUK KE AKUN' : 'KELUAR APLIKASI', 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent.shade400)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.redAccent.shade400, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3)
    );
  }

  Widget _buildMenuOption(IconData icon, String title, {bool isDisabled = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: isDisabled ? Colors.grey.shade400 : toscaDark, size: 26),
        title: Text(title, style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDisabled ? Colors.grey.shade400 : Colors.black87
        )),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade500),
        onTap: isDisabled ? null : onTap,
      ),
    );
  }
}