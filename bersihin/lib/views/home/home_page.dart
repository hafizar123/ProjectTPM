import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../services/auth_service.dart';

import '../auth/login_page.dart';
import '../../widgets/custom_navbar.dart';
import '../../widgets/home_carousel.dart';
import '../order/service_detail_page.dart';
import '../order/order_layanan_page.dart';
import '../about/about_us_page.dart';
import '../support/mini_game_page.dart';

class HomePage extends StatefulWidget {
  final String? username;
  const HomePage({Key? key, this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  bool _isCollapsed = false;
  String _username = 'Tamu';
  bool _isGuest = true;
  
  // ZHANGG! Variabel buat Jam Futuristik lu Mon!
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  String _selectedZone = 'WIB'; // Default awalnye WIB pak
  
  // Peta waktu sakti buat konversi offset dari UTC
  final Map<String, int> _timeZones = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 1, // Asumsi pake British Summer Time (BST)
  };

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  // ── Shake detection ──────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _prevAccelMag = 0;
  bool _shakeOverlayShown = false;
  static const double _shakeThreshold = 500.0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _startShakeDetection();

    // Setup Timer biar detiknya jalan terus pak!
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

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

  Future<void> _loadHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? "";
    
    // ZHANGG! Kita tarik zona waktu terakhir yang disimpen pak!
    final savedZone = prefs.getString('zona_waktu') ?? 'WIB';

    if (savedEmail.isNotEmpty) {
      setState(() {
        _isGuest = false;
        _username = prefs.getString('saved_username') ?? "Pengguna";
        _selectedZone = savedZone; // Otomatis nampilin zona terakhir
      });
      
      final response = await _authService.getProfile(savedEmail);
      if (response['statusCode'] == 200) {
        if (mounted) {
          setState(() {
            _username = response['body']['username'] ?? response['body']['user']['username'];
          });
        }
        await prefs.setString('saved_username', _username);
      }
    } else {
      setState(() {
        _isGuest = true;
        _username = "Tamu";
        _selectedZone = savedZone;
      });
    }
  }


