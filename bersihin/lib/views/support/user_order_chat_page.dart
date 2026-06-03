import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

/// Halaman chat fullscreen antara User dan Karyawan untuk satu order tertentu.
/// Dipanggil dari ActivityPage saat user tap tombol chat di card order.
class UserOrderChatPage extends StatefulWidget {
  final int orderId;
  final String serviceName;
  final String employeeName;
  final String status;

  const UserOrderChatPage({
    super.key,
    required this.orderId,
    required this.serviceName,
    required this.employeeName,
    required this.status,
  });

  @override
  State<UserOrderChatPage> createState() => _UserOrderChatPageState();
}

class _UserOrderChatPageState extends State<UserOrderChatPage> {
  static const Color _bg      = Color(0xFF060E1A);
  static const Color _surface = Color(0xFF0D1B2A);
  static const Color _card    = Color(0xFF112233);
  static const Color _accent  = Color(0xFF00D4AA);
  static const Color _accentDim = Color(0xFF025955);

  final AuthService _svc = AuthService();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<dynamic> _chats = [];
  bool _isSending = false;
  bool _isLoading = true;
  String _userEmail = '';
  Timer? _pollTimer;

  bool get _isReadOnly => widget.status == 'selesai' || widget.status == 'cancelled';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('saved_email') ?? '';
    await _fetchChats();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchChats());
  }

  Future<void> _fetchChats() async {
    final res = await _svc.getEmployeeChat(widget.orderId);
    if (!mounted) return;
    if (res['statusCode'] == 200) {
      final newChats = res['body']['data'] as List? ?? [];
      final wasAtBottom = !_scrollCtrl.hasClients ||
          _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 80;
      setState(() {
        _chats = newChats;
        _isLoading = false;
      });
      if (wasAtBottom) _scrollToBottom();
    } else {
      setState(() => _isLoading = false);
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

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isSending || _userEmail.isEmpty) return;

    setState(() => _isSending = true);
    _chatCtrl.clear();

    final res = await _svc.sendEmployeeChat(
      widget.orderId,
      'user',
      _userEmail,
      text,
    );

    setState(() => _isSending = false);

    if (res['statusCode'] == 201) {
      await _fetchChats();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengirim pesan',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.status);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.serviceName,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(children: [
              Icon(Icons.engineering_rounded, color: _accent, size: 12),
              const SizedBox(width: 4),
              Text(
                widget.employeeName,
                style: GoogleFonts.outfit(color: _accent, fontSize: 11),
              ),
            ]),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              _statusLabel(widget.status),
              style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _accent.withOpacity(0.4),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // ── Pesan ────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _chats.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _chats.length,
                      itemBuilder: (_, i) => _buildChatBubble(_chats[i]),
                    ),
        ),

        // ── Read-only banner ─────────────────────────────────────
        if (_isReadOnly)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: _surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Order selesai — chat hanya bisa dibaca',
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

        // ── Input chat ───────────────────────────────────────────
        if (!_isReadOnly)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: _surface,
              border: Border(
                  top: BorderSide(color: _accent.withOpacity(0.12))),
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
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: Colors.white),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan ke karyawan...',
                        hintStyle: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
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
                    width: 44,
                    height: 44,
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
                    child: Icon(
                      _isSending
                          ? Icons.hourglass_empty_rounded
                          : Icons.send_rounded,
                      color: _isSending ? Colors.white30 : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildChatBubble(dynamic chat) {
    final isEmployee = (chat['sender_role'] as String? ?? '') == 'employee';
    final message = chat['message'] as String? ?? '';
    final createdAt = chat['created_at'] as String? ?? '';

    String timeLabel = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      timeLabel =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isEmployee ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar karyawan
          if (isEmployee) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.08),
              child: const Icon(Icons.engineering_rounded,
                  color: _accent, size: 16),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isEmployee
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: isEmployee ? _card : _accentDim,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isEmployee ? 4 : 16),
                      bottomRight: Radius.circular(isEmployee ? 16 : 4),
                    ),
                    border: isEmployee
                        ? Border.all(color: Colors.white.withOpacity(0.08))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEmployee ? widget.employeeName : 'Anda',
                        style: GoogleFonts.outfit(
                            color: isEmployee
                                ? _accent.withOpacity(0.7)
                                : Colors.white60,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (timeLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeLabel,
                    style: GoogleFonts.outfit(
                        color: Colors.white24, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),

          if (!isEmployee) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.07),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 48, color: _accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesan',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu bisa memulai percakapan\ndengan karyawan di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white38, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
