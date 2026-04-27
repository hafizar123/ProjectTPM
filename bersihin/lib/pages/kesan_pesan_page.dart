import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'custom_navbar.dart'; // ZHANGG! Pastiin navbar sakti kita ke-import pak

class KesanPesanPage extends StatefulWidget {
  const KesanPesanPage({Key? key}) : super(key: key);

  @override
  _KesanPesanPageState createState() => _KesanPesanPageState();
}

class _KesanPesanPageState extends State<KesanPesanPage> {
  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();
  
  bool _isLoggedIn = false;
  bool _isLoading = true;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _isLoading = false;
    });
  }

  void _handleSubmit() {
    if (_kesanController.text.isEmpty || _pesanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi seluruh formulir evaluasi Anda.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Berhasil Terkirim', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: toscaDark)),
        content: Text('Terima kasih. Saran dan kesan Anda telah berhasil disimpan dalam sistem evaluasi akademik.', 
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _kesanController.clear();
              _pesanController.clear();
            },
            child: Text('OK', 
              style: GoogleFonts.poppins(color: toscaMedium, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      
      // ZHANGG! Scaffold cuma satu di mari Mon, biar robotnye kaga ada animasi fade-in
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: toscaDark))
          : (_isLoggedIn ? _buildMainContent() : _buildRestrictedContent()),
      
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  // =========================================================
  // WIDGET KESAN PESAN (BAHASA BAKU & ELEGAN)
  // =========================================================
  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, toscaLight.withOpacity(0.05)],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: toscaDark,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            title: Text('Saran & Kesan', 
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
          ),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 40, top: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [toscaDark, toscaMedium.withOpacity(0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    )
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 80, color: Colors.white24),
                      const SizedBox(height: 15),
                      Text('Evaluasi Mata Kuliah', 
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('Teknologi & Pemrograman Mobile', 
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Kesan Terhadap Perkuliahan'),
                      _buildField(_kesanController, 'Tuliskan kesan Anda...', Icons.history_edu_rounded),
                      const SizedBox(height: 25),
                      _buildLabel('Pesan dan Saran'),
                      _buildField(_pesanController, 'Tuliskan saran konstruktif Anda...', Icons.lightbulb_outline_rounded, maxLines: 5),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _handleSubmit,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [toscaMedium, toscaDark]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: toscaMedium.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                            ],
                          ),
                          child: Center(
                            child: Text('KIRIM EVALUASI', 
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 120), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // WIDGET AKSES TERBATAS
  // =========================================================
  Widget _buildRestrictedContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: toscaMedium.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)
                ],
              ),
              child: Icon(Icons.lock_person_rounded, size: 80, color: toscaDark),
            ),
            const SizedBox(height: 40),
            Text('Akses Terbatas', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: toscaDark)),
            const SizedBox(height: 15),
            Text('Mohon maaf, Anda harus masuk ke akun Anda terlebih dahulu untuk mengakses halaman Evaluasi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))
                    .then((_) => _checkLoginStatus()); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: toscaDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text('MASUK SEKARANG', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: toscaDark)),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100)
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: toscaMedium),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}