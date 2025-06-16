import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../helper/logger.dart';
import '../model/location_history.dart';
import 'geo_fence_Controller.dart';

class MovementHistoryController extends GetxController {

  final Rx<LatLng> mapPosition = const LatLng(11.005064, 76.950846).obs;

  final Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();

  final RxBool isMapLoading = true.obs;

  final RxBool isPolylineLoading = true.obs;

  final RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;

  final RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  final GeofenceController geofenceController = Get.find<GeofenceController>();

  final Map<String, Color> geofenceColors = {};

  final Color polylineColor = Colors.red;

  final Map<String, List<LatLng>> _polylineCache = {};

  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    await initializeMapPosition();
    await renderHistoricalRoutes();
  }

  @override
  void onClose() {
    googleMapController.value?.dispose();
    super.onClose();
  }

  Future<void> initializeMapPosition() async {
    try {
      mapPosition.value = await _getInitialPosition();
      await _animateCameraToCoordinates([]);
    } catch (e) {
      logger.e('Error : $e');
    } finally {
      isMapLoading.value = false;
    }
  }

  Future<void> renderHistoricalRoutes({int limit = 100}) async {
    isPolylineLoading.value = true;
    polyLines.clear();
    markers.clear();

    try {
      final groupedHistory = _groupHistoryByGeofence(limit);

      groupedHistory.forEach((title, entries) async {
        final color = geofenceColors[title] = polylineColor;
        for (var title in groupedHistory.keys) {
          geofenceColors[title] = polylineColor; // or any color you prefer
        }

        _addMarkers(entries, title, color);

        final coordinates = await _getBatchRouteCoordinates(entries, title);
        if (coordinates.isNotEmpty) {
          _addPolyline(coordinates, title, color);
        }
      });

      await _animateCameraToCoordinates(polyLines.values.expand((p) => p.points).toList());
    } catch (e) {
      logger.e('Error loading history poly-lines: $e');
    } finally {
      isPolylineLoading.value = false;
      update();
    }
  }

  /// Determines the most appropriate initial position for the map
  Future<LatLng> _getInitialPosition() async {
    final position = geofenceController.currentPosition.value;

    if (position != null) return LatLng(position.latitude, position.longitude);

    if (geofenceController.locationHistory.isNotEmpty) {
      final last = geofenceController.locationHistory.last;
      return LatLng(last.latitude, last.longitude);
    }

    await geofenceController.getCurrentLocation();
    final updatedPosition = geofenceController.currentPosition.value;
    return updatedPosition != null
        ? LatLng(updatedPosition.latitude, updatedPosition.longitude)
        : mapPosition.value;
  }

  /// Groups location history entries by geofence title
  Map<String, List<LocationHistoryEntry>> _groupHistoryByGeofence(int limit) {
    final grouped = <String, List<LocationHistoryEntry>>{};

    for (var entry in geofenceController.locationHistory.take(limit)) {
      grouped.putIfAbsent(entry.title ?? 'Unknown_${entry.hashCode}', () => []).add(entry);
    }

    return grouped;
  }

  /// Retrieves route coordinates for a batch, utilizing cache or shared preferences if available
  Future<List<LatLng>> _getBatchRouteCoordinates(List<LocationHistoryEntry> batch, String geofenceTitle) async {
    if (batch.length < 2) return [];

    final cacheKey = batch.map((e) => '${e.latitude},${e.longitude}').join('|');
    if (_polylineCache.containsKey(cacheKey)) return _polylineCache[cacheKey]!;

    final cachedData = _prefs?.getString('polyline_$cacheKey');
    if (cachedData != null) {
      final cachedCoordinates = (jsonDecode(cachedData) as List<dynamic>)
          .map((e) => LatLng(e['latitude'], e['longitude']))
          .toList();
      _polylineCache[cacheKey] = cachedCoordinates;
      return cachedCoordinates;
    }

    final coordinates = batch.map((e) => LatLng(e.latitude, e.longitude)).toList();

    _polylineCache[cacheKey] = coordinates;
    await _prefs?.setString('polyline_$cacheKey', jsonEncode(coordinates
        .map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
        .toList()));

    return coordinates;
  }

  /// Adds markers to map for each point in the route
  void _addMarkers(List<LocationHistoryEntry> entries, String title, Color color) {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final markerId = MarkerId('marker_${title}_$i');
      final marker = Marker(
        markerId: markerId,
        position: LatLng(entry.latitude, entry.longitude),
        infoWindow: InfoWindow(
          title: title,
          snippet: '${entry.status} at ${DateFormat('hh:mm a, MMM dd').format(entry.timestamp)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(HSVColor.fromColor(color).hue),
      );
      markers[markerId] = marker;
    }
  }

  /// Adds a single polyline to the map
  void _addPolyline(List<LatLng> coordinates, String title, Color color) {
    final id = PolylineId('poly_$title');
    polyLines[id] = Polyline(
      polylineId: id,
      color: color,
      points: coordinates,
      width: 10,
      visible: true,
      geodesic: true,
    );
  }

  /// Moves the camera to show all coordinates in view
  Future<void> _animateCameraToCoordinates(List<LatLng> coordinates) async {
    final controller = googleMapController.value;
    if (controller == null || coordinates.isEmpty) return;

    final bounds = _calculateBounds(coordinates);
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  /// Calculates the bounding box for a list of coordinates
  LatLngBounds _calculateBounds(List<LatLng> coordinates) {
    double? minLat, maxLat, minLng, maxLng;

    for (var point in coordinates) {
      minLat = minLat == null ? point.latitude : (point.latitude < minLat ? point.latitude : minLat);
      maxLat = maxLat == null ? point.latitude : (point.latitude > maxLat ? point.latitude : maxLat);
      minLng = minLng == null ? point.longitude : (point.longitude < minLng ? point.longitude : minLng);
      maxLng = maxLng == null ? point.longitude : (point.longitude > maxLng ? point.longitude : maxLng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}
