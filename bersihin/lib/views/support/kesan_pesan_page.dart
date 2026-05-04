import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../../widgets/custom_navbar.dart';

class EvaluasiPage extends StatefulWidget {
  const EvaluasiPage({Key? key}) : super(key: key);
  @override
  State<EvaluasiPage> createState() => _EvaluasiPageState();
}

class _EvaluasiPageState extends State<EvaluasiPage> {
  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  // rating: 0.5 – 5.0, step 0.5
  double _rating = 5.0;
  bool _isGuest = true;
  String _email = '';
  bool _isLoading = false;
  bool _submitted = false;

  final Color toscaDark  = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  @override
  void initState() { super.initState(); _checkLogin(); }

  @override
  void dispose() { _kesanController.dispose(); _saranController.dispose(); super.dispose(); }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';
    setState(() { _email = email; _isGuest = email.isEmpty; });
  }

  Future<void> _submit() async {
    if (_kesanController.text.trim().isEmpty || _saranController.text.trim().isEmpty) {
      _snack('Isi kesan dan saran dulu ya!', isError: true); return;
    }
    setState(() => _isLoading = true);
    final res = await AuthService().submitEvaluasi(_email, _rating, _kesanController.text.trim(), _saranController.text.trim());
    setState(() => _isLoading = false);
    if (res['statusCode'] == 201) {
      setState(() => _submitted = true);
    } else {
      _snack('Gagal mengirim. Coba lagi!', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent.shade400 : toscaMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ── label & warna dinamis ─────────────────────────────────
  String get _ratingLabel {
    if (_rating <= 1.0) return 'Sangat Buruk';
    if (_rating <= 1.5) return 'Buruk';
    if (_rating <= 2.0) return 'Kurang';
    if (_rating <= 2.5) return 'Cukup';
    if (_rating <= 3.0) return 'Lumayan';
    if (_rating <= 3.5) return 'Cukup Baik';
    if (_rating <= 4.0) return 'Baik';
    if (_rating <= 4.5) return 'Sangat Baik';
    return 'Luar Biasa!';
  }

  Color get _ratingColor {
    if (_rating <= 2.0) return Colors.redAccent;
    if (_rating <= 3.0) return Colors.orange;
    if (_rating <= 4.0) return Colors.amber.shade700;
    return toscaMedium;
  }

  // ── bintang interaktif ────────────────────────────────────
  Widget _buildStars({double size = 44}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final full = (i + 1).toDouble();
        final half = i + 0.5;
        return GestureDetector(
          onTapDown: (d) {
            // tap sisi kiri bintang = setengah, sisi kanan = penuh
            final isHalf = d.localPosition.dx < size / 2;
            setState(() => _rating = isHalf ? half : full);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SizedBox(
              width: size, height: size,
              child: Stack(children: [
                Icon(Icons.star_rounded, size: size, color: Colors.grey.shade200),
                ClipRect(
                  clipper: _StarClipper(
                    fill: _rating >= full ? 1.0 : (_rating >= half ? 0.5 : 0.0),
                  ),
                  child: Icon(Icons.star_rounded, size: size, color: Colors.amber.shade500),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ── mini bintang (read-only) ──────────────────────────────
  Widget _miniStars(double val, {double size = 28}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final full = (i + 1).toDouble();
        final half = i + 0.5;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(width: size, height: size, child: Stack(children: [
            Icon(Icons.star_rounded, size: size, color: Colors.grey.shade200),
            ClipRect(
              clipper: _StarClipper(fill: val >= full ? 1.0 : (val >= half ? 0.5 : 0.0)),
              child: Icon(Icons.star_rounded, size: size, color: Colors.amber.shade500),
            ),
          ])),
        );
      }),
    );
  }

  // ── scaffold ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        title: Text('Kesan dan Pesan TPM',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17)),
        centerTitle: true,
        backgroundColor: toscaDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [toscaLight, toscaMedium])),
          ),
        ),
      ),
      body: _isGuest ? _buildGuest() : (_submitted ? _buildSuccess() : _buildForm()),
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  // ── GUEST ─────────────────────────────────────────────────
  Widget _buildGuest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [toscaDark.withOpacity(0.08), toscaLight.withOpacity(0.05)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_person_rounded, size: 64, color: toscaDark),
          ),
          const SizedBox(height: 24),
          Text('Akses Terbatas',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: toscaDark)),
          const SizedBox(height: 10),
          Text('Login terlebih dahulu untuk mengisi evaluasi mata kuliah TPM.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.6)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()))
                  .then((_) => _checkLogin()),
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              label: Text('MASUK SEKARANG',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: toscaDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── SUCCESS ───────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text('Terima Kasih!',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: toscaDark)),
          const SizedBox(height: 10),
          Text('Evaluasi kamu sudah berhasil dikirim.\nMasukan kamu sangat berarti untuk kemajuan mata kuliah TPM.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.6)),
          const SizedBox(height: 16),
          _miniStars(_rating),
          const SizedBox(height: 6),
          Text(_ratingLabel,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _ratingColor)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _submitted = false;
                _kesanController.clear();
                _saranController.clear();
                _rating = 5.0;
              }),
              icon: Icon(Icons.refresh_rounded, color: toscaDark),
              label: Text('Isi Ulang Evaluasi',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: toscaDark, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── FORM ──────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── info card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [toscaDark, toscaMedium], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kesan dan Pesan',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 3),
              Text('Teknologi Pemrograman Mobile',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text('2025/2026',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── rating bintang ─────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            // judul
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 18),
              const SizedBox(width: 6),
              Text('Penilaian Kepuasan',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 15)),
            ]),
            const SizedBox(height: 20),

            // angka besar
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_rating.toStringAsFixed(1),
                  style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.w900, color: _ratingColor, height: 1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text('/5.0',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(_ratingLabel,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: _ratingColor)),
            const SizedBox(height: 20),

            // bintang interaktif
            _buildStars(),
            const SizedBox(height: 8),
            Text('Ketuk bintang untuk memberikan penilaian',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400)),
          ]),
        ),

        const SizedBox(height: 16),

        // ── kesan ──────────────────────────────────────────
        _inputCard(
          icon: Icons.sentiment_satisfied_alt_rounded,
          title: 'Kesan Selama Kuliah',
          ctrl: _kesanController,
          hint: 'Ceritakan pengalaman belajar Anda di mata kuliah TPM ini...',
        ),

        const SizedBox(height: 14),

        // ── saran ──────────────────────────────────────────
        _inputCard(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Saran Membangun',
          ctrl: _saranController,
          hint: 'Berikan saran konstruktif untuk dosen dan mata kuliah ini...',
        ),

        const SizedBox(height: 28),

        // ── tombol kirim ───────────────────────────────────
        GestureDetector(
          onTap: _isLoading ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity, height: 58,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade400])
                  : LinearGradient(colors: [toscaDark, toscaMedium]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _isLoading ? [] : [BoxShadow(color: toscaMedium.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 7))],
            ),
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text('KIRIM EVALUASI',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2, fontSize: 15)),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _inputCard({required IconData icon, required String title, required TextEditingController ctrl, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: toscaLight.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: toscaDark, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 14)),
          ]),
        ),
        TextField(
          controller: ctrl, maxLines: 4,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          ),
        ),
      ]),
    );
  }
}

// ── clipper setengah bintang ──────────────────────────────────
class _StarClipper extends CustomClipper<Rect> {
  final double fill; // 0.0, 0.5, atau 1.0
  const _StarClipper({required this.fill});
  @override
  Rect getClip(Size s) => Rect.fromLTWH(0, 0, s.width * fill, s.height);
  @override
  bool shouldReclip(_StarClipper old) => old.fill != fill;
}
