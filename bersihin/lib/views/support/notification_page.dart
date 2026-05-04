import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model satu item notifikasi
class NotifItem {
  final String id;
  final String title;
  final String body;
  final String type;      // 'payment' | 'order' | 'schedule'
  final DateTime time;
  bool isRead;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'body': body,
    'type': type, 'time': time.toIso8601String(), 'isRead': isRead,
  };

  factory NotifItem.fromJson(Map<String, dynamic> j) => NotifItem(
    id: j['id'], title: j['title'], body: j['body'],
    type: j['type'],
    time: DateTime.parse(j['time']),
    isRead: j['isRead'] ?? false,
  );
}

/// Service untuk menyimpan & membaca riwayat notifikasi lokal
class NotifHistoryService {
  static const _key = 'notif_history';

  static Future<List<NotifItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => NotifItem.fromJson(e)).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  static Future<void> add(NotifItem item) async {
    final items = await load();
    // Hindari duplikat berdasarkan id
    items.removeWhere((e) => e.id == item.id);
    items.insert(0, item);
    // Simpan maksimal 50 notifikasi
    final trimmed = items.take(50).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<void> markAllRead() async {
    final items = await load();
    for (final item in items) { item.isRead = true; }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<int> unreadCount() async {
    final items = await load();
    return items.where((e) => !e.isRead).length;
  }
}

/// Halaman riwayat notifikasi
class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Color toscaDark   = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight  = const Color(0xFF48C9B0);

  List<NotifItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await NotifHistoryService.load();
    await NotifHistoryService.markAllRead();
    if (mounted) setState(() { _items = items; _isLoading = false; });
  }

  Future<void> _clearAll() async {
    await NotifHistoryService.clear();
    if (mounted) setState(() => _items = []);
  }

  // ── warna & ikon per tipe ────────────────────────────────────
  Color _typeColor(String type) {
    switch (type) {
      case 'payment':  return Colors.red.shade600;
      case 'order':    return toscaDark;
      case 'schedule': return Colors.orange.shade700;
      default:         return toscaMedium;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'payment':  return Icons.payment_rounded;
      case 'order':    return Icons.receipt_long_rounded;
      case 'schedule': return Icons.event_rounded;
      default:         return Icons.notifications_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'payment':  return 'Pembayaran';
      case 'order':    return 'Status Pesanan';
      case 'schedule': return 'Jadwal';
      default:         return 'Info';
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Baru saja';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)    return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)      return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──────────────────────────────────────────
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
            actions: [
              if (_items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Hapus Semua?',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark)),
                        content: Text('Semua riwayat notifikasi akan dihapus.',
                            style: GoogleFonts.outfit(fontSize: 14)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context),
                              child: Text('BATAL', style: GoogleFonts.outfit(color: Colors.grey))),
                          TextButton(
                            onPressed: () { Navigator.pop(context); _clearAll(); },
                            child: Text('HAPUS', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70, size: 18),
                    label: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [toscaDark, const Color(0xFF0F2027)],
                  ),
                ),
                child: Stack(children: [
                  Positioned(right: -30, top: -30,
                    child: Icon(Icons.notifications_rounded, size: 200, color: Colors.white.withOpacity(0.04))),
                  SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
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
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Notifikasi',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            Text('${_items.length} riwayat aktivitas',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                          ]),
                        ]),
                      ],
                    ),
                  )),
                ]),
              ),
            ),
          ),

          // ── BODY ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: toscaMedium)),
                  )
                : _items.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80, left: 40, right: 40),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: toscaMedium.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Icon(Icons.notifications_off_outlined, size: 60, color: toscaMedium.withOpacity(0.4)),
        ),
        const SizedBox(height: 24),
        Text('Belum Ada Notifikasi',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: toscaDark)),
        const SizedBox(height: 8),
        Text('Notifikasi pembayaran, status pesanan, dan jadwal akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500, height: 1.6)),
      ]),
    );
  }

  Widget _buildList() {
    // Kelompokkan per hari
    final Map<String, List<NotifItem>> grouped = {};
    for (final item in _items) {
      final now = DateTime.now();
      final dt  = item.time;
      String label;
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        label = 'Hari Ini';
      } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
        label = 'Kemarin';
      } else {
        label = '${dt.day}/${dt.month}/${dt.year}';
      }
      grouped.putIfAbsent(label, () => []).add(item);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label tanggal
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(entry.key,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500, letterSpacing: 0.5)),
            ),
            ...entry.value.map((item) => _buildCard(item)).toList(),
            const SizedBox(height: 8),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildCard(NotifItem item) {
    final color = _typeColor(item.type);
    final icon  = _typeIcon(item.type);
    final label = _typeLabel(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : toscaLight.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isRead ? Colors.grey.shade100 : toscaMedium.withOpacity(0.2),
          width: item.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isRead ? Colors.black.withOpacity(0.03) : toscaMedium.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ikon tipe
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Badge tipe + waktu
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
              Text(_relativeTime(item.time),
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400)),
            ]),
            const SizedBox(height: 6),
            Text(item.title,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(item.body,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
          ])),
          // Dot unread
          if (!item.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: toscaMedium, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }
}
