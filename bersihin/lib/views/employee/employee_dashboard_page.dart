import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'employee_order_detail_page.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  static const Color _bg      = Color(0xFF060E1A);
  static const Color _surface = Color(0xFF0D1B2A);
  static const Color _card    = Color(0xFF112233);
  static const Color _accent  = Color(0xFF00D4AA);
  static const Color _accentDim = Color(0xFF025955);

  final AuthService _svc = AuthService();

  List<dynamic> _orders = [];
  bool _isLoading = true;
  int _employeeId = 0;
  String _employeeName = '';
  String _employeeEmail = '';

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _employeeId   = prefs.getInt('employee_id') ?? 0;
    _employeeName  = prefs.getString('employee_name') ?? 'Karyawan';
    _employeeEmail = prefs.getString('employee_email') ?? '';
    await _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    if (_employeeId == 0) {
      setState(() => _isLoading = false);
      return;
    }
    final res = await _svc.getEmployeeOrders(_employeeId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['statusCode'] == 200) {
          _orders = res['body']['data'] ?? [];
        }
      });
    }
  }

  // Stat helpers
  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get _todayOrders => _orders
      .where((o) => (o['schedule_date'] ?? '').toString().startsWith(_todayStr()))
      .length;

  int get _activeOrders => _orders
      .where((o) => ['menunggu_konfirmasi', 'pengerjaan'].contains(o['status']))
      .length;

  int get _doneOrders =>
      _orders.where((o) => o['status'] == 'selesai').length;

  // Status helpers
  Color _statusColor(String s) {
    switch (s) {
      case 'menunggu_konfirmasi': return Colors.orange.shade400;
      case 'pengerjaan':          return Colors.blue.shade400;
      case 'selesai':             return _accent;
      case 'cancelled':           return Colors.red.shade400;
      default:                    return Colors.grey.shade500;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'menunggu_konfirmasi': return 'Menunggu';
      case 'pengerjaan':          return 'Dikerjakan';
      case 'selesai':             return 'Selesai';
      case 'cancelled':           return 'Dibatalkan';
      default:                    return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _surface,
        onRefresh: _fetchOrders,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildStatsRow(),
            _buildSectionTitle(),
            _buildOrderList(),
          ],
        ),
      ),
    );
  }

  // APP BAR
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: _surface,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF025955), Color(0xFF060E1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            Positioned(right: -50, top: -50,
              child: Container(width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.06),
                ))),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    // Badge karyawan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Karyawan',
                          style: GoogleFonts.outfit(
                            color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    // Tombol logout
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      ),
                    ),
                  ]),
                  const Spacer(),
                  Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [_accentDim, _accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Selamat datang,',
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
                      Text(_employeeName,
                        style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Text(_employeeEmail,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )),
          ]),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _accent.withOpacity(0.4), Colors.transparent],
            ),
          )),
      ),
    );
  }

  // STATS ROW
  Widget _buildStatsRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(children: [
          _statCard('Order\nHari Ini', _todayOrders, Icons.today_rounded, Colors.blue.shade400),
          const SizedBox(width: 10),
          _statCard('Order\nAktif', _activeOrders, Icons.pending_actions_rounded, Colors.orange.shade400),
          const SizedBox(width: 10),
          _statCard('Order\nSelesai', _doneOrders, Icons.task_alt_rounded, _accent),
        ]),
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text('$count',
            style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, height: 1.3)),
        ]),
      ),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Daftar Orderan',
            style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${_orders.length} total',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }

  // ORDER LIST
  Widget _buildOrderList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator(color: _accent)),
        ),
      );
    }

    if (_orders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(child: Column(children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 12),
            Text('Belum ada orderan',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15)),
          ])),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _buildOrderCard(_orders[i]),
          childCount: _orders.length,
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final status = order['status'] as String? ?? '';
    final color  = _statusColor(status);
    final label  = _statusLabel(status);
    final addr   = order['address'] as String? ?? '';
    final shortAddr = addr.length > 40 ? '${addr.substring(0, 40)}...' : addr;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => EmployeeOrderDetailPage(
            order: order,
            employeeId: _employeeId,
          ),
        ));
        _fetchOrders();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header: nama layanan + badge status
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Text(order['service_name'] ?? '',
                  style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
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
                  Text(label,
                    style: GoogleFonts.outfit(
                      fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            // User email
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 13, color: Colors.white38),
              const SizedBox(width: 5),
              Expanded(
                child: Text(order['user_email'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 5),
            // Alamat singkat
            Row(children: [
              Icon(Icons.location_on_outlined, size: 13, color: Colors.white38),
              const SizedBox(width: 5),
              Expanded(
                child: Text(shortAddr,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 5),
            // Jadwal
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white38),
              const SizedBox(width: 5),
              Text('${order['schedule_date'] ?? ''} • ${order['schedule_time'] ?? ''}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('employee_id');
    await prefs.remove('employee_name');
    await prefs.remove('employee_email');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
