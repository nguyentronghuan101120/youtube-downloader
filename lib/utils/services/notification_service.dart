import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// THAY ĐỔI: Tạo lớp NotificationService để quản lý thông báo cho tất cả nền tảng
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService();

  // THAY ĐỔI: Khởi tạo thông báo cho tất cả nền tảng
  Future<void> initialize() async {
    // Cấu hình cho Android
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình cho iOS và macOS (dùng DarwinInitializationSettings)
    const DarwinInitializationSettings darwinInit =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Cấu hình cho Linux
    const LinuxInitializationSettings linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    // Cấu hình cho Windows
    const WindowsInitializationSettings windowsInit =
        WindowsInitializationSettings(
      appName: 'YouTube Downloader', // Tên ứng dụng
      // GUID tùy chọn, có thể tạo từ các công cụ online nếu cần
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
      appUserModelId: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
    );

    // Kết hợp tất cả cấu hình
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
      windows: windowsInit,
    );

    // Khởi tạo plugin với các thiết lập
    await _notificationsPlugin.initialize(initSettings);
  }

  // THAY ĐỔI: Hàm hiển thị thông báo chung cho tất cả nền tảng
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Chi tiết thông báo cho Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'download_channel',
      'Download Notifications',
      channelDescription: 'Notifications for download status',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Chi tiết thông báo cho iOS và macOS
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

    // Chi tiết thông báo cho Linux
    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    // Chi tiết thông báo cho Windows
    const WindowsNotificationDetails windowsDetails =
        WindowsNotificationDetails();

    // Kết hợp chi tiết thông báo cho tất cả nền tảng
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );

    // Hiển thị thông báo
    await _notificationsPlugin.show(id, title, body, platformDetails);
  }
}