  @override
  void dispose() {
    _clockTimer?.cancel();
    _accelSub?.cancel();
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
    // Hapus sesi saja, pertahankan data order (timer & mata uang)
    await _clearSessionOnly(prefs);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  /// Hapus sesi aktif tanpa menghapus data order (timer countdown & mata uang)
  Future<void> _clearSessionOnly(dynamic prefs) async {
    final keysToRemove = [
      'saved_email', 'saved_username', 'saved_password',
      'profile_image', 'profile_base64',
      'order_address', 'order_house_type', 'order_patokan', 'zona_waktu',
    ];
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  // ── Shake detection: kocok HP di home → masuk mini game ─────
  void _startShakeDetection() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      if (!mounted || _shakeOverlayShown) return;
      final mag = event.x * event.x + event.y * event.y + event.z * event.z;
      final delta = (mag - _prevAccelMag).abs();
      _prevAccelMag = mag;
      if (delta > _shakeThreshold) {
        _shakeOverlayShown = true;
        _showShakeOverlay();
      }
    });
  }

  void _showShakeOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
        return ScaleTransition(scale: curved, child: child);
      },
      pageBuilder: (ctx, _, __) => _ShakeOverlay(
        toscaDark: toscaDark,
        toscaMedium: toscaMedium,
        toscaLight: toscaLight,
        onPlay: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a1, a2) => const MiniGamePage(),
              transitionsBuilder: (_, a1, __, child) =>
                  FadeTransition(opacity: a1, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ).then((_) {
            // Reset flag setelah kembali dari game
            if (mounted) setState(() => _shakeOverlayShown = false);
            _startShakeDetection();
          });
        },
        onDismiss: () {
          Navigator.pop(ctx);
          if (mounted) setState(() => _shakeOverlayShown = false);
          // Cooldown 5 detik sebelum bisa trigger lagi
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _startShakeDetection();
          });
        },
      ),
    );
  }

  // Sapaan otomatis berdasarkan jam zona waktu yang dipilih
  String _greetingText() {
    final utcTime = _currentTime.toUtc();
    final offset  = _timeZones[_selectedZone] ?? 7;
    final hour    = utcTime.add(Duration(hours: offset)).hour;
    if (hour >= 4  && hour < 11) return 'Halo, Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Halo, Selamat Siang';
    if (hour >= 15 && hour < 19) return 'Halo, Selamat Sore';
    return 'Halo, Selamat Malam';
  }

  // =================================================================
  // WIDGET JAM KONVERSI — ELEGAN & FUTURISTIK
  // =================================================================
  Widget _buildRealTimeClock() {
    final utcTime = _currentTime.toUtc();
    final offset  = _timeZones[_selectedZone] ?? 7;
    final zoneTime = utcTime.add(Duration(hours: offset));
    final timeString = "${zoneTime.hour.toString().padLeft(2, '0')}:${zoneTime.minute.toString().padLeft(2, '0')}:${zoneTime.second.toString().padLeft(2, '0')}";
    final dateString = _formatDate(zoneTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF025955), Color(0xFF0A1628)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF025955).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(children: [
        // Dekorasi lingkaran
        Positioned(right: -20, top: -20,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: toscaLight.withOpacity(0.06)))),
        Positioned(left: -10, bottom: -10,
          child: Container(width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: toscaMedium.withOpacity(0.08)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kiri: jam + tanggal
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.access_time_filled_rounded, color: toscaLight, size: 14),
                  const SizedBox(width: 6),
                  Text('Waktu Real-Time',
                      style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 6),
                Text(timeString,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(dateString,
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              ]),

              // Kanan: dropdown zona waktu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    dropdownColor: const Color(0xFF025955),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    items: _timeZones.keys.map((zone) => DropdownMenuItem(
                      value: zone,
                      child: Text(zone),
                    )).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _selectedZone = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('zona_waktu', val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const days   = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5FAFA),
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
            centerTitle: true,
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
                              onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()))
                                  .then((_) => _loadHomeData()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Text('Masuk / Daftar',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white, size: 22),
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
                                Text(_greetingText(),
                                    style: GoogleFonts.outfit(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14)),
                                if (_isGuest)
                                  GestureDetector(
                                    onTap: () => Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => const LoginPage()))
                                        .then((_) => _loadHomeData()),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: Text('Masuk / Daftar',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                else
                                  IconButton(
                                    onPressed: _showLogoutDialog,
                                    icon: const Icon(Icons.logout_rounded,
                                        color: Colors.white, size: 22)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(_username,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                  centerTitle: false,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isCollapsed ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(_username, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  colors: [Colors.white, const Color(0xFFF0F9F8)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Jam real-time
                    _buildRealTimeClock(),

                    // Carousel: Info App + Apa Kata Orang
                    const HomeCarousel(),
                    const SizedBox(height: 25),

                    if (_isGuest)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.lock_person_rounded,
                              color: Colors.amber.shade700, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Silakan masuk untuk menikmati fitur penuh.',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const LoginPage()))
                                .then((_) => _loadHomeData()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Masuk',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 28),
                    // ── Hint shake mini game ─────────────────────────
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: toscaDark.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: toscaLight.withOpacity(0.35)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: toscaDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.vibration_rounded,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Fitur Tersembunyi: ',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: toscaDark),
                                ),
                                TextSpan(
                                  text: 'Kocok HP kamu untuk masuk ke Mini Game!',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                    // ── Section header Layanan Kami ──────────────────
                    Row(children: [
                      Container(
                        width: 4, height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [toscaDark, toscaMedium],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Layanan Kami',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: toscaLight.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('8 Layanan',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: toscaDark, fontWeight: FontWeight.w600)),
                      ),
                    ]),
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
                                targetOrderPage: OrderLayananPage(namaLayanan: 'Pemanas Air'),
                                benefits: const [
                                  {'icon': Icons.flash_on_rounded, 'title': 'Efisiensi Waktu', 'desc': 'Teknisi profesional kami akan tiba di lokasi sesuai dengan jadwal yang Anda tentukan.'},
                                  {'icon': Icons.verified_user_rounded, 'title': 'Harga Transparan', 'desc': 'Seluruh rincian biaya ditampilkan secara eksplisit di awal pemesanan tanpa biaya tersembunyi.'},
                                  {'icon': Icons.engineering_rounded, 'title': 'Teknisi Ahli', 'desc': 'Proses pengerjaan dilakukan oleh tenaga ahli yang telah melewati proses verifikasi.'},
                                ],
                              ),
                            ),
                          );
                        }),
                        _buildServiceItem(Icons.cleaning_services_outlined, 'Reguler', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Reguler Cleaning',
                            imagePath: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=2070&auto=format&fit=crop',
                            description: 'Layanan kebersihan harian dengan standar hotel bintang 5. Tim BersihIn akan menyulap hunian Anda menjadi zona nyaman yang higienis.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Reguler Cleaning'), // Sementare numpang dulu Mon!
                            benefits: const [
                              {'icon': Icons.schedule_rounded, 'title': 'Waktu Fleksibel', 'desc': 'Atur jadwal kedatangan teknisi kebersihan sesuai ritme aktivitas harian Anda.'},
                              {'icon': Icons.eco_rounded, 'title': 'Eco-Friendly', 'desc': 'Menggunakan cairan pembersih ramah lingkungan yang aman bagi keluarga.'},
                              {'icon': Icons.star_border_rounded, 'title': 'Standar Premium', 'desc': 'Setiap sudut ruangan dibersihkan dengan protokol kebersihan ketat.'},
                            ],
                          )));
                        }),
                        _buildServiceItem(Icons.local_car_wash_outlined, 'Cuci\nKendaraan', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Cuci Kendaraan',
                            imagePath: 'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?q=80&w=2031&auto=format&fit=crop',
                            description: 'Layanan cuci kendaraan profesional langsung di depan rumah Anda. Motor, mobil, hingga kendaraan keluarga besar ditangani dengan peralatan modern.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Cuci Kendaraan'), 
                            benefits: const [
                              {'icon': Icons.water_drop_rounded, 'title': 'Bersih Menyeluruh', 'desc': 'Pembersihan eksterior dan interior kendaraan dengan sabun khusus anti-jamur.'},
                              {'icon': Icons.home_rounded, 'title': 'Layanan di Rumah', 'desc': 'Teknisi datang ke lokasi Anda, tidak perlu antri di tempat cuci umum.'},
                              {'icon': Icons.shield_rounded, 'title': 'Aman untuk Cat', 'desc': 'Menggunakan produk ramah cat yang menjaga kilap dan melindungi bodi kendaraan.'},
                            ],
                          )));
                        }),
                        _buildServiceItem(Icons.bed_outlined, 'Cuci\nKasur', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Cuci Kasur',
                            imagePath: 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=2070&auto=format&fit=crop',
                            description: 'Kasur bersih, bebas tungau, dan wangi segar. Layanan cuci kasur profesional dengan teknologi steam cleaning yang aman untuk semua jenis kasur.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Cuci Kasur'),
                            benefits: const [
                              {'icon': Icons.bug_report_rounded, 'title': 'Basmi Tungau', 'desc': 'Steam cleaning 100°C membunuh tungau dan bakteri penyebab alergi secara efektif.'},
                              {'icon': Icons.air_rounded, 'title': 'Wangi Tahan Lama', 'desc': 'Menggunakan pewangi khusus kasur yang aman dan tahan lama hingga berminggu-minggu.'},
                              {'icon': Icons.health_and_safety_rounded, 'title': 'Tidur Lebih Sehat', 'desc': 'Kasur bersih meningkatkan kualitas tidur dan mengurangi risiko gangguan pernapasan.'},
                            ],
                          )));
                        }),
                        _buildServiceItem(Icons.home_outlined, 'Deep\nClean', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Deep Cleaning',
                            imagePath: 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?q=80&w=1974&auto=format&fit=crop',
                            description: 'Pembersihan intensif hingga ke sudut terdalam rumah Anda. Solusi sempurna untuk sterilisasi total hunian.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Deep Cleaning'), 
                            benefits: const [
                              {'icon': Icons.sanitizer_rounded, 'title': 'Disinfeksi 99%', 'desc': 'Membunuh bakteri menggunakan chemical disinfektan berstandar medis.'},
                              {'icon': Icons.hardware_rounded, 'title': 'Alat Khusus', 'desc': 'Pengerjaan menggunakan peralatan heavy-duty untuk mengangkat noda.'},
                              {'icon': Icons.bug_report_rounded, 'title': 'Bebas Tungau', 'desc': 'Vakum khusus memastikan kasur dan karpet terbebas dari tungau.'},
                            ],
                          )));
                        }),
                        _buildServiceItem(Icons.spa_outlined, 'Pijat', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Pijat Relaksasi',
                            imagePath: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?q=80&w=2070&auto=format&fit=crop',
                            description: 'Hadirkan suasana spa eksklusif di ruang keluarga Anda. Kembalikan energi tubuh bersama terapis profesional.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Pijat Relaksasi'), 
                            benefits: const [
                              {'icon': Icons.accessibility_new_rounded, 'title': 'Terapis Sertifikasi', 'desc': 'Dilayani langsung oleh terapis profesional yang telah tersertifikasi.'},
                              {'icon': Icons.self_improvement_rounded, 'title': 'Metode Beragam', 'desc': 'Pilih metode pijat sesuai kebutuhan, dari tradisional hingga shiatsu.'},
                              {'icon': Icons.lock_person_rounded, 'title': 'Privasi Terjamin', 'desc': 'Nikmati relaksasi maksimal tanpa harus keluar dari privasi rumah.'},
                            ],
                          )));
                        }),
                        _buildServiceItem(Icons.ac_unit_outlined, 'Service AC', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Service AC',
                            imagePath: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?q=80&w=2069&auto=format&fit=crop',
                            description: 'Perawatan AC menyeluruh dengan teknologi diagnosa presisi. Udara kembali sejuk, bersih, dan hemat energi.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Service AC'), 
                            benefits: const [
                              {'icon': Icons.water_rounded, 'title': 'Cuci Bersih', 'desc': 'Pembersihan evaporator dan kondensor menghilangkan debu dan jamur.'},
                              {'icon': Icons.gas_meter_rounded, 'title': 'Cek Freon', 'desc': 'Pengukuran tekanan freon untuk memastikan kinerja pendinginan.'},
                              {'icon': Icons.ac_unit_rounded, 'title': 'Garansi Dingin', 'desc': 'Garansi service jika AC Anda tidak kembali dingin setelah perawatan.'},
                            ],
                          )));
                        }),
                        _buildServiceItem(Icons.chair_outlined, 'Cuci Sofa', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(
                            title: 'Cuci Sofa',
                            imagePath: 'https://images.unsplash.com/photo-1512314889357-e157c22f938d?q=80&w=2071&auto=format&fit=crop',
                            description: 'Kembalikan warna dan kebersihan furnitur kesayangan Anda dengan metode ekstraksi vakum basah canggih.',
                            targetOrderPage: OrderLayananPage(namaLayanan: 'Cuci Sofa'), 
                            benefits: const [
                              {'icon': Icons.cleaning_services_rounded, 'title': 'Angkat Noda', 'desc': 'Teknologi ekstraksi mampu mengangkat noda membandel pada kain.'},
                              {'icon': Icons.timer_rounded, 'title': 'Cepat Kering', 'desc': 'Metode dry-cleaning kami memastikan sofa bisa langsung digunakan.'},
                              {'icon': Icons.health_and_safety_rounded, 'title': 'Aman untuk Kain', 'desc': 'Menggunakan shampo khusus yang tidak merusak serat furnitur.'},
                            ],
                          )));
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Tentang Bersih.In — card klik ke About Us ───
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutUsPage()),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: toscaLight.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: toscaMedium.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          // Ikon kiri
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: toscaLight.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: toscaLight.withOpacity(0.3)),
                            ),
                            child: Icon(Icons.info_outline_rounded, color: toscaDark, size: 26),
                          ),
                          const SizedBox(width: 16),
                          // Teks tengah
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tentang Bersih.In',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: toscaDark)),
                                const SizedBox(height: 3),
                                Text('Kenali lebih jauh visi, misi, dan tim di balik layanan kami.',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Panah kanan
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: toscaDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 100),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: toscaMedium.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6)),
              ],
              border: Border.all(color: toscaLight.withOpacity(0.15)),
            ),
            child: Icon(icon, size: 26, color: toscaDark),
          ),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Overlay animasi saat shake terdeteksi ────────────────────
