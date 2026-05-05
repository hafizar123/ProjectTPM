import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color toscaDark   = Color(0xFF025955);
    const Color toscaMedium = Color(0xFF00909E);
    const Color toscaLight  = Color(0xFF48C9B0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tentang Kami',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: toscaDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [toscaLight, toscaMedium]),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Header perusahaan ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 32, 25, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [toscaDark, Color(0xFF0F2027)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                // Logo / ikon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.cleaning_services_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Bersih.In',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Your Clean Space, Perfected',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text('Didirikan 2026 • Yogyakarta, Indonesia',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tentang perusahaan ───────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.info_outline_rounded, 'Tentang Bersih.In', toscaDark),
                        const SizedBox(height: 12),
                        Text(
                          'Bersih.In adalah platform layanan kebersihan dan perawatan hunian berbasis mobile yang menghubungkan pengguna dengan teknisi profesional terverifikasi. '
                          'Kami hadir untuk memberikan solusi kebersihan yang mudah, cepat, dan terpercaya langsung di depan pintu rumah Anda.',
                          style: GoogleFonts.outfit(
                              fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Visi & Misi ──────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.flag_rounded, 'Visi & Misi', toscaDark),
                        const SizedBox(height: 14),
                        _visiMisiItem(
                          icon: Icons.visibility_rounded,
                          color: toscaDark,
                          title: 'Visi',
                          desc: 'Menjadi platform layanan kebersihan hunian terdepan di Indonesia yang mengutamakan kualitas, kepercayaan, dan kemudahan akses bagi seluruh lapisan masyarakat.',
                        ),
                        const SizedBox(height: 12),
                        _visiMisiItem(
                          icon: Icons.rocket_launch_rounded,
                          color: toscaMedium,
                          title: 'Misi',
                          desc: 'Menghadirkan layanan kebersihan profesional yang terjangkau, menghubungkan teknisi terverifikasi dengan pengguna, serta terus berinovasi untuk meningkatkan kualitas hidup masyarakat melalui hunian yang bersih dan nyaman.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Tim CEO ──────────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.people_rounded, 'Tim Pendiri', toscaDark),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ceoCard(
                                imagePath: 'assets/images/ceo1.png',
                                name: 'Akmal Danendra Maulana',
                                nim: '123230135',
                                role: 'Co-Founder & CEO',
                                toscaDark: toscaDark,
                                toscaMedium: toscaMedium,
                                toscaLight: toscaLight,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _ceoCard(
                                imagePath: 'assets/images/ceo2.png',
                                name: 'Hafiz Alaudin Rasendriya',
                                nim: '123230149',
                                role: 'Co-Founder & CTO',
                                toscaDark: toscaDark,
                                toscaMedium: toscaMedium,
                                toscaLight: toscaLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Nilai perusahaan ─────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.star_rounded, 'Nilai Perusahaan', toscaDark),
                        const SizedBox(height: 14),
                        _valueItem(Icons.verified_rounded, 'Kepercayaan',
                            'Setiap teknisi telah melalui proses seleksi dan verifikasi ketat', toscaDark),
                        _valueItem(Icons.workspace_premium_rounded, 'Kualitas',
                            'Standar layanan premium dengan jaminan kepuasan pelanggan', toscaMedium),
                        _valueItem(Icons.bolt_rounded, 'Efisiensi',
                            'Proses pemesanan cepat dan teknisi tiba tepat waktu', toscaLight),
                        _valueItem(Icons.favorite_rounded, 'Kepedulian',
                            'Menggunakan produk ramah lingkungan yang aman bagi keluarga', Colors.green.shade600),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Kontak ───────────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.contact_mail_rounded, 'Hubungi Kami', toscaDark),
                        const SizedBox(height: 14),
                        _contactItem(Icons.email_rounded, 'Email', 'support@bersihin.in', toscaMedium),
                        _contactItem(Icons.location_on_rounded, 'Alamat',
                            'Tambak Bayan, Yogyakarta', toscaMedium),
                        _contactItem(Icons.access_time_rounded, 'Jam Operasional',
                            'Senin – Minggu, 07:00 – 21:00 WIB', toscaMedium),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ───────────────────────────────────
                  Center(
                    child: Column(children: [
                      Text('© 2024 Bersih.In. Hak cipta dilindungi.',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('v2.0.4',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, fontSize: 16, color: color)),
    ]);
  }

  Widget _ceoCard({
    required String imagePath,
    required String name,
    required String nim,
    required String role,
    required Color toscaDark,
    required Color toscaMedium,
    required Color toscaLight,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [toscaDark.withOpacity(0.04), toscaLight.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: toscaLight.withOpacity(0.25)),
      ),
      child: Column(children: [
        // Foto CEO
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: toscaMedium, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: toscaMedium.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 90,
              height: 90,
              errorBuilder: (_, _, _) => Container(
                color: toscaLight.withOpacity(0.2),
                child: Icon(Icons.person_rounded, color: toscaDark, size: 44),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 12, color: toscaDark)),
        const SizedBox(height: 4),
        Text(nim,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(role,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _visiMisiItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(desc,
            style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
      ])),
    ]);
  }

  Widget _valueItem(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          Text(desc,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _contactItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}
