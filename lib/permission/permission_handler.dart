import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helper/logger.dart';
import '../helper/toaster.dart';
import '../services/notification_service.dart';

Future<bool> requestGeofencePermissions(NotificationService notificationService) async {
  try {
    /// Step 1: Ensure Location Services are Enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      openAppSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        Toast.showToast('Please enable location services to allow tracking.');
        return false;
      }
    }

    /// Step 2: Check Foreground Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Toast.showToast('Location access is required for tracking your movements.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      if (await Geolocator.checkPermission() == LocationPermission.deniedForever) {
        Toast.showToast('Please allow location access from app settings to continue.');
        return false;
      }
    }

    /// Android-specific permissions
    if (Platform.isAndroid) {
      /// Step 3: Background Location
      if (!await _checkAndRequestPermission(
          Permission.locationAlways,
          'To track location in the background, please allow "All the time" location access in settings.')) {
        return false;
      }

      /// Step 4: Notification Permission
      if (!await _checkAndRequestPermission(
          Permission.notification,
          'Enable notifications to receive geofence alerts and updates.')) {
        return false;
      }

      /// Step 5: Ignore Battery Optimizations (Optional)
      await _checkAndRequestPermission(
        Permission.ignoreBatteryOptimizations,
        'To ensure accurate tracking, consider disabling battery optimizations for this app.',
      );
    }

    /// Step 6: Initialize Service
    await notificationService.initializeBackgroundService();
    logger.i('All required permissions granted');
    return true;
  } catch (e) {
    logger.e('Failed to request permissions: $e');
    Toast.showToast('Something went wrong while requesting permissions.');
    return false;
  }
}

/// Utility method to check and request a specific permission
Future<bool> _checkAndRequestPermission(Permission permission, [String? failureMessage]) async {
  if (await permission.isGranted) return true;

  await permission.request();
  if (await permission.isGranted) return true;

  openAppSettings();
  if (await permission.isGranted) return true;

  if (failureMessage != null) {
    Toast.showToast(failureMessage);
  }
  return false;
}
