import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({Key? key}) : super(key: key);
  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  final AuthService _svc = AuthService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _email = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('saved_email') ?? '';
    await _fetchMessages();
    // Polling setiap 3 detik untuk pesan baru
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  Future<void> _fetchMessages() async {
    if (_email.isEmpty) { setState(() => _isLoading = false); return; }
    final res = await _svc.getMessages(_email);
    if (mounted && res['statusCode'] == 200) {
      final newMsgs = res['body']['data'] as List? ?? [];
      final wasAtBottom = _isAtBottom();
      setState(() {
        _messages = newMsgs;
        _isLoading = false;
      });
      if (wasAtBottom) _scrollToBottom();
    }
  }

  bool _isAtBottom() {
    if (!_scroll.hasClients) return true;
    return _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _ctrl.clear();
    await _svc.sendMessage(_email, 'user', text);
    setState(() => _isSending = false);
    await _fetchMessages();
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        backgroundColor: toscaDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [toscaMedium, toscaLight]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Admin Bersih.In',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Row(children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Online', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
            ]),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [toscaLight, toscaMedium]))),
        ),
      ),
      body: Column(children: [
        // ── Pesan ────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: toscaMedium))
              : _email.isEmpty
                  ? _buildLoginPrompt()
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _buildBubble(_messages[i]),
                        ),
        ),

        // ── Input ─────────────────────────────────────────────
        if (_email.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: GoogleFonts.outfit(fontSize: 14),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: _isSending
                        ? const Padding(padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildBubble(dynamic msg) {
    final isUser   = msg['sender'] == 'user';
    final time     = _formatTime(msg['created_at']?.toString());
    final text     = (msg['message'] ?? '') as String;
    final isReport = text.startsWith('🚩');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                isReport
                    ? _buildReportBubble(text, isUser, msg)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? LinearGradient(colors: [toscaDark, toscaMedium])
                              : null,
                          color: isUser ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUser ? 18 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUser
                                  ? toscaMedium.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(text,
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: isUser ? Colors.white : Colors.black87,
                                height: 1.4)),
                      ),
                const SizedBox(height: 3),
                Text(time,
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Bubble khusus untuk pesan laporan — bisa diklik untuk lihat detail
  Widget _buildReportBubble(String text, bool isUser, dynamic msg) {
    // Parse isi laporan dari teks
    final lines = text.split('\n');
    String orderId = '';
    String layanan = '';
    String keterangan = '';
    bool adaGambar = false;

    for (final line in lines) {
      if (line.contains('LAPORAN PESANAN')) {
        orderId = line.replaceAll(RegExp(r'[^0-9]'), '');
      } else if (line.startsWith('Layanan:')) {
        layanan = line.replaceFirst('Layanan:', '').trim();
      } else if (line.startsWith('Keterangan:')) {
        keterangan = line.replaceFirst('Keterangan:', '').trim();
      } else if (line.contains('Gambar dilampirkan') || line.contains('📎')) {
        adaGambar = true;
      }
    }

    return GestureDetector(
      onTap: () => _showReportDetail(
        orderId: orderId,
        layanan: layanan,
        keterangan: keterangan,
        adaGambar: adaGambar,
        time: _formatTime(msg['created_at']?.toString()),
      ),
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? toscaDark : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: Colors.red.shade300.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header merah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Laporan Pesanan${orderId.isNotEmpty ? ' #$orderId' : ''}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              const Icon(Icons.open_in_new_rounded,
                  color: Colors.white70, size: 14),
            ]),
          ),
          // Isi ringkasan
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              if (layanan.isNotEmpty) ...[
                Row(children: [
                  Icon(Icons.cleaning_services_rounded,
                      size: 13,
                      color: isUser
                          ? Colors.white70
                          : Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(layanan,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isUser
                                ? Colors.white70
                                : Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 6),
              ],
              if (keterangan.isNotEmpty)
                Text(
                  keterangan,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (adaGambar) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.image_rounded,
                      size: 13,
                      color: isUser ? toscaLight : toscaMedium),
                  const SizedBox(width: 5),
                  Text('Foto terlampir',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isUser ? toscaLight : toscaMedium,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('Ketuk untuk detail',
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isUser
                            ? Colors.white54
                            : Colors.grey.shade400,
                        fontStyle: FontStyle.italic)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showReportDetail({
    required String orderId,
    required String layanan,
    required String keterangan,
    required bool adaGambar,
    required String time,
  }) {
    // Cari data report dari DB berdasarkan orderId
    if (orderId.isNotEmpty) {
      _fetchAndShowReportDetail(int.tryParse(orderId) ?? 0,
          layanan: layanan, keterangan: keterangan, time: time);
    } else {
      _showReportDetailDialog(
        orderId: orderId,
        layanan: layanan,
        keterangan: keterangan,
        imageBase64: null,
        time: time,
      );
    }
  }

  Future<void> _fetchAndShowReportDetail(int orderId,
      {required String layanan,
      required String keterangan,
      required String time}) async {
    // Ambil data report dari API untuk mendapatkan gambar
    final res = await _svc.getAdminReports();
    String? imageBase64;
    String? status;
    if (res['statusCode'] == 200) {
      final reports = res['body']['data'] as List? ?? [];
      final match = reports.firstWhere(
        (r) => r['order_id'].toString() == orderId.toString(),
        orElse: () => null,
      );
      if (match != null) {
        imageBase64 = match['image_base64'] as String?;
        status = match['status'] as String?;
        if (match['description'] != null) keterangan = match['description'];
        if (match['service_name'] != null) layanan = match['service_name'];
      }
    }
    if (mounted) {
      _showReportDetailDialog(
        orderId: orderId.toString(),
        layanan: layanan,
        keterangan: keterangan,
        imageBase64: imageBase64,
        time: time,
        status: status,
      );
    }
  }

  void _showReportDetailDialog({
    required String orderId,
    required String layanan,
    required String keterangan,
    required String? imageBase64,
    required String time,
    String? status,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(children: [
                const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      'Detail Laporan${orderId.isNotEmpty ? ' — Pesanan #$orderId' : ''}',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(time,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 11)),
                  ]),
                ),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'ditangani'
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status == 'ditangani' ? 'Ditangani' : 'Pending',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Layanan
                if (layanan.isNotEmpty) ...[
                  _detailRow(Icons.cleaning_services_rounded, 'Layanan',
                      layanan),
                  const SizedBox(height: 14),
                ],

                // Keterangan
                Text('Keterangan',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    keterangan.isNotEmpty ? keterangan : '—',
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5),
                  ),
                ),

                // Foto bukti
                if (imageBase64 != null && imageBase64.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Foto Bukti',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(imageBase64),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: toscaDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Tutup',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: toscaMedium),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600)),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [toscaDark.withOpacity(0.08), toscaLight.withOpacity(0.05)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 52, color: toscaDark),
          ),
          const SizedBox(height: 20),
          Text('Mulai Percakapan',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
          const SizedBox(height: 8),
          Text('Kirim pesan ke admin Bersih.In.\nKami siap membantu Anda!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500, height: 1.6)),
        ]),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_person_rounded, size: 64, color: toscaDark),
          const SizedBox(height: 16),
          Text('Login Diperlukan',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
          const SizedBox(height: 8),
          Text('Silakan login untuk menggunakan fitur Live Chat',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}

// ── Admin Chat Room List ──────────────────────────────────────
class AdminChatPage extends StatefulWidget {
  const AdminChatPage({Key? key}) : super(key: key);
  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final AuthService _svc  = AuthService();
  List<dynamic> _rooms = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    final res = await _svc.getAdminChatRooms();
    if (mounted && res['statusCode'] == 200) {
      setState(() { _rooms = res['body']['data'] ?? []; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: toscaDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Chat — Admin',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: toscaMedium))
          : _rooms.isEmpty
              ? Center(child: Text('Belum ada percakapan',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _rooms.length,
                  itemBuilder: (_, i) {
                    final r = _rooms[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AdminChatRoomPage(userEmail: r['user_email']))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: toscaMedium.withOpacity(0.2),
                            child: Text((r['user_email'] ?? '?')[0].toUpperCase(),
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r['user_email'] ?? '',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(r['last_message'] ?? '',
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Admin Chat Room (balas pesan user) ───────────────────────
class AdminChatRoomPage extends StatefulWidget {
  final String userEmail;
  const AdminChatRoomPage({Key? key, required this.userEmail}) : super(key: key);
  @override
  State<AdminChatRoomPage> createState() => _AdminChatRoomPageState();
}

class _AdminChatRoomPageState extends State<AdminChatRoomPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final AuthService _svc  = AuthService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<dynamic> _messages = [];
  bool _isSending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() { _pollTimer?.cancel(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    final res = await _svc.getMessages(widget.userEmail);
    if (mounted && res['statusCode'] == 200) {
      final msgs = res['body']['data'] as List? ?? [];
      final wasAtBottom = !_scroll.hasClients || _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;
      setState(() => _messages = msgs);
      if (wasAtBottom) Future.delayed(const Duration(milliseconds: 100), () {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _ctrl.clear();
    await _svc.sendMessage(widget.userEmail, 'admin', text);
    setState(() => _isSending = false);
    await _fetch();
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: toscaDark, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.userEmail, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('User', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          physics: const BouncingScrollPhysics(),
          itemCount: _messages.length,
          itemBuilder: (_, i) {
            final msg = _messages[i];
            final isAdmin = msg['sender'] == 'admin';
            final time = _formatTime(msg['created_at']?.toString());
            final text = (msg['message'] ?? '') as String;
            final isReport = text.startsWith('🚩');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: Column(
                    crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      isReport
                          ? _buildAdminReportBubble(text, isAdmin, msg)
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                              decoration: BoxDecoration(
                                gradient: isAdmin ? LinearGradient(colors: [toscaDark, toscaMedium]) : null,
                                color: isAdmin ? null : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isAdmin ? 18 : 4),
                                  bottomRight: Radius.circular(isAdmin ? 4 : 18),
                                ),
                              ),
                              child: Text(text,
                                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, height: 1.4)),
                            ),
                      const SizedBox(height: 3),
                      Text(time, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                    ],
                  )),
                ],
              ),
            );
          },
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: Colors.white.withOpacity(0.05),
          child: SafeArea(child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.15))),
              child: TextField(
                controller: _ctrl,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Balas pesan...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [toscaDark, toscaMedium]),
                  shape: BoxShape.circle),
                child: _isSending
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
            ),
          ])),
        ),
      ]),
    );
  }

  Widget _buildAdminReportBubble(String text, bool isAdmin, dynamic msg) {
    final lines = text.split('\n');
    String orderId = '';
    String layanan = '';
    String keterangan = '';

    for (final line in lines) {
      if (line.contains('LAPORAN PESANAN') || line.contains('Laporan baru untuk pesanan')) {
        final match = RegExp(r'#(\d+)').firstMatch(line);
        if (match != null) orderId = match.group(1) ?? '';
      } else if (line.startsWith('Layanan:')) {
        layanan = line.replaceFirst('Layanan:', '').trim();
      } else if (line.startsWith('Keterangan:')) {
        keterangan = line.replaceFirst('Keterangan:', '').trim();
      }
    }

    return GestureDetector(
      onTap: () => _fetchAndShowAdminReportDetail(
        orderId,
        layanan: layanan,
        keterangan: keterangan,
        time: _formatTime(msg['created_at']?.toString()),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: Colors.red.shade400.withOpacity(0.6), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Laporan Pesanan${orderId.isNotEmpty ? ' #$orderId' : ''}',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              )),
              const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 13),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (layanan.isNotEmpty) ...[
                Text(layanan,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
              ],
              if (keterangan.isNotEmpty)
                Text(keterangan,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('Ketuk untuk detail',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic)),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _fetchAndShowAdminReportDetail(String orderId,
      {required String layanan, required String keterangan, required String time}) async {
    final res = await _svc.getAdminReports();
    String? imageBase64;
    String? status;
    String finalKet = keterangan;
    String finalLayanan = layanan;
    int? reportId;

    if (res['statusCode'] == 200) {
      final reports = res['body']['data'] as List? ?? [];
      final match = reports.firstWhere(
        (r) => r['order_id'].toString() == orderId,
        orElse: () => null,
      );
      if (match != null) {
        reportId = match['id'] as int?;
        imageBase64 = match['image_base64'] as String?;
        status = match['status'] as String?;
        if (match['description'] != null) finalKet = match['description'];
        if (match['service_name'] != null) finalLayanan = match['service_name'];
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Row(children: [
                  const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Detail Laporan${orderId.isNotEmpty ? ' — Pesanan #$orderId' : ''}',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(time, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                  ])),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'ditangani' ? Colors.green.shade600 : Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(status == 'ditangani' ? 'Ditangani' : 'Pending',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (finalLayanan.isNotEmpty) ...[
                    Text('Layanan', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(finalLayanan, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: toscaDark)),
                    const SizedBox(height: 14),
                  ],
                  Text('Keterangan', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(finalKet.isNotEmpty ? finalKet : '—',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, height: 1.5)),
                  ),
                  if (imageBase64 != null && imageBase64.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Foto Bukti', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(base64Decode(imageBase64), width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (status == 'pending' && reportId != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _svc.updateReportStatus(reportId!, 'ditangani');
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        label: Text('Tandai Ditangani',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Tutup', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
