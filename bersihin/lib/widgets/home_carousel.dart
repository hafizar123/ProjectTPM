import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

// ── Carousel dua slide: Info App + Apa Kata Orang ────────────
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({Key? key}) : super(key: key);
  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  final PageController _ctrl = PageController();
  int _page = 0;

  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 200,
        child: PageView(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _page = i),
          children: const [
            _SlideInfoApp(),
            _SlideApaKataOrang(),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Dot indicator
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _page == i ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _page == i ? const Color(0xFF025955) : const Color(0xFF48C9B0).withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        )),
      ),
    ]);
  }
}

// ── Slide 1: Info Aplikasi ────────────────────────────────────
class _SlideInfoApp extends StatelessWidget {
  const _SlideInfoApp();

  @override
  Widget build(BuildContext context) {
    const toscaDark   = Color(0xFF025955);
    const toscaMedium = Color(0xFF00909E);
    const toscaLight  = Color(0xFF48C9B0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [toscaDark, Color(0xFF0F2027)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: toscaDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(children: [
        // Dekorasi lingkaran
        Positioned(right: -30, top: -30,
          child: Container(width: 130, height: 130,
            decoration: BoxDecoration(shape: BoxShape.circle, color: toscaLight.withOpacity(0.08)))),
        Positioned(left: -20, bottom: -20,
          child: Container(width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: toscaMedium.withOpacity(0.1)))),

        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: toscaLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: toscaLight.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_rounded, color: toscaLight, size: 13),
                  const SizedBox(width: 5),
                  Text('Layanan Terpercaya', style: GoogleFonts.outfit(
                      color: toscaLight, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),

              // Judul & deskripsi
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bersih.In', style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Solusi kebersihan & perawatan hunian\nprofesional, cepat, dan terpercaya.',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.4)),
              ]),

              // Stats row
              Row(children: [
                _statChip(Icons.star_rounded, '4.9', 'Rating'),
                const SizedBox(width: 10),
                _statChip(Icons.people_rounded, '10K+', 'Pengguna'),
                const SizedBox(width: 10),
                _statChip(Icons.cleaning_services_rounded, '8', 'Layanan'),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: const Color(0xFF48C9B0), size: 14),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9)),
        ]),
      ]),
    );
  }
}

// ── Slide 2: Apa Kata Orang ───────────────────────────────────
class _SlideApaKataOrang extends StatefulWidget {
  const _SlideApaKataOrang();
  @override
  State<_SlideApaKataOrang> createState() => _SlideApaKataOrangState();
}

class _SlideApaKataOrangState extends State<_SlideApaKataOrang> {
  final AuthService _svc = AuthService();
  List<dynamic> _reviews = [];
  bool _loading = true;
  String _errorMsg = '';

  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await _svc.getAllEvaluasi();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['statusCode'] == 200) {
          final data = res['body'];
          List<dynamic> parsed = [];

          // Handle semua kemungkinan format response backend
          if (data is List) {
            // Format: [ {...}, {...} ]
            parsed = data;
          } else if (data is Map) {
            // Format: { "data": [...] }
            if (data['data'] is List) {
              parsed = data['data'] as List;
            }
            // Format: { "evaluasi": [...] }
            else if (data['evaluasi'] is List) {
              parsed = data['evaluasi'] as List;
            }
            // Format: { "result": [...] }
            else if (data['result'] is List) {
              parsed = data['result'] as List;
            }
            // Format: { "rows": [...] }
            else if (data['rows'] is List) {
              parsed = data['rows'] as List;
            }
          }

          _reviews = parsed;
          // Debug: print ke console untuk diagnosa
          debugPrint('[Carousel] Status: ${res['statusCode']}');
          debugPrint('[Carousel] Body type: ${data.runtimeType}');
          debugPrint('[Carousel] Parsed ${_reviews.length} reviews');
          if (_reviews.isNotEmpty) {
            debugPrint('[Carousel] First item keys: ${_reviews[0].keys}');
          }
        } else {
          _errorMsg = 'Error ${res['statusCode']}';
          // Tampilkan error di console
          debugPrint('[Carousel] Error ${res['statusCode']}: ${res['body']}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: toscaLight.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: toscaDark.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [toscaDark.withOpacity(0.05), toscaLight.withOpacity(0.03)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Apa Kata Orang', style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 15, color: toscaDark)),
            const Spacer(),
            if (!_loading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: toscaLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_reviews.length} ulasan',
                    style: GoogleFonts.outfit(fontSize: 11, color: toscaDark, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),

        // Konten
        Expanded(child: _loading
          ? Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: toscaMedium)))
          : _reviews.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_outline_rounded, color: toscaLight.withOpacity(0.4), size: 32),
                const SizedBox(height: 6),
                Text(
                  _errorMsg.isNotEmpty ? 'Gagal memuat ($_errorMsg)' : 'Belum ada ulasan',
                  style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ]))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                itemCount: _reviews.length,
                itemBuilder: (_, i) => _ReviewCard(review: _reviews[i]),
              ),
        ),
      ]),
    );
  }
}

// ── Kartu satu ulasan ─────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    const toscaDark   = Color(0xFF025955);
    const toscaMedium = Color(0xFF00909E);
    const toscaLight  = Color(0xFF48C9B0);

    final email  = (review['email'] ?? '').toString();
    final kesan  = (review['kesan'] ?? '').toString();
    final rating = double.tryParse(review['rating']?.toString() ?? '5') ?? 5.0;
    // Ambil nama dari email (sebelum @)
    final name   = email.contains('@') ? email.split('@')[0] : email;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: toscaDark.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toscaLight.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bintang
          Row(children: List.generate(5, (i) {
            final full = (i + 1).toDouble();
            final half = i + 0.5;
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Stack(children: [
                Icon(Icons.star_rounded, size: 14, color: Colors.grey.shade200),
                ClipRect(
                  clipper: _HalfStarClipper(
                    fill: rating >= full ? 1.0 : (rating >= half ? 0.5 : 0.0),
                  ),
                  child: Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade500),
                ),
              ]),
            );
          })),
          const SizedBox(height: 6),
          // Teks ulasan
          Expanded(
            child: Text(
              kesan.isEmpty ? '—' : kesan,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.black87, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          // Nama pengguna
          Row(children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: toscaMedium.withOpacity(0.15),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: toscaDark)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(name,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: toscaDark),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }
}

class _HalfStarClipper extends CustomClipper<Rect> {
  final double fill;
  const _HalfStarClipper({required this.fill});
  @override
  Rect getClip(Size s) => Rect.fromLTWH(0, 0, s.width * fill, s.height);
  @override
  bool shouldReclip(_HalfStarClipper old) => old.fill != fill;
}
