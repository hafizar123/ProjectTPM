import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // ZHANGG! Pastiin path file auth_service lu bener ye pak
import 'location_picker_page.dart';

class SavedAddressPage extends StatefulWidget {
  final Widget targetOrderPage;
  
  const SavedAddressPage({Key? key, required this.targetOrderPage}) : super(key: key);

  @override
  _SavedAddressPageState createState() => _SavedAddressPageState();
}

class _SavedAddressPageState extends State<SavedAddressPage> {
  // Palet Warna Futuristik Bersih.In
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService(); 
  
  List<dynamic> _savedAddresses = [];
  String _username = 'Tamu';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddressesFromDB();
  }

  // ==========================================
  // SEDOT DATA DARI XAMPP VIA AUTH SERVICE
  // ==========================================
  Future<void> _loadAddressesFromDB() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('saved_username') ?? 'Tamu';
    
    if (_username == 'Tamu') {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _authService.getSavedAddresses(_username);
      if (response['statusCode'] == 200) {
        if (mounted) {
          setState(() {
            _savedAddresses = response['body']['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // FUNGSI HAPUS ALAMAT (DELETE)
  // ==========================================
  Future<void> _deleteAddress(String id) async {
    setState(() => _isLoading = true);
    final response = await _authService.deleteAddress(id);
    
    if (response['statusCode'] == 200) {
      _showNotif('Alamat berhasil dihapus pak!');
      _loadAddressesFromDB();
    } else {
      _showNotif('Gagal menghapus alamat.');
      setState(() => _isLoading = false);
    }
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.outfit()), 
        backgroundColor: toscaMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )
    );
  }

  // ==========================================
  // BOTTOM SHEET BUAT EDIT (LABEL, TIPE, PATOKAN)
  // ==========================================
  void _showEditBottomSheet(dynamic item) {
    // ZHANGG! Logika misahin Label (Bold) sama Alamat asli dari DB pak
    String fullAddress = item['address'] ?? '';
    List<String> parts = fullAddress.split(', ');
    String currentLabel = parts.isNotEmpty ? parts[0] : "";
    String rawAddress = parts.length > 1 ? parts.sublist(1).join(', ') : fullAddress;

    final TextEditingController _labelController = TextEditingController(text: currentLabel);
    final TextEditingController _descController = TextEditingController(text: item['description'] ?? '');
    String _selectedHouseType = item['house_type'] ?? 'Rumah / Townhouse';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
                top: 30, left: 25, right: 25
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 25),
                  Text('Edit Alamat Tersimpan', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
                  const SizedBox(height: 20),
                  
                  // INPUT BUAT EDIT NAMA TEMPAT (BOLD)
                  Text('Nama Tempat / Label', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _labelController,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Rumah Simon, Kosan Akmal...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: toscaMedium)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PILIHAN TIPE HUNIAN
                  Text('Tipe Hunian', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedHouseType,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: toscaMedium),
                        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 15),
                        items: ['Rumah / Townhouse', 'Apartemen / Kondominium', 'Villa / Resor'].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) {
                          setModalState(() => _selectedHouseType = newValue!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // INPUT PATOKAN BARU
                  Text('Detail Patokan', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: toscaMedium)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // TOMBOL SIMPAN
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); 
                        setState(() => _isLoading = true);

                        // Gabungin balik Label sama Alamat Peta aslinye pak!
                        String label = _labelController.text.trim();
                        String finalAddressToSave = label.isNotEmpty ? "$label, $rawAddress" : rawAddress;

                        final response = await _authService.editAddress(
                          item['id'].toString(), 
                          finalAddressToSave, // Kirim alamat gabungan ke backend
                          _selectedHouseType, 
                          _descController.text
                        );
                        
                        if (response['statusCode'] == 200) {
                          _showNotif('Alamat berhasil diupdate pak!');
                          _loadAddressesFromDB();
                        } else {
                          _showNotif('Gagal update alamat!');
                          setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: toscaDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('SIMPAN PERUBAHAN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER SLIVER FUTURISTIK
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            elevation: 0,
            backgroundColor: toscaDark,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [toscaDark, toscaMedium],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.map_outlined, size: 150, color: Colors.white.withOpacity(0.05)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, bottom: 30, right: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lokasi Anda', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                          const SizedBox(height: 5),
                          Text('Daftar Alamat', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: false,
              title: Text('Daftar Alamat', style: GoogleFonts.outfit(color: Colors.transparent)),
            ),
          ),

          // ISI KONTEN (LIST ALAMAT)
          SliverToBoxAdapter(
            child: _isLoading 
              ? Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator(color: toscaMedium)),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alamat Tersimpan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                      const SizedBox(height: 15),

                      _savedAddresses.isEmpty 
                        ? _buildEmptyState() 
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _savedAddresses.length,
                            itemBuilder: (context, index) {
                              final item = _savedAddresses[index];
                              return _buildAddressCard(item);
                            },
                          ),
                          
                      const SizedBox(height: 120), // Spasi buat tombol di bawah
                    ],
                  ),
                ),
          ),
        ],
      ),

      // TOMBOL FLOATING TAMBAH ALAMAT 
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -10))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_username == 'Tamu') {
                  _showNotif('Login dulu pak bos kalo mau nyimpen alamat!');
                  return;
                }

                // Lari ke map, kalo balikan dapet nilai true, refresh listnye
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationPickerPage()),
                );

                if (result == true) {
                  setState(() => _isLoading = true);
                  _loadAddressesFromDB(); 
                }
              },
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
              label: Text('TAMBAH ALAMAT BARU', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: toscaDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET KETIKA BELUM ADA ALAMAT
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: toscaLight.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.map_rounded, size: 60, color: toscaMedium),
          ),
          const SizedBox(height: 25),
          Text('Belum Ada Alamat', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
          const SizedBox(height: 8),
          Text('Tambahkan lokasi rumah atau kantor Anda untuk memudahkan pemesanan layanan.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
        ],
      ),
    );
  }

  // WIDGET CARD ALAMAT TERSIMPAN PREMIUM
  Widget _buildAddressCard(dynamic item) {
    String fullAddress = item['address'] ?? 'Alamat Tidak Diketahui';
    
    // ZHANGG! Ini logika pemisah alamat yang bikin UI lu rapi pak
    List<String> parts = fullAddress.split(', ');
    String title = parts.isNotEmpty ? parts[0] : 'Lokasi'; 
    String subAddress = parts.length > 1 ? parts.sublist(1).join(', ') : fullAddress;

    String houseType = item['house_type'] ?? 'Rumah';
    String desc = item['description'] ?? '';

    IconData typeIcon = Icons.home_rounded;
    if (houseType.contains('Apartemen')) typeIcon = Icons.apartment_rounded;
    if (houseType.contains('Villa')) typeIcon = Icons.holiday_village_rounded;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: toscaDark.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Pas diklik, lari ke form order lu Mon
            Navigator.push(context, MaterialPageRoute(builder: (context) => widget.targetOrderPage));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: toscaLight.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(typeIcon, color: toscaDark, size: 22),
                ),
                const SizedBox(width: 15),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(houseType, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ),
                      const SizedBox(height: 6),
                      
                      // Nama Tempat / Label (Bold)
                      Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: toscaDark)),
                      const SizedBox(height: 4),
                      
                      // Alamat Detail 
                      Text(subAddress, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: toscaMedium),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Patokan: $desc', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                
                // TOMBOL MENU TITIK TIGA
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  onSelected: (String result) {
                    if (result == 'edit') {
                      _showEditBottomSheet(item);
                    } else if (result == 'delete') {
                      _deleteAddress(item['id'].toString());
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: toscaMedium, size: 20),
                          const SizedBox(width: 10),
                          Text('Edit Detail', style: GoogleFonts.outfit(color: Colors.black87)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Text('Hapus', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}