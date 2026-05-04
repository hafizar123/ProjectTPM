import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'live_chat_page.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bantuan & Dukungan', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: toscaDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Futuristik
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40, left: 25, right: 25, top: 20),
              decoration: BoxDecoration(
                color: toscaDark,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 80, color: Colors.white24),
                  const SizedBox(height: 15),
                  Text('Ada yang bisa kami bantu?', 
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Tim Bersih.In siap membantu Anda 24/7', 
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontak Kami', 
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 20),
                  
                  // Row Tombol Kontak Cepat
                  Row(
                    children: [
                      _buildContactCard(context, Icons.chat_rounded, 'Live Chat', toscaMedium, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveChatPage()));
                      }),
                      const SizedBox(width: 15),
                      _buildContactCard(context, Icons.email_rounded, 'Email', Colors.blueAccent, () async {
                        try {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Email: support@bersihin.in',
                                  style: GoogleFonts.outfit(color: Colors.white)),
                              backgroundColor: Colors.blueAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ));
                          }
                        } catch (_) {}
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 35),
                  Text('Pertanyaan Populer (FAQ)', 
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 15),

                  // FAQ List
                  _buildFAQItem('Bagaimana cara memesan layanan?', 'Buka beranda, pilih layanan yang diinginkan, lalu tentukan jadwal pengerjaan'),
                  _buildFAQItem('Apakah pesanan bisa dibatalkan?', 'Bisa, maksimal 2 jam sebelum teknisi tiba'),
                  _buildFAQItem('Pembayaran melalui apa saja?', 'Bisa menggunakan E-Wallet atau Transfer Bank'),
                  _buildFAQItem('Apakah teknisi kebersihan aman?', 'Semua mitra kami telah melalui seleksi ketat dan bersertifikat profesional'),
                  
                  const SizedBox(height: 40),
                  
                  // Banner Info Tambahan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [toscaMedium.withOpacity(0.1), toscaLight.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: toscaMedium.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text('Versi Aplikasi', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                        Text('v2.0.4', 
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: toscaDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        iconColor: toscaMedium,
        collapsedIconColor: Colors.grey,
        title: Text(question, 
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, 
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
          ),
        ],
      ),
    );
  }
}