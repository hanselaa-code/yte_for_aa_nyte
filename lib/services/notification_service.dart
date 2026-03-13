import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint("NotificationService: Initializing...");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification tapped: ${details.payload}");
        },
      );

      // Channel v9: Using system default sound (no specific sound resource)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'beer_alerts_v9', 
        'Øl-varsler',
        description: 'Varsler når du har fortjent en ny øl',
        importance: Importance.max,
        playSound: true, // Uses system default when sound is null
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      _isInitialized = true;
      debugPrint("NotificationService: Initialized successfully with v9 channel (System Default Sound)");
    } catch (e) {
      debugPrint("NotificationService: Initialization error: $e");
    }

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> showBeerMilestone(int beerNumber) async {
    if (!_isInitialized) await initialize();

    try {
      const String title = 'SKÅL! 🍻';
      const String body = 'Du har nå fortjent en ny enhet! Fantastisk innsats! 🎉';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'beer_alerts_v9',
            'Øl-varsler',
            channelDescription: 'Varsler når du har fortjent en ny øl',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true, // Default sound
            ticker: 'Skål! 🍻',
            icon: 'launcher_icon',
            enableVibration: true,
            enableLights: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        beerNumber,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint("NotificationService: Error in showBeerMilestone: $e");
    }
  }

  Future<void> testNotification() async {
    await requestPermissions();
    await showBeerMilestone(1);
  }
}
