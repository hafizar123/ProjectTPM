import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ZHANGG! Pastiin ini nyambung ke file AuthService lu ye pak
import '../services/auth_service.dart'; 
import 'login_page.dart';
import 'custom_navbar.dart';
import 'service_detail_page.dart';
import 'order_pemanas_air_page.dart'; 
import 'location_picker_page.dart'; 

class HomePage extends StatefulWidget {
  final String? username;
  const HomePage({Key? key, this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService(); // ZHANGG! Inisialisasi service lu Mon
  
  bool _isCollapsed = false;
  String _username = 'Tamu';
  bool _isGuest = true;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _loadHomeData(); // ZHANGG! Tembak detektifnye pas layar kebuka
    
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

  // ==========================================
  // SEDOT USERNAME LIVE DARI DB XAMPP PAK!
  // ==========================================
  Future<void> _loadHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    // ZHANGG! Kalo di _handleLogin lu cuma nge-set 'saved_email',
    // lu cukup ngecek emailnye aje, kaga usah nungguin 'is_logged_in'
    final savedEmail = prefs.getString('saved_email') ?? "";

    if (savedEmail.isNotEmpty) {
      // Set nama sementara dari brankas lokal biar kaga kosong duluan
      setState(() {
        _isGuest = false; // Lu bukan tamu lagi Mon!
        _username = prefs.getString('saved_username') ?? "Pengguna";
      });

      // Tembak API buat dapet nama aslinye dari database!
      final response = await _authService.getProfile(savedEmail);
      
      if (response['statusCode'] == 200) {
        if (mounted) {
          setState(() {
            // ZHANGG! Pastiin 'user' ato langsung 'username' sesuai balikan API lu pak
            _username = response['body']['username'] ?? response['body']['user']['username'];
          });
        }
        // Update brankas lokal sekalian biar nyinkron pak
        await prefs.setString('saved_username', _username);
      }
    } else {
      setState(() {
        _isGuest = true;
        _username = "Tamu";
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
              Navigator.pop(context); 
              _handleLogout(); 
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
    await prefs.clear(); // Bersihin brankas HP!
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()), 
      (route) => false,
    );
  }

  void _showComingSoon(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Layanan $serviceName sedang dalam pengembangan.', style: GoogleFonts.outfit()),
        backgroundColor: toscaMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      )
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
            automaticallyImplyLeading: false, 
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
                          onPressed: _showLogoutDialog, 
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
                                  IconButton(onPressed: _showLogoutDialog, icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22)),
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
                            Expanded(child: Text('Akses terbatas. Silakan Login untuk menikmati fitur penuh.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.amber.shade900))),
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
                        _buildServiceItem(Icons.water_drop_outlined, 'Pemanas\nAir', onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => ServiceDetailPage(
                                title: 'Layanan Pemanas Air',
                                imagePath: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=2070&auto=format&fit=crop', 
                                description: 'BersihIn menyediakan solusi teknis profesional untuk perawatan dan perbaikan sistem pemanas air Anda guna menjamin ketersediaan air hangat yang stabil dan efisien di hunian Anda.',
                                targetOrderPage: const OrderPemanasAirPage(),
                                benefits: const [
                                  {
                                    'icon': Icons.flash_on_rounded,
                                    'title': 'Efisiensi Waktu',
                                    'desc': 'Teknisi profesional kami akan tiba di lokasi sesuai dengan jadwal yang Anda tentukan tanpa penundaan.',
                                  },
                                  {
                                    'icon': Icons.verified_user_rounded,
                                    'title': 'Harga Transparan',
                                    'desc': 'Seluruh rincian biaya ditampilkan secara eksplisit di awal pemesanan tanpa adanya biaya tersembunyi.',
                                  },
                                  {
                                    'icon': Icons.engineering_rounded,
                                    'title': 'Teknisi Ahli',
                                    'desc': 'Proses pengerjaan dilakukan oleh tenaga ahli yang telah melewati proses verifikasi dan pelatihan ketat.',
                                  },
                                ],
                              ),
                            ),
                          );
                        }),
                        _buildServiceItem(Icons.cleaning_services_outlined, 'Reguler', onTap: () => _showComingSoon('Reguler Cleaning')),
                        _buildServiceItem(Icons.iron_outlined, 'Setrika', onTap: () => _showComingSoon('Setrika')),
                        _buildServiceItem(Icons.calendar_month_outlined, 'Bulanan', onTap: () => _showComingSoon('Langganan Bulanan')),
                        _buildServiceItem(Icons.home_outlined, 'Deep\nClean', onTap: () => _showComingSoon('Deep Clean')),
                        _buildServiceItem(Icons.spa_outlined, 'Pijat', onTap: () => _showComingSoon('Pijat Relaksasi')),
                        _buildServiceItem(Icons.ac_unit_outlined, 'Service AC', onTap: () => _showComingSoon('Service AC')),
                        _buildServiceItem(Icons.chair_outlined, 'Cuci Sofa', onTap: () => _showComingSoon('Cuci Sofa')),
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
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0)
    );
  }

  Widget _buildServiceItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24), 
              boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: Icon(icon, size: 28, color: toscaMedium),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}