import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../auth/login_page.dart';
import 'settings_page.dart';
import '../support/help_support_page.dart';
import '../support/notification_page.dart';
import '../support/mini_game_page.dart';
import 'transaction_history_page.dart';
import '../../widgets/custom_navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();

  String? _imageBase64;
  String _username = "Memuat...";
  String _email = "tamu@bersih.in";
  bool _isGuest = true;
  int _unreadNotif = 0;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);
  final Color backgroundMint = const Color(0xFFDCF2ED);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotifHistoryService.unreadCount();
    if (mounted) setState(() => _unreadNotif = count);
  }

  Future<void> _loadProfileData() async {
    final savedEmail = await _authController.getSavedEmail();
    final isGuest = savedEmail.isEmpty;

    // Tampilkan data cache dulu agar UI tidak kosong
    final cached = await _authController.getCachedProfile();
    if (mounted) {
      setState(() {
        _isGuest = isGuest;
        _email = isGuest ? "Silakan masuk untuk akses penuh" : savedEmail;
        _username = isGuest ? "Tamu" : cached.username;
        _imageBase64 = cached.avatarBase64;
      });
    }

    // Ambil data terbaru dari server
    if (!isGuest) {
      final user = await _authController.fetchAndCacheProfile(savedEmail);
      if (user != null && mounted) {
        setState(() {
          _username = user.username;
          if (user.avatarBase64 != null && user.avatarBase64!.isNotEmpty) {
            _imageBase64 = user.avatarBase64;
          }
        });
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
    await _authController.clearSession();
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
                      // Prioritaskan Base64 dari server/cache
                      child: _imageBase64 != null
                          ? Image.memory(
                              base64Decode(_imageBase64!),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            )
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
                      ).then((value) => _loadProfileData());
                    },
                  ),
                  // ── Menu Notifikasi dengan badge unread ──────
                  _buildMenuOption(
                    Icons.notifications_outlined,
                    'Notifikasi',
                    isDisabled: false,
                    badge: _unreadNotif > 0 ? _unreadNotif : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationPage()),
                      ).then((_) => _loadUnreadCount());
                    },
                  ),
                  _buildMenuOption(
                    Icons.history_outlined,
                    'Riwayat Transaksi',
                    isDisabled: _isGuest,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
                      );
                    },
                  ),
                  _buildMenuOption(
                    Icons.sports_esports_rounded,
                    'Mini Game',
                    isDisabled: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MiniGamePage()),
                      );
                    },
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
                    },
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: _isGuest
                        // ── Belum login → tombol hijau ──────────────────
                        ? ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            ),
                            icon: const Icon(Icons.login_rounded, color: Colors.white),
                            label: Text('MASUK KE AKUN',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF025955),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              elevation: 4,
                              shadowColor: const Color(0xFF025955).withOpacity(0.4),
                            ),
                          )
                        // ── Sudah login → tombol merah keluar ───────────
                        : OutlinedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: Icon(Icons.logout_rounded, color: Colors.redAccent.shade400),
                            label: Text('KELUAR APLIKASI',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent.shade400)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.redAccent.shade400, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
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

  Widget _buildMenuOption(IconData icon, String title, {bool isDisabled = false, VoidCallback? onTap, int? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: isDisabled ? Colors.grey.shade400 : toscaDark, size: 26),
        title: Text(title, style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDisabled ? Colors.grey.shade400 : Colors.black87,
        )),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge unread notifikasi
            if (badge != null && badge > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade500,
            ),
          ],
        ),
        onTap: isDisabled ? null : onTap,
      ),
    );
  }
}