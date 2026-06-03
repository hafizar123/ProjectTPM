import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../order/waiting_payment_page.dart';
import '../support/user_order_chat_page.dart';
import '../../widgets/custom_navbar.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);
  final AuthService _authService = AuthService();

  List<dynamic> _ongoingOrders = [];
  List<dynamic> _historyOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('saved_email');

    if (email == null) {
      setState(() => _isLoading = false);
      return;
    }

    final response = await _authService.getOrders(email);
    if (response['statusCode'] == 200) {
      final List<dynamic> allOrders = response['body']['data'];
      if (mounted) {
        setState(() {
          _ongoingOrders = allOrders
              .where((o) => o['status'] != 'selesai' && o['status'] != 'cancelled')
              .toList();
          _historyOrders = allOrders
              .where((o) => o['status'] == 'selesai' || o['status'] == 'cancelled')
              .toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran':  return Colors.red.shade500;
      case 'menunggu_konfirmasi':  return Colors.orange.shade600;
      case 'pengerjaan':           return Colors.blue.shade600;
      case 'selesai':              return const Color(0xFF025955);
      case 'cancelled':            return Colors.grey.shade500;
      default:                     return Colors.grey.shade500;
    }
  }

  String _formatStatusText(String rawStatus) {
    switch (rawStatus) {
      case 'menunggu_pembayaran':  return 'Menunggu Pembayaran';
      case 'menunggu_konfirmasi':  return 'Menunggu Konfirmasi';
      case 'pengerjaan':           return 'Sedang Dikerjakan';
      case 'selesai':              return 'Selesai';
      case 'cancelled':            return 'Dibatalkan';
      default:                     return 'Diproses';
    }
  }

  IconData _getIconForService(String serviceName) {
    final lowerName = serviceName.toLowerCase();
    if (lowerName.contains('ac')) return Icons.ac_unit_rounded;
    if (lowerName.contains('sofa')) return Icons.chair_rounded;
    if (lowerName.contains('air') || lowerName.contains('pemanas')) {
      return Icons.water_drop_rounded;
    }
    if (lowerName.contains('deep') || lowerName.contains('rumah')) {
      return Icons.home_rounded;
    }
    return Icons.cleaning_services_rounded;
  }

  bool _isChatableStatus(String status) {
    return status == 'menunggu_konfirmasi' ||
        status == 'pengerjaan' ||
        status == 'selesai';
  }

  void _openChat(BuildContext context, Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserOrderChatPage(
          orderId: int.tryParse(order['id']?.toString() ?? '0') ?? 0,
          serviceName: order['service_name'] as String? ?? '',
          employeeName: order['employee_name'] as String? ?? 'Karyawan',
          status: order['status'] as String? ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: toscaDark,
          elevation: 0,
          toolbarHeight: 70,
          titleSpacing: 25,
          title: Text(
            'Aktivitas',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55.0),
            child: Container(
              color: Colors.white,
              child: TabBar(
                indicatorColor: toscaMedium,
                indicatorWeight: 4,
                labelColor: toscaDark,
                labelStyle:
                    GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelColor: Colors.grey.shade400,
                unselectedLabelStyle:
                    GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 16),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Sedang Berjalan'),
                  Tab(text: 'Riwayat Selesai'),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, toscaLight.withOpacity(0.04)],
            ),
          ),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildActivityList(isOngoing: true),
              _buildActivityList(isOngoing: false),
            ],
          ),
        ),
        floatingActionButton: const CustomFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
      ),
    );
  }

  Widget _buildActivityList({required bool isOngoing}) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: toscaMedium));
    }

    final List<dynamic> targetData =
        isOngoing ? _ongoingOrders : _historyOrders;

    if (targetData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 80, color: toscaMedium.withOpacity(0.3)),
            const SizedBox(height: 15),
            Text('Belum ada aktivitas',
                style: GoogleFonts.outfit(
                    color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 25, bottom: 120, left: 20, right: 20),
      itemCount: targetData.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final data = targetData[index];
        final String status = data['status'] as String? ?? '';
        final bool hasEmployee = data['employee_id'] != null;
        final bool showChat = hasEmployee && _isChatableStatus(status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaitingPaymentPage(
                    orderId: data['id'],
                    totalAmount: data['total_amount'],
                    paymentMethod: data['payment_method'],
                    serviceName: data['service_name'],
                    vaNumber: data['va_number'],
                    qrisUrl: data['qris_url'],
                    initialStatus: data['status'],
                    address: data['address'],
                    transactionTime: data['waktu_transaksi'],
                    houseType: data['house_type'],
                    patokan: data['patokan'],
                  ),
                ),
              );
              if (shouldRefresh == true || shouldRefresh == null) {
                _fetchOrders();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: toscaDark.withOpacity(0.06),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
                border:
                    Border.all(color: toscaLight.withOpacity(0.15), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon layanan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            toscaMedium.withOpacity(0.2),
                            toscaLight.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: toscaLight.withOpacity(0.3)),
                      ),
                      child: Icon(
                          _getIconForService(data['service_name']),
                          color: toscaDark,
                          size: 32),
                    ),
                    const SizedBox(width: 20),

                    // Info order
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama layanan
                          Text(
                            data['service_name'],
                            style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: toscaDark,
                                letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Jadwal
                          Row(children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${data['schedule_date']}   ${data['schedule_time']}',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),

                          // Status badge + tombol Chat sejajar
                          Row(children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        _statusColor(status).withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatStatusText(status),
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(status),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tombol Chat — hanya muncul jika ada karyawan & status bisa chat
                            if (showChat) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _openChat(
                                    context, Map<String, dynamic>.from(data)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: toscaMedium.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: toscaMedium.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_rounded,
                                          size: 13, color: toscaMedium),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Chat',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: toscaMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ]),

                          // Info karyawan
                          if (hasEmployee) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              Icon(Icons.engineering_rounded,
                                  size: 15, color: toscaMedium),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ditangani oleh: ${data['employee_name'] ?? 'Karyawan'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: toscaDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
