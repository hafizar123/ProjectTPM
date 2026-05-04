import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../order/waiting_payment_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);
  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);
  final AuthService _svc  = AuthService();

  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filter = 'semua'; // semua | menunggu_pembayaran | menunggu_konfirmasi | pengerjaan | selesai

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';
    if (email.isEmpty) { setState(() => _isLoading = false); return; }
    final res = await _svc.getOrders(email);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['statusCode'] == 200) {
          _orders = res['body']['data'] ?? [];
        }
      });
    }
  }

  List<dynamic> get _filtered => _filter == 'semua'
      ? _orders
      : _orders.where((o) => o['status'] == _filter).toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'menunggu_pembayaran': return Colors.red.shade500;
      case 'menunggu_konfirmasi': return Colors.orange.shade600;
      case 'pengerjaan':          return Colors.blue.shade600;
      case 'selesai':             return const Color(0xFF025955);
      default:                    return Colors.grey.shade500;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'menunggu_pembayaran': return 'Menunggu Bayar';
      case 'menunggu_konfirmasi': return 'Menunggu Konfirmasi';
      case 'pengerjaan':          return 'Dikerjakan';
      case 'selesai':             return 'Selesai';
      default:                    return 'Diproses';
    }
  }

  IconData _serviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('ac'))      return Icons.ac_unit_rounded;
    if (n.contains('sofa'))    return Icons.chair_rounded;
    if (n.contains('pemanas') || n.contains('air')) return Icons.water_drop_rounded;
    if (n.contains('deep'))    return Icons.home_rounded;
    if (n.contains('pijat'))   return Icons.spa_rounded;
    if (n.contains('kendaraan') || n.contains('cuci')) return Icons.local_car_wash_rounded;
    return Icons.cleaning_services_rounded;
  }

  String _formatCurrency(dynamic amount) {
    final int val = int.tryParse(amount.toString()) ?? 0;
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: toscaDark,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [toscaDark, const Color(0xFF0F2027)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(right: -30, top: -30,
                    child: Icon(Icons.receipt_long_rounded, size: 200, color: Colors.white.withOpacity(0.04))),
                  SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 55, 25, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Riwayat Transaksi',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            Text('${_orders.length} total transaksi',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                          ]),
                        ]),
                      ],
                    ),
                  )),
                ]),
              ),
            ),
          ),

          // ── FILTER CHIPS ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _chip('semua', 'Semua'),
                  _chip('menunggu_pembayaran', 'Menunggu Bayar'),
                  _chip('menunggu_konfirmasi', 'Konfirmasi'),
                  _chip('pengerjaan', 'Dikerjakan'),
                  _chip('selesai', 'Selesai'),
                ]),
              ),
            ),
          ),

          // ── LIST ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: toscaMedium)),
                  )
                : _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 80, left: 40, right: 40),
                        child: Column(children: [
                          Icon(Icons.inbox_rounded, size: 72, color: toscaMedium.withOpacity(0.25)),
                          const SizedBox(height: 16),
                          Text('Tidak ada transaksi',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
                          const SizedBox(height: 6),
                          Text('Belum ada transaksi dengan status ini.',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500),
                              textAlign: TextAlign.center),
                        ]),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          children: _filtered.map((data) => _buildCard(data)).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final isSel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSel ? LinearGradient(colors: [toscaDark, toscaMedium]) : null,
          color: isSel ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildCard(dynamic data) {
    final status = data['status'] as String? ?? '';
    final color  = _statusColor(status);

    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingPaymentPage(
              orderId: data['id'],
              totalAmount: data['total_amount'],
              paymentMethod: data['payment_method'],
              serviceName: data['service_name'],
              vaNumber: data['va_number'],
              qrisUrl: data['qris_url'],
              initialStatus: status,
              address: data['address'],
              transactionTime: data['waktu_transaksi'],
              houseType: data['house_type'],
              patokan: data['patokan'],
            ),
          ),
        );
        if (shouldRefresh == true || shouldRefresh == null) _fetch();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ikon layanan
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(_serviceIcon(data['service_name'] ?? ''), color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Nama layanan + badge status
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(data['service_name'] ?? '',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: toscaDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 5),
                    Text(_statusLabel(status),
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ]),
                ),
              ]),
              const SizedBox(height: 6),
              // Jadwal
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Text('${data['schedule_date'] ?? ''} • ${data['schedule_time'] ?? ''}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 8),
              // Total + metode bayar
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_formatCurrency(data['total_amount']),
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: toscaDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text((data['payment_method'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}
