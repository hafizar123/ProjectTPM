import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/home/home_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('userBox');

  // Init notifikasi — channel dibuat di sini
  await NotificationService().init();

  runApp(const BersihInApp());
}

class BersihInApp extends StatelessWidget {
  const BersihInApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bersih.In',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF025955),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF025955),
          secondary: const Color(0xFF48C9B0),
        ),
      ),
      home: const _AppRoot(),
    );
  }
}

/// Root widget yang request permission notifikasi saat pertama buka
class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Request permission notifikasi — wajib di Android 13+ (API 33+)
      await NotificationService().requestPermission();

      // Jadwalkan notifikasi promosi untuk guest (belum login)
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = (prefs.getString('saved_email') ?? '').isNotEmpty;
      if (!isLoggedIn) {
        await NotificationService().scheduleGuestNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const HomePage();
}