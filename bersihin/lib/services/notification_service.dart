import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../views/support/notification_page.dart';

class NotifId {
  static const int paymentReminder = 1001;
  static const int paymentExpired  = 1002;
  static const int orderConfirmed  = 2001;
  static const int orderInProgress = 2002;
  static const int orderDone       = 2003;
  static const int scheduleRemindH1  = 3001;
  static const int scheduleRemindDay = 3002;
}

class NotifChannel {
  static const String payment  = 'bersihin_payment';
  static const String order    = 'bersihin_order';
  static const String schedule = 'bersihin_schedule';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotifChannel.payment, 'Pembayaran',
      description: 'Notifikasi batas waktu dan status pembayaran',
      importance: Importance.high, playSound: true, enableVibration: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotifChannel.order, 'Status Pesanan',
      description: 'Update status pesanan dari admin',
      importance: Importance.high, playSound: true, enableVibration: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotifChannel.schedule, 'Jadwal Pengerjaan',
      description: 'Pengingat jadwal kedatangan teknisi',
      importance: Importance.defaultImportance, playSound: true,
    ));
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  AndroidNotificationDetails _androidDetail({
    required String channelId, required String channelName,
    Color? color, Importance importance = Importance.high,
    Priority priority = Priority.high, StyleInformation? styleInfo,
    bool ongoing = false,
  }) {
    return AndroidNotificationDetails(
      channelId, channelName,
      importance: importance,
      priority: priority,
      color: color ?? const Color(0xFF025955),
      icon: '@mipmap/ic_launcher',
      styleInformation: styleInfo ?? const DefaultStyleInformation(true, true),
      enableVibration: true,
      playSound: true,
      ongoing: ongoing,
      // Tampilkan di lock screen
      visibility: NotificationVisibility.public,
    );
  }

  Future<void> _show({
    required int id, required String title, required String body,
    required String channelId, required String channelName,
    Color? color, StyleInformation? styleInfo,
  }) async {
    await _plugin.show(id, title, body, NotificationDetails(
      android: _androidDetail(channelId: channelId, channelName: channelName, color: color, styleInfo: styleInfo),
    ));
  }

  Future<void> _schedule({
    required int id, required String title, required String body,
    required DateTime scheduledTime, required String channelId, required String channelName,
    Color? color,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id, title, body, tzTime,
      NotificationDetails(android: _androidDetail(channelId: channelId, channelName: channelName, color: color)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── PUBLIC API ───────────────────────────────────────────────

  Future<void> schedulePaymentReminder({
    required int orderId, required String serviceName, required int createdAtMs,
  }) async {
    final reminderTime = DateTime.fromMillisecondsSinceEpoch(createdAtMs)
        .add(const Duration(minutes: 20));
    await _schedule(
      id: NotifId.paymentReminder,
      title: '⏰ Segera Selesaikan Pembayaran!',
      body: 'Pembayaran "$serviceName" akan kedaluwarsa dalam 10 menit.',
      scheduledTime: reminderTime,
      channelId: NotifChannel.payment, channelName: 'Pembayaran',
      color: const Color(0xFFE53935),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'pay_reminder_$orderId',
      title: '⏰ Segera Selesaikan Pembayaran!',
      body: 'Pembayaran "$serviceName" akan kedaluwarsa dalam 10 menit. Jangan sampai pesanan dibatalkan!',
      type: 'payment', time: reminderTime,
    ));
  }

  Future<void> showPaymentExpired(String serviceName) async {
    await cancel(NotifId.paymentReminder);
    await _show(
      id: NotifId.paymentExpired,
      title: '❌ Pembayaran Kedaluwarsa',
      body: 'Pesanan "$serviceName" dibatalkan karena batas waktu habis.',
      channelId: NotifChannel.payment, channelName: 'Pembayaran',
      color: const Color(0xFFE53935),
      styleInfo: BigTextStyleInformation(
        'Pesanan "$serviceName" dibatalkan karena batas waktu pembayaran 30 menit telah habis. Silakan buat pesanan baru.',
        htmlFormatBigText: true,
        contentTitle: '<b>❌ Pembayaran Kedaluwarsa</b>', htmlFormatContentTitle: true,
      ),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'pay_expired_${DateTime.now().millisecondsSinceEpoch}',
      title: '❌ Pembayaran Kedaluwarsa',
      body: 'Pesanan "$serviceName" dibatalkan karena batas waktu 30 menit habis.',
      type: 'payment', time: DateTime.now(),
    ));
  }

  Future<void> showOrderConfirmed(String serviceName) async {
    await _show(
      id: NotifId.orderConfirmed,
      title: '✅ Pesanan Dikonfirmasi!',
      body: 'Pembayaran "$serviceName" telah diverifikasi. Teknisi sedang dalam perjalanan.',
      channelId: NotifChannel.order, channelName: 'Status Pesanan',
      color: const Color(0xFF025955),
      styleInfo: BigTextStyleInformation(
        'Pembayaran "$serviceName" telah diverifikasi oleh admin Bersih.In. Teknisi profesional kami sedang dipersiapkan untuk menuju lokasi Anda.',
        htmlFormatBigText: true,
        contentTitle: '<b>✅ Pesanan Dikonfirmasi!</b>', htmlFormatContentTitle: true,
      ),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'order_confirmed_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Pesanan Dikonfirmasi!',
      body: 'Pembayaran "$serviceName" telah diverifikasi. Teknisi sedang dalam perjalanan.',
      type: 'order', time: DateTime.now(),
    ));
  }

  Future<void> showOrderInProgress(String serviceName) async {
    await _show(
      id: NotifId.orderInProgress,
      title: '🔧 Pengerjaan Dimulai',
      body: '"$serviceName" sedang dikerjakan oleh teknisi kami.',
      channelId: NotifChannel.order, channelName: 'Status Pesanan',
      color: const Color(0xFF1565C0),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'order_progress_${DateTime.now().millisecondsSinceEpoch}',
      title: '🔧 Pengerjaan Dimulai',
      body: '"$serviceName" sedang dikerjakan oleh teknisi kami.',
      type: 'order', time: DateTime.now(),
    ));
  }

  Future<void> showOrderDone(String serviceName) async {
    await _show(
      id: NotifId.orderDone,
      title: '🎉 Pesanan Selesai!',
      body: '"$serviceName" telah selesai dikerjakan. Terima kasih telah menggunakan Bersih.In!',
      channelId: NotifChannel.order, channelName: 'Status Pesanan',
      color: const Color(0xFF025955),
      styleInfo: BigTextStyleInformation(
        '"$serviceName" telah selesai dikerjakan dengan sempurna. Terima kasih telah mempercayakan kebersihan hunian Anda kepada Bersih.In!',
        htmlFormatBigText: true,
        contentTitle: '<b>🎉 Pesanan Selesai!</b>', htmlFormatContentTitle: true,
      ),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'order_done_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Pesanan Selesai!',
      body: '"$serviceName" telah selesai dikerjakan. Terima kasih telah menggunakan Bersih.In!',
      type: 'order', time: DateTime.now(),
    ));
  }

  Future<void> scheduleH1Reminder({
    required String serviceName, required DateTime scheduleDateTime,
  }) async {
    final reminderTime = DateTime(
      scheduleDateTime.year, scheduleDateTime.month, scheduleDateTime.day - 1, 19, 0,
    );
    await _schedule(
      id: NotifId.scheduleRemindH1,
      title: '📅 Besok Ada Jadwal Layanan!',
      body: 'Teknisi "$serviceName" akan datang besok. Pastikan Anda ada di lokasi.',
      scheduledTime: reminderTime,
      channelId: NotifChannel.schedule, channelName: 'Jadwal Pengerjaan',
      color: const Color(0xFF025955),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'sched_h1_${scheduleDateTime.millisecondsSinceEpoch}',
      title: '📅 Besok Ada Jadwal Layanan!',
      body: 'Teknisi "$serviceName" akan datang besok. Pastikan Anda ada di lokasi.',
      type: 'schedule', time: reminderTime,
    ));
  }

  Future<void> scheduleHariHReminder({
    required String serviceName, required DateTime scheduleDateTime,
  }) async {
    final reminderTime = DateTime(
      scheduleDateTime.year, scheduleDateTime.month, scheduleDateTime.day, 8, 0,
    );
    await _schedule(
      id: NotifId.scheduleRemindDay,
      title: '🏠 Hari Ini Ada Layanan Bersih.In!',
      body: '"$serviceName" dijadwalkan hari ini. Teknisi akan segera tiba.',
      scheduledTime: reminderTime,
      channelId: NotifChannel.schedule, channelName: 'Jadwal Pengerjaan',
      color: const Color(0xFF025955),
    );
    await NotifHistoryService.add(NotifItem(
      id: 'sched_day_${scheduleDateTime.millisecondsSinceEpoch}',
      title: '🏠 Hari Ini Ada Layanan Bersih.In!',
      body: '"$serviceName" dijadwalkan hari ini. Teknisi akan segera tiba.',
      type: 'schedule', time: reminderTime,
    ));
  }

  static DateTime? parseScheduleDateTime(String date, String time) {
    try {
      const bulan = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'Mei': 5, 'Jun': 6,
        'Jul': 7, 'Ags': 8, 'Sep': 9, 'Okt': 10, 'Nov': 11, 'Des': 12,
      };
      final parts = date.trim().split(' ');
      final day   = int.parse(parts[0]);
      final month = bulan[parts[1]] ?? 1;
      final year  = int.parse(parts[2]);
      final timeParts = time.trim().split(':');
      final hour   = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].split(' ')[0]);
      return DateTime(year, month, day, hour, minute);
    } catch (_) { return null; }
  }

  // ── NOTIFIKASI UNTUK GUEST (belum login) ─────────────────────
  // Jadwal: pagi 08:00, siang 12:00, sore 17:00
  static const _guestNotifKey = 'guest_notif_scheduled';

  Future<void> scheduleGuestNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScheduled = prefs.getString(_guestNotifKey) ?? '';
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (lastScheduled == todayStr) return;

    await _schedule(
      id: 4001,
      title: '🌅 Selamat Pagi dari Bersih.In!',
      body: 'Mulai hari dengan hunian bersih. Pesan layanan kebersihan sekarang!',
      scheduledTime: DateTime(today.year, today.month, today.day, 8, 0),
      channelId: NotifChannel.schedule, channelName: 'Jadwal Pengerjaan',
      color: const Color(0xFF025955),
    );

    await _schedule(
      id: 4002,
      title: '☀️ Promo Siang Bersih.In!',
      body: 'Cuci sofa mulai Rp 120.000, Service AC mulai Rp 100.000. Pesan sekarang!',
      scheduledTime: DateTime(today.year, today.month, today.day, 12, 0),
      channelId: NotifChannel.schedule, channelName: 'Jadwal Pengerjaan',
      color: const Color(0xFF025955),
    );

    await _schedule(
      id: 4003,
      title: '🏠 Rumah Bersih, Hidup Nyaman!',
      body: 'Deep Cleaning mulai Rp 350.000. Jadwalkan sekarang untuk hunian yang lebih sehat!',
      scheduledTime: DateTime(today.year, today.month, today.day, 17, 0),
      channelId: NotifChannel.schedule, channelName: 'Jadwal Pengerjaan',
      color: const Color(0xFF025955),
    );

    await prefs.setString(_guestNotifKey, todayStr);
  }

  Future<void> cancelGuestNotifications() async {
    await cancel(4001);
    await cancel(4002);
    await cancel(4003);
  }
}
