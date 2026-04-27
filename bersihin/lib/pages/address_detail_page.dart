import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'location_picker_page.dart'; // ZHANGG! Wajib import map lu di mari pak

class AddressDetailPage extends StatefulWidget {
  final Map<String, dynamic> locationData; 

  const AddressDetailPage({Key? key, required this.locationData}) : super(key: key);

  @override
  _AddressDetailPageState createState() => _AddressDetailPageState();
}

class _AddressDetailPageState extends State<AddressDetailPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService();
  
  // ZHANGG! State buat nampung data map yang bisa berubah-ubah
  late Map<String, dynamic> _currentLocationData;
  
  // Controller baru buat Label (Tulisan Bold) dan Patokan
  final TextEditingController _labelController = TextEditingController(); 
  final TextEditingController _descController = TextEditingController();
  
  String _selectedHouseType = 'Rumah / Townhouse';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _houseTypes = [
    {'title': 'Rumah / Townhouse', 'icon': Icons.home_rounded},
    {'title': 'Apartemen / Kondominium', 'icon': Icons.apartment_rounded},
    {'title': 'Villa / Resor', 'icon': Icons.holiday_village_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _currentLocationData = Map.from(widget.locationData);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('saved_username') ?? "Tamu";

    // ZHANGG! Trik Dewa: Label digabung koma sama alamat asli biar DB XAMPP aman pak!
    String label = _labelController.text.trim();
    String rawAddress = _currentLocationData['address'];
    String finalAddressToSave = label.isNotEmpty ? "$label, $rawAddress" : rawAddress;

    final response = await _authService.saveNewAddress(
      username,
      finalAddressToSave, 
      _currentLocationData['lat'].toString(),
      _currentLocationData['lng'].toString(),
      _selectedHouseType,
      _descController.text,
    );

    if (response['statusCode'] == 200) {
      if (mounted) {
        Navigator.pop(context, true); 
        Navigator.pop(context, true); 
      }
    } else {
      _showNotif("Gagal menyimpan detail alamat.");
    }
    setState(() => _isSubmitting = false);
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit()), backgroundColor: toscaMedium)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: toscaDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Lokasi', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ZHANGG! 1. INPUT LABEL ALAMAT (BISA DIKETIK MANUAL)
            Text('Label Alamat (Opsional):', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _labelController,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Contoh: Rumah Simon, Kosan Akmal, Kantor...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.bookmark_border_rounded, color: toscaMedium),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: toscaMedium)),
              ),
            ),
            const SizedBox(height: 25),

            // ZHANGG! 2. ALAMAT MAP (KAGA BISA DIKETIK, KLIK LARI KE MAP)
            Text('Alamat Peta:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              readOnly: true, // BENGONG ALIAS kaga bisa diketik manual pak!
              onTap: () async {
                // Lari lagi ke LBS map buat milih ulang
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationPickerPage()),
                );
                
                // Kalo balikan bawa data, update alamatnye
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    _currentLocationData = result;
                  });
                }
              },
              controller: TextEditingController(text: _currentLocationData['address']),
              maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.location_on_rounded, color: Colors.redAccent.shade400),
                suffixIcon: Icon(Icons.edit_location_alt_rounded, color: toscaMedium),
                filled: true,
                fillColor: Colors.red.shade50.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.red.shade100)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.red.shade100)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.red.shade200)),
              ),
            ),
            const SizedBox(height: 30),

            // PILIH JENIS BANGUNAN
            Text('Tipe Hunian:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 16)),
            const SizedBox(height: 15),
            ..._houseTypes.map((type) => _buildRadioTile(type)).toList(),

            const SizedBox(height: 30),

            // INPUT PATOKAN
            Text('Detail Patokan / Nomer Rumah:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Contoh: Rumah pagar hitam samping Masjid Al-Ikhlas, lantai 2...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: toscaMedium)),
              ),
            ),
            const SizedBox(height: 50),

            // BUTTON CONFIRM
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: toscaDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('KONFIRMASI DAN SIMPAN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(Map<String, dynamic> type) {
    bool isSelected = _selectedHouseType == type['title'];
    return GestureDetector(
      onTap: () => setState(() => _selectedHouseType = type['title']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? toscaLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? toscaMedium : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(type['icon'], color: isSelected ? toscaMedium : Colors.grey),
            const SizedBox(width: 15),
            Expanded(child: Text(type['title'], style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? toscaDark : Colors.black87))),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? toscaMedium : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}