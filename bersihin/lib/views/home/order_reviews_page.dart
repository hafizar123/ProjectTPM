import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class OrderReviewsPage extends StatefulWidget {
  const OrderReviewsPage({super.key});

  @override
  State<OrderReviewsPage> createState() => _OrderReviewsPageState();
}

class _OrderReviewsPageState extends State<OrderReviewsPage> {
  final AuthService _svc = AuthService();

  static const Color toscaDark   = Color(0xFF025955);
  static const Color toscaMedium = Color(0xFF00909E);
  static const Color toscaLight  = Color(0xFF48C9B0);

  List<dynamic> _allReviews  = [];
  List<dynamic> _shown       = [];
  bool _loading              = true;
  String _errorMsg           = '';

  // Filter: null = semua, 1–5 = bintang tertentu
  int? _filterRating;
  // Sort: 'terbaru' | 'tertinggi' | 'terendah'
  String _sortMode = 'terbaru';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _errorMsg = ''; });
    final res = await _svc.getAllOrderReviews();
    if (!mounted) return;
    if (res['statusCode'] == 200) {
      final body = res['body'];
      List<dynamic> parsed = [];
      if (body is List) {
        parsed = body;
      } else if (body is Map) {
        parsed = (body['data'] ?? body['reviews'] ?? body['result'] ?? []) as List;
      }
      setState(() {
        _allReviews = parsed;
        _loading    = false;
      });
      _applyFilter();
    } else {
      setState(() {
        _loading  = false;
        _errorMsg = 'Gagal memuat ulasan (${res['statusCode']})';
      });
    }
  }

  void _applyFilter() {
    List<dynamic> list = List.from(_allReviews);

    // Filter bintang
    if (_filterRating != null) {
      list = list.where((r) {
        final rating = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
        return rating.round() == _filterRating;
      }).toList();
    }

    // Sort
    list.sort((a, b) {
      final rA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0;
      final rB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0;
      if (_sortMode == 'tertinggi') return rB.compareTo(rA);
      if (_sortMode == 'terendah')  return rA.compareTo(rB);
      // terbaru: pakai created_at
      final dA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final dB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return dB.compareTo(dA);
    });

    setState(() => _shown = list);
  }

  // Hitung rata-rata rating
  double get _avgRating {
    if (_allReviews.isEmpty) return 0;
    final sum = _allReviews.fold<double>(0, (acc, r) =>
        acc + (double.tryParse(r['rating']?.toString() ?? '0') ?? 0));
    return sum / _allReviews.length;
  }

  // Hitung distribusi bintang
  Map<int, int> get _distribution {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _allReviews) {
      final star = (double.tryParse(r['rating']?.toString() ?? '0') ?? 0).round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: toscaDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF012E2B), toscaDark, Color(0xFF014D49)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(right: -30, top: -30,
                    child: Container(width: 160, height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: toscaLight.withOpacity(0.07)))),
                  Positioned(left: -20, bottom: -20,
                    child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: toscaMedium.withOpacity(0.1)))),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: toscaLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: toscaLight.withOpacity(0.35)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.star_rounded,
                                    color: toscaLight, size: 13),
                                const SizedBox(width: 4),
                                Text('Ulasan Pengguna',
                                    style: GoogleFonts.outfit(
                                        color: toscaLight,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text('Apa Kata Mereka?',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          Text('${_allReviews.length} ulasan dari pengguna Bersih.In',
                              style: GoogleFonts.outfit(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: toscaMedium),
                    ),
                  )
                : _errorMsg.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Column(children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.grey.shade400, size: 48),
                            const SizedBox(height: 12),
                            Text(_errorMsg,
                                style: GoogleFonts.outfit(
                                    color: Colors.grey.shade500)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: toscaDark,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text('Coba Lagi',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white)),
                            ),
                          ]),
                        ),
                      )
                    : Column(children: [
                        // ── Ringkasan rating ─────────────────────
                        if (_allReviews.isNotEmpty) _buildSummaryCard(),

                        // ── Filter & Sort bar ────────────────────
                        _buildFilterBar(),

                        // ── Jumlah hasil ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(children: [
                            Text('${_shown.length} ulasan ditampilkan',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ]),
                        ),
                      ]),
          ),

          // ── Daftar review ──────────────────────────────────────
          if (!_loading && _errorMsg.isEmpty)
            _shown.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.rate_review_outlined,
                              color: toscaLight.withOpacity(0.4), size: 56),
                          const SizedBox(height: 12),
                          Text('Belum ada ulasan',
                              style: GoogleFonts.outfit(
                                  color: Colors.grey.shade400, fontSize: 14)),
                        ]),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _ReviewCard(review: _shown[i]),
                        childCount: _shown.length,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  // ── Kartu ringkasan rating ─────────────────────────────────────
  Widget _buildSummaryCard() {
    final avg  = _avgRating;
    final dist = _distribution;
    final total = _allReviews.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF012E2B), toscaDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: toscaDark.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kiri: angka besar
          Column(children: [
            Text(avg.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1)),
            const SizedBox(height: 4),
            Row(children: List.generate(5, (i) => Icon(
              i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber.shade400, size: 16,
            ))),
            const SizedBox(height: 4),
            Text('$total ulasan',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 11)),
          ]),
          const SizedBox(width: 20),
          // Kanan: bar distribusi
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final pct   = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Text('$star',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 4),
                    Icon(Icons.star_rounded,
                        color: Colors.amber.shade400, size: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 22,
                      child: Text('$count',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 10),
                          textAlign: TextAlign.right),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar filter & sort ──────────────────────────────────────────
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter bintang
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: [
              _filterChip('Semua', null),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final star = 5 - i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _filterChip('$star ★', star),
                );
              }),
            ]),
          ),
          const SizedBox(height: 10),
          // Sort
          Row(children: [
            Text('Urutkan: ',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.grey.shade600)),
            _sortChip('Terbaru', 'terbaru'),
            const SizedBox(width: 8),
            _sortChip('Tertinggi', 'tertinggi'),
            const SizedBox(width: 8),
            _sortChip('Terendah', 'terendah'),
          ]),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? value) {
    final active = _filterRating == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterRating = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [toscaDark, toscaMedium])
              : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? Colors.transparent : toscaLight.withOpacity(0.3)),
          boxShadow: active
              ? [BoxShadow(
                  color: toscaDark.withOpacity(0.25),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }

  Widget _sortChip(String label, String mode) {
    final active = _sortMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _sortMode = mode);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? toscaDark.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? toscaDark : Colors.grey.shade300),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? toscaDark : Colors.grey.shade500)),
      ),
    );
  }
}

