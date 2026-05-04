import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../views/home/home_page.dart';
import '../views/activity/activity_page.dart';
import '../views/support/kesan_pesan_page.dart';
import '../views/profile/profile_page.dart';
import '../views/support/ai_chat_page.dart';

// ==========================================
// WIDGET BOTTOM NAVIGATION BAR
// ==========================================
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
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
        page = const EvaluasiPage();
        break;
      case 3:
        page = const ProfilePage();
        break;
      default:
        page = const HomePage();
    }

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
        selectedFontSize: 10,
        unselectedFontSize: 10,
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
    return SizedBox(
      width: 65,
      height: 65,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatPage()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 12,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF48C9B0), Color(0xFF025955)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF025955).withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
