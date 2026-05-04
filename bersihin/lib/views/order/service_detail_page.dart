import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'saved_address_page.dart';
import '../auth/login_page.dart';

class ServiceDetailPage extends StatelessWidget {
  final String title;
  final String imagePath;
  final String description;
  final List<Map<String, dynamic>> benefits;
  final Widget targetOrderPage;

  const ServiceDetailPage({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.benefits,
    required this.targetOrderPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color toscaDark = const Color(0xFF025955);
    final Color toscaMedium = const Color(0xFF00909E);
    final Color toscaLight = const Color(0xFF48C9B0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HEADER: GAMBAR DENGAN EFEK PARALLAX & GRADIENT FUTURISTIK
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                stretch: true,
                backgroundColor: toscaDark,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imagePath, 
                        fit: BoxFit.cover,
                      ),
                      // Overlay gradasi elegan biar teks title pop-up!
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                              toscaDark.withOpacity(0.9),
                              Colors.white,
                            ],
                            stops: const [0.0, 0.5, 0.9, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))
                      ]
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 25, bottom: 40),
                  centerTitle: false,
                ),
              ),

              // BODY: PENJELASAN LAYANAN
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 35, 25, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul & Deskripsi Utama
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: toscaMedium, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Tentang Layanan',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: toscaDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          description,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.7,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Point-point Keunggulan
                        Text(
                          'Mengapa Memilih BersihIn?',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: toscaDark,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Loop benefits list pak!
                        ...benefits.map((benefit) => _buildBenefitItem(
                          benefit['icon'], 
                          benefit['title'], 
                          benefit['desc'],
                          toscaMedium,
                          toscaLight,
                        )).toList(),

                        const SizedBox(height: 120), // Spasi lega buat tombol ngambang di bawah
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // TOMBOL AKSI: FLOATING GLASSMORPHISM STYLE
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.only(left: 25, right: 25, top: 20, bottom: 35),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    boxShadow: [
                      BoxShadow(color: toscaDark.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -10))
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Cek login dulu sebelum lanjut order
                        final prefs = await SharedPreferences.getInstance();
                        final email = prefs.getString('saved_email') ?? '';
                        if (!context.mounted) return;
                        if (email.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Row(children: [
                                Icon(Icons.lock_person_rounded, color: toscaDark),
                                const SizedBox(width: 10),
                                Text('Login Diperlukan',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark)),
                              ]),
                              content: Text(
                                'Silakan login terlebih dahulu untuk memesan layanan ini.',
                                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const LoginPage()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: toscaDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text('LOGIN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavedAddressPage(targetOrderPage: targetOrderPage),
                          ),
                        );                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                        shadowColor: toscaMedium.withOpacity(0.4),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [toscaDark, toscaMedium],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            'MULAI PENGALAMAN',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET ITEM KEUNGGULAN (MAKIN ELEGAN MON)
  Widget _buildBenefitItem(IconData icon, String title, String desc, Color primary, Color light) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: primary.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))
              ],
              border: Border.all(color: light.withOpacity(0.2)),
            ),
            child: Icon(icon, color: primary, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}