import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; 
import 'activity_page.dart';
import 'settings_page.dart'; // ZHANGG! Biar bisa pindah alam ke Setting pak
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _imagePath;
  String _username = "Tamu";
  String _email = "tamu@bersih.in"; // REVISI: Siapin variabel email pak
  bool _isGuest = true;
  
  int _selectedIndex = 3; 
  
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // REVISI: Fungsi ini sekarang narik Email jg buat gantiin tulisan "Mahasiswa"
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('saved_username') ?? "Tamu";
      _email = prefs.getString('saved_email') ?? "Login buat akses penuh pak!";
      _imagePath = prefs.getString('profile_image');
      _isGuest = prefs.getBool('is_logged_in') == null || prefs.getBool('is_logged_in') == false;
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ActivityPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: toscaDark,
        elevation: 0,
        title: Text('Profil Saya', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
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
              // HEADER PROFIL (REVISI: Foto Polos & Email Aktif)
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
                    // REVISI: TULISAN MAHASISWA UDEH GANTI JADI EMAIL USER PAK!
                    Text(
                      _email,
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // MENU OPSIONAL (REVISI: OnTap Pengaturan nyambung ke SettingsPage)
              _buildMenuOption(
                Icons.settings_outlined, 
                'Pengaturan Akun', 
                isDisabled: _isGuest,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ).then((value) => _loadProfileData()); // Refresh data pas balik
                }
              ),
              _buildMenuOption(
                Icons.history_outlined, 
                'Riwayat Pesanan', 
                isDisabled: _isGuest,
                onTap: () {}
              ),
              _buildMenuOption(
                Icons.help_outline, 
                'Bantuan & Dukungan', 
                isDisabled: false,
                onTap: () {}
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
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
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
      
      // FLOATING ACTION BUTTON
      floatingActionButton: SizedBox(
        width: 65, height: 65,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 12,
          child: Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [toscaLight, toscaDark]),
              boxShadow: [
                BoxShadow(color: toscaDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: toscaDark,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Aktivitas'),
            BottomNavigationBarItem(icon: Icon(Icons.rate_review_outlined), label: 'Kesan Pesan'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
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