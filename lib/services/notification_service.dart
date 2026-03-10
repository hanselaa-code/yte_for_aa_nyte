import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showBeerMilestone(int beerNumber) async {
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'beer_milestones',
      'Beer Milestones',
      channelDescription: 'Notifications when you earn a new beer',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(
        'beer_pour',
      ), // We'd need to add this sound asset late if possible, or use default
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0,
      'SKÅL! 🍻',
      'Du har nå tjent opp til halvliter nr. $beerNumber! Fantastisk innsats!',
      details,
    );
  }

  Future<void> testNotification() async {
    await showBeerMilestone(1);
  }
}
