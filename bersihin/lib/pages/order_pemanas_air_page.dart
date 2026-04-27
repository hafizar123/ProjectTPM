import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_page.dart'; // ZHANGG! Pastiin file payment_page.dart udeh lu bikin pak

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
  int _selectedServiceType = 0; 
  final TextEditingController _catatanController = TextEditingController();

  DateTime? _pickedDate;
  String? _pickedTime;

  final List<Map<String, dynamic>> _serviceTypes = [
    {'title': 'Perbaikan Kerusakan', 'price': 'Rp 150.000', 'icon': Icons.build_circle_outlined},
    {'title': 'Pemasangan Baru', 'price': 'Rp 250.000', 'icon': Icons.add_circle_outline_rounded},
    {'title': 'Perawatan Berkala', 'price': 'Rp 100.000', 'icon': Icons.published_with_changes_rounded},
  ];

  // ZHANGG! Jam udeh otomatis dari 07:00 sampe 21:00 pak!
  final List<String> _timeSlots = List.generate(
    15, 
    (index) => '${(index + 7).toString().padLeft(2, '0')}:00'
  );

  // Helper buat nama hari & bulan ala tongkrongan
  String _getHari(int weekday) {
    const hari = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return hari[weekday];
  }

  String _getBulan(int month) {
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return bulan[month];
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.outfit()), 
        backgroundColor: Colors.redAccent, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )
    );
  }

  // ==========================================
  // ZHANGG! BOTTOM SHEET JADWAL (VERSI FIX)
  // ==========================================
  void _showJadwalBottomSheet() {
    // Biar pas buka modal, dia ngerujuk ke pilihan terakhir atau hari ini
    DateTime tempDate = _pickedDate ?? DateTime.now();
    String? tempTime = _pickedTime;

    List<DateTime> upcomingDays = List.generate(30, (index) => DateTime.now().add(Duration(days: index)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75, 
              padding: const EdgeInsets.only(top: 25, left: 25, right: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 25),
                  Text('Pilih Jadwal Pengerjaan', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 25),

                  Text('Tanggal', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 85,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: upcomingDays.length,
                      itemBuilder: (context, index) {
                        DateTime day = upcomingDays[index];
                        bool isSelected = tempDate.day == day.day && tempDate.month == day.month;

                        return GestureDetector(
                          onTap: () => setModalState(() => tempDate = day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 70,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? toscaDark : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isSelected ? toscaDark : Colors.grey.shade200, width: 1.5),
                              boxShadow: [if (isSelected) BoxShadow(color: toscaMedium.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_getHari(day.weekday), style: GoogleFonts.outfit(fontSize: 13, color: isSelected ? Colors.white70 : Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text('${day.day}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : toscaDark)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  Text('Waktu (07:00 - 21:00)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _timeSlots.map((time) {
                          bool isSelected = tempTime == time;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempTime = time),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: (MediaQuery.of(context).size.width - 50 - 36) / 4, 
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? toscaLight.withOpacity(0.15) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? toscaMedium : Colors.grey.shade200, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                time,
                                style: GoogleFonts.outfit(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? toscaDark : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // ZHANGG! TOMBOL SIMPAN UDEH SAKTI MON
                  Container(
                    width: double.infinity,
                    height: 55,
                    margin: const EdgeInsets.only(bottom: 20, top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (tempTime == null) {
                          _showNotif('Pilih waktunye dulu pak!');
                          return;
                        }
                        // ZHANGG! setState di mari biar halaman utama lu ikutan seger pak!
                        setState(() {
                          _pickedDate = tempDate;
                          _pickedTime = tempTime;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: toscaDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('SIMPAN JADWAL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = _pickedDate != null ? "${_pickedDate!.day} ${_getBulan(_pickedDate!.month)} ${_pickedDate!.year}" : "Pilih Tanggal";
    String displayTime = _pickedTime != null ? "$_pickedTime WIB" : "Pilih Waktu";

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
                            border: Border.all(color: isSelected ? toscaMedium : Colors.grey.shade200, width: isSelected ? 2 : 1),
                            boxShadow: [if (isSelected) BoxShadow(color: toscaMedium.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))]
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
                              Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? toscaMedium : Colors.grey.shade300),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  Text('Jadwal Pengerjaan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(child: _buildPickerCard(Icons.calendar_month_rounded, 'Tanggal', displayDate)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildPickerCard(Icons.access_time_rounded, 'Waktu', displayTime)),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Text('Catatan Keluhan (Opsional)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 15),
                  
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
                  
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ),
        ],
      ),

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
                  onPressed: () {
                    // ZHANGG! Validasi sebelum ke Payment Page Mon!
                    if (_pickedDate == null || _pickedTime == null) {
                      _showNotif('Pilih tanggal sama waktunye dulu pak bos!');
                      return;
                    }
                    
                    String formattedDate = "${_pickedDate!.day} ${_getBulan(_pickedDate!.month)} ${_pickedDate!.year}";
                    String formattedTime = "$_pickedTime WIB";

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          serviceName: _serviceTypes[_selectedServiceType]['title'],
                          price: _serviceTypes[_selectedServiceType]['price'],
                          date: formattedDate,
                          time: formattedTime,

                          address: "Jl. Seturan Raya No. 123", // Sementara tembak manual dulu
                          houseType: "Rumah / Townhouse", 
                          patokan: "Samping Burjo",
                        ),
                      ),
                    );
                  },
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
    return GestureDetector(
      onTap: _showJadwalBottomSheet, 
      child: Container(
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
      ),
    );
  }
}