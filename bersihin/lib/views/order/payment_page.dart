import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/notification_service.dart';
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
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);
  final AuthService _authService = AuthService();

  String _selectedMethod = '';   // id metode terpilih
  String _selectedCurrency = 'IDR'; // mata uang aktif
  bool _isLoading = false;
  bool _intlExpanded = false;    // accordion bank internasional

  // ── data bank internasional ──────────────────────────────────
  static const _intlBanks = [
    {'currency': 'CNY', 'flag': '🇨🇳'},
    {'currency': 'SGD', 'flag': '🇸🇬'},
    {'currency': 'SAR', 'flag': '🇸🇦'},
  ];

  // ── hitung harga dalam mata uang aktif ───────────────────────
  String _fmt(int idr) => CurrencyService.formatFromIdr(idr, _selectedCurrency);

  int get _ppn  => (widget.price * 0.11).round();
  int get _total => widget.price + _ppn;

  // ── proses ke waiting page ───────────────────────────────────
  void _processToWaiting() async {
    if (_selectedMethod.isEmpty) {
      _notif('Silakan pilih metode pembayaran terlebih dahulu');
      return;
    }
    setState(() => _isLoading = true);

    String? generatedVa;
    String? generatedQris;

    if (_selectedMethod == 'qris') {
      generatedQris = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=BersihIn_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      generatedVa = '8877${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }

    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('saved_email') ?? 'guest@gmail.com';
    final timeZone  = prefs.getString('zona_waktu') ?? 'WIB';
    final offset    = {'WIB': 7, 'WITA': 8, 'WIT': 9, 'London': 1}[timeZone] ?? 7;
    final zoneTime  = DateTime.now().toUtc().add(Duration(hours: offset));
    final trxTime   = '${zoneTime.day.toString().padLeft(2,'0')}/${zoneTime.month.toString().padLeft(2,'0')}/${zoneTime.year} '
                      '${zoneTime.hour.toString().padLeft(2,'0')}:${zoneTime.minute.toString().padLeft(2,'0')} $timeZone';

    // Simpan total dalam IDR ke DB, plus info mata uang & nilai konversi
    final totalIdr = _total;
    final totalConverted = CurrencyService.fromIdr(totalIdr, _selectedCurrency);

    final orderData = {
      'user_email'       : userEmail,
      'service_name'     : widget.serviceName,
      'total_amount'     : totalIdr,
      'payment_method'   : _selectedMethod,
      'va_number'        : generatedVa,
      'qris_url'         : generatedQris,
      'address'          : widget.address,
      'schedule_date'    : widget.date,
      'schedule_time'    : widget.time,
      'waktu_transaksi'  : trxTime,
      'currency'         : _selectedCurrency,
      'total_converted'  : totalConverted,
    };

    final response = await _authService.createOrder(orderData);
    setState(() => _isLoading = false);

    if (response['statusCode'] == 201) {
      final realOrderId = response['body']['orderId'];
      if (!mounted) return;

      // Simpan timestamp + info mata uang ke SharedPreferences lokal.
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('order_created_at_$realOrderId', createdAt);
      await prefs.setString('order_currency_$realOrderId', _selectedCurrency);
      await prefs.setDouble('order_converted_$realOrderId', totalConverted);

      // ── Jadwalkan notifikasi ──────────────────────────────────
      final notif = NotificationService();

      // 1. Pengingat 10 menit sebelum pembayaran expired
      await notif.schedulePaymentReminder(
        orderId: realOrderId,
        serviceName: widget.serviceName,
        createdAtMs: createdAt,
      );

      // 2. Pengingat jadwal H-1 dan hari-H
      final schedDt = NotificationService.parseScheduleDateTime(
          widget.date, widget.time);
      if (schedDt != null) {
        await notif.scheduleH1Reminder(
            serviceName: widget.serviceName, scheduleDateTime: schedDt);
        await notif.scheduleHariHReminder(
            serviceName: widget.serviceName, scheduleDateTime: schedDt);
      }

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => WaitingPaymentPage(
          orderId       : realOrderId,
          totalAmount   : totalIdr,
          paymentMethod : _selectedMethod,
          serviceName   : widget.serviceName,
          vaNumber      : generatedVa,
          qrisUrl       : generatedQris,
          initialStatus : 'menunggu_pembayaran',
          address       : widget.address,
          houseType     : widget.houseType,
          patokan       : widget.patokan,
          transactionTime: trxTime,
          currency      : _selectedCurrency,
          totalConverted: totalConverted,
        ),
      ));
    } else {
      _notif('Gagal memproses pesanan. Periksa koneksi internet Anda');
    }
  }

  void _notif(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
    backgroundColor: Colors.red.shade600,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  ));

  // ── BUILD ────────────────────────────────────────────────────
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
        title: Text('Detail Pembayaran',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 10),

          // ── lokasi ──────────────────────────────────────
          _sectionTitle('Lokasi Pengerjaan'),
          _infoCard(icon: Icons.location_on_rounded, title: widget.houseType,
              subtitle: widget.address,
              footer: widget.patokan != '-' ? 'Patokan: ${widget.patokan}' : null),
          const SizedBox(height: 22),

          // ── layanan ─────────────────────────────────────
          _sectionTitle('Detail Layanan'),
          _infoCard(icon: Icons.cleaning_services_rounded, title: widget.serviceName,
              subtitle: '${widget.date} | ${widget.time}'),
          const SizedBox(height: 22),

          // ── metode pembayaran ────────────────────────────
          _sectionTitle('Pilih Metode Pembayaran'),

          // QRIS
          _subLabel('Pembayaran Instan'),
          const SizedBox(height: 8),
          _methodTile(id: 'qris', label: 'QRIS (Gopay, Dana, OVO, ShopeePay)',
              icon: Icons.qr_code_scanner_rounded),
          const SizedBox(height: 18),

          // VA Lokal
          _subLabel('Virtual Account Bank Lokal'),
          const SizedBox(height: 8),
          _methodTile(id: 'bca',     label: 'BCA Virtual Account',     icon: Icons.account_balance_rounded),
          _methodTile(id: 'mandiri', label: 'Mandiri Virtual Account',  icon: Icons.account_balance_rounded),
          _methodTile(id: 'bni',     label: 'BNI Virtual Account',      icon: Icons.account_balance_rounded),
          _methodTile(id: 'bri',     label: 'BRI Virtual Account',      icon: Icons.account_balance_rounded),
          const SizedBox(height: 18),

          // Bank Internasional (accordion)
          _subLabel('Bank Internasional'),
          const SizedBox(height: 8),
          _buildIntlBankSection(),
          const SizedBox(height: 22),

          // ── ringkasan biaya ──────────────────────────────
          _sectionTitle('Ringkasan Biaya'),
          _buildPriceSummary(),
          const SizedBox(height: 120),
        ]),
      ),

      // ── bottom bar ───────────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(child: SizedBox(
          width: double.infinity, height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processToWaiting,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text('BAYAR SEKARANG',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              ),
            ),
          ),
        )),
      ),
    );
  }

  // ── BANK INTERNASIONAL ACCORDION ────────────────────────────
  Widget _buildIntlBankSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _intlBanks.any((b) => _selectedMethod == CurrencyService.bankCode[b['currency']])
              ? toscaMedium
              : Colors.grey.shade200,
          width: _intlBanks.any((b) => _selectedMethod == CurrencyService.bankCode[b['currency']]) ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // Header accordion
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _intlExpanded = !_intlExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: toscaLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.language_rounded, color: toscaDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bank Internasional',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                Text('Bank of China • UOB • Saudi National Bank',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
              ])),
              AnimatedRotation(
                turns: _intlExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
              ),
            ]),
          ),
        ),

        // Daftar bank (expandable)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            Divider(height: 1, color: Colors.grey.shade100),
            ..._intlBanks.map((bank) {
              final currency = bank['currency']!;
              final flag     = bank['flag']!;
              final code     = CurrencyService.bankCode[currency]!;
              final bankNm   = CurrencyService.bankName[currency]!;
              final currNm   = CurrencyService.name[currency]!;
              final isSel    = _selectedMethod == code;

              return InkWell(
                onTap: () => setState(() {
                  _selectedMethod  = code;
                  _selectedCurrency = currency;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSel ? toscaLight.withOpacity(0.08) : Colors.transparent,
                  ),
                  child: Row(children: [
                    // Flag + currency badge
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isSel ? toscaDark : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(flag, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(bankNm,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14,
                              color: isSel ? toscaDark : Colors.black87)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSel ? toscaMedium.withOpacity(0.15) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(currency,
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold,
                                  color: isSel ? toscaDark : Colors.grey.shade600)),
                        ),
                        const SizedBox(width: 6),
                        Text(currNm,
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                    ])),
                    Icon(
                      isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSel ? toscaMedium : Colors.grey.shade300,
                      size: 22,
                    ),
                  ]),
                ),
              );
            }).toList(),
          ]),
          crossFadeState: _intlExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    );
  }

  // ── RINGKASAN BIAYA ──────────────────────────────────────────
  Widget _buildPriceSummary() {
    final isIntl = _selectedCurrency != 'IDR';
    final sym    = CurrencyService.symbol[_selectedCurrency]!;
    final nm     = CurrencyService.name[_selectedCurrency]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: toscaDark.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: toscaMedium.withOpacity(0.12)),
      ),
      child: Column(children: [
        // Badge mata uang aktif
        if (isIntl) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Harga dalam $sym ($nm)',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ),
            ]),
          ),
        ],

        _priceRow('Biaya Layanan', _fmt(widget.price)),
        const SizedBox(height: 10),
        _priceRow('PPN (11%)', _fmt(_ppn)),

        // Kurs referensi jika internasional
        if (isIntl) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber.shade800),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'Kurs: 1 $sym = ${CurrencyService.formatFromIdr((CurrencyService.fromIdr(1, _selectedCurrency) == 0 ? 1 : (1 / CurrencyService.fromIdr(1, _selectedCurrency)).round()), 'IDR')}',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber.shade900),
              )),
            ]),
          ),
        ],

        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, thickness: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Pembayaran',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_fmt(_total),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: toscaDark)),
            if (isIntl)
              Text(CurrencyService.formatFromIdr(_total, 'IDR'),
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ]),
      ]),
    );
  }

  // ── HELPER WIDGETS ───────────────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(t, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
  );

  Widget _subLabel(String t) => Text(t,
      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600));

  Widget _infoCard({required IconData icon, required String title, required String subtitle, String? footer}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: toscaMedium, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: toscaDark)),
          const SizedBox(height: 3),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(footer, style: GoogleFonts.outfit(fontSize: 12, color: toscaMedium, fontStyle: FontStyle.italic)),
          ],
        ])),
      ]),
    );
  }

  Widget _methodTile({required String id, required String label, required IconData icon}) {
    final isSel = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMethod   = id;
        _selectedCurrency = 'IDR'; // reset ke IDR saat pilih metode lokal
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSel ? toscaLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? toscaMedium : Colors.grey.shade200, width: isSel ? 2 : 1),
          boxShadow: isSel ? [BoxShadow(color: toscaMedium.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(children: [
          Icon(icon, color: isSel ? toscaDark : Colors.grey.shade400, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: GoogleFonts.outfit(fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? toscaDark : Colors.black87, fontSize: 14))),
          Icon(isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSel ? toscaMedium : Colors.grey.shade300, size: 20),
        ]),
      ),
    );
  }

  Widget _priceRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700)),
      Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    ],
  );
}
