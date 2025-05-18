import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotiService {
  static final NotiService _instance = NotiService._internal();
  factory NotiService() => _instance;
  NotiService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'vehicle_reminders';
  static const String _channelName = 'Vehicle Reminders';
  static const String _channelDescription = 'Vehicle service reminders';
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
  }

  Future<void> schedule({
    required String vehicleId,
    required String serviceType,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();

    // ✅ Skip past dates
    if (scheduledDate.isBefore(DateTime.now())) {
      print("❗ Skipping $serviceType for $vehicleId - date is in the past: $scheduledDate");
      return;
    }

    final notificationId = _generateNotificationId(vehicleId, serviceType);
    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzDateTime,
      _notificationDetails(),
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: _createPayload(vehicleId, serviceType),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAllForVehicle(String vehicleId) async {
    final notifications = await notificationsPlugin.pendingNotificationRequests();
    for (var notification in notifications) {
      if (notification.payload?.contains(vehicleId) ?? false) {
        await notificationsPlugin.cancel(notification.id);
      }
    }
  }

  Future<void> cancelSingleNotification(String vehicleId, String serviceType) async {
    final notificationId = _generateNotificationId(vehicleId, serviceType);
    await notificationsPlugin.cancel(notificationId);
  }

  Future<List<PendingNotificationRequest>> getScheduledNotifications() async {
    return await notificationsPlugin.pendingNotificationRequests();
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        colorized: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  int _generateNotificationId(String vehicleId, String serviceType) {
    // Generate consistent ID from vehicleId and serviceType
    return '$vehicleId-$serviceType'.hashCode.abs();
  }

  String _createPayload(String vehicleId, String serviceType) {
    return 'vehicle_$vehicleId|service_$serviceType';
  }

  Future<void> rescheduleNotification({
    required String vehicleId,
    required String serviceType,
    required DateTime newDate,
    required String newTitle,
    required String newBody,
  }) async {
    await cancelSingleNotification(vehicleId, serviceType);
    await schedule(
      vehicleId: vehicleId,
      serviceType: serviceType,
      scheduledDate: newDate,
      title: newTitle,
      body: newBody,
    );
  }
}
