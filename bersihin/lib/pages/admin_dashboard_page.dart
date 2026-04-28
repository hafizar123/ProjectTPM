import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService();
  
  List<dynamic> _allOrders = [];
  int _totalRevenue = 0;
  int _totalCompletedOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    // ZHANGG! Tarik data pesanan sama cuan barengan pak!
    final ordersRes = await _authService.getAllOrdersAdmin();
    final revenueRes = await _authService.getAdminRevenue();

    if (mounted) {
      setState(() {
        if (ordersRes['statusCode'] == 200) {
          _allOrders = ordersRes['body']['data'] ?? [];
        }
        if (revenueRes['statusCode'] == 200) {
          _totalRevenue = int.parse(revenueRes['body']['total_revenue'].toString());
          _totalCompletedOrders = int.parse(revenueRes['body']['total_orders'].toString());
        }
        _isLoading = false;
      });
    }
  }

  // FUNGSI SAKTI BUAT UPDATE STATUS PESANAN
  Future<void> _updateStatus(int orderId, String currentStatus) async {
    String nextStatus = '';
    if (currentStatus == 'menunggu_konfirmasi') nextStatus = 'pengerjaan';
    else if (currentStatus == 'pengerjaan') nextStatus = 'selesai';
    else return;

    final response = await _authService.updateOrderStatus(orderId, nextStatus);
    
    if (response['statusCode'] == 200) {
      _showNotif('Status berhasil diupdate jadi ${nextStatus.toUpperCase()}!');
      _fetchDashboardData(); // Refresh data biar UI update
    } else {
      _showNotif('Gagal update status pak!');
    }
  }

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit()), backgroundColor: toscaMedium)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: toscaMedium))
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manajemen Pesanan', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
                      const SizedBox(height: 15),
                      _allOrders.isEmpty 
                        ? Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text('Belum ada pesanan masuk nih bos.', style: GoogleFonts.outfit(color: Colors.grey))))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _allOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(_allOrders[index]);
                            },
                          ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260.0,
      pinned: true,
      elevation: 0,
      backgroundColor: toscaDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [toscaDark, toscaMedium]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dashboard Admin', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                      Icon(Icons.admin_panel_settings_rounded, color: Colors.white.withOpacity(0.5), size: 40),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Total Pendapatan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                  Text(_formatCurrency(_totalRevenue), style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('$_totalCompletedOrders Pesanan Selesai', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    String status = order['status'];
    Color statusColor = Colors.grey;
    String btnText = '';
    
    // ZHANGG! Logika tombol dinamis pak!
    if (status == 'menunggu_pembayaran') {
      statusColor = Colors.red.shade400;
    } else if (status == 'menunggu_konfirmasi') {
      statusColor = Colors.orange.shade500;
      btnText = 'KONFIRMASI BAYAR';
    } else if (status == 'pengerjaan') {
      statusColor = Colors.blue.shade500;
      btnText = 'SELESAIKAN PESANAN';
    } else if (status == 'selesai') {
      statusColor = toscaDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: toscaDark.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['user_email'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          Text(order['service_name'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: toscaDark)),
          const SizedBox(height: 5),
          Text("${order['schedule_date']} • ${order['schedule_time']}", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metode Bayar', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
                  Text(order['payment_method'].toString().toUpperCase(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Tagihan', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
                  Text(_formatCurrency(order['total_amount']), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: toscaDark)),
                ],
              ),
            ],
          ),
          
          // Tombol Aksi Admin
          if (btnText.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => _updateStatus(order['id'], status),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(btnText, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, letterSpacing: 1)),
              ),
            )
          ]
        ],
      ),
    );
  }
}