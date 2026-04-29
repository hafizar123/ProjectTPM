import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import semua halaman lu di mari ye pak
import 'home_page.dart';
import 'activity_page.dart';
import 'kesan_pesan_page.dart';
import 'profile_page.dart';
import 'ai_chat_page.dart';

// ==========================================
// WIDGET BOTTOM NAVIGATION BAR
// ==========================================
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    // Kalo lu ngeklik menu yang lagi aktif, kaga usah ngapa-ngapain pak
    if (selectedIndex == index) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const ActivityPage();
        break;
      case 2:
        page = const KesanPesanPage(); // Halaman Evaluasi
        break;
      case 3:
        page = const ProfilePage();
        break;
      default:
        page = const HomePage();
    }

    // Pake PageRouteBuilder biar perpindahan halamannye kaga ada animasi slide (biar berasa beneran navbar)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color toscaDark = const Color(0xFF025955);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 10, // ZHANGG! Tambahin ini Mon biar kaga overflow
        unselectedFontSize: 10, // Tambahin ini juga ye
        selectedItemColor: toscaDark,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Aktivitas'),
          BottomNavigationBarItem(icon: Icon(Icons.rate_review_outlined), label: 'Evaluasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET FLOATING ACTION BUTTON (FAB)
// ==========================================
class CustomFAB extends StatelessWidget {
  const CustomFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color toscaDark = const Color(0xFF025955);
    final Color toscaLight = const Color(0xFF48C9B0);

    return SizedBox(
      width: 65, height: 65,
      child: FloatingActionButton(
        onPressed: () {
          // ZHANGG! Peratiin bae-bae ada (context) => di sini pak!
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatPage()), // <-- INI YANG BENER MON!
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 12,
        child: Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            gradient: LinearGradient(colors: [toscaLight, toscaDark])
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}