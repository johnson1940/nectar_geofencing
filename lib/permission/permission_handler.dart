import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helper/logger.dart';
import '../helper/toaster.dart';
import '../services/notification_service.dart';

Future<bool> requestGeofencePermissions(NotificationService notificationService) async {
  bool canStartService = true;

  try {
    // Step 1: Check Location Services
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      openAppSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Toast.showToast('Location services are required for tracking.');
        return false;
      }
    }

    // Step 2: Request Foreground Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Toast.showToast('Please allow location access.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        Toast.showToast('Location permission is required for tracking.');
        return false;
      }
    }

    if (Platform.isAndroid) {
      // Step 3: Request Background Location
      var status = await Permission.locationAlways.status;
      if (!status.isGranted) {
        status = await Permission.locationAlways.request();
        if (!status.isGranted) {
          openAppSettings();
          status = await Permission.locationAlways.status;
          if (!status.isGranted) {
            Toast.showToast('Background location access is required.');
            return false;
          }
        }
      }

      // Step 4: Request Notification Permission
      status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
        if (!status.isGranted) {
          openAppSettings();
          status = await Permission.notification.status;
          if (!status.isGranted) {
            Toast.showToast('Notifications are required for geofence alerts.');
            return false;
          }
        }
      }

      // Step 5: Request Battery Optimization Exception (Optional)
      status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        status = await Permission.ignoreBatteryOptimizations.request();
        if (!status.isGranted) {
          openAppSettings();
          // Optional: Proceed even if not granted
        }
      }
    }

    await notificationService.initializeBackgroundService();
    logger.i('All required permissions granted');
    return true;
  } catch (e) {
    logger.e('Failed to request permissions: $e');
    Toast.showToast('Failed to request permissions: $e');
    return false;
  }
}
