import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'waiting_payment_page.dart';

// ZHANGG! Pastiin file custom_navbar lu ke-import ye pak
import 'custom_navbar.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final AuthService _authService = AuthService();
  
  // ZHANGG! Wadah penampung data asli dari DB pak
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
    String? email = prefs.getString('saved_email');

    if (email == null) {
      setState(() => _isLoading = false);
      return;
    }

    final response = await _authService.getOrders(email);

    if (response['statusCode'] == 200) {
      List<dynamic> allOrders = response['body']['data'];
      
      setState(() {
        // Yang belom kelar masuk kubu Ongoing
        _ongoingOrders = allOrders.where((order) => order['status'] != 'selesai').toList();
        // Yang udeh beres masuk kubu History
        _historyOrders = allOrders.where((order) => order['status'] == 'selesai').toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Helper benerin format teks status dari DB biar enak dibaca Mon
  String _formatStatusText(String rawStatus) {
    switch (rawStatus) {
      case 'menunggu_pembayaran': return 'Menunggu Pembayaran';
      case 'menunggu_konfirmasi': return 'Menunggu Konfirmasi';
      case 'pengerjaan': return 'Sedang Dikerjakan';
      case 'selesai': return 'Selesai';
      default: return 'Diproses';
    }
  }

  // Helper ngasih icon otomatis berdasarin nama layanan pak
  IconData _getIconForService(String serviceName) {
    String lowerName = serviceName.toLowerCase();
    if (lowerName.contains('ac')) return Icons.ac_unit_rounded;
    if (lowerName.contains('sofa')) return Icons.chair_rounded;
    if (lowerName.contains('air') || lowerName.contains('pemanas')) return Icons.water_drop_rounded;
    if (lowerName.contains('deep') || lowerName.contains('rumah')) return Icons.home_rounded;
    return Icons.cleaning_services_rounded; // Default aje Mon
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
              letterSpacing: -0.5
            )
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
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelColor: Colors.grey.shade400,
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 16),
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
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1)
      ),
    );
  }

  Widget _buildActivityList({required bool isOngoing}) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: toscaMedium));
    }

    // ZHANGG! Pake data asli dari DB pak!
    List<dynamic> targetData = isOngoing ? _ongoingOrders : _historyOrders;

    if (targetData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: toscaMedium.withOpacity(0.3)),
            const SizedBox(height: 15),
            Text('Belum ada aktivitas nih, Mon!', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 25, bottom: 120, left: 20, right: 20),
      itemCount: targetData.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        var data = targetData[index];
        
        // ZHANGG! Mulai nambahin InkWell di sini pak biar bisa diklik!
        return InkWell(
          onTap: () async {
          // ZHANGG! Tungguin user balik dari halaman detail pak
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
              ),
            ),
          );

          // Kalo user balik bawa sinyal 'true' ato emang balik biasa, kita tarik data baru dari DB
          if (shouldRefresh == true || shouldRefresh == null) {
            _fetchOrders(); 
          }
        },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), 
              boxShadow: [
                BoxShadow(
                  color: toscaDark.withOpacity(0.06), 
                  blurRadius: 25, 
                  offset: const Offset(0, 10)
                )
              ],
              border: Border.all(color: toscaLight.withOpacity(0.15), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [toscaMedium.withOpacity(0.2), toscaLight.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: toscaLight.withOpacity(0.3)),
                    ),
                    child: Icon(_getIconForService(data['service_name']), color: toscaDark, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['service_name'],
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: toscaDark, letterSpacing: -0.3),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "${data['schedule_date']} • ${data['schedule_time']}",
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOngoing ? Colors.orange.withOpacity(0.1) : toscaLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOngoing ? Colors.orange.withOpacity(0.3) : toscaLight.withOpacity(0.3),
                            )
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOngoing ? Colors.orange.shade600 : toscaDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatStatusText(data['status']),
                                style: GoogleFonts.outfit(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold, 
                                  color: isOngoing ? Colors.orange.shade800 : toscaDark,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ); // Akhir InkWell
      },
    );
  }
}