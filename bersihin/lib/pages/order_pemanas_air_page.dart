import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderPemanasAirPage extends StatefulWidget {
  const OrderPemanasAirPage({Key? key}) : super(key: key);

  @override
  _OrderPemanasAirPageState createState() => _OrderPemanasAirPageState();
}

class _OrderPemanasAirPageState extends State<OrderPemanasAirPage> {
  // Palet Warna Futuristik Bersih.In
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  // Variabel State buat Form
  int _selectedServiceType = 0; // 0: Perbaikan, 1: Pemasangan, 2: Perawatan
  String _selectedDate = "Pilih Tanggal";
  String _selectedTime = "Pilih Waktu";
  final TextEditingController _catatanController = TextEditingController();

  final List<Map<String, dynamic>> _serviceTypes = [
    {'title': 'Perbaikan Kerusakan', 'price': 'Rp 150.000', 'icon': Icons.build_circle_outlined},
    {'title': 'Pemasangan Baru', 'price': 'Rp 250.000', 'icon': Icons.add_circle_outline_rounded},
    {'title': 'Perawatan Berkala', 'price': 'Rp 100.000', 'icon': Icons.published_with_changes_rounded},
  ];

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pesanan Berhasil', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark)),
        content: Text('Jadwal layanan Pemanas Air Anda telah masuk ke dalam sistem. Teknisi kami akan segera menghubungi Anda.', 
          style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Balik ke Home
            },
            child: Text('KEMBALI KE BERANDA', 
              style: GoogleFonts.outfit(color: toscaMedium, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER FUTURISTIK PAKE SLIVER
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: toscaDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [toscaDark, toscaMedium.withOpacity(0.9)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(Icons.water_drop_outlined, size: 250, color: Colors.white.withOpacity(0.05)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, bottom: 40, right: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: toscaLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: toscaLight.withOpacity(0.5)),
                            ),
                            child: Text('Layanan Teknis', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          Text('Pemanas Air', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 5),
                          Text('Layanan perbaikan, instalasi, dan perawatan.', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BODY FORMULIR
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, toscaLight.withOpacity(0.03)],
                ),
              ),
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kategori Layanan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 15),
                  
                  // LIST PILIHAN LAYANAN
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _serviceTypes.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedServiceType == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedServiceType = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? toscaLight.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? toscaMedium : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isSelected) BoxShadow(color: toscaMedium.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))
                            ]
                          ),
                          child: Row(
                            children: [
                              Icon(_serviceTypes[index]['icon'], color: isSelected ? toscaDark : Colors.grey.shade400, size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_serviceTypes[index]['title'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? toscaDark : Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text('Mulai dari ${_serviceTypes[index]['price']}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? toscaMedium : Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  Text('Jadwal Pengerjaan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 15),
                  
                  // DATE & TIME PICKER (Dummy UI)
                  Row(
                    children: [
                      Expanded(child: _buildPickerCard(Icons.calendar_month_rounded, 'Tanggal', _selectedDate)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildPickerCard(Icons.access_time_rounded, 'Waktu', _selectedTime)),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Text('Catatan Keluhan (Opsional)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 15),
                  
                  // TEXT AREA KELUHAN
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 4,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Air tidak mau panas, ada kebocoran di pipa...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Spasi buat bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ==========================================
      // BOTTOM BAR STICKY BUAT TOTAL & TOMBOL PESAN
      // ==========================================
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimasi Biaya', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
                    Text(
                      _serviceTypes[_selectedServiceType]['price'],
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: toscaDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showSuccessDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: toscaDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: toscaMedium.withOpacity(0.5),
                  ),
                  child: Text('PESAN', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: toscaMedium, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: toscaDark), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}