import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../order/waiting_payment_page.dart';
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

  // Menyimpan state controller chat per orderId
  final Map<int, TextEditingController> _chatControllers = {};
  final Map<int, bool> _chatSending = {};
  final Map<int, List<dynamic>> _chatMessages = {};
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _loadEmail();
  }

  @override
  void dispose() {
    for (final ctrl in _chatControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userEmail = prefs.getString('saved_email') ?? '';
      });
    }
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

      if (mounted) {
        setState(() {
          // Ongoing: belum selesai dan belum cancelled
          _ongoingOrders = allOrders
              .where((o) => o['status'] != 'selesai' && o['status'] != 'cancelled')
              .toList();
          // History: selesai atau cancelled
          _historyOrders = allOrders
              .where((o) => o['status'] == 'selesai' || o['status'] == 'cancelled')
              .toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Warna unik per status
  Color _statusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return Colors.red.shade500;
      case 'menunggu_konfirmasi':
        return Colors.orange.shade600;
      case 'pengerjaan':
        return Colors.blue.shade600;
      case 'selesai':
        return const Color(0xFF025955);
      case 'cancelled':
        return Colors.grey.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  // Helper memperbaiki format teks status dari DB agar enak dibaca
  String _formatStatusText(String rawStatus) {
    switch (rawStatus) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi';
      case 'pengerjaan':
        return 'Sedang Dikerjakan';
      case 'selesai':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Diproses';
    }
  }

  // Helper memberikan icon otomatis berdasarin nama layanan
  IconData _getIconForService(String serviceName) {
    String lowerName = serviceName.toLowerCase();
    if (lowerName.contains('ac')) return Icons.ac_unit_rounded;
    if (lowerName.contains('sofa')) return Icons.chair_rounded;
    if (lowerName.contains('air') || lowerName.contains('pemanas')) {
      return Icons.water_drop_rounded;
    }
    if (lowerName.contains('deep') || lowerName.contains('rumah')) {
      return Icons.home_rounded;
    }
    return Icons.cleaning_services_rounded; // Default saja
  }

  bool _isChatableStatus(String status) {
    return status == 'menunggu_konfirmasi' ||
        status == 'pengerjaan' ||
        status == 'selesai';
  }

  TextEditingController _getController(int orderId) {
    return _chatControllers.putIfAbsent(orderId, () => TextEditingController());
  }

  Future<void> _sendChat(int orderId, String status) async {
    // Pastikan email sudah ter-load
    if (_userEmail.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _userEmail = prefs.getString('saved_email') ?? '';
    }

    final ctrl = _getController(orderId);
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    if (_chatSending[orderId] == true) return;
    if (_userEmail.isEmpty) return; // Tidak bisa kirim tanpa email

    setState(() => _chatSending[orderId] = true);
    ctrl.clear();

    final res = await _authService.sendEmployeeChat(orderId, 'user', _userEmail, text);

    // Refresh chat setelah kirim
    if (res['statusCode'] == 201) {
      await _refreshChat(orderId);
    }

    if (mounted) {
      setState(() => _chatSending[orderId] = false);
    }
  }

  Future<void> _refreshChat(int orderId) async {
    final res = await _authService.getEmployeeChat(orderId);
    if (mounted && res['statusCode'] == 200) {
      setState(() {
        _chatMessages[orderId] = res['body']['data'] ?? [];
      });
    }
  }

  Future<void> _loadChatIfNeeded(int orderId) async {
    if (_chatMessages.containsKey(orderId)) return;
    await _refreshChat(orderId);
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
                labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelColor: Colors.grey.shade400,
                unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500, fontSize: 16),
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

    List<dynamic> targetData = isOngoing ? _ongoingOrders : _historyOrders;

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
      padding:
          const EdgeInsets.only(top: 25, bottom: 120, left: 20, right: 20),
      itemCount: targetData.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        var data = targetData[index];
        final int orderId =
            int.tryParse(data['id']?.toString() ?? '0') ?? 0;
        final String status = data['status'] as String? ?? '';
        final bool hasEmployee = data['employee_id'] != null;
        final bool showChat = hasEmployee && _isChatableStatus(status);
        final bool chatReadOnly = status == 'selesai';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
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
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft:
                        Radius.circular(showChat ? 0 : 24),
                    bottomRight:
                        Radius.circular(showChat ? 0 : 24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: toscaDark.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(
                      color: toscaLight.withOpacity(0.15), width: 1.5),
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
                            colors: [
                              toscaMedium.withOpacity(0.2),
                              toscaLight.withOpacity(0.1)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: toscaLight.withOpacity(0.3)),
                        ),
                        child: Icon(
                            _getIconForService(data['service_name']),
                            color: toscaDark,
                            size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.grey.shade500),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    "${data['schedule_date']}   ${data['schedule_time']}",
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _statusColor(status)
                                      .withOpacity(0.35),
                                ),
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
                            // Info karyawan
                            if (hasEmployee) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
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
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section chat karyawan
            if (showChat)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FFFE),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border.all(
                      color: toscaLight.withOpacity(0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: toscaDark.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 15, color: toscaMedium),
                          const SizedBox(width: 6),
                          Text(
                            'Chat Karyawan',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: toscaDark,
                            ),
                          ),
                          if (chatReadOnly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Read-only',
                                style: GoogleFonts.outfit(
                                    color: Colors.grey.shade500,
                                    fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE0F5F3)),
                    // Chat messages — pakai state lokal agar auto-refresh setelah kirim
                    Builder(builder: (context) {
                      // Load chat pertama kali jika belum ada
                      if (!_chatMessages.containsKey(orderId)) {
                        _loadChatIfNeeded(orderId);
                      }
                      final chats = _chatMessages[orderId] ?? [];
                      final displayChats = chats.length > 5
                          ? chats.sublist(chats.length - 5)
                          : chats;

                      if (displayChats.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            'Belum ada pesan dari karyawan.',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        itemCount: displayChats.length,
                        itemBuilder: (_, i) =>
                            _buildChatBubble(displayChats[i]),
                      );
                    }),

                    // Input chat (sembunyikan jika read-only)
                    if (!chatReadOnly)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: toscaLight.withOpacity(0.4)),
                                ),
                                child: TextField(
                                  controller: _getController(orderId),
                                  style: GoogleFonts.outfit(
                                      fontSize: 13, color: Colors.black87),
                                  maxLines: null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'Balas karyawan...',
                                    hintStyle: GoogleFonts.outfit(
                                        color: Colors.grey.shade400,
                                        fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _chatSending[orderId] == true
                                  ? null
                                  : () => _sendChat(orderId, status),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _chatSending[orderId] == true
                                      ? Colors.grey.shade300
                                      : toscaMedium,
                                ),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildChatBubble(dynamic chat) {
    final isEmployee =
        (chat['sender_role'] as String? ?? '') == 'employee';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isEmployee ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isEmployee) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: toscaMedium.withOpacity(0.15),
              child: Icon(Icons.engineering_rounded,
                  color: toscaMedium, size: 14),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65),
              decoration: BoxDecoration(
                color: isEmployee
                    ? toscaLight.withOpacity(0.15)
                    : toscaDark.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isEmployee ? 4 : 14),
                  bottomRight: Radius.circular(isEmployee ? 14 : 4),
                ),
                border: Border.all(
                    color: toscaLight.withOpacity(0.3), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['message'] ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 12,
                        height: 1.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEmployee ? 'Karyawan' : 'Anda',
                    style: GoogleFonts.outfit(
                        color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (!isEmployee) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
