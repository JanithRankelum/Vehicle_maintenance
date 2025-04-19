import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const String channelId = 'vehicle_reminders';
  static const String channelName = 'Vehicle Reminders';
  static const String channelDescription = 'Vehicle service reminders';

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
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleVehicleNotification({
    required String vehicleId,
    required String serviceType,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();

    // Generate unique ID for this vehicle+service combination
    final notificationId = _generateNotificationId(vehicleId, serviceType);

    await notificationsPlugin.show(
      notificationId,
      title,
      body,
      _notificationDetails(),
      payload: 'vehicle_$vehicleId',
    );
  }

  Future<void> cancelVehicleNotifications(String vehicleId) async {
    final serviceTypes = [
      'insurance_expiry_date',
      'next_oil_change',
      'next_tire_replace',
      'next_service'
    ];

    for (final type in serviceTypes) {
      final id = _generateNotificationId(vehicleId, type);
      await notificationsPlugin.cancel(id);
    }
  }

  int _generateNotificationId(String vehicleId, String serviceType) {
    return '$vehicleId-$serviceType'.hashCode;
  }
}