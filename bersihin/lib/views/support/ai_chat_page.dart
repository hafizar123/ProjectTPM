import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({Key? key}) : super(key: key);

  @override
  _AiChatPageState createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();

  static const Color _bg       = Color(0xFF060E1A);
  static const Color _surface  = Color(0xFF0D1B2A);
  static const Color _card     = Color(0xFF112233);
  static const Color _accent   = Color(0xFF00D4AA);
  static const Color _accentDim = Color(0xFF025955);
  static const Color _userBubble = Color(0xFF025955);

  List<Map<String, dynamic>> messages = [
    {
      'role': 'ai',
      'text':
          'Selamat datang di Asisten Bersih.In! 👋\n\nSaya siap membantu Anda dengan informasi seputar layanan kebersihan, harga, jadwal, dan tips perawatan hunian. Silakan ajukan pertanyaan Anda.',
    }
  ];

  bool _isTyping = false;

  // Saran pertanyaan cepat
  static const List<String> _quickSuggestions = [
    'Layanan apa saja yang tersedia?',
    'Berapa harga cuci sofa?',
    'Bagaimana cara memesan?',
    'Tips menjaga kebersihan rumah',
  ];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? preset]) async {
    final text = (preset ?? _chatController.text).trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      _chatController.clear();
    });
    _scrollToBottom();

    final response = await _aiService.nanyaRobot(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        messages.add({'role': 'ai', 'text': response});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(children: [
        // ── Area pesan ──────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            physics: const BouncingScrollPhysics(),
            itemCount: messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == messages.length) return _buildTypingIndicator();
              return _buildBubble(messages[i]);
            },
          ),
        ),

        // ── Saran pertanyaan (hanya saat belum ada percakapan panjang) ──
        if (messages.length <= 2 && !_isTyping) _buildQuickSuggestions(),

        // ── Input ───────────────────────────────────────────
        _buildInputBar(),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white70, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        // Ikon AI kustom
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [_accentDim, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Asisten Bersih.In',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: _accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text('Aktif sekarang',
                style: GoogleFonts.outfit(
                    color: _accent, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _accent, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Avatar AI
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [_accentDim, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: _accent.withOpacity(0.15), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _accentDim.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                msg['text'] ?? '',
                style: GoogleFonts.outfit(
                  color: isUser ? Colors.white : Colors.white.withOpacity(0.88),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [_accentDim, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _accent.withOpacity(0.15)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Row(children: [
                  _dot(0),
                  const SizedBox(width: 4),
                  _dot(1),
                  const SizedBox(width: 4),
                  _dot(2),
                ]),
              ),
              const SizedBox(width: 10),
              Text('Sedang memproses...',
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final delay = index * 0.15;
        final val = (((_pulseCtrl.value - delay) % 1.0 + 1.0) % 1.0);
        final opacity = (val < 0.5 ? val * 2 : (1 - val) * 2).clamp(0.3, 1.0);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
                color: _accent, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pertanyaan Umum',
            style: GoogleFonts.outfit(
                color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSuggestions.map((q) => GestureDetector(
            onTap: () => _sendMessage(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: Text(q,
                  style: GoogleFonts.outfit(
                      color: _accent, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _accent.withOpacity(0.12), width: 1),
        ),
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
                controller: _chatController,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu...',
                  hintStyle: GoogleFonts.outfit(
                      color: Colors.white30, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 13),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isTyping
                    ? null
                    : const LinearGradient(
                        colors: [_accentDim, _accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isTyping ? Colors.white12 : null,
                boxShadow: _isTyping
                    ? []
                    : [
                        BoxShadow(
                          color: _accent.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isTyping ? Colors.white30 : Colors.white,
                size: 20,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
