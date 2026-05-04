import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';

// ============================================================
// DATA KATALOG SEMUA LAYANAN
// ============================================================
class LayananCatalog {
  static const Map<String, Map<String, dynamic>> data = {
    'Pemanas Air': {
      'subtitle': 'Layanan perbaikan, instalasi, dan perawatan.',
      'badge': 'Layanan Teknis',
      'headerIcon': Icons.water_drop_outlined,
      'catatan_hint': 'Contoh: Air tidak mau panas, ada kebocoran di pipa...',
      'options': [
        {'title': 'Perbaikan Kerusakan', 'price': 150000, 'icon': Icons.build_circle_outlined, 'desc': 'Diagnosa & perbaikan kerusakan komponen pemanas air oleh teknisi berpengalaman.'},
        {'title': 'Pemasangan Baru', 'price': 250000, 'icon': Icons.add_circle_outline_rounded, 'desc': 'Instalasi unit pemanas air baru dengan garansi pemasangan dan uji coba langsung.'},
        {'title': 'Perawatan Berkala', 'price': 100000, 'icon': Icons.published_with_changes_rounded, 'desc': 'Servis rutin untuk menjaga performa optimal dan memperpanjang usia pemanas air.'},
      ],
    },
    'Reguler Cleaning': {
      'subtitle': 'Kebersihan harian standar hotel bintang 5.',
      'badge': 'Layanan Kebersihan',
      'headerIcon': Icons.cleaning_services_outlined,
      'catatan_hint': 'Contoh: Fokus di dapur dan kamar mandi, ada noda membandel di lantai...',
      'options': [
        {'title': 'Paket Basic (2 Jam)', 'price': 80000, 'icon': Icons.timer_outlined, 'desc': 'Sapu, pel, lap permukaan, dan buang sampah. Cocok untuk hunian kecil atau studio.'},
        {'title': 'Paket Standard (4 Jam)', 'price': 150000, 'icon': Icons.home_outlined, 'desc': 'Termasuk pembersihan kamar mandi, dapur, dan semua ruangan. Untuk rumah 2-3 kamar.'},
        {'title': 'Paket Premium (Full Day)', 'price': 280000, 'icon': Icons.star_outline_rounded, 'desc': 'Pembersihan menyeluruh seharian penuh termasuk jendela, lemari, dan area tersembunyi.'},
      ],
    },
    'Cuci Kendaraan': {
      'subtitle': 'Cuci motor & mobil profesional di depan rumah.',
      'badge': 'Layanan Kendaraan',
      'headerIcon': Icons.local_car_wash_outlined,
      'catatan_hint': 'Contoh: Mobil SUV, ada noda lumpur di kolong, minta poles juga...',
      'options': [
        {'title': 'Cuci Motor', 'price': 25000, 'icon': Icons.two_wheeler_rounded, 'desc': 'Cuci bersih motor dengan sabun khusus, bilas, dan lap kering. Cepat dan bersih.'},
        {'title': 'Cuci Mobil Standar', 'price': 60000, 'icon': Icons.directions_car_rounded, 'desc': 'Cuci eksterior mobil sedan/city car lengkap dengan lap dan pengering.'},
        {'title': 'Cuci Mobil + Interior', 'price': 120000, 'icon': Icons.car_repair_rounded, 'desc': 'Cuci eksterior + vacuum interior + lap dashboard. Untuk semua jenis mobil.'},
      ],
    },
    'Cuci Kasur': {
      'subtitle': 'Kasur bersih, bebas tungau, dan wangi segar.',
      'badge': 'Layanan Furnitur',
      'headerIcon': Icons.bed_outlined,
      'catatan_hint': 'Contoh: Kasur ukuran King, ada noda, bahan memory foam...',
      'options': [
        {'title': 'Kasur Single / Twin', 'price': 100000, 'icon': Icons.single_bed_rounded, 'desc': 'Cuci kasur ukuran single dengan steam cleaning. Bersih dan kering dalam 3-4 jam.'},
        {'title': 'Kasur Double / Queen', 'price': 150000, 'icon': Icons.bed_rounded, 'desc': 'Untuk kasur ukuran double atau queen. Termasuk pembersihan bantal dan guling.'},
        {'title': 'Kasur King + Bantal Set', 'price': 220000, 'icon': Icons.king_bed_rounded, 'desc': 'Paket lengkap kasur king size + 2 bantal + 1 guling. Garansi bebas tungau.'},
      ],
    },
    'Deep Cleaning': {
      'subtitle': 'Sterilisasi total hingga sudut terdalam rumah.',
      'badge': 'Layanan Intensif',
      'headerIcon': Icons.sanitizer_rounded,
      'catatan_hint': 'Contoh: Baru pindahan, ada area berdebu tebal, perlu disinfeksi menyeluruh...',
      'options': [
        {'title': 'Deep Clean Studio/Kos', 'price': 350000, 'icon': Icons.meeting_room_outlined, 'desc': 'Pembersihan intensif untuk unit studio atau kamar kos. Termasuk disinfeksi.'},
        {'title': 'Deep Clean Rumah (2-3 KT)', 'price': 650000, 'icon': Icons.house_outlined, 'desc': 'Pembersihan menyeluruh rumah 2-3 kamar tidur. Termasuk cuci AC filter dan jendela.'},
        {'title': 'Deep Clean Rumah Besar (4+ KT)', 'price': 950000, 'icon': Icons.villa_outlined, 'desc': 'Untuk hunian besar. Tim 3 orang, alat heavy-duty, disinfeksi UV, garansi bersih.'},
      ],
    },
    'Pijat Relaksasi': {
      'subtitle': 'Spa eksklusif langsung di rumah Anda.',
      'badge': 'Layanan Wellness',
      'headerIcon': Icons.spa_outlined,
      'catatan_hint': 'Contoh: Fokus di punggung dan bahu, ada cedera ringan di lutut kiri...',
      'options': [
        {'title': 'Pijat Tradisional (60 Menit)', 'price': 120000, 'icon': Icons.self_improvement_rounded, 'desc': 'Pijat relaksasi seluruh tubuh dengan teknik tradisional Jawa. Meredakan pegal dan lelah.'},
        {'title': 'Pijat Refleksi (60 Menit)', 'price': 100000, 'icon': Icons.accessibility_new_rounded, 'desc': 'Fokus pada titik refleksi telapak kaki untuk meningkatkan sirkulasi dan vitalitas.'},
        {'title': 'Pijat Premium (90 Menit)', 'price': 200000, 'icon': Icons.star_rounded, 'desc': 'Kombinasi pijat tradisional + refleksi + aromaterapi. Pengalaman spa terlengkap.'},
      ],
    },
    'Service AC': {
      'subtitle': 'AC kembali dingin, bersih, dan hemat energi.',
      'badge': 'Layanan Teknis',
      'headerIcon': Icons.ac_unit_outlined,
      'catatan_hint': 'Contoh: AC tidak dingin, ada bunyi berisik, mau tambah freon...',
      'options': [
        {'title': 'Cuci AC Standard', 'price': 100000, 'icon': Icons.water_drop_rounded, 'desc': 'Pembersihan filter, evaporator, dan kondensor. AC kembali dingin dan bebas bau.'},
        {'title': 'Servis + Isi Freon', 'price': 250000, 'icon': Icons.gas_meter_rounded, 'desc': 'Cuci AC lengkap ditambah pengisian freon R32/R410A. Garansi dingin 30 hari.'},
        {'title': 'Bongkar Pasang + Servis', 'price': 400000, 'icon': Icons.handyman_rounded, 'desc': 'Relokasi unit AC ke posisi baru termasuk servis lengkap dan uji coba.'},
      ],
    },
    'Cuci Sofa': {
      'subtitle': 'Furnitur bersih, segar, dan bebas tungau.',
      'badge': 'Layanan Furnitur',
      'headerIcon': Icons.chair_outlined,
      'catatan_hint': 'Contoh: Ada noda kopi di cushion, sofa berbau apek, bahan beludru...',
      'options': [
        {'title': 'Sofa 1-2 Dudukan', 'price': 120000, 'icon': Icons.chair_outlined, 'desc': 'Cuci sofa kecil dengan metode ekstraksi uap. Bersih, kering dalam 2-3 jam.'},
        {'title': 'Sofa 3 Dudukan / L-Shape', 'price': 220000, 'icon': Icons.weekend_outlined, 'desc': 'Untuk sofa besar atau model L. Termasuk pembersihan sela-sela dan bantal sofa.'},
        {'title': 'Paket Sofa + Karpet', 'price': 350000, 'icon': Icons.layers_outlined, 'desc': 'Cuci sofa 3 dudukan + karpet ukuran sedang. Paket hemat untuk ruang tamu lengkap.'},
      ],
    },
  };
}

