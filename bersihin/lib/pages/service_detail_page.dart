import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saved_address_page.dart';

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER: GAMBAR DENGAN EFEK PARALLAX
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: toscaDark,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imagePath, // Ganti pake image URL/Asset lu pak
                    fit: BoxFit.cover,
                  ),
                  // Overlay gradasi biar teks title tetep kebaca pas dikecilin
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
            ),
          ),

          // BODY: PENJELASAN LAYANAN
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul & Deskripsi Utama
                  Text(
                    'Tentang Layanan',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: toscaDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Point-point Keunggulan (Baku & Futuristik)
                  Text(
                    'Mengapa Memilih BersihIn?',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: toscaDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Loop benefits list
                  ...benefits.map((benefit) => _buildBenefitItem(
                    benefit['icon'], 
                    benefit['title'], 
                    benefit['desc'],
                    toscaMedium,
                    toscaLight,
                  )).toList(),

                  const SizedBox(height: 100), // Spasi buat tombol di bawah
                ],
              ),
            ),
          ),
        ],
      ),

      // TOMBOL AKSI: MULAI PENGALAMAN (STICKY BOTTOM)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                // Navigasi ke Location Picker dulu baru ke form order
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedAddressPage(targetOrderPage: targetOrderPage),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: toscaDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(
                'MULAI PENGALAMAN',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET ITEM KEUNGGULAN
  Widget _buildBenefitItem(IconData icon, String title, String desc, Color primary, Color light) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: light.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 24),
          ),
          const SizedBox(width: 15),
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
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
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