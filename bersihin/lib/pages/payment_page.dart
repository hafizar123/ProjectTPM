import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'waiting_payment_page.dart'; 

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final int price; 
  final String date;
  final String time;
  final String address;
  final String houseType;
  final String patokan;

  const PaymentPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.date,
    required this.time,
    required this.address,
    required this.houseType,
    required this.patokan,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService();
  String _selectedPaymentMethod = '';
  bool _isLoading = false;

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  void _processToWaiting() async {
    if (_selectedPaymentMethod.isEmpty) {
      _showNotif('Silakan pilih metode pembayaran terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);

    int ppn = (widget.price * 0.11).round();
    int total = widget.price + ppn;

    String? generatedVa;
    String? generatedQris;

    if (_selectedPaymentMethod == 'qris') {
      generatedQris = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=BersihIn_${DateTime.now().millisecondsSinceEpoch}";
    } else {
      generatedVa = "8877${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    }

    final prefs = await SharedPreferences.getInstance();
    String userEmail = prefs.getString('saved_email') ?? 'guest@gmail.com';

    Map<String, dynamic> orderData = {
      'user_email': userEmail,
      'service_name': widget.serviceName,
      'total_amount': total,
      'payment_method': _selectedPaymentMethod,
      'va_number': generatedVa,
      'qris_url': generatedQris,
      'address': widget.address,
      'schedule_date': widget.date,
      'schedule_time': widget.time,
    };

    final response = await _authService.createOrder(orderData);
    
    setState(() => _isLoading = false);

    if (response['statusCode'] == 201) {
      int realOrderId = response['body']['orderId'];

      if (!mounted) return;
      
      // ZHANGG! Ini dia kunciannya biar kaga merah pak! 
      // Kita tambahin initialStatus pas mau Navigator.push
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingPaymentPage(
            orderId: realOrderId,
            totalAmount: total,
            paymentMethod: _selectedPaymentMethod,
            serviceName: widget.serviceName,
            vaNumber: generatedVa,
            qrisUrl: generatedQris,
            initialStatus: 'menunggu_pembayaran', // ZHANGG! Kirim status awal ke DB Mon!
          ),
        ),
      );
    } else {
      _showNotif('Gagal memproses pesanan. Silakan periksa koneksi sistem.');
    }
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.outfit(color: Colors.white)), 
        backgroundColor: Colors.red.shade600, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    int ppnFee = (widget.price * 0.11).round();
    int totalPrice = widget.price + ppnFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: toscaDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Pembayaran', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionTitle('Lokasi Pengerjaan'),
            _buildInfoCard(
              icon: Icons.location_on_rounded,
              title: widget.houseType,
              subtitle: widget.address,
              footer: widget.patokan != "-" ? "Patokan: ${widget.patokan}" : null,
            ),
            const SizedBox(height: 25),
            _buildSectionTitle('Detail Layanan'),
            _buildInfoCard(
              icon: Icons.water_drop_rounded,
              title: widget.serviceName,
              subtitle: "${widget.date} | ${widget.time}",
            ),
            const SizedBox(height: 25),
            _buildSectionTitle('Pilih Metode Pembayaran'),
            Text('Pembayaran Instan', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _buildPaymentTile('qris', 'QRIS (Gopay, Dana, OVO, ShopeePay)', Icons.qr_code_scanner_rounded),
            const SizedBox(height: 20),
            Text('Virtual Account Bank', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _buildPaymentTile('bca', 'BCA Virtual Account', Icons.account_balance_rounded),
            _buildPaymentTile('mandiri', 'Mandiri Virtual Account', Icons.account_balance_rounded),
            _buildPaymentTile('bni', 'BNI Virtual Account', Icons.account_balance_rounded),
            _buildPaymentTile('bri', 'BRI Virtual Account', Icons.account_balance_rounded),
            const SizedBox(height: 25),
            _buildSectionTitle('Ringkasan Biaya'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: toscaDark.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: toscaMedium.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Biaya Layanan', _formatCurrency(widget.price)),
                  const SizedBox(height: 10),
                  _buildPriceRow('PPN (11%)', _formatCurrency(ppnFee)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1, thickness: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Pembayaran', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      Text(_formatCurrency(totalPrice), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: toscaDark)), 
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120), 
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processToWaiting,
              style: ElevatedButton.styleFrom(
                backgroundColor: toscaDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text('BAYAR SEKARANG', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, String? footer}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: toscaMedium, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: toscaDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  Text(footer, style: GoogleFonts.outfit(fontSize: 12, color: toscaMedium, fontStyle: FontStyle.italic)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700)),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPaymentTile(String id, String name, IconData icon) {
    bool isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? toscaLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? toscaMedium : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected) BoxShadow(color: toscaMedium.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? toscaDark : Colors.grey.shade400, size: 22),
            const SizedBox(width: 15),
            Text(name, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? toscaDark : Colors.black87, fontSize: 14)),
            const Spacer(),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? toscaMedium : Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}