// ============================================================
// HALAMAN ORDER DINAMIS — SEMUA LAYANAN
// ============================================================
class OrderLayananPage extends StatefulWidget {
  final String namaLayanan;
  final String? address;
  final String? houseType;
  final String? patokan;

  const OrderLayananPage({
    Key? key,
    required this.namaLayanan,
    this.address,
    this.houseType,
    this.patokan,
  }) : super(key: key);

  @override
  State<OrderLayananPage> createState() => _OrderLayananPageState();
}

class _OrderLayananPageState extends State<OrderLayananPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  int _selectedOption = 0;
  final TextEditingController _catatanController = TextEditingController();
  DateTime? _pickedDate;
  String? _pickedTime;

  String _address = 'Alamat belum dipilih';
  String _houseType = 'Rumah';
  String _patokan = '-';

  final List<String> _timeSlots =
      List.generate(15, (i) => '${(i + 7).toString().padLeft(2, '0')}:00');

  late Map<String, dynamic> _catalog;
  late List<Map<String, dynamic>> _options;

  @override
  void initState() {
    super.initState();
    _catalog = LayananCatalog.data[widget.namaLayanan] ??
        LayananCatalog.data['Pemanas Air']!;
    _options = List<Map<String, dynamic>>.from(_catalog['options'] as List);
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _address = prefs.getString('order_address') ?? 'Alamat belum dipilih';
      _houseType = prefs.getString('order_house_type') ?? 'Rumah';
      _patokan = prefs.getString('order_patokan') ?? '-';
    });
  }

  String _formatPrice(int p) => 'Rp ${p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  String _getHari(int w) =>
      ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][w];

  String _getBulan(int m) =>
      ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'][m];

  void _showNotif(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  void _showJadwalBottomSheet() {
    final now = DateTime.now();
    final startOffset = now.hour >= 21 ? 1 : 0;
    final days =
        List.generate(30, (i) => now.add(Duration(days: i + startOffset)));
    DateTime tempDate = _pickedDate ?? days[0];
    if (tempDate.day == now.day && startOffset == 1) tempDate = days[0];
    String? tempTime = _pickedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.78,
          padding: const EdgeInsets.only(top: 12, left: 25, right: 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF025955).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.edit_calendar_rounded,
                      color: toscaDark, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Pilih Jadwal Pengerjaan',
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: toscaDark)),
              ]),
              const SizedBox(height: 24),
              Text('Tanggal',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: days.length,
                  itemBuilder: (_, i) {
                    final day = days[i];
                    final sel = tempDate.day == day.day &&
                        tempDate.month == day.month;
                    return GestureDetector(
                      onTap: () =>
                          setModal(() {
                            tempDate = day;
                            tempTime = null;
                          }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 68,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          gradient: sel
                              ? LinearGradient(
                                  colors: [toscaDark, toscaMedium],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight)
                              : null,
                          color: sel ? null : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: sel
                                  ? Colors.transparent
                                  : Colors.grey.shade200,
                              width: 1.5),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: toscaMedium.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5))
                                ]
                              : [],
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getHari(day.weekday),
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: sel
                                          ? Colors.white70
                                          : Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              Text('${day.day}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: sel ? Colors.white : toscaDark)),
                              Text(_getBulan(day.month),
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: sel
                                          ? Colors.white60
                                          : Colors.grey.shade400)),
                            ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('Waktu (07:00 – 21:00)',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      fontSize: 13)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots.map((time) {
                      final slotH = int.parse(time.split(':')[0]);
                      final isToday = tempDate.day == now.day &&
                          tempDate.month == now.month &&
                          tempDate.year == now.year;
                      final isPast = isToday && slotH <= now.hour;
                      final isSel = tempTime == time && !isPast;
                      return GestureDetector(
                        onTap: isPast
                            ? null
                            : () => setModal(() => tempTime = time),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width:
                              (MediaQuery.of(context).size.width - 50 - 30) /
                                  4,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: isSel
                                ? LinearGradient(
                                    colors: [toscaDark, toscaMedium])
                                : null,
                            color: isPast
                                ? Colors.grey.shade100
                                : (isSel ? null : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPast
                                  ? Colors.grey.shade200
                                  : (isSel
                                      ? Colors.transparent
                                      : Colors.grey.shade200),
                              width: 1.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                        color: toscaMedium.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4))
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(time,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isPast
                                    ? Colors.grey.shade400
                                    : (isSel
                                        ? Colors.white
                                        : Colors.grey.shade700),
                                decoration: isPast
                                    ? TextDecoration.lineThrough
                                    : null,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 20, top: 12),
                child: ElevatedButton(
                  onPressed: () {
                    if (tempTime == null) {
                      _showNotif('Silakan pilih waktu terlebih dahulu');
                      return;
                    }
                    setState(() {
                      _pickedDate = tempDate;
                      _pickedTime = tempTime;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: [toscaDark, toscaMedium]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text('SIMPAN JADWAL',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = _options[_selectedOption]['price'] as int;
    final combinedSchedule = (_pickedDate != null && _pickedTime != null)
        ? '${_pickedDate!.day} ${_getBulan(_pickedDate!.month)} ${_pickedDate!.year} • $_pickedTime WIB'
        : 'Pilih Tanggal & Waktu';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230.0,
            pinned: true,
            backgroundColor: toscaDark,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF025955), Color(0xFF0F2027)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Icon(_catalog['headerIcon'] as IconData,
                          size: 260,
                          color: Colors.white.withOpacity(0.04)),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(_catalog['headerIcon'] as IconData,
                          size: 160,
                          color: Colors.white.withOpacity(0.03)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 25, bottom: 35, right: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: toscaLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: toscaLight.withOpacity(0.4)),
                            ),
                            child: Text(_catalog['badge'] as String,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 10),
                          Text(widget.namaLayanan,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text(_catalog['subtitle'] as String,
                              style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BODY ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      Icons.layers_rounded, 'Pilih Paket Layanan'),
                  const SizedBox(height: 14),
                  ..._options
                      .asMap()
                      .entries
                      .map((e) => _buildOptionCard(e.key, e.value)),

                  const SizedBox(height: 28),
                  _buildSectionHeader(
                      Icons.event_rounded, 'Jadwal Pengerjaan'),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _showJadwalBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (_pickedDate != null)
                              ? toscaMedium.withOpacity(0.4)
                              : Colors.grey.shade200,
                          width: (_pickedDate != null) ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [toscaDark, toscaMedium]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.edit_calendar_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Waktu Kedatangan',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                            const SizedBox(height: 3),
                            Text(combinedSchedule,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _pickedDate != null
                                      ? toscaDark
                                      : Colors.grey.shade400,
                                )),
                          ],
                        )),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _buildSectionHeader(Icons.notes_rounded,
                      'Catatan Tambahan (Opsional)'),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 4,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _catalog['catatan_hint'] as String,
                        hintStyle: GoogleFonts.outfit(
                            color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 130),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── BOTTOM BAR ──────────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Row(children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimasi Biaya',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(_formatPrice(currentPrice),
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: toscaDark)),
                  Text('Belum termasuk PPN 11%',
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_pickedDate == null || _pickedTime == null) {
                    _showNotif('Silakan pilih tanggal dan waktu terlebih dahulu');
                    return;
                  }
                  if (_address == 'Alamat belum dipilih') {
                    _showNotif('Silakan pilih alamat terlebih dahulu');
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          serviceName:
                              '${widget.namaLayanan} – ${_options[_selectedOption]['title']}',
                          price: currentPrice,
                          date:
                              '${_pickedDate!.day} ${_getBulan(_pickedDate!.month)} ${_pickedDate!.year}',
                          time: '$_pickedTime WIB',
                          address: _address,
                          houseType: _houseType,
                          patokan: _patokan,
                        ),
                      ));
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [toscaDark, toscaMedium]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: toscaMedium.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('PESAN SEKARANG',
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: toscaMedium, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: toscaDark)),
    ]);
  }

  Widget _buildOptionCard(int index, Map<String, dynamic> option) {
    final isSel = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSel ? toscaDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                      color: toscaDark.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSel
                  ? Colors.white.withOpacity(0.15)
                  : toscaLight.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(option['icon'] as IconData,
                color: isSel ? Colors.white : toscaDark, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(option['title'] as String,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Text(option['desc'] as String,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isSel
                          ? Colors.white70
                          : Colors.grey.shade600,
                      height: 1.4)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSel
                      ? Colors.white.withOpacity(0.2)
                      : toscaLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    'Mulai ${_formatPrice(option['price'] as int)}',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : toscaDark)),
              ),
            ],
          )),
          const SizedBox(width: 8),
          Icon(
            isSel
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            color: isSel ? Colors.white : Colors.grey.shade300,
            size: 22,
          ),
        ]),
      ),
    );
  }
}
