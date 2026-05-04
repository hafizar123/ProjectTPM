import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/notification_service.dart';
import '../home/home_page.dart';
import '../support/live_chat_page.dart';

class WaitingPaymentPage extends StatefulWidget {
  final int orderId;
  final int totalAmount;
  final String paymentMethod;
  final String serviceName;
  final String? vaNumber;
  final String? qrisUrl;
  final String initialStatus;

  final String? address;
  final String? houseType;
  final String? patokan;
  final String? transactionTime;
  final String? currency;        // kode mata uang (IDR/CNY/SGD/SAR)
  final double? totalConverted;  // nilai total dalam mata uang asing

  const WaitingPaymentPage({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.serviceName,
    required this.initialStatus,
    this.vaNumber,
    this.qrisUrl,
    this.address,
    this.houseType,
    this.patokan,
    this.transactionTime,
    this.currency,
    this.totalConverted,
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
  // -1 = belum diinisialisasi (menunggu _initTimer selesai)
  // 0  = expired
  // >0 = sisa detik
  int _start = -1;
  bool _isLoading = false;
  late String _currentStatus;

  // Review state
  double _reviewRating = 0;
  final TextEditingController _reviewCtrl = TextEditingController();
  bool _reviewSubmitted = false;
  bool _reviewLoading = false;
  String _userEmail = '';

  // Mata uang & nilai konversi — bisa dari parameter (langsung dari payment)
  // atau dari SharedPreferences (dibuka dari Activity)
  String _currency = 'IDR';
  double? _totalConverted;

  static const int _paymentWindowSecs = 1800; // 30 menit

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    // Pakai nilai dari parameter dulu jika ada
    _currency       = widget.currency ?? 'IDR';
    _totalConverted = widget.totalConverted;

    // Load email user
    SharedPreferences.getInstance().then((p) {
      _userEmail = p.getString('saved_email') ?? '';
      _checkReviewSubmitted();
    });

    // Load mata uang dari prefs SELALU — tidak peduli status pesanan
    _loadCurrencyFromPrefs().then((_) {
      // Timer hanya untuk status menunggu pembayaran
      if (_currentStatus == 'menunggu_pembayaran') {
        _initTimer();
      }
    });
  }

  /// Baca currency & converted dari SharedPreferences.
  /// Dipanggil selalu di initState agar tampilan mata uang benar
  /// meski dibuka dari Activity setelah logout-login.
  Future<void> _loadCurrencyFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency  = prefs.getString('order_currency_${widget.orderId}');
    final savedConverted = prefs.getDouble('order_converted_${widget.orderId}');

    if (mounted) {
      setState(() {
        // Prioritas: parameter widget > SharedPreferences
        // Jika parameter tidak ada (null/IDR dari activity), pakai dari prefs
        if (savedCurrency != null && savedCurrency != 'IDR' && _currency == 'IDR') {
          _currency = savedCurrency;
        }
        if (savedConverted != null && _totalConverted == null) {
          _totalConverted = savedConverted;
        }
      });
    }
  }

  /// Baca timestamp dari SharedPreferences dan hitung sisa countdown.
  Future<void> _initTimer() async {
    final prefs = await SharedPreferences.getInstance();
    // Coba baca dengan orderId sebagai int maupun string (defensive)
    final key = 'order_created_at_${widget.orderId}';
    final createdAt = prefs.getInt(key);

    if (createdAt != null && createdAt > 0) {
      final elapsed   = ((DateTime.now().millisecondsSinceEpoch - createdAt) / 1000).round();
      final remaining = _paymentWindowSecs - elapsed;
      if (mounted) setState(() => _start = remaining > 0 ? remaining : 0);
    } else {
      // Tidak ada timestamp tersimpan — jangan reset ke 30 menit penuh
      // Tandai sebagai expired agar user tahu
      if (mounted) setState(() => _start = 0);
    }

    if (_start > 0) _startTimer();
  }

