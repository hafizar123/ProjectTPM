import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class WaitingPaymentPage extends StatefulWidget {
  final int orderId; 
  final int totalAmount;
  final String paymentMethod;
  final String serviceName;
  final String? vaNumber;
  final String? qrisUrl;
  final String initialStatus; 

  const WaitingPaymentPage({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.serviceName,
    required this.initialStatus, 
    this.vaNumber,
    this.qrisUrl,
  }) : super(key: key);

  @override
  _WaitingPaymentPageState createState() => _WaitingPaymentPageState();
}

class _WaitingPaymentPageState extends State<WaitingPaymentPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService();
  late Timer _timer;
  int _start = 1800; 
  bool _isLoading = false;
  late String _currentStatus; 

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus; 
    if (_currentStatus == 'menunggu_pembayaran') {
      _startTimer();
    }
  }

  @override
  void dispose() {
    if (_currentStatus == 'menunggu_pembayaran') _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0 || _currentStatus != 'menunggu_pembayaran') {
        timer.cancel();
      } else {
        setState(() => _start--);
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _handleConfirmPayment() async {
    setState(() => _isLoading = true);
    final response = await _authService.updateOrderStatus(widget.orderId, 'menunggu_konfirmasi');
    setState(() => _isLoading = false);

    if (response['statusCode'] == 200) {
      setState(() => _currentStatus = 'menunggu_konfirmasi');
      _showNotif('Konfirmasi pembayaran berhasil dikirim.');
    } else {
      _showNotif('Gagal memperbarui status. Silakan coba lagi.');
    }
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit(color: Colors.white)), backgroundColor: toscaMedium, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedAmount = "Rp ${widget.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    // ZHANGG! Ini dia PopScope yang udeh pinter pak!
    return PopScope(
      canPop: _currentStatus != 'menunggu_pembayaran', // Kalo udeh bayar, bolehin pop langsung
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (_currentStatus == 'menunggu_pembayaran') {
          _showBackDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [toscaDark, toscaMedium]),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(45), bottomRight: Radius.circular(45)),
              ),
            ),
            Positioned(right: -50, top: -20, child: Icon(Icons.water_drop_outlined, size: 250, color: Colors.white.withOpacity(0.05))),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          if (_currentStatus == 'menunggu_pembayaran') _buildTimerCard(formattedAmount),
                          const SizedBox(height: 35),
                          _buildMainContent(),
                          const SizedBox(height: 40),
                          if (_currentStatus == 'menunggu_pembayaran') ...[
                            _buildActionButtons(),
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: _showCancelDialog,
                              child: Text('Batalkan Pesanan', style: GoogleFonts.outfit(color: Colors.red.shade400, fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), 
            onPressed: () {
              // ZHANGG! Logika tombol back manualnye udeh pinter juga pak
              if (_currentStatus == 'menunggu_pembayaran') {
                _showBackDialog();
              } else {
                Navigator.pop(context, true); // Bawa sinyal true biar ActivityPage ngereload
              }
            }
          ),
          Expanded(child: Text('Detail Pesanan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTimerCard(String amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.timer_outlined, size: 18, color: Colors.red.shade700), const SizedBox(width: 8), Text('Batas Waktu Pembayaran', style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 12),
          Text(_timerText, style: GoogleFonts.outfit(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.red.shade900, letterSpacing: 2)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
          Text('Total Tagihan', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 8),
          Text(amount, style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: toscaDark, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentStatus == 'menunggu_pembayaran') {
      return widget.paymentMethod == 'qris' ? _buildQRISSection() : _buildVASection();
    } else {
      return _buildOrderDetailCard();
    }
  }

  Widget _buildOrderDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(),
          const SizedBox(height: 25),
          Text('Ringkasan Layanan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: toscaDark)),
          const SizedBox(height: 15),
          _buildDetailRow('Layanan', widget.serviceName),
          _buildDetailRow('Metode Bayar', widget.paymentMethod.toUpperCase()),
          _buildDetailRow('Total Biaya', "Rp ${widget.totalAmount.toString()}"),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
          Text('Status pesanan akan diperbarui secara otomatis setelah diverifikasi oleh Admin Bersih.In.', 
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label = _currentStatus.replaceAll('_', ' ').toUpperCase();
    Color color = toscaMedium;
    if (_currentStatus == 'menunggu_konfirmasi') color = Colors.orange;
    if (_currentStatus == 'pengerjaan') color = Colors.blue;
    if (_currentStatus == 'selesai') color = toscaDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildQRISSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.qr_code_2_rounded, size: 26), const SizedBox(width: 10), Text('QRIS BERSIIH.IN', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18))]),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.qrisUrl ?? '', height: 220, width: 220, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 30),
          Text('Pindai QR Code menggunakan aplikasi e-wallet atau mobile banking Anda.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildVASection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nomor Virtual Account', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.vaNumber ?? 'Gagal memuat VA', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: toscaDark, letterSpacing: 2)),
                IconButton(icon: const Icon(Icons.copy_rounded, size: 24), color: toscaMedium, onPressed: () { 
                  if(widget.vaNumber != null) {
                    Clipboard.setData(ClipboardData(text: widget.vaNumber!)); 
                    _showNotif('Nomor Virtual Account berhasil disalin.'); 
                  }
                }),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(height: 1)),
          Text('Instruksi Pembayaran:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 20),
          _buildStep('1', 'Buka m-banking Anda dan pilih menu Transfer Virtual Account.'),
          _buildStep('2', 'Masukkan nomor Virtual Account yang tertera di atas.'),
          _buildStep('3', 'Pastikan nominal tagihan sesuai sebelum mengonfirmasi pembayaran.'),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: toscaLight.withOpacity(0.2), shape: BoxShape.circle), child: Text(num, style: TextStyle(fontSize: 13, color: toscaDark, fontWeight: FontWeight.bold))),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleConfirmPayment,
        style: ElevatedButton.styleFrom(backgroundColor: toscaDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 8, shadowColor: toscaDark.withOpacity(0.4)),
        child: _isLoading 
          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text('SAYA SUDAH BAYAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
      ),
    );
  }

  Future<void> _showBackDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Kembali ke Beranda?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark)),
          content: Text('Pesanan Anda tidak akan dibatalkan. Anda tetap dapat menyelesaikan pembayaran ini melalui menu Aktivitas.', style: GoogleFonts.outfit(fontSize: 14)),
          actions: <Widget>[
            TextButton(child: Text('TIDAK', style: GoogleFonts.outfit(color: Colors.grey)), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('YA, KEMBALI', style: GoogleFonts.outfit(color: toscaMedium, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Batalkan Pesanan?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
          content: Text('Apakah Anda yakin ingin membatalkan pesanan ini? Data pada sistem akan dihapus secara permanen.', style: GoogleFonts.outfit(fontSize: 14)),
          actions: <Widget>[
            TextButton(child: Text('TIDAK', style: GoogleFonts.outfit(color: Colors.grey)), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('YA, BATALKAN', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                String email = prefs.getString('saved_email') ?? 'guest@gmail.com';
                await _authService.cancelOrder(email); 
                if (!mounted) return;
                Navigator.pop(context, 'cancel'); 
              },
            ),
          ],
        );
      },
    );
  }
}