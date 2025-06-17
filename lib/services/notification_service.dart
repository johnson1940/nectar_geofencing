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
        throw Exception('Failed to initialize notifications');
      }
      if (Platform.isAndroid) {
        const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
          'locatr_background_channel',
          'locatr Background Service',
          description: 'Keeps the app running in the background to detect geofence events',
          importance: Importance.low,
        );
        const AndroidNotificationChannel geofenceChannel = AndroidNotificationChannel(
          'locatr_channel',
          'locatr Notifications',
          description: 'Alerts you when entering or exiting a geo-fenced area',
          importance: Importance.high,
        );
        final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(backgroundChannel);
        await androidPlugin?.createNotificationChannel(geofenceChannel);
      }
    } catch (e) {
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
          notificationChannelId: 'locatr_background_channel',
          initialNotificationTitle: 'Locatr',
          initialNotificationContent: 'Background location tracking enabled',
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
          title:   'Locatr',
          content: 'Background location tracking enabled',
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
    Timer(Duration(seconds: 30), () async {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final prefs = await SharedPreferences.getInstance();
        final geofenceList = prefs.getString('geofences') ?? '[]';
        final List<Geofence> geofences = (jsonDecode(geofenceList) as List).map((json) => Geofence.fromJson(json)).toList();
        await _checkGeofencesInBackground(position, geofences);
      } catch (e) {
        logger.i('Unable to track');
      }
    });
    return true;
  }

  static Future<void> _checkGeofencesInBackground(Position position, List<Geofence> geofences) async {
    try {
      final updates = detectGeofenceStatusChanges({'position': position, 'geofences': geofences});
      if (updates.isEmpty) {
        logger.i('No geofence status changes detected in background');
        return;
      }
      for (var update in updates) {
        final index = update['index'] as int;
        final status = update['status'] as String;
        final geofence = geofences[index];

        final prefs = await SharedPreferences.getInstance();
        final historyList = prefs.getString('history') ?? '[]';
        final List<LocationHistoryEntry> history = (jsonDecode(historyList) as List).map((json) => LocationHistoryEntry.fromJson(json)).toList();
        history.add(
            LocationHistoryEntry(
               timestamp: DateTime.now(),
               latitude: position.latitude,
               longitude: position.longitude,
               status: status,
               title: geofence.title, // Add geofence title
           )
        );
        await prefs.setString('history', jsonEncode(history.map((h) => h.toJson()).toList()));
      }
    } catch (e) {
       logger.i('Error : $e');
    }
  }


  static List<Map<String, dynamic>> detectGeofenceStatusChanges(Map<String, dynamic> data) {
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

      return [];
    }
  }


  static Future<void> showNotification(String title, String body) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          Toast.showToast('Notification Permission Not Enabled');
          return;
        }
      }
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'locatr_channel',
        'locatr Notifications',
        channelDescription: 'Notifications for geofence entry and exit events',
        importance: Importance.high,
        priority: Priority.high,
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
    } catch (e) {
      logger.e('Notification Error: $e');
    }
  }

}