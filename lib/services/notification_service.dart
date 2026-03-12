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

    // 1. Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      // 2. Initialize the plugin
      bool? initialized = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification tapped: ${details.payload}");
        },
      );
      
      debugPrint("NotificationService: Plugin initialized: $initialized");

      // 3. Create the notification channel (Android 8.0+)
      // Using v8 to force a fresh channel with sound enabled
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'beer_alerts_v8', 
        'Øl-varsler (Viktig)',
        description: 'Varsler med lyd når du har fortjent en ny øl',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('beer_pling'),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        audioAttributes: AudioAttributes(
          usage: AudioAttributesUsage.notification,
          contentType: AudioAttributesContentType.sonification,
        ),
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      _isInitialized = true;
      debugPrint("NotificationService: Initialized successfully with v8 channel");
    } catch (e) {
      debugPrint("NotificationService: Initialization error: $e");
    }

    // 4. Handle Permissions (especially for Android 13+)
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    debugPrint("NotificationService: Checking permissions...");
    
    // Check status using permission_handler
    var status = await Permission.notification.status;
    debugPrint("NotificationService: Current status: $status");

    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint("NotificationService: Requesting permission explicitly...");
      status = await Permission.notification.request();
      debugPrint("NotificationService: New status after request: $status");
    }

    // Also call the plugin's internal request to be safe
    try {
      final bool? granted =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
      debugPrint("NotificationService: Plugin-reported granted: $granted");
    } catch (e) {
      debugPrint("NotificationService: Plugin permission error: $e");
    }
  }

  Future<void> showBeerMilestone(int beerNumber) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint("NotificationService: Attempting to show milestone #$beerNumber");
      
      final String title = 'SKÅL! 🍻';
      final String body = 'Du har nå fortjent en ny enhet! Fantastisk innsats! 🎉';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'beer_alerts_v8',
            'Øl-varsler (Viktig)',
            channelDescription: 'Varsler med lyd når du har fortjent en ny øl',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('beer_pling'),
            ticker: 'Skål! 🍻',
            icon: 'launcher_icon',
            enableVibration: true,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Ny øl tjent!',
            ),
          );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        beerNumber,
        title,
        body,
        details,
      );
      debugPrint("NotificationService: Successfully triggered show() for beer #$beerNumber");
    } catch (e) {
      debugPrint("NotificationService: Error in showBeerMilestone: $e");
    }
  }

  Future<void> showSimpleNotification() async {
    try {
      debugPrint("NotificationService: Showing fallback test notification");
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'general_alerts',
            'Generelle varsler',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Test',
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        999,
        'Prøvevarsel felles',
        'Dette er et testvarsel uten spesial-lyd.',
        details,
      );
    } catch (e) {
      debugPrint("NotificationService: Error in simple notification: $e");
    }
  }

  Future<void> testNotification() async {
    debugPrint("NotificationService: Starting manual test...");
    await requestPermissions();
    await showBeerMilestone(1);
    
    // Fallback if the main one fails
    Future.delayed(const Duration(seconds: 4), () => showSimpleNotification());
  }
}
