import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// THAY ĐỔI: Tạo lớp NotificationService để quản lý thông báo cho tất cả nền tảng
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService();

  // THAY ĐỔI: Thêm phương thức yêu cầu quyền thông báo
  Future<bool> requestPermission() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    return true; // Trả về true cho các nền tảng không yêu cầu quyền
  }

  // THAY ĐỔI: Khởi tạo thông báo và yêu cầu quyền nếu cần
  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinInit =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const LinuxInitializationSettings linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const WindowsInitializationSettings windowsInit =
        WindowsInitializationSettings(
      appName: 'YouTube Downloader',
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
      appUserModelId: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
      windows: windowsInit,
    );

    await _notificationsPlugin.initialize(initSettings);
    await requestPermission(); // THAY ĐỔI: Yêu cầu quyền sau khi khởi tạo
  }

  // THAY ĐỔI: Hàm hiển thị thông báo chung cho tất cả nền tảng
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'download_channel',
      'Download Notifications',
      channelDescription: 'Notifications for download status',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();
    const WindowsNotificationDetails windowsDetails =
        WindowsNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );

    await _notificationsPlugin.show(id, title, body, platformDetails);
  }

  // THAY ĐỔI: Thêm phương thức lấy chi tiết khởi động từ thông báo
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }
}
