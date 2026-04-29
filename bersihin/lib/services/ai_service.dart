import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // ZHANGG! Taruh API Key yang lu dapet dari Google di mari pak!
  final String _apiKey = 'AIzaSyC4dpz9e7XJAfgIjGTpcv86i9e8W5pT8jU';
  
  late final GenerativeModel _model;

  AiService() {
    // Kita pake model gemini-1.5-flash biar balesnye ngebut kek gua
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: _apiKey,
    );
  }

  // Fungsi sakti buat nanya ke robot
  Future<String> nanyaRobot(String pertanyaanUser) async {
    try {
      // Kita kasih contekan dikit ke robotnye biar dia tau dia siapa
      final promptString = "Lu adalah Asisten AI dari aplikasi Bersih.In, aplikasi layanan kebersihan rumah. Jawab pertanyaan ini dengan ramah: $pertanyaanUser";
      
      final content = [Content.text(promptString)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'Waduh, gua nge-blank nih pak bos!';
    } catch (e) {
      return 'Yah robotnye lagi ngambek Mon: $e';
    }
  }
}