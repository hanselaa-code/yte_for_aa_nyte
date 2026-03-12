import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      // 1. Initialize the plugin
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification tapped: ${details.payload}");
        },
      );

      // 2. Create the notification channel (Android 8.0+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'beer_alerts_v7', // Fresh ID for sound
        'Øl-varsler',
        description: 'Varsler når du har fortjent en ny øl',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('beer_pling'),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint("NotificationService: Initialized successfully with v7 channel");
    } catch (e) {
      debugPrint("NotificationService: Initialization error: $e");
    }

    // Request permissions for Android 13+
    try {
      final bool? granted =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
      debugPrint("NotificationService: Permissions granted: $granted");
    } catch (e) {
      debugPrint("NotificationService: Permission error: $e");
    }
  }

  Future<void> showBeerMilestone(int beerNumber) async {
    try {
      debugPrint("NotificationService: Attempting to show milestone #$beerNumber");
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'beer_alerts_v7',
            'Øl-varsler',
            channelDescription: 'Varsler når du har fortjent en ny øl',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('beer_pling'),
            ticker: 'Skål! 🍻',
            icon: 'launcher_icon',
            enableVibration: true,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        beerNumber,
        'SKÅL! 🍻',
        'Du har nå fortjent en ny enhet! Fantastisk innsats! 🎉',
        details,
      );
      debugPrint("NotificationService: Successfully triggered show()");
    } catch (e) {
      debugPrint("NotificationService: Error in showBeerMilestone: $e");
    }
  }

  Future<void> showSimpleNotification() async {
    try {
      debugPrint("NotificationService: Attempting to show simple notification");
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'simple_notifications',
            'Simple Notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Test',
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        999,
        'Test Varsel',
        'Dette er et enkelt testvarsel uten lydfil.',
        details,
      );
      debugPrint("NotificationService: Successfully triggered simple show()");
    } catch (e) {
      debugPrint("NotificationService: Error in showSimpleNotification: $e");
    }
  }

  Future<void> testNotification() async {
    debugPrint("NotificationService: testNotification starting");
    
    // Request permissions again just in case
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await showBeerMilestone(1);
    
    // If the above fails or is silent, this one uses default settings
    Future.delayed(const Duration(seconds: 3), () => showSimpleNotification());
  }
}
