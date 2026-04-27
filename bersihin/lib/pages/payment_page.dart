import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final String price;
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

  String _selectedPaymentMethod = '';
  bool _isProcessing = false;

  void _processPayment() {
    if (_selectedPaymentMethod.isEmpty) {
      _showNotif('Pilih metode pembayaran dulu pak bos!');
      return;
    }

    setState(() => _isProcessing = true);
    // ZHANGG! Simulasi bayar pak
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    });
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: const EdgeInsets.all(30),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: toscaLight.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: toscaMedium, size: 60),
            ),
            const SizedBox(height: 25),
            Text('Pembayaran Berhasil!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: toscaDark)),
            const SizedBox(height: 10),
            Text('Pesanan Anda sudah masuk antrean teknisi Bersih.In!', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(backgroundColor: toscaDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text('KEMBALI KE BERANDA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            
            // ==========================================
            // 1. DETAIL ALAMAT (ELEGAN)
            // ==========================================
            _buildSectionTitle('Lokasi Pengerjaan'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_rounded, color: toscaMedium, size: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.houseType, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: toscaDark)),
                        const SizedBox(height: 4),
                        Text(widget.address, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                        if (widget.patokan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Patokan: ${widget.patokan}', style: GoogleFonts.outfit(fontSize: 12, color: toscaMedium, fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==========================================
            // 2. DETAIL LAYANAN
            // ==========================================
            _buildSectionTitle('Detail Layanan'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.settings_suggest_rounded, 'Jasa', widget.serviceName),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Jadwal', '${widget.date} | ${widget.time}'),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==========================================
            // 3. METODE PEMBAYARAN (QRIS ADDED!)
            // ==========================================
            _buildSectionTitle('Metode Pembayaran'),
            _buildPaymentMethodTile('qris', 'QRIS (Gopay, Dana, ShopeePay)', Icons.qr_code_scanner_rounded),
            _buildPaymentMethodTile('gopay', 'GoPay', Icons.account_balance_wallet_rounded),
            _buildPaymentMethodTile('bca_va', 'BCA Virtual Account', Icons.account_balance_rounded),

            const SizedBox(height: 25),

            // ==========================================
            // 4. RINCIAN BIAYA (DIBAWAH PAK!)
            // ==========================================
            _buildSectionTitle('Ringkasan Biaya'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: toscaDark.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: toscaMedium.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Biaya Layanan', widget.price),
                  const SizedBox(height: 10),
                  _buildPriceRow('Biaya Platform', 'Rp 2.000'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1, thickness: 1, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Pembayaran', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      Text(widget.price, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: toscaDark)), // ZHANGG! Totalnye Mon
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 120), 
          ],
        ),
      ),

      // ==========================================
      // STICKY BOTTOM BUTTON
      // ==========================================
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
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: toscaDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: _isProcessing 
                ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text('BAYAR SEKARANG', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: toscaMedium),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
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

  Widget _buildPaymentMethodTile(String id, String name, IconData icon) {
    bool isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? toscaLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? toscaMedium : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? toscaDark : Colors.grey.shade400, size: 22),
            const SizedBox(width: 15),
            Text(name, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? toscaDark : Colors.black87)),
            const Spacer(),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? toscaMedium : Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}