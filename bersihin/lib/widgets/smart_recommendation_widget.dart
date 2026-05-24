import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recommendation_service.dart';
import '../views/order/order_layanan_page.dart';
import '../views/order/service_detail_page.dart';

class SmartRecommendationWidget extends StatefulWidget {
  final String email;
  final bool isGuest;

  const SmartRecommendationWidget({
    super.key,
    required this.email,
    required this.isGuest,
  });

  @override
  State<SmartRecommendationWidget> createState() =>
      _SmartRecommendationWidgetState();
}

class _SmartRecommendationWidgetState extends State<SmartRecommendationWidget>
    with TickerProviderStateMixin {
  // ── Warna tema ──────────────────────────────────────────────
  static const Color _toscaDark   = Color(0xFF025955);
  static const Color _toscaMedium = Color(0xFF00909E);
  static const Color _toscaLight  = Color(0xFF48C9B0);
  static const Color _bgDark      = Color(0xFF060E1A);
  static const Color _bgCard      = Color(0xFF0D1B2A);

  final RecommendationService _recService = RecommendationService();

  List<ServiceRecommendation> _recommendations = [];
  bool _isLoading = true;
  bool _hasError = false;

  // Animasi
  late AnimationController _shimmerCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _loadRecommendations();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _scanCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final recs = widget.isGuest
          ? _recService.getPopularPublic()
          : await _recService.getRecommendations(widget.email);

      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // ── Map nama layanan ke ServiceDetailPage ───────────────────
  static const Map<String, Map<String, dynamic>> _serviceDetailMap = {
    'Pemanas Air': {
      'title': 'Layanan Pemanas Air',
      'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=2070&auto=format&fit=crop',
      'desc': 'BersihIn menyediakan solusi teknis profesional untuk perawatan dan perbaikan sistem pemanas air Anda.',
    },
    'Reguler Cleaning': {
      'title': 'Reguler Cleaning',
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=2070&auto=format&fit=crop',
      'desc': 'Layanan kebersihan harian dengan standar hotel bintang 5.',
    },
    'Cuci Kendaraan': {
      'title': 'Cuci Kendaraan',
      'image': 'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?q=80&w=2031&auto=format&fit=crop',
      'desc': 'Layanan cuci kendaraan profesional langsung di depan rumah Anda.',
    },
    'Cuci Kasur': {
      'title': 'Cuci Kasur',
      'image': 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=2070&auto=format&fit=crop',
      'desc': 'Kasur bersih, bebas tungau, dan wangi segar dengan teknologi steam cleaning.',
    },
    'Deep Cleaning': {
      'title': 'Deep Cleaning',
      'image': 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?q=80&w=1974&auto=format&fit=crop',
      'desc': 'Pembersihan intensif hingga ke sudut terdalam rumah Anda.',
    },
    'Pijat Relaksasi': {
      'title': 'Pijat Relaksasi',
      'image': 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?q=80&w=2070&auto=format&fit=crop',
      'desc': 'Hadirkan suasana spa eksklusif di ruang keluarga Anda.',
    },
    'Service AC': {
      'title': 'Service AC',
      'image': 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?q=80&w=2069&auto=format&fit=crop',
      'desc': 'Perawatan AC menyeluruh dengan teknologi diagnosa presisi.',
    },
    'Cuci Sofa': {
      'title': 'Cuci Sofa',
      'image': 'https://images.unsplash.com/photo-1512314889357-e157c22f938d?q=80&w=2071&auto=format&fit=crop',
      'desc': 'Kembalikan warna dan kebersihan furnitur kesayangan Anda.',
    },
    'Langganan Bulanan': {
      'title': 'Langganan Bulanan',
      'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=2070&auto=format&fit=crop',
      'desc': 'Hemat lebih banyak dengan paket berlangganan bulanan.',
    },
  };

  void _navigateToService(BuildContext context, String serviceName) {
    final detail = _serviceDetailMap[serviceName];
    if (detail == null) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => ServiceDetailPage(
          title: detail['title'] as String,
          imagePath: detail['image'] as String,
          description: detail['desc'] as String,
          targetOrderPage: OrderLayananPage(namaLayanan: serviceName),
          benefits: const [
            {'icon': Icons.flash_on_rounded,      'title': 'Efisiensi Waktu',  'desc': 'Teknisi profesional tiba sesuai jadwal.'},
            {'icon': Icons.verified_user_rounded, 'title': 'Harga Transparan', 'desc': 'Tidak ada biaya tersembunyi.'},
            {'icon': Icons.engineering_rounded,   'title': 'Teknisi Ahli',     'desc': 'Tenaga ahli terverifikasi.'},
          ],
        ),
        transitionsBuilder: (_, a1, _, child) =>
            FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 14),
          if (_isLoading)
            _buildLoadingState()
          else if (_hasError)
            _buildErrorState()
          else
            FadeTransition(
              opacity: _fadeAnim,
              child: _buildRecommendationCards(),
            ),
        ],
      ),
    );
  }

  // ── Section header dengan badge AI ──────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_toscaDark, _toscaMedium],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          widget.isGuest ? 'Layanan Populer' : 'Rekomendasi Untukmu',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _toscaDark,
          ),
        ),
        const SizedBox(width: 8),
        // Badge AI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF025955), Color(0xFF00D4AA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 10),
            const SizedBox(width: 4),
            Text(
              'AI',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ]),
        ),
        const Spacer(),
        if (!_isLoading)
          GestureDetector(
            onTap: _loadRecommendations,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _toscaLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh_rounded, color: _toscaDark, size: 16),
            ),
          ),
      ],
    );
  }

  // ── Loading state dengan shimmer + scan line ─────────────────
  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _bgDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _toscaLight.withValues(alpha: 0.15)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, child) {
                return Stack(children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _scanCtrl.value * 48,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _toscaLight.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology_rounded, color: _toscaLight, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'AI sedang menganalisis preferensi kamu...',
                          style: GoogleFonts.outfit(
                            color: _toscaLight.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
        // Shimmer cards
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: _bgCard,
              ),
              child: AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.03),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                      stops: [
                        (_shimmerCtrl.value - 0.3).clamp(0.0, 1.0),
                        _shimmerCtrl.value.clamp(0.0, 1.0),
                        (_shimmerCtrl.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds),
                    child: Container(color: Colors.white),
                  );
                },
              ),
            ),
          )),
        ),
      ],
    );
  }

  // ── Error state ──────────────────────────────────────────────
  Widget _buildErrorState() {
    return GestureDetector(
      onTap: _loadRecommendations,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _toscaLight.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Icon(Icons.wifi_off_rounded, color: _toscaLight.withValues(alpha: 0.4), size: 28),
          const SizedBox(height: 8),
          Text(
            'Ketuk untuk coba lagi',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
          ),
        ]),
      ),
    );
  }

  // ── Kartu rekomendasi ────────────────────────────────────────
  Widget _buildRecommendationCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_recommendations.length, (i) {
        final rec = _recommendations[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => _navigateToService(context, rec.serviceName),
            child: Container(
              margin: EdgeInsets.only(right: i < _recommendations.length - 1 ? 10 : 0),
              child: _RecommendationCard(
                recommendation: rec,
                index: i,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Kartu individual ─────────────────────────────────────────
class _RecommendationCard extends StatefulWidget {
  final ServiceRecommendation recommendation;
  final int index;

  const _RecommendationCard({
    required this.recommendation,
    required this.index,
  });

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _hoverCtrl;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF025955), Color(0xFF0A2A40)],
    [Color(0xFF0A2A40), Color(0xFF012E2B)],
    [Color(0xFF012E2B), Color(0xFF060E1A)],
  ];

  static const List<Color> _accentColors = [
    Color(0xFF00D4AA),
    Color(0xFF00B4D8),
    Color(0xFF48C9B0),
  ];

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.index % 3;
    final gradient = _cardGradients[idx];
    final accent = _accentColors[idx];

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _hoverCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _hoverCtrl.reverse();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _hoverCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: _pressed ? 0.5 : 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dekorasi lingkaran sudut
              Positioned(
                right: -12, top: -12,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.07),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji icon dalam container
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.recommendation.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nama layanan
                  Text(
                    widget.recommendation.serviceName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Alasan AI
                  Text(
                    widget.recommendation.reason,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 9,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Harga + arrow
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.recommendation.priceRange,
                          style: GoogleFonts.outfit(
                            color: accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: accent,
                          size: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
