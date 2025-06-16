import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' as location;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/logger.dart';
import '../helper/toaster.dart';
import '../model/geo_fence_model.dart';
import '../model/location_history.dart';
import '../permission/permission_handler.dart';
import '../services/notification_service.dart';

@pragma('vm:entry-point')
class GeofenceController extends GetxController {
  var geoFencesList = <Geofence>[].obs; // List of saved geofences
  var locationHistory = <LocationHistoryEntry>[].obs; // List of recorded location history
  var currentPosition = Rxn<Position>(); // Current position of the device
  var currentLatitude = ''.obs;
  var currentLongitude = ''.obs;
  var isTracking = false.obs; // Flag to show whether tracking is active
  Timer? _locationTimer; // Timer for periodic location updates
  StreamSubscription<Position>? _positionStream; // Stream to listen to live location
  Timer? _permissionRecheckTimer; // Timer to recheck permissions

  late final NotificationService notificationService; // For triggering notifications

  /// Requests permissions needed for geofence tracking.
  /// If granted, starts location tracking.
  Future<void> requestPermissions() async {
    bool granted = await requestGeofencePermissions(notificationService);
    if (granted) {
      startLocationTracking();
    } else {
      Toast.showToast('Please grant all permissions to enable tracking.');
    }
  }

  /// Fetches and updates the current device location.
  Future<void> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentLatitude.value = position.latitude.toString();
      currentLongitude.value = position.longitude.toString();
      currentPosition.value = position;
      logger.i('Current location: Lat: ${currentLatitude.value}, Long: ${currentLongitude.value}');
    } catch (e) {
      logger.e('Failed to get current location: $e');
      Toast.showToast('Failed to get location: $e');
    }
  }

  /// Loads geo-fences from SharedPreferences and populates `geoFencesList`.
  Future<void> loadGeoFencesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofenceList = prefs.getString('geofences') ?? '[]';
      final List<dynamic> jsonList = jsonDecode(geofenceList);
      geoFencesList.assignAll(jsonList.map((json) => Geofence.fromJson(json)).toList());
      logger.i('Geo-fences Items: ${geoFencesList.length}');
    } catch (e) {
      logger.e('Failed to load:  $e');
    }
  }

  /// Loads the location history from SharedPreferences and assigns it to `locationHistory`.
  Future<void> loadLocationHistoryFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getString('history') ?? '[]';
      final List<dynamic> jsonList = jsonDecode(historyList);
      final List<LocationHistoryEntry> loadedHistory = jsonList.map((json) => LocationHistoryEntry.fromJson(json)).toList();

      // Migrates old entries missing `title` field by finding the closest geofence.
      for (var entry in loadedHistory) {
        if (entry.title == null) {
          Geofence? closestGeofence;
          double minDistance = double.infinity;
          for (var geofence in geoFencesList) {
            double distance = Geolocator.distanceBetween(
              entry.latitude,
              entry.longitude,
              geofence.latitude,
              geofence.longitude,
            );
            if (distance < minDistance && distance <= geofence.radius) {
              minDistance = distance;
              closestGeofence = geofence;
            }
          }
          entry.title = closestGeofence?.title ?? 'Unknown Geofence';
        }
      }

      locationHistory.assignAll(loadedHistory);
      logger.i('History loaded: ${locationHistory.length}');
    } catch (e) {
      logger.e('Failed to load history: $e');
    }
  }

  /// Saves the list of geo-fences to SharedPreferences.
  Future<void> saveGeoFencesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = geoFencesList.map((geofence) => geofence.toJson()).toList();
      await prefs.setString('geofences', jsonEncode(jsonList));
      logger.i('Saved Successful');
    } catch (e) {
      logger.e('Failed to save geofences: $e');
    }
  }

  /// Saves the location history to SharedPreferences.
  Future<void> saveLocationHistoryToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = locationHistory.map((entry) => entry.toJson()).toList();
      await prefs.setString('history', jsonEncode(jsonList));
      logger.i('History saved');
    } catch (e) {
      logger.e('Failed to save history: $e');
    }
  }

  /// Adds a new geofence to the list and persists it.
  Future<void> saveNewGeofence(Geofence geofence) async {
    try {
      geoFencesList.add(geofence);
      await saveGeoFencesToStorage();
      logger.i('Geofence added: ${geofence.title}');
    } catch (e) {
      logger.e('Failed to add geofence: $e');
    }
  }

  /// Updates an existing geofence at the specified index and saves the changes.
  Future<void> updateGeofence(int index, Geofence geofence) async {
    try {
      geoFencesList[index] = geofence;
      await saveGeoFencesToStorage();
      logger.i('Geofence updated at index: $index');
    } catch (e) {
      logger.e('Failed to update geofence: $e');
    }
  }

  /// Removes a geofence at the specified index and persists the updated list.
  Future<void> deleteGeofence(int index) async {
    try {
      geoFencesList.removeAt(index);
      await saveGeoFencesToStorage();
      logger.i('Geofence deleted at index: $index');
    } catch (e) {
      logger.e('Failed to delete geofence: $e');
    }
  }

  /// Starts location tracking:
  /// - Requests permission if needed.
  /// - Starts a periodic timer for updating location every 60 seconds.
  /// - Starts listening to position stream for real-time updates.
  Future<void> startLocationTracking() async {
    try {
      bool isPermissionGranted = await _checkLocationPermission();
      if (!isPermissionGranted) {
        logger.w('Location permission not granted');
        return;
      }

      _locationTimer?.cancel();
      _positionStream?.cancel();

      _locationTimer = Timer.periodic(Duration(seconds: 60), (_) async {
        await updateLocation();
      });

      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(
            (Position position) {
          currentPosition.value = position;
          checkGeofences(position);
        },
        onError: (e) {
          logger.e('Location stream error: $e');
          Toast.showToast('Location access denied or unavailable: $e');
        },
      );

      isTracking.value = true;
      logger.i('Location tracking started');
    } catch (e) {
      logger.e('Failed to start location tracking: $e');
      Toast.showToast('Failed to start location tracking: $e');
    }
  }

  /// Checks for required location permission and requests it if not yet granted.
  Future<bool> _checkLocationPermission() async {
    try {
      final locationService = location.Location();

      bool serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) return false;
      }

      final status = await Permission.location.status;

      if (status.isGranted) return true;

      if (status.isDenied) {
        final newStatus = await Permission.location.request();
        if (newStatus.isGranted) return true;
        if (newStatus.isPermanentlyDenied) {
          openAppSettings();
          Toast.showToast('Please enable location permission in settings.');
        }
        return false;
      }

      if (status.isPermanentlyDenied) {
        openAppSettings();
        Toast.showToast('Please enable location permission in settings.');
      }

      return false;
    } catch (e) {
      logger.e("Permission check error: $e");
      return false;
    }
  }

  /// Updates the current position manually (used by periodic timer) and checks geofences.
  Future<void> updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentPosition.value = position;
      checkGeofences(position);
    } catch (e) {
      logger.e('Failed to update location: $e');
      Toast.showToast('Failed to get location: $e');
    }
  }

  /// Verifies geofence boundaries for the provided [position].
  /// Sends notifications when entering/exiting geofences.
  Future<void> checkGeofences(Position position) async {
    try {
      final result = await compute(_checkGeofencesIsolate, {
        'position': position,
        'geofences': geoFencesList.toList(),
      });

      if (result.isEmpty) return;

      for (var update in result) {
        final index = update['index'] as int;
        final status = update['status'] as String;
        final geofence = geoFencesList[index];
        geofence.isInside = status == 'Entered';
        geoFencesList[index] = geofence;

        await NotificationService.showNotification(
          geofence.title,
          '$status ${geofence.title} at (${geofence.latitude.toStringAsFixed(4)}, ${geofence.longitude.toStringAsFixed(4)})',
        );

        addHistory(LocationHistoryEntry(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          status: status,
          title: geofence.title,
        ));
      }
    } catch (e) {
      logger.e('Error checking geofences: $e');
      Toast.showToast('Failed to check geofences: $e');
    }
  }

  /// Runs geofence checking logic in a background isolate.
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
          updates.add({'index': i, 'status': isInside ? 'Entered' : 'Exited'});
        }
      }
      return updates;
    } catch (e) {
      logger.e('Error in geofence isolate: $e');
      return [];
    }
  }

  /// Adds an entry to the location history and saves it.
  Future<void> addHistory(LocationHistoryEntry entry) async {
    try {
      locationHistory.add(entry);
      await saveLocationHistoryToStorage();
      logger.i('History entry added: ${entry.status} for ${entry.title ?? "unknown"}');
    } catch (e) {
      logger.e('Failed to add history: $e');
    }
  }

  /// Called when the controller is initialized.
  /// Loads geofences and history, requests permissions, and initializes notifications.
  @override
  void onInit() {
    super.onInit();
    notificationService = NotificationService();
    logger.i('GeofenceController initialized');

    notificationService.initializeNotifications().then((_) {
      loadGeoFencesFromStorage();
      loadLocationHistoryFromStorage();
      requestPermissions();
    }).catchError((e) {
      logger.e('Error initializing notifications: $e');
      Toast.showToast('Notification initialization failed');
    });
  }

  /// Called when the controller is fully initialized.
  /// Starts a short timer to request permissions again (helps with race conditions in some platforms).
  @override
  void onReady() {
    super.onReady();
    _permissionRecheckTimer?.cancel();
    _permissionRecheckTimer = Timer(const Duration(seconds: 2), () {
      requestPermissions();
    });
  }

  /// Called when the controller is closed.
  /// Cleans up timers and streams to avoid memory leaks.
  @override
  void onClose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    _permissionRecheckTimer?.cancel();
    logger.i('GeofenceController closed');
    super.onClose();
  }
}
