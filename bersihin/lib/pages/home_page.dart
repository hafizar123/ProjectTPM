import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String? username;
  const HomePage({Key? key, this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // LANGSUNG DIINISIALISASI DI SINI BIAR KAGA ERROR JING!
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Palette Tosca Premium
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    
    // Logic buat ngebaca scroll lu pak
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.offset > 110 && !_isCollapsed) {
          setState(() {
            _isCollapsed = true;
          });
        } else if (_scrollController.offset <= 110 && _isCollapsed) {
          setState(() {
            _isCollapsed = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()), 
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = widget.username != null && widget.username != "Tamu";
    String displayUsername = widget.username ?? "Tamu";

    return Scaffold(
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
            
            // ACTIONS: TOMBOL YANG MUNCUL DI NAVBAR ATAS PAS DI-SCROLL
            actions: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 1.0 : 0.0, 
                child: IgnorePointer(
                  ignoring: !_isCollapsed, 
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: !isLoggedIn 
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
                // Makin di-scroll, opasitasnya makin abis alias ilang
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
                      opacity: opacity, // INI YANG BIKIN KONTEN AWAL ILANG PAS DI-SCROLL
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 70, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Halo, Selamat Pagi',
                                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 14),
                                ),
                                // TOMBOL AWAL YANG ADA DI BAWAH PAS BELOM DI-SCROLL
                                !isLoggedIn 
                                ? GestureDetector(
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
                                  )
                                : IconButton(
                                    onPressed: _handleLogout,
                                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              displayUsername,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  centerTitle: false,
                  // NAMA KECIL MUNCUL DI NAVBAR PAS UDAH DI-SCROLL
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isCollapsed ? 1.0 : 0.0,
                    child: Text(
                      displayUsername,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [toscaMedium, toscaLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: toscaMedium.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                        ]
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
                        _buildServiceItem(Icons.chair_outlined, 'Cuci Sofa'),
                      ],
                    ),

                    const SizedBox(height: 35),
                    Text('Tips & Informasi', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                    const SizedBox(height: 15),

                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildInfoCard('AC Lebih Dingin', 'Cuci rutin AC lu biar kaga meledak Mon tagihan listriknya.', Icons.ac_unit),
                          _buildInfoCard('Bebas Tungau', 'Vakum kasur itu wajib biar kaga gatel-gatel.', Icons.bed),
                          _buildInfoCard('Hemat Waktu', 'Pake jasa Bersih.In biar lu fokus ngoding aje.', Icons.timer_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), 
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: toscaMedium.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
            ],
            border: Border.all(color: toscaLight.withOpacity(0.05)),
          ),
          child: Icon(icon, size: 28, color: toscaMedium),
        ),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
        border: Border.all(color: toscaMedium.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: toscaMedium, size: 28),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: toscaDark)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600), maxLines: 2),
        ],
      ),
    );
  }
}