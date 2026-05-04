import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final AuthService _svc = AuthService();

  static const Color toscaDark   = Color(0xFF025955);
  static const Color toscaMedium = Color(0xFF00909E);
  static const Color toscaLight  = Color(0xFF48C9B0);

  List<dynamic> _reviews = [];
  bool _reviewsLoading = true;

  // ── Data Founders ────────────────────────────────────────────
  static const List<Map<String, String>> _founders = [
    {
      'name': 'Founder 1',
      'role': 'Chief Executive Officer',
      'bio': 'Visioner di balik Bersih.In. Berpengalaman lebih dari 10 tahun di industri layanan rumah tangga dan teknologi.',
      'initials': 'F1',
    },
    {
      'name': 'Founder 2',
      'role': 'Chief Technology Officer',
      'bio': 'Arsitek platform digital Bersih.In. Ahli dalam pengembangan aplikasi mobile dan sistem manajemen layanan.',
      'initials': 'F2',
    },
  ];

  // ── Nilai Perusahaan ─────────────────────────────────────────
  static const List<Map<String, dynamic>> _values = [
    {'icon': Icons.verified_rounded,        'title': 'Terpercaya',    'desc': 'Setiap mitra kami melewati proses verifikasi ketat sebelum melayani pelanggan.'},
    {'icon': Icons.speed_rounded,           'title': 'Cepat & Tepat', 'desc': 'Layanan dijadwalkan sesuai keinginan Anda, tanpa antrian panjang.'},
    {'icon': Icons.eco_rounded,             'title': 'Ramah Lingkungan', 'desc': 'Produk pembersih yang kami gunakan aman bagi keluarga dan lingkungan.'},
    {'icon': Icons.support_agent_rounded,   'title': 'Dukungan 24/7', 'desc': 'Tim kami siap membantu kapan pun Anda membutuhkan bantuan.'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final res = await _svc.getAllOrderReviews();
    if (mounted) {
      setState(() {
        _reviewsLoading = false;
        if (res['statusCode'] == 200) {
          final data = res['body'];
          if (data is Map && data['data'] is List) {
            _reviews = data['data'] as List;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: toscaDark,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [toscaDark, Color(0xFF0F2027)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  // Dekorasi
                  Positioned(right: -40, top: -40,
                    child: Container(width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: toscaLight.withOpacity(0.07),
                      ))),
                  Positioned(left: -30, bottom: -30,
                    child: Container(width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: toscaMedium.withOpacity(0.08),
                      ))),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Logo / ikon
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.cleaning_services_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 10),
                          Text('Bersih.In',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 3),
                          Text('Platform Kebersihan & Perawatan Hunian',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 12),
                          // Stats — pakai IntrinsicWidth agar tidak overflow
                          Row(children: [
                            Expanded(child: _statBadge('10K+', 'Pengguna')),
                            const SizedBox(width: 8),
                            Expanded(child: _statBadge('8', 'Layanan')),
                            const SizedBox(width: 8),
                            Expanded(child: _statBadge('4.9★', 'Rating')),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Tentang Kami ───────────────────────────
                  _sectionTitle(Icons.info_outline_rounded, 'Tentang Kami'),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: _cardDecor(),
                    child: Text(
                      'Bersih.In adalah platform layanan kebersihan dan perawatan hunian profesional yang hadir untuk memudahkan kehidupan sehari-hari Anda. '
                      'Kami menghubungkan Anda dengan tenaga ahli terverifikasi yang siap memberikan layanan terbaik langsung di rumah Anda.\n\n'
                      'Didirikan dengan visi menjadikan setiap hunian bersih, nyaman, dan sehat, Bersih.In terus berinovasi menghadirkan solusi kebersihan '
                      'yang mudah diakses, transparan, dan terpercaya untuk seluruh masyarakat Indonesia.',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: Colors.grey.shade700, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Nilai Perusahaan ───────────────────────
                  _sectionTitle(Icons.star_outline_rounded, 'Nilai Kami'),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: _values.map((v) => _valueCard(v)).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Tim Pendiri ────────────────────────────
                  _sectionTitle(Icons.people_outline_rounded, 'Tim Pendiri'),
                  const SizedBox(height: 14),
                  ..._founders.map((f) => _founderCard(f)),

                  const SizedBox(height: 28),

                  // ── Ulasan Pengguna ────────────────────────
                  Row(children: [
                    _sectionTitle(Icons.format_quote_rounded, 'Ulasan Pengguna'),
                    const Spacer(),
                    if (!_reviewsLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: toscaLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_reviews.length} ulasan',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: toscaDark,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews section ──────────────────────────────────────────
  Widget _buildReviewsSection() {
    if (_reviewsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: toscaMedium, strokeWidth: 2),
        ),
      );
    }
    if (_reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: _cardDecor(),
        child: Column(children: [
          Icon(Icons.chat_bubble_outline_rounded,
              color: toscaLight.withOpacity(0.4), size: 40),
          const SizedBox(height: 10),
          Text('Belum ada ulasan',
              style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Jadilah yang pertama memberikan ulasan!',
              style: GoogleFonts.outfit(color: Colors.grey.shade300, fontSize: 12)),
        ]),
      );
    }
    return Column(
      children: _reviews.map((r) => _reviewCard(r)).toList(),
    );
  }

  Widget _reviewCard(dynamic r) {
    final email       = (r['user_email'] ?? '').toString();
    final review      = (r['review'] ?? '').toString();
    final rating      = double.tryParse(r['rating']?.toString() ?? '5') ?? 5.0;
    final serviceName = (r['service_name'] ?? '').toString();
    final name        = email.contains('@') ? email.split('@')[0] : email;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: toscaMedium.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            if (serviceName.isNotEmpty)
              Text(serviceName,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Bintang
          Row(children: List.generate(5, (i) => Icon(
            rating >= (i + 1).toDouble()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: 14,
            color: rating >= (i + 1).toDouble()
                ? Colors.amber.shade500
                : Colors.grey.shade300,
          ))),
        ]),
        const SizedBox(height: 12),
        Text(review,
            style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
      ]),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────

  Widget _sectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [toscaDark, toscaMedium]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.bold, color: toscaDark)),
    ]);
  }

  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _valueCard(Map<String, dynamic> v) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: toscaLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(v['icon'] as IconData, color: toscaDark, size: 18),
          ),
          const SizedBox(height: 8),
          Text(v['title'] as String,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 12, color: toscaDark)),
          const SizedBox(height: 3),
          Text(v['desc'] as String,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Colors.grey.shade600, height: 1.35),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _founderCard(Map<String, String> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Row(children: [
        // Avatar
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [toscaDark, toscaMedium],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: toscaMedium.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(f['initials']!,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f['name']!,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16, color: toscaDark)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: toscaLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(f['role']!,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: toscaDark, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Text(f['bio']!,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
        ])),
      ]),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14,
          offset: const Offset(0, 5)),
    ],
  );
}
