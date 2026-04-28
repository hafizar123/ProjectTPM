import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart'; 

class OrderPemanasAirPage extends StatefulWidget {
  final String? address;
  final String? houseType;
  final String? patokan;

  const OrderPemanasAirPage({
    Key? key, 
    this.address, 
    this.houseType, 
    this.patokan
  }) : super(key: key);

  @override
  _OrderPemanasAirPageState createState() => _OrderPemanasAirPageState();
}

class _OrderPemanasAirPageState extends State<OrderPemanasAirPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  int _selectedServiceType = 0; 
  final TextEditingController _catatanController = TextEditingController();

  DateTime? _pickedDate;
  String? _pickedTime;

  String _address = "Alamat belum dipilih";
  String _houseType = "Rumah";
  String _patokan = "-";

  final List<Map<String, dynamic>> _serviceTypes = [
    {'title': 'Perbaikan Kerusakan', 'price': 150000, 'icon': Icons.build_circle_outlined},
    {'title': 'Pemasangan Baru', 'price': 250000, 'icon': Icons.add_circle_outline_rounded},
    {'title': 'Perawatan Berkala', 'price': 100000, 'icon': Icons.published_with_changes_rounded},
  ];

  final List<String> _timeSlots = List.generate(15, (index) => '${(index + 7).toString().padLeft(2, '0')}:00');

  @override
  void initState() {
    super.initState();
    _loadSavedAddress(); 
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _address = prefs.getString('order_address') ?? "Alamat belum dipilih";
      _houseType = prefs.getString('order_house_type') ?? "Rumah";
      _patokan = prefs.getString('order_patokan') ?? "-";
    });
  }

  String _formatPrice(int p) {
    return "Rp ${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

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
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))
    );
  }

  void _showJadwalBottomSheet() {
    DateTime now = DateTime.now();
    
    // ZHANGG! Kalo udeh lewat jam operasional (21:00), hari ini kaga usah ditampilin pak!
    int startOffset = now.hour >= 21 ? 1 : 0;
    List<DateTime> upcomingDays = List.generate(30, (index) => now.add(Duration(days: index + startOffset)));

    // Pastiin default milih yg pertama, mencegah error kalo kemaren udeh milih hari ini terus kelewat
    DateTime tempDate = _pickedDate ?? upcomingDays[0];
    if (tempDate.day == now.day && startOffset == 1) {
      tempDate = upcomingDays[0]; 
    }
    
    String? tempTime = _pickedTime;

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
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
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
                          onTap: () {
                            setModalState(() {
                              tempDate = day;
                              // ZHANGG! Kalo ganti tanggal, jamnya kita reset biar ga nyangkut di jam yg mati pak
                              tempTime = null; 
                            });
                          },
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
                          // ZHANGG! Logika sakti buat matiin jam yang udeh lewat
                          int slotHour = int.parse(time.split(':')[0]);
                          bool isToday = tempDate.day == now.day && tempDate.month == now.month && tempDate.year == now.year;
                          bool isPast = isToday && slotHour <= now.hour; // Kalo jamnye sama ato kurang, mampus!

                          bool isSelected = tempTime == time && !isPast;

                          return GestureDetector(
                            onTap: isPast ? null : () => setModalState(() => tempTime = time),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: (MediaQuery.of(context).size.width - 50 - 36) / 4, 
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isPast 
                                    ? Colors.grey.shade100 // Warna mati Mon
                                    : (isSelected ? toscaLight.withOpacity(0.15) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPast 
                                      ? Colors.grey.shade200 
                                      : (isSelected ? toscaMedium : Colors.grey.shade200), 
                                  width: isSelected ? 1.5 : 1
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                time,
                                style: GoogleFonts.outfit(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isPast 
                                      ? Colors.grey.shade400 // Teks redup
                                      : (isSelected ? toscaDark : Colors.grey.shade600),
                                  decoration: isPast ? TextDecoration.lineThrough : null, // ZHANGG! Coret sekalian
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    height: 55,
                    margin: const EdgeInsets.only(bottom: 20, top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (tempTime == null) { _showNotif('Pilih waktunye dulu pak!'); return; }
                        setState(() { _pickedDate = tempDate; _pickedTime = tempTime; });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: toscaDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
    int currentPrice = _serviceTypes[_selectedServiceType]['price'];
    
    String displayDate = _pickedDate != null ? "${_pickedDate!.day} ${_getBulan(_pickedDate!.month)} ${_pickedDate!.year}" : "";
    String displayTime = _pickedTime != null ? "$_pickedTime WIB" : "";
    String combinedSchedule = (_pickedDate != null && _pickedTime != null) 
        ? "$displayDate • $displayTime" 
        : "Pilih Tanggal & Waktu";

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
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [toscaDark, toscaMedium.withOpacity(0.9)]),
                ),
                child: Stack(
                  children: [
                    Positioned(right: -50, top: -50, child: Icon(Icons.water_drop_outlined, size: 250, color: Colors.white.withOpacity(0.05))),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, bottom: 40, right: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: toscaLight.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: toscaLight.withOpacity(0.5))),
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
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, toscaLight.withOpacity(0.03)])),
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
                                    Text('Mulai dari ${_formatPrice(_serviceTypes[index]['price'])}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
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
                  
                  GestureDetector(
                    onTap: _showJadwalBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: toscaLight.withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(Icons.edit_calendar_rounded, color: toscaDark, size: 24),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Waktu Kedatangan', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Text(combinedSchedule, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: toscaDark)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
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
                      _formatPrice(currentPrice), 
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: toscaDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_pickedDate == null || _pickedTime == null) {
                      _showNotif('Pilih tanggal sama waktunye dulu pak bos!');
                      return;
                    }
                    if (_address == "Alamat belum dipilih") {
                      _showNotif('Lu belom milih alamat dari halaman sebelumnya Mon!');
                      return;
                    }
                    
                    String formattedDate = "${_pickedDate!.day} ${_getBulan(_pickedDate!.month)} ${_pickedDate!.year}";
                    String formattedTime = "$_pickedTime WIB";

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          serviceName: _serviceTypes[_selectedServiceType]['title'],
                          price: currentPrice, 
                          date: formattedDate,
                          time: formattedTime,
                          address: _address, 
                          houseType: _houseType, 
                          patokan: _patokan,
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
}