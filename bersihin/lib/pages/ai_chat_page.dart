import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart'; // ZHANGG! Pastiin path-nye bener pak!

class AiChatPage extends StatefulWidget {
  const AiChatPage({Key? key}) : super(key: key);

  @override
  _AiChatPageState createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService(); // Manggil si otak buatan

  // ZHANGG! Pesan pembuka dari si Robot
  List<Map<String, dynamic>> messages = [
    {
      "role": "ai", 
      "text": "Halo Bos! Gua asisten pinter dari Bersih.In. Mau nanya soal harga, layanan, atau tips bersih-bersih rumah? Sikat miring tanyain aje ke gua!"
    }
  ];
  
  bool _isTyping = false;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    String userText = _chatController.text.trim();
    
    setState(() {
      messages.add({"role": "user", "text": userText});
      _isTyping = true;
      _chatController.clear();
    });

    _scrollToBottom();

    // Tembak API Gemini lu pak!
    String aiResponse = await _aiService.nanyaRobot(userText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        messages.add({"role": "ai", "text": aiResponse});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: toscaDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bersih.In AI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                Text('Selalu sedia 24/7', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ARENA CHAT
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUser = messages[index]['role'] == 'user';
                return _buildChatBubble(messages[index]['text'], isUser);
              },
            ),
          ),
          
          // INDIKATOR TYPING
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 15, height: 15, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00909E))
                    ),
                    const SizedBox(width: 10),
                    Text('Robot lagi mikir...', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

          // KOTAK KETIK
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _chatController,
                        style: GoogleFonts.outfit(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tanya apa aja ke AI...',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isTyping ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isTyping ? Colors.grey : toscaMedium,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_isTyping)
                            BoxShadow(color: toscaMedium.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                        ]
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? toscaDark : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}