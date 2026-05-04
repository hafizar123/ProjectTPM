import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_page.dart';
import '../support/live_chat_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService();
  List<dynamic> _allOrders = [];
  int _totalRevenue = 0;
  int _totalCompletedOrders = 0;
  bool _isLoading = true;
  String _revenueCurrency = 'IDR';
  String _filterStatus = 'semua';

  @override
  void initState() { super.initState(); _fetchDashboardData(); }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final ordersRes  = await _authService.getAllOrdersAdmin();
    final revenueRes = await _authService.getAdminRevenue();
    if (mounted) {
      setState(() {
        if (ordersRes['statusCode'] == 200)  _allOrders = ordersRes['body']['data'] ?? [];
        if (revenueRes['statusCode'] == 200) {
          _totalRevenue          = int.parse(revenueRes['body']['total_revenue'].toString());
          _totalCompletedOrders  = int.parse(revenueRes['body']['total_orders'].toString());
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int orderId, String currentStatus) async {
    String nextStatus = '';
    if (currentStatus == 'menunggu_konfirmasi') nextStatus = 'pengerjaan';
    else if (currentStatus == 'pengerjaan')     nextStatus = 'selesai';
    else return;

    final response = await _authService.updateOrderStatus(orderId, nextStatus);
    if (response['statusCode'] == 200) {
      _showNotif('Status berhasil diperbarui');
      final order = _allOrders.firstWhere((o) => o['id'] == orderId, orElse: () => null);
      if (order != null) {
        final svc = order['service_name'] as String? ?? 'Layanan';
        if (nextStatus == 'pengerjaan') await NotificationService().showOrderConfirmed(svc);
        else if (nextStatus == 'selesai') await NotificationService().showOrderDone(svc);
      }
      _fetchDashboardData();
    } else {
      _showNotif('Gagal memperbarui status');
    }
  }

  String _formatCurrency(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _showNotif(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: toscaMedium, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));

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

  List<dynamic> get _filteredOrders => _filterStatus == 'semua'
      ? _allOrders
      : _allOrders.where((o) => o['status'] == _filterStatus).toList();

  // ── Hitung stat per status ───────────────────────────────────
  int _countStatus(String s) => _allOrders.where((o) => o['status'] == s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: toscaLight))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                _buildStatCards(),
                _buildFilterBar(),
                _buildOrderList(),
              ],
            ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final revenueDisplay = CurrencyService.formatFromIdr(_totalRevenue, _revenueCurrency);
    final isIntl = _revenueCurrency != 'IDR';

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0A1628),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF025955), Color(0xFF0F2027)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            // Dekorasi
            Positioned(right: -60, top: -60,
              child: Container(width: 220, height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF48C9B0).withOpacity(0.06)))),
            Positioned(left: -40, bottom: -40,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF00909E).withOpacity(0.08)))),

            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Dashboard Admin',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                      Text('Bersih.In',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ]),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 24),
                    ),
                    // Tombol Chat Admin
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminChatPage())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: toscaLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: toscaLight.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    // Tombol Logout Admin
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        // Admin logout: hapus sesi saja, pertahankan data order
                        final keysToRemove = [
                          'saved_email', 'saved_username', 'saved_password',
                          'profile_image', 'profile_base64',
                          'order_address', 'order_house_type', 'order_patokan', 'zona_waktu',
                        ];
                        for (final key in keysToRemove) { await prefs.remove(key); }
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                      ),
                    ),
                  ]),

                  const Spacer(),

                  // Revenue section
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Total Pendapatan',
                          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(revenueDisplay,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 32,
                                fontWeight: FontWeight.w900, letterSpacing: -1)),
                      ),
                      if (isIntl) ...[
                        const SizedBox(height: 2),
                        Text('≈ ${_formatCurrency(_totalRevenue)} IDR',
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                      ],
                    ]),

                    // Dropdown mata uang
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _revenueCurrency,
                          dropdownColor: const Color(0xFF025955),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          items: CurrencyService.allCurrencies.map((code) {
                            final flag = code == 'IDR' ? '🇮🇩' : code == 'CNY' ? '🇨🇳'
                                : code == 'SGD' ? '🇸🇬' : '🇸🇦';
                            return DropdownMenuItem(value: code, child: Text('$flag $code'));
                          }).toList(),
                          onChanged: (v) { if (v != null) setState(() => _revenueCurrency = v); },
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Badge pesanan selesai
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: toscaLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: toscaLight.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded, color: toscaLight, size: 14),
                        const SizedBox(width: 6),
                        Text('$_totalCompletedOrders Pesanan Selesai',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_allOrders.length} Total Pesanan',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    ),
                  ]),
                ],
              ),
            )),
          ]),
        ),
      ),
    );
  }

  // ── STAT CARDS ───────────────────────────────────────────────
  Widget _buildStatCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(children: [
          _statCard('Menunggu\nBayar', _countStatus('menunggu_pembayaran'), Colors.red.shade400, Icons.payment_rounded),
          const SizedBox(width: 10),
          _statCard('Konfirmasi', _countStatus('menunggu_konfirmasi'), Colors.orange.shade500, Icons.pending_actions_rounded),
          const SizedBox(width: 10),
          _statCard('Dikerjakan', _countStatus('pengerjaan'), Colors.blue.shade500, Icons.engineering_rounded),
          const SizedBox(width: 10),
          _statCard('Selesai', _countStatus('selesai'), toscaMedium, Icons.task_alt_rounded),
        ]),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text('$count',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9, height: 1.3)),
        ]),
      ),
    );
  }

  // ── FILTER BAR ───────────────────────────────────────────────
  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Manajemen Pesanan',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: [
              _filterChip('semua', 'Semua'),
              _filterChip('menunggu_pembayaran', 'Menunggu Bayar'),
              _filterChip('menunggu_konfirmasi', 'Konfirmasi'),
              _filterChip('pengerjaan', 'Dikerjakan'),
              _filterChip('selesai', 'Selesai'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSel = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSel ? LinearGradient(colors: [toscaDark, toscaMedium]) : null,
          color: isSel ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? Colors.transparent : Colors.white.withOpacity(0.15)),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : Colors.white60)),
      ),
    );
  }

  // ── ORDER LIST ───────────────────────────────────────────────
  /// Tampilkan total tagihan dalam mata uang yang dipilih user saat order.
  /// Jika ada data currency & total_converted dari DB → pakai itu.
  /// Fallback ke IDR jika tidak ada.
  Widget _buildOrderTotal(dynamic order) {
    final totalIdr   = order['total_amount'] ?? 0;
    final currency   = (order['currency'] as String?)?.toUpperCase() ?? 'IDR';
    final converted  = order['total_converted'];

    // Jika mata uang asing dan ada nilai konversi
    if (currency != 'IDR' && converted != null) {
      final convertedVal = double.tryParse(converted.toString()) ?? 0.0;
      return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(CurrencyService.format(convertedVal, currency),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: toscaLight)),
        Text('≈ ${_formatCurrency(totalIdr)}',
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
      ]);
    }

    // IDR biasa
    return Text(_formatCurrency(totalIdr),
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: toscaLight));
  }

  Widget _buildOrderList() {
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(child: Column(children: [
            Icon(Icons.inbox_rounded, size: 60, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),
            Text('Tidak ada pesanan', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15)),
          ])),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _buildOrderCard(orders[i]),
          childCount: orders.length,
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final status     = order['status'] as String? ?? '';
    final color      = _statusColor(status);
    final label      = _statusLabel(status);
    String btnText   = '';
    if (status == 'menunggu_konfirmasi') btnText = 'KONFIRMASI BAYAR';
    else if (status == 'pengerjaan')     btnText = 'SELESAIKAN PESANAN';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: email + badge status
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.15),
                  child: Text((order['user_email'] ?? '?')[0].toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order['user_email'] ?? '',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 5),
                Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ]),
            ),
          ]),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // Nama layanan
          Text(order['service_name'] ?? '',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white38),
            const SizedBox(width: 5),
            Text('${order['schedule_date'] ?? ''} • ${order['schedule_time'] ?? ''}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
          ]),

          const SizedBox(height: 14),

          // Metode bayar + total
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Metode Bayar', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
              Text((order['payment_method'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Total Tagihan', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
              // Tampilkan dalam mata uang yang dipilih user saat order
              _buildOrderTotal(order),
            ]),
          ]),

          // Tombol aksi
          if (btnText.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton(
                onPressed: () => _updateStatus(order['id'], status),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(btnText,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white,
                            fontSize: 13, letterSpacing: 0.8)),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
