import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class EmployeeOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final int employeeId;

  const EmployeeOrderDetailPage({
    super.key,
    required this.order,
    required this.employeeId,
  });

  @override
  State<EmployeeOrderDetailPage> createState() => _EmployeeOrderDetailPageState();
}

class _EmployeeOrderDetailPageState extends State<EmployeeOrderDetailPage> {
  static const Color _bg       = Color(0xFF060E1A);
  static const Color _surface  = Color(0xFF0D1B2A);
  static const Color _card     = Color(0xFF112233);
  static const Color _accent   = Color(0xFF00D4AA);
  static const Color _accentDim = Color(0xFF025955);

  final AuthService _svc = AuthService();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late Map<String, dynamic> _order;
  List<dynamic> _chats = [];
  bool _isSending = false;
  bool _isUpdating = false;
  String _employeeName = '';

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _loadEmployee();
    _fetchChats();
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeName = prefs.getString('employee_name') ?? 'Karyawan';
    });
  }

  Future<void> _fetchChats() async {
    final orderId = _order['id'] as int? ?? 0;
    if (orderId == 0) return;
    final res = await _svc.getEmployeeChat(orderId);
    if (mounted && res['statusCode'] == 200) {
      setState(() => _chats = res['body']['data'] ?? []);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final orderId = _order['id'] as int? ?? 0;
    final res = await _svc.updateOrderStatusByEmployee(orderId, newStatus, widget.employeeId);
    setState(() => _isUpdating = false);

    if (res['statusCode'] == 200) {
      setState(() => _order['status'] = newStatus);
      _showSnack('Status diperbarui: $newStatus');
    } else {
      _showSnack('Gagal memperbarui status', isError: true);
    }
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _chatCtrl.clear();

    final orderId = _order['id'] as int? ?? 0;
    final res = await _svc.sendEmployeeChat(
      orderId,
      'employee',
      widget.employeeId.toString(),
      text,
    );

    setState(() => _isSending = false);

    if (res['statusCode'] == 201) {
      await _fetchChats();
    } else {
      _showSnack('Gagal mengirim pesan', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent : _accentDim,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────
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
      case 'menunggu_konfirmasi': return 'Menunggu Konfirmasi';
      case 'pengerjaan':          return 'Sedang Dikerjakan';
      case 'selesai':             return 'Selesai';
      case 'cancelled':           return 'Dibatalkan';
      default:                    return s;
    }
  }

  bool _canStartWork() {
    final status = _order['status'] as String? ?? '';
    if (status != 'menunggu_konfirmasi') return false;

    // Cek apakah waktu sekarang sudah >= jam order
    try {
      final dateStr  = _order['schedule_date'] as String? ?? '';
      final timeStr  = _order['schedule_time'] as String? ?? '';
      if (dateStr.isEmpty || timeStr.isEmpty) return true;

      final parts = timeStr.split(':');
      final hour   = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      final dateParts = dateStr.split('-');
      final year  = int.tryParse(dateParts[0]) ?? 2000;
      final month = int.tryParse(dateParts.length > 1 ? dateParts[1] : '1') ?? 1;
      final day   = int.tryParse(dateParts.length > 2 ? dateParts[2] : '1') ?? 1;

      final schedDt = DateTime(year, month, day, hour, minute);
      return DateTime.now().isAfter(schedDt) || DateTime.now().isAtSameMomentAs(schedDt);
    } catch (_) {
      return true;
    }
  }

  bool get _isOrderDone => (_order['status'] as String? ?? '') == 'selesai';
  bool get _isOrderCancelled => (_order['status'] as String? ?? '') == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] as String? ?? '';
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Order',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _accent.withOpacity(0.4), Colors.transparent],
              ),
            )),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header card ──────────────────────────────────
              _buildHeaderCard(statusColor, status),
              const SizedBox(height: 16),

              // ── Lokasi ───────────────────────────────────────
              _buildSection('Lokasi', Icons.location_on_rounded, [
                _infoRow(Icons.home_outlined, 'Alamat', _order['address'] ?? '-'),
                if ((_order['house_type'] ?? '').toString().isNotEmpty)
                  _infoRow(Icons.house_outlined, 'Tipe Rumah', _order['house_type'] ?? '-'),
                if ((_order['patokan'] ?? '').toString().isNotEmpty)
                  _infoRow(Icons.flag_outlined, 'Patokan', _order['patokan'] ?? '-'),
              ]),
              const SizedBox(height: 16),

              // ── Tombol aksi ──────────────────────────────────
              if (!_isOrderDone && !_isOrderCancelled) ...[
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],

              // ── Chat ─────────────────────────────────────────
              _buildChatSection(),
              const SizedBox(height: 20),
            ]),
          ),
        ),

        // ── Input chat ────────────────────────────────────────
        if (!_isOrderDone && !_isOrderCancelled) _buildChatInput(),
      ]),
    );
  }

  // ── Header card ───────────────────────────────────────────────
  Widget _buildHeaderCard(Color statusColor, String status) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(_order['service_name'] ?? '',
              style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(_statusLabel(status),
              style: GoogleFonts.outfit(
                color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(color: Colors.white12),
        const SizedBox(height: 10),
        _infoRow(Icons.person_outline_rounded, 'Pelanggan', _order['user_email'] ?? '-'),
        const SizedBox(height: 6),
        _infoRow(Icons.calendar_today_rounded, 'Jadwal',
          '${_order['schedule_date'] ?? ''} • ${_order['schedule_time'] ?? ''}'),
      ]),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 8),
          Text(title,
            style: GoogleFonts.outfit(
              color: _accent, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text('$label: ',
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        Expanded(
          child: Text(value,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
            maxLines: 3),
        ),
      ]),
    );
  }

  // ── Tombol aksi ───────────────────────────────────────────────
  Widget _buildActionButtons() {
    final status = _order['status'] as String? ?? '';
    final canStart = _canStartWork();

    return Column(children: [
      // Tombol Mulai Pengerjaan
      if (status == 'menunggu_konfirmasi') ...[
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: (canStart && !_isUpdating) ? () => _updateStatus('pengerjaan') : null,
            icon: _isUpdating
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              canStart ? 'Mulai Pengerjaan' : 'Belum Waktunya',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: canStart ? Colors.blue.shade700 : Colors.grey.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        if (!canStart) ...[
          const SizedBox(height: 6),
          Text(
            'Tombol aktif saat sudah mencapai jam order: ${_order['schedule_time'] ?? ''}',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ],

      // Tombol Selesaikan Order
      if (status == 'pengerjaan') ...[
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _isUpdating ? null : () => _updateStatus('selesai'),
            icon: _isUpdating
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_rounded, size: 20),
            label: Text('Selesaikan Order',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentDim,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    ]);
  }

  // ── Chat section ──────────────────────────────────────────────
  Widget _buildChatSection() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: _accent, size: 18),
            const SizedBox(width: 8),
            Text('Chat dengan Pelanggan',
              style: GoogleFonts.outfit(
                color: _accent, fontSize: 14, fontWeight: FontWeight.bold)),
            if (_isOrderDone) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Read-only',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
              ),
            ],
          ]),
        ),
        const Divider(color: Colors.white12, height: 1),

        // Daftar pesan
        if (_chats.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Belum ada pesan',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            itemCount: _chats.length,
            itemBuilder: (_, i) => _buildChatBubble(_chats[i]),
          ),
      ]),
    );
  }

  Widget _buildChatBubble(dynamic chat) {
    final isEmployee = (chat['sender_role'] as String? ?? '') == 'employee';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isEmployee ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isEmployee) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.person_rounded, color: Colors.white54, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68),
              decoration: BoxDecoration(
                color: isEmployee ? _accentDim : _surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isEmployee ? 16 : 4),
                  bottomRight: Radius.circular(isEmployee ? 4 : 16),
                ),
                border: isEmployee
                  ? null
                  : Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(chat['message'] ?? '',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  isEmployee ? _employeeName : 'Pelanggan',
                  style: GoogleFonts.outfit(
                    color: isEmployee ? Colors.white60 : Colors.white38,
                    fontSize: 10),
                ),
              ]),
            ),
          ),
          if (isEmployee) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Chat input ────────────────────────────────────────────────
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _accent.withOpacity(0.12))),
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _chatCtrl,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendChat(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _sendChat,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isSending
                  ? null
                  : const LinearGradient(
                      colors: [_accentDim, _accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                color: _isSending ? Colors.white12 : null,
              ),
              child: Icon(Icons.send_rounded,
                color: _isSending ? Colors.white30 : Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}
