import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/home_page.dart';

void main() async {
  // Wajib dipanggil kalo fungsi main-nye pake async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive buat database lokal biar kenceng
  await Hive.initFlutter();
  
  // Buka box (brankas) khusus buat nyimpen session dan data user
  await Hive.openBox('userBox'); 

  runApp(const BersihInApp());
}

class BersihInApp extends StatelessWidget {
  const BersihInApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bersih.In',
      debugShowCheckedModeBanner: false, // Biar banner tulisan DEBUG-nye ilang
      theme: ThemeData(
        primaryColor: const Color(0xFF025955),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF025955),
          secondary: const Color(0xFF48C9B0),
        ),
      ),
      // Halaman awal tetep nembak ke HomePage sebagai landing pagenya
      home: const HomePage(), 
    );
  }
}