  @override
  void dispose() {
    if (_currentStatus == 'menunggu_pembayaran') {
      // Hanya cancel jika timer sudah diinisialisasi
      try { _timer.cancel(); } catch (_) {}
    }
    _reviewCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start <= 0 || _currentStatus != 'menunggu_pembayaran') {
        timer.cancel();
        if (_start == 0 && _currentStatus == 'menunggu_pembayaran') {
          NotificationService().showPaymentExpired(widget.serviceName);
        }
      } else {
        setState(() => _start--);
      }
    });
  }

  String get _timerText {
    if (_start < 0) return '--:--'; // Masih loading timestamp
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
      // Cancel reminder pembayaran karena sudah dikonfirmasi
      await NotificationService().cancel(NotifId.paymentReminder);
      _showNotif('Konfirmasi pembayaran berhasil dikirim');
    } else {
      _showNotif('Gagal memperbarui status. Silakan coba lagi');
    }
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit(color: Colors.white)), backgroundColor: toscaMedium, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
    );
  }

  Future<void> _checkReviewSubmitted() async {
    // Cek dari API dulu (sumber kebenaran)
    final res = await _authService.checkOrderReview(widget.orderId);
    if (mounted) {
      setState(() {
        _reviewSubmitted = res['statusCode'] == 200 && (res['body']['reviewed'] == true);
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewRating == 0) {
      _showNotif('Silakan pilih rating bintang terlebih dahulu');
      return;
    }
    if (_reviewCtrl.text.trim().isEmpty) {
      _showNotif('Silakan tulis ulasan Anda');
      return;
    }
    setState(() => _reviewLoading = true);
    final res = await _authService.submitOrderReview(
      widget.orderId,
      _userEmail,
      _reviewRating,
      _reviewCtrl.text.trim(),
    );
    setState(() => _reviewLoading = false);
    if (res['statusCode'] == 201) {
      if (mounted) setState(() => _reviewSubmitted = true);
      _showNotif('Ulasan berhasil dikirim. Terima kasih!');
    } else if (res['statusCode'] == 409) {
      if (mounted) setState(() => _reviewSubmitted = true);
      _showNotif('Ulasan untuk pesanan ini sudah pernah dikirim');
    } else {
      _showNotif('Gagal mengirim ulasan. Silakan coba lagi');
    }
  }

  void _showReportDialog() {
    final TextEditingController reportCtrl = TextEditingController();
    String? reportImageBase64;
    String? reportImageName;
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade400]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Laporkan Masalah',
                          style: GoogleFonts.outfit(
                              fontSize: 17, fontWeight: FontWeight.bold, color: toscaDark)),
                      Text('Pesanan #${widget.orderId}',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 18),

                // Input deskripsi
                Text('Deskripsi Masalah',
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: reportCtrl,
                    maxLines: 4,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Petugas tidak datang tepat waktu, hasil kurang bersih...',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.grey.shade400, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Upload gambar
                Text('Lampirkan Bukti Foto (Opsional)',
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 60,
                      maxWidth: 1024,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final b64 = base64Encode(bytes);
                      setDialog(() {
                        reportImageBase64 = b64;
                        reportImageName = picked.name;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: reportImageBase64 != null
                          ? toscaLight.withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: reportImageBase64 != null
                            ? toscaMedium.withOpacity(0.5)
                            : Colors.grey.shade200,
                        width: reportImageBase64 != null ? 1.5 : 1,
                      ),
                    ),
                    child: reportImageBase64 != null
                        ? Column(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(reportImageBase64!),
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check_circle_rounded,
                                  color: toscaDark, size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  reportImageName ?? 'Gambar dipilih',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: toscaDark,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setDialog(() {
                                  reportImageBase64 = null;
                                  reportImageName = null;
                                }),
                                child: Icon(Icons.close_rounded,
                                    color: Colors.red.shade400, size: 16),
                              ),
                            ]),
                          ])
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: Colors.grey.shade400, size: 22),
                            const SizedBox(width: 8),
                            Text('Pilih dari Galeri',
                                style: GoogleFonts.outfit(
                                    fontSize: 13, color: Colors.grey.shade500)),
                          ]),
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol aksi
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text('Batal',
                          style: GoogleFonts.outfit(color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: sending
                          ? null
                          : () async {
                              if (reportCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Harap isi deskripsi laporan',
                                      style: GoogleFonts.outfit(color: Colors.white)),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ));
                                return;
                              }
                              setDialog(() => sending = true);
                              // Simpan ke tabel reports
                              final res = await _authService.submitReport(
                                orderId: widget.orderId,
                                userEmail: _userEmail,
                                description: reportCtrl.text.trim(),
                                imageBase64: reportImageBase64,
                              );
                              setDialog(() => sending = false);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (res['statusCode'] == 201) {
                                // Kirim notifikasi ke live chat juga
                                await _authService.sendMessage(
                                  _userEmail,
                                  'user',
                                  '🚩 Laporan baru untuk pesanan #${widget.orderId} — ${widget.serviceName} telah dikirim. Tim kami akan segera menindaklanjuti.',
                                );
                                if (mounted) {
                                  _showNotif('Laporan berhasil dikirim!');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LiveChatPage()),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  _showNotif('Gagal mengirim laporan. Silakan coba lagi');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Kirim Laporan',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ZHANGG! Fungsi sakti buat bablas ke Home pak!
  void _backToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan total dalam mata uang yang dipilih user
    // Pakai state _currency/_totalConverted yang sudah di-resolve dari prefs
    final isIntl = _currency != 'IDR';
    final String formattedAmount = isIntl && _totalConverted != null
        ? CurrencyService.format(_totalConverted!, _currency)
        : CurrencyService.formatFromIdr(widget.totalAmount, 'IDR');
    
    return PopScope(
      canPop: false, // Konci rapet Mon!
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        _backToHome(); // Kalo tombol back hape dipencet, langsung tebas ke Home!
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
                          // Form review hanya muncul saat status selesai
                          if (_currentStatus == 'selesai') ...[
                            const SizedBox(height: 24),
                            _buildReviewSection(),
                          ],
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
            onPressed: _backToHome,
          ),
          Expanded(child: Text('Detail Pesanan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
          // Tombol report hanya muncul saat status selesai
          if (_currentStatus == 'selesai')
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
              ),
              onPressed: _showReportDialog,
              tooltip: 'Laporkan Masalah',
            )
          else
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
    // Pakai state _currency/_totalConverted (sudah di-resolve dari prefs)
    final isIntl = _currency != 'IDR';
    final bankNm = isIntl ? (CurrencyService.bankName[_currency] ?? '') : '';

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

          if (widget.transactionTime != null)
            _buildDetailRow('Waktu Transaksi', widget.transactionTime!),

          _buildDetailRow('Layanan', widget.serviceName),
          _buildDetailRow('Metode Bayar', widget.paymentMethod.replaceAll('_', ' ').toUpperCase()),

          // Total IDR selalu ditampilkan
          _buildDetailRow('Total (IDR)', CurrencyService.formatFromIdr(widget.totalAmount, 'IDR')),

          // Jika bayar pakai mata uang asing, tampilkan konversi
          if (isIntl && _totalConverted != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [toscaDark.withOpacity(0.06), toscaMedium.withOpacity(0.04)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: toscaMedium.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.currency_exchange_rounded, color: toscaDark, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dibayar via $bankNm',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
                  Text(CurrencyService.format(_totalConverted!, _currency),
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark)),
                ])),
              ]),
            ),
          ],

          if (widget.address != null) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
            Text('Alamat Pengerjaan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: toscaDark)),
            const SizedBox(height: 8),
            Text('${widget.houseType ?? 'Hunian'} - ${widget.address}',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
            if (widget.patokan != null && widget.patokan != '-') ...[
              const SizedBox(height: 4),
              Text('Patokan: ${widget.patokan}',
                  style: GoogleFonts.outfit(fontSize: 12, color: toscaMedium, fontStyle: FontStyle.italic)),
            ],
          ],

          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
          Text('Status pesanan akan diperbarui secara otomatis setelah diverifikasi oleh Admin Bersih.In.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    if (_reviewSubmitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: toscaLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: toscaDark, size: 32),
          ),
          const SizedBox(height: 12),
          Text('Ulasan Terkirim',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark)),
          const SizedBox(height: 4),
          Text('Terima kasih atas ulasan Anda!',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Beri Ulasan',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark)),
        ]),
        const SizedBox(height: 6),
        Text('Bagaimana pengalaman Anda dengan layanan ini?',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 18),
        // Bintang rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starVal = (i + 1).toDouble();
            return GestureDetector(
              onTap: () => setState(() => _reviewRating = starVal),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  _reviewRating >= starVal
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _reviewRating >= starVal
                      ? Colors.amber.shade500
                      : Colors.grey.shade300,
                  size: 38,
                ),
              ),
            );
          }),
        ),
        if (_reviewRating > 0) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              ['', 'Sangat Buruk', 'Buruk', 'Cukup', 'Bagus', 'Sangat Bagus'][_reviewRating.toInt()],
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Input teks ulasan
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _reviewCtrl,
            maxLines: 3,
            style: GoogleFonts.outfit(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalaman Anda...',
              hintStyle: GoogleFonts.outfit(
                  color: Colors.grey.shade400, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _reviewLoading ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: toscaDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _reviewLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Kirim Ulasan',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
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
                    _showNotif('Nomor Virtual Account berhasil disalin');
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

  Future<void> _showCancelDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Batalkan Pesanan?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
          content: Text(
              'Apakah Anda yakin ingin membatalkan pesanan ini? Data pada sistem akan dihapus secara permanen.',
              style: GoogleFonts.outfit(fontSize: 14)),
          actions: <Widget>[
            TextButton(
                child: Text('TIDAK', style: GoogleFonts.outfit(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('YA, BATALKAN',
                  style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(context).pop();

                // Kirim orderId (bukan email) ke endpoint cancel-order
                final response = await _authService.cancelOrder(widget.orderId.toString());

                if (!mounted) return;

                if (response['statusCode'] == 200) {
                  // Bersihkan data order dari SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('order_created_at_${widget.orderId}');
                  await prefs.remove('order_currency_${widget.orderId}');
                  await prefs.remove('order_converted_${widget.orderId}');

                  _backToHome();
                } else {
                  _showNotif('Gagal membatalkan pesanan. Silakan coba lagi');
                }
              },
            ),
          ],
        );
      },
    );
  }
}