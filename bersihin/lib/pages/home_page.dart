import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'activity_page.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String? username;
  const HomePage({Key? key, this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Variabel buat ngatur Tamu vs User
  String _username = 'Tamu';
  bool _isGuest = true;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _bukaBrankas();
    
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.offset > 110 && !_isCollapsed) {
          setState(() => _isCollapsed = true);
        } else if (_scrollController.offset <= 110 && _isCollapsed) {
          setState(() => _isCollapsed = false);
        }
      }
    });
  }

  Future<void> _bukaBrankas() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('saved_username');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn && savedName != null) {
      setState(() {
        _username = savedName;
        _isGuest = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const ActivityPage())
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const ProfilePage())
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()), 
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController, 
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            elevation: 0,
            stretch: true,
            backgroundColor: toscaDark,
            actions: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 1.0 : 0.0, 
                child: IgnorePointer(
                  ignoring: !_isCollapsed, 
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _isGuest 
                      ? Center(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                'Login / Register',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                        ),
                  ),
                ),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                var top = constraints.biggest.height;
                double opacity = ((top - kToolbarHeight) / (200.0 - kToolbarHeight)).clamp(0.0, 1.0);
                return FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [toscaDark, toscaMedium.withOpacity(0.9), Colors.white],
                        stops: const [0.0, 0.7, 1.0], 
                      ),
                    ),
                    child: Opacity(
                      opacity: opacity, 
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 70, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Halo, Selamat Pagi', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                                if (_isGuest)
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: Text('Login / Register', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                else
                                  IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(_username, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  centerTitle: false,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isCollapsed ? 1.0 : 0.0,
                    child: Text(_username, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                );
              }
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, toscaLight.withOpacity(0.02)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // ZHANGG! Banner Terbatas buat Tamu
                    if (_isGuest)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 25),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.shade200)),
                        child: Row(
                          children: [
                            Icon(Icons.lock_person_rounded, color: Colors.amber.shade800),
                            const SizedBox(width: 15),
                            Expanded(child: Text('Akses terbatas pak! Login biar rumah lu bisa makin kinclong.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.amber.shade900))),
                          ],
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [toscaMedium, toscaLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SPECIAL OFFER', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                                const SizedBox(height: 4),
                                Text('Kebersihan rumah adalah investasi.', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 35),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    Text('Layanan Kami', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                    const SizedBox(height: 18),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 22,
                      childAspectRatio: 0.72,
                      children: [
                        _buildServiceItem(Icons.water_drop_outlined, 'Pemanas\nAir'),
                        _buildServiceItem(Icons.cleaning_services_outlined, 'Reguler'),
                        _buildServiceItem(Icons.iron_outlined, 'Setrika'),
                        _buildServiceItem(Icons.calendar_month_outlined, 'Bulanan'),
                        _buildServiceItem(Icons.home_outlined, 'Deep\nClean'),
                        _buildServiceItem(Icons.spa_outlined, 'Pijat'),
                        _buildServiceItem(Icons.ac_unit_outlined, 'Service AC'),
                        _buildServiceItem(Icons.chair_outlined, 'Cuci Sofa'), // ZHANGG! Udeh gue bersihin komennye pak!
                      ],
                    ),
                    const SizedBox(height: 160), 
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 65, height: 65,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 12,
          child: Container(
            width: 62, height: 62,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [toscaLight, toscaDark])),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

  Widget _buildServiceItem(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]),
          child: Icon(icon, size: 28, color: toscaMedium),
        ),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}