import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ── Model kotoran yang harus dibersihkan ─────────────────────
class DirtSpot {
  double x;   // posisi relatif 0.0–1.0
  double y;
  double size;
  bool cleaned;
  final int id;

  DirtSpot({required this.x, required this.y, required this.size, required this.id})
      : cleaned = false;
}

// ── Halaman Mini Game ────────────────────────────────────────
class MiniGamePage extends StatefulWidget {
  const MiniGamePage({Key? key}) : super(key: key);
  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage> with TickerProviderStateMixin {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  // ── State gyroscope & posisi sapu ───────────────────────────
  double _broomX = 0.5;  // posisi sapu 0.0–1.0
  double _broomY = 0.5;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // ── State game ───────────────────────────────────────────────
  List<DirtSpot> _dirts = [];
  int _score = 0;
  int _timeLeft = 30;
  bool _gameStarted = false;
  bool _gameOver = false;
  Timer? _countdownTimer;
  int _level = 1;
  int _totalDirts = 0;

  // ── Animasi ──────────────────────────────────────────────────
  late AnimationController _broomAnim;
  late AnimationController _pulseAnim;

  static const double _broomRadius = 0.08; // radius deteksi pembersihan

  @override
  void initState() {
    super.initState();
    _broomAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _generateDirts();
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _countdownTimer?.cancel();
    _broomAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _generateDirts() {
    final rng = Random();
    final count = 8 + (_level - 1) * 3; // makin banyak per level
    _totalDirts = count;
    _dirts = List.generate(count, (i) => DirtSpot(
      id: i,
      x: 0.1 + rng.nextDouble() * 0.8,
      y: 0.15 + rng.nextDouble() * 0.7,
      size: 18 + rng.nextDouble() * 14,
    ));
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver    = false;
      _score       = 0;
      _timeLeft    = max(10, 30 - (_level - 1) * 5);
      _broomX      = 0.5;
      _broomY      = 0.5;
      _generateDirts();
    });

    // Mulai gyroscope
    _gyroSub?.cancel();
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!mounted || _gameOver) return;
      setState(() {
        _broomX = (_broomX + event.y * 0.018).clamp(0.05, 0.95);
        _broomY = (_broomY + event.x * 0.018).clamp(0.05, 0.95);
        _checkClean();
      });
    });

    // Countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          t.cancel();
          _endGame();
        }
      });
    });
  }

  void _checkClean() {
    bool anyNew = false;
    for (final d in _dirts) {
      if (d.cleaned) continue;
      final dx = _broomX - d.x;
      final dy = _broomY - d.y;
      if (sqrt(dx * dx + dy * dy) < _broomRadius + (d.size / 1000)) {
        d.cleaned = true;
        _score += 10;
        anyNew = true;
        _broomAnim.forward(from: 0);
      }
    }
    if (anyNew && _dirts.every((d) => d.cleaned)) {
      _countdownTimer?.cancel();
      _gyroSub?.cancel();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() { _gameOver = true; _level++; });
      });
    }
  }

  void _endGame() {
    _gyroSub?.cancel();
    setState(() => _gameOver = true);
  }

  void _restartGame() {
    setState(() {
      _level = 1;
      _gameStarted = false;
      _gameOver    = false;
    });
    _generateDirts();
  }

  int get _cleanedCount => _dirts.where((d) => d.cleaned).length;
  double get _progress => _totalDirts == 0 ? 0 : _cleanedCount / _totalDirts;
  bool get _allCleaned => _dirts.isNotEmpty && _dirts.every((d) => d.cleaned);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(children: [
        // ── Background dekoratif ─────────────────────────────
        Positioned.fill(child: CustomPaint(painter: _BgPainter(toscaDark))),

        SafeArea(child: Column(children: [
          _buildHeader(),
          Expanded(child: _gameStarted ? _buildGameArea() : _buildStartScreen()),
        ])),

        // ── Game Over / Level Clear overlay ──────────────────
        if (_gameOver) _buildResultOverlay(),
      ]),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bersih-Bersih!', style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text('Level \$_level  •  Miringkan perangkat untuk menggerakkan sapu',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ])),
        if (_gameStarted && !_gameOver) ...[
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeLeft <= 10 ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _timeLeft <= 10 ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(children: [
              Icon(Icons.timer_rounded,
                  color: _timeLeft <= 10 ? Colors.red.shade300 : Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text('$_timeLeft',
                  style: GoogleFonts.outfit(
                      color: _timeLeft <= 10 ? Colors.red.shade300 : Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          const SizedBox(width: 10),
          // Skor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: toscaDark.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: toscaMedium.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 16),
              const SizedBox(width: 4),
              Text('$_score',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── START SCREEN ─────────────────────────────────────────────
  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Ikon animasi
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + _pulseAnim.value * 0.08,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: toscaMedium.withOpacity(0.4 + _pulseAnim.value * 0.2),
                    blurRadius: 30, spreadRadius: 5,
                  )],
                ),
                child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 56),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Bersihkan Rumah!',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            'Miringkan HP ke kiri/kanan/atas/bawah untuk menggerakkan sapu.\nBersihkan semua kotoran sebelum waktu habis!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 12),
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(children: [
              _tipRow(Icons.phone_android_rounded, 'Miringkan perangkat = gerakkan sapu'),
              const SizedBox(height: 8),
              _tipRow(Icons.cleaning_services_rounded, 'Lewati kotoran untuk membersihkan'),
              const SizedBox(height: 8),
              _tipRow(Icons.star_rounded, '+10 poin per kotoran'),
              const SizedBox(height: 8),
              _tipRow(Icons.trending_up_rounded, 'Level naik = lebih banyak kotoran!'),
            ]),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _startGame,
            child: Container(
              width: double.infinity, height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text('MULAI GAME', style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) => Row(children: [
    Icon(icon, color: toscaLight, size: 16),
    const SizedBox(width: 10),
    Text(text, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
  ]);

  // ── GAME AREA ────────────────────────────────────────────────
  Widget _buildGameArea() {
    return Column(children: [
      // Progress bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Kebersihan', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
            Text('$_cleanedCount / $_totalDirts',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(toscaLight),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),

      // Arena game
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(children: [
                // Lantai
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        const Color(0xFF1A2E44),
                        const Color(0xFF0D1B2A),
                      ],
                    ),
                  ),
                ),
                // Grid lantai
                CustomPaint(
                  size: Size(w, h),
                  painter: _FloorPainter(),
                ),
                // Kotoran
                ..._dirts.map((d) => _buildDirt(d, w, h)),
                // Sapu
                _buildBroom(w, h),
              ]);
            }),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDirt(DirtSpot d, double w, double h) {
    if (d.cleaned) return const SizedBox.shrink();
    return Positioned(
      left: d.x * w - d.size / 2,
      top:  d.y * h - d.size / 2,
      child: AnimatedOpacity(
        opacity: d.cleaned ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: d.size, height: d.size,
          decoration: BoxDecoration(
            color: const Color(0xFF5D4037).withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6)],
          ),
          child: Center(
            child: Text(
              d.size > 26 ? '💩' : '🟤',
              style: TextStyle(fontSize: d.size * 0.55),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBroom(double w, double h) {
    return AnimatedBuilder(
      animation: _broomAnim,
      builder: (_, __) {
        final shake = sin(_broomAnim.value * pi * 4) * 4;
        return Positioned(
          left: _broomX * w - 28,
          top:  _broomY * h - 28,
          child: Transform.rotate(
            angle: shake * 0.05,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [toscaDark, toscaMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: toscaMedium.withOpacity(0.6), blurRadius: 16, spreadRadius: 2),
                ],
              ),
              child: const Center(
                child: Text('🧹', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── RESULT OVERLAY ───────────────────────────────────────────
  Widget _buildResultOverlay() {
    final isWin = _allCleaned;
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isWin
                  ? [toscaDark, const Color(0xFF0F2027)]
                  : [const Color(0xFF1A0A0A), const Color(0xFF2D1515)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isWin ? toscaMedium.withOpacity(0.4) : Colors.red.withOpacity(0.3),
            ),
            boxShadow: [BoxShadow(
              color: (isWin ? toscaMedium : Colors.red).withOpacity(0.3),
              blurRadius: 30,
            )],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isWin ? '🎉' : '⏰', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              isWin ? 'Rumah Bersih!' : 'Waktu Habis!',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isWin
                  ? 'Level ${_level - 1} selesai!\nSiap ke level $_level?'
                  : 'Kamu membersihkan $_cleanedCount dari $_totalDirts kotoran.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Skor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 20),
                const SizedBox(width: 8),
                Text('$_score poin',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ]),
            ),
            const SizedBox(height: 24),
            // Tombol aksi
            if (isWin)
              _resultBtn(
                label: 'LANJUT LEVEL $_level',
                icon: Icons.arrow_forward_rounded,
                onTap: _startGame,
                gradient: [toscaDark, toscaMedium],
              )
            else
              _resultBtn(
                label: 'COBA LAGI',
                icon: Icons.refresh_rounded,
                onTap: _restartGame,
                gradient: [toscaDark, toscaMedium],
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keluar', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _resultBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8)),
        ]),
      ),
    );
  }
}

// ── Custom Painters ──────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final Color color;
  _BgPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.06);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        80.0 + i * 40,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _FloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