// ── Kartu satu ulasan ──────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    const toscaDark   = Color(0xFF025955);
    const toscaMedium = Color(0xFF00909E);
    const toscaLight  = Color(0xFF48C9B0);

    final email       = (review['user_email'] ?? review['email'] ?? '').toString();
    final reviewText  = (review['review'] ?? review['kesan'] ?? '').toString();
    final serviceName = (review['service_name'] ?? '').toString();
    final rating      = double.tryParse(review['rating']?.toString() ?? '5') ?? 5.0;
    final name        = email.contains('@') ? email.split('@')[0] : email;
    final dateRaw     = review['created_at']?.toString() ?? '';
    final date        = _formatDate(dateRaw);

    // Warna bintang berdasarkan rating
    Color starColor;
    if (rating >= 4.5) {
      starColor = Colors.amber.shade500;
    } else if (rating >= 3) starColor = Colors.orange.shade400;
    else starColor = Colors.red.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: toscaLight.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nama + rating
          Row(children: [
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [toscaDark, toscaMedium]),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            // Nama + tanggal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (date.isNotEmpty)
                    Text(date,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
            // Badge rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: starColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: starColor.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: starColor, size: 14),
                const SizedBox(width: 3),
                Text(rating.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                        color: starColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
            ),
          ]),

          const SizedBox(height: 12),

          // Bintang visual
          Row(children: List.generate(5, (i) {
            final full = (i + 1).toDouble();
            final half = i + 0.5;
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Stack(children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.grey.shade200),
                ClipRect(
                  clipper: _HalfStarClipper(
                    fill: rating >= full ? 1.0 : (rating >= half ? 0.5 : 0.0),
                  ),
                  child: Icon(Icons.star_rounded,
                      size: 16, color: Colors.amber.shade500),
                ),
              ]),
            );
          })),

          const SizedBox(height: 10),

          // Teks ulasan
          Text(
            reviewText.isEmpty ? '—' : reviewText,
            style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.black87, height: 1.5),
          ),

          // Label layanan
          if (serviceName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: toscaLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cleaning_services_rounded,
                    color: toscaDark, size: 12),
                const SizedBox(width: 5),
                Text(serviceName,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: toscaDark,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
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
