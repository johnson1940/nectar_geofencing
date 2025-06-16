import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/logger.dart';
import '../helper/toaster.dart';
import '../model/location_history.dart';
import '../model/geo_fence_model.dart';


@pragma('vm:entry-point')
class NotificationService {

  static int _notificationId = 0;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      bool? initialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      if (initialized != true) {
       // logger.e('Notification initialization failed');
        throw Exception('Failed to initialize notifications');
      }
      if (Platform.isAndroid) {
        const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
          'geofence_background',
          'Geofence Background Service',
          description: 'Notification channel for geofence background service',
          importance: Importance.low,
        );
        const AndroidNotificationChannel geofenceChannel = AndroidNotificationChannel(
          'geofence_channel',
          'Geofence Notifications',
          description: 'Notifications for geofence entry and exit events',
          importance: Importance.high,
        );
        final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(backgroundChannel);
        await androidPlugin?.createNotificationChannel(geofenceChannel);
       // logger.i('Notification channels created');
      }
    } catch (e) {
      //logger.e('Failed to initialize notifications: $e');
      Toast.showToast('Notifications may not work. Please check permissions.');
    }
  }

  Future<void> initializeBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'geofence_background',
          initialNotificationTitle: 'Geofence Tracker',
          initialNotificationContent: 'Monitoring location in background',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onBackgroundServiceStart,
          onBackground: onIosBackground,
        ),
      );
      await service.startService();
      logger.i('Background service initialized and started');
    } catch (e) {
      logger.e('Failed to initialize background service: $e');
      Toast.showToast('Failed to start background service');
    }
  }

  @pragma('vm:entry-point')
  static void onBackgroundServiceStart(ServiceInstance service) async {
    logger.i('Background service started');
    try {
      if (Platform.isAndroid) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          logger.w('Notification permission not granted for background service');
          return;
        }
      }
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      if (service is AndroidServiceInstance) {
        await service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: 'Geofence Tracker',
          content: 'Monitoring location in background',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final geofenceList = prefs.getString('geofences') ?? '[]';
      final List<Geofence> geofences = (jsonDecode(geofenceList) as List).map((json) => Geofence.fromJson(json)).toList();

      Timer.periodic(Duration(seconds: 60), (timer) async {
        logger.i('Updating location in background');
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await _checkGeofencesInBackground(position, geofences);
        } catch (e) {
          logger.e('Background location update failed: $e');
        }
      });
    } catch (e) {
      logger.e('Error in background service start: $e');
    }
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    logger.i('iOS background service running');
    Timer(Duration(seconds: 60), () async {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final prefs = await SharedPreferences.getInstance();
        final geofenceList = prefs.getString('geofences') ?? '[]';
        final List<Geofence> geofences = (jsonDecode(geofenceList) as List).map((json) => Geofence.fromJson(json)).toList();
        await _checkGeofencesInBackground(position, geofences);
      } catch (e) {
       // logger.e('iOS background location update failed: $e');
      }
    });
    return true;
  }

  static Future<void> _checkGeofencesInBackground(Position position, List<Geofence> geofences) async {
    try {
      final updates = _checkGeofencesIsolate({'position': position, 'geofences': geofences});
      if (updates.isEmpty) {
        logger.i('No geofence status changes detected in background');
        return;
      }
      for (var update in updates) {
        final index = update['index'] as int;
        final status = update['status'] as String;
        final geofence = geofences[index];
        logger.i('Background geofence event: $status ${geofence.title}');
        await showNotification(
          geofence.title,
          '$status ${geofence.title} '
              'at (${geofence.latitude.toStringAsFixed(4)}, ${geofence.longitude.toStringAsFixed(4)})',
        );
        final prefs = await SharedPreferences.getInstance();
        final historyList = prefs.getString('history') ?? '[]';
        final List<LocationHistoryEntry> history = (jsonDecode(historyList) as List).map((json) => LocationHistoryEntry.fromJson(json)).toList();
        history.add(LocationHistoryEntry(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          status: status,
          title: geofence.title, // Add geofence title
        ));
        await prefs.setString('history', jsonEncode(history.map((h) => h.toJson()).toList()));
      }
    } catch (e) {
      logger.e('Error checking geofences in background: $e');
    }
  }

  static List<Map<String, dynamic>> _checkGeofencesIsolate(Map<String, dynamic> data) {
    try {
      final position = data['position'] as Position;
      final geofences = data['geofences'] as List<Geofence>;
      final updates = <Map<String, dynamic>>[];
      for (var i = 0; i < geofences.length; i++) {
        final geofence = geofences[i];
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          geofence.latitude,
          geofence.longitude,
        );
        bool isInside = distance <= geofence.radius;
        if (isInside != geofence.isInside) {
          String status = isInside ? 'Entered' : 'Exited';
          updates.add({
            'index': i,
            'status': status,
          });
        }
      }
      return updates;
    } catch (e) {
      logger.e('Error in geofence isolate: $e');
      return [];
    }
  }


  static Future<void> showNotification(String title, String body) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          logger.w('Notification permission not granted');
          return;
        }
      }
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'geofence_channel',
        'Geofence Notifications',
        channelDescription: 'Notifications for geofence entry and exit events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );
      await flutterLocalNotificationsPlugin.show(
        _notificationId++,
        title,
        body,
        platformChannelSpecifics,

      );
      logger.i('Notification shown: $title - $body');
    } catch (e) {
      logger.e('Failed to show notification: $e');
    }
  }

}