class _ShakeOverlay extends StatefulWidget {
  final Color toscaDark;
  final Color toscaMedium;
  final Color toscaLight;
  final VoidCallback onPlay;
  final VoidCallback onDismiss;

  const _ShakeOverlay({
    required this.toscaDark,
    required this.toscaMedium,
    required this.toscaLight,
    required this.onPlay,
    required this.onDismiss,
  });

  @override
  State<_ShakeOverlay> createState() => _ShakeOverlayState();
}

class _ShakeOverlayState extends State<_ShakeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.toscaDark, const Color(0xFF0A1628)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: widget.toscaLight.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.toscaMedium.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Ikon berputar + pulse
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnim, _rotateCtrl]),
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Stack(alignment: Alignment.center, children: [
                  // Lingkaran luar berputar
                  Transform.rotate(
                    angle: _rotateCtrl.value * 2 * 3.14159,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.toscaLight.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(painter: _DashedCirclePainter(widget.toscaLight)),
                    ),
                  ),
                  // Ikon tengah
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.toscaMedium, widget.toscaLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.toscaLight.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cleaning_services_rounded,
                        color: Colors.white, size: 38),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 20),

            // Badge "Fitur Rahasia"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.amber, size: 13),
                const SizedBox(width: 5),
                Text('Fitur Tersembunyi Ditemukan!',
                    style: GoogleFonts.outfit(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ]),
            ),

            const SizedBox(height: 14),

            Text('Mini Game\nBersih-Bersih!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2)),

            const SizedBox(height: 10),

            Text(
              'Kamu menemukan mini game rahasia!\nBersihkan kotoran dengan memiringkan HP.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white60, fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 24),

            // Tombol main
            GestureDetector(
              onTap: widget.onPlay,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.toscaMedium, widget.toscaLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.toscaLight.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text('MAIN SEKARANG',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.8)),
                ]),
              ),
            ),

            const SizedBox(height: 10),

            // Tombol nanti
            TextButton(
              onPressed: widget.onDismiss,
              child: Text('Nanti saja',
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 13)),
            ),
          ]),
        ),
      ),
    );
  }
}

// Painter untuk lingkaran putus-putus dekoratif
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashCount = 16;
    const dashAngle = 3.14159 * 2 / dashCount;
    final r = size.width / 2;
    final center = Offset(r, r);
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) continue;
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 1),
        startAngle,
        dashAngle * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
