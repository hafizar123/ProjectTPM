import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page.dart'; 
import 'login_page.dart';
import 'help_support_page.dart';
import 'custom_navbar.dart'; // ZHANGG! Pastiin ini udeh masuk ye pak

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _imagePath;
  String _username = "Tamu";
  String _email = "tamu@bersih.in"; 
  bool _isGuest = true;
  
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('saved_username') ?? "Tamu";
      _email = prefs.getString('saved_email') ?? "Silakan masuk untuk akses penuh";
      _imagePath = prefs.getString('profile_image');
      _isGuest = prefs.getBool('is_logged_in') == null || prefs.getBool('is_logged_in') == false;
    });
  }

  // ==========================================
  // DIALOG KONFIRMASI LOGOUT (BAHASA BAKU)
  // ==========================================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: toscaDark),
            const SizedBox(width: 10),
            Text(
              'Konfirmasi Keluar',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: toscaDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Anda? Seluruh sesi aktif akan dihentikan.',
          style: GoogleFonts.outfit(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialognye dulu pak
              _handleLogout(); // Baru eksekusi logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'KELUAR',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: toscaDark,
        elevation: 0,
        title: Text('Profil Pengguna', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, toscaLight.withOpacity(0.04)],
            ),
          ),
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(
            children: [
              // HEADER PROFIL
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
                        backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                        child: _imagePath == null 
                            ? Icon(Icons.person_outline, size: 60, color: toscaDark)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _username,
                      style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _email,
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // MENU OPSIONAL 
              _buildMenuOption(
                Icons.settings_outlined, 
                'Pengaturan Akun', 
                isDisabled: _isGuest,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ).then((value) => _loadProfileData()); 
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

              const SizedBox(height: 20),

              // TOMBOL LOGOUT / LOGIN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (_isGuest) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      } else {
                        // ZHANGG! Di mari cuma manggil dialognye doang pak
                        _showLogoutDialog();
                      }
                    },
                    icon: Icon(_isGuest ? Icons.login_rounded : Icons.logout_rounded, color: Colors.redAccent),
                    label: Text(_isGuest ? 'MASUK KE AKUN' : 'KELUAR APLIKASI', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100), // Biar kaga kena Bottom Nav
            ],
          ),
        ),
      ),
      
      // ZHANGG! NAVBAR UDEH BENER INDEX KE-3
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3)
    );
  }

  Widget _buildMenuOption(IconData icon, String title, {bool isDisabled = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!isDisabled)
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: ListTile(
          leading: Icon(icon, color: isDisabled ? Colors.grey.shade400 : toscaMedium),
          title: Text(title, style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: isDisabled ? Colors.grey.shade400 : Colors.black87
          )),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDisabled ? Colors.grey.shade300 : Colors.grey),
          onTap: isDisabled ? null : onTap,
        ),
      ),
    );
  }
}