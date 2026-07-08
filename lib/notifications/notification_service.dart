import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Local notifications setup.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Firebase Cloud Messaging setup.
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          title: notification.title ?? 'CuroME',
          body: notification.body ?? '',
        );
      }
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'curome_channel',
      'CuroME Reminders',
      channelDescription: 'Medication and appointment reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String label,
    required String time,
  }) async {
    await showLocalNotification(
      id: id,
      title: 'Medication Reminder',
      body: 'Time to take $label ($time)',
    );
  }

  Future<void> sendSosAlert(String patientName) async {
    await showLocalNotification(
      title: 'SOS ALERT',
      body: '$patientName has triggered an emergency SOS request.',
    );
  }
}