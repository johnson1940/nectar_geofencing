import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../helper/logger.dart';
import '../model/location_history.dart';
import 'geo_fence_Controller.dart';

/// Controller responsible for handling historical movement data,
/// rendering polylines and markers on Google Maps, and managing the map's state.
class MovementHistoryController extends GetxController {
  /// Default initial position of the map (Coimbatore location here)
  final Rx<LatLng> initialMapPosition = const LatLng(11.005064, 76.950846).obs;

  /// Google Maps controller instance
  final Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();

  // Stores all polylines displayed on the map
  final RxMap<PolylineId, Polyline> routePolylines = <PolylineId, Polyline>{}.obs;

  // Stores all markers displayed on the map
  final RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  // Reference to GeofenceController to access current position & location history
  final GeofenceController geofenceController = Get.find<GeofenceController>();

  // Stores colors assigned to each geofence for consistent visuals
  final Map<String, Color> geofenceColors = {};

  // Default color used for polylines and markers
  final Color polylineColor = Colors.red;

  // Cache for route coordinates to avoid recomputation or redundant reads
  final Map<String, List<LatLng>> _routeCoordinateCache = {};

  // SharedPreferences instance for caching route data locally
  SharedPreferences? _prefs;

  /// Lifecycle method - Initializes preferences, determines map position, and renders routes.
  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    await _determineInitialMapPosition();
    await renderHistoricalRoutes();
  }

  /// Lifecycle method - Disposes of map controller when no longer needed.
  @override
  void onClose() {
    googleMapController.value?.dispose();
    super.onClose();
  }


  /// Determines the initial camera position for the map.
  /// Uses current position, last recorded location, or falls back to default.
  Future<void> _determineInitialMapPosition() async {
    try {
      initialMapPosition.value = await _getSuitableInitialPosition();
      await _focusMapOnCoordinates([]);
    } catch (e) {
      logger.e('Error determining initial map position: $e');
    }
  }

  /// Clears existing polylines and markers, regenerates them from stored location history.
  Future<void> renderHistoricalRoutes() async {
    routePolylines.clear();
    markers.clear();

    try {
      final groupedHistory = _groupLocationHistory();

      groupedHistory.forEach((title, entries) async {
        final color = geofenceColors[title] = polylineColor;

        _addRouteMarkers(entries, title, color);

        final coordinates = await _getRouteCoordinates(entries, title);
        if (coordinates.isNotEmpty) {
          _addPolylineToMap(coordinates, title, color);
        }
      });

      await _focusMapOnCoordinates(routePolylines.values.expand((p) => p.points).toList());
    } catch (e) {
      logger.e('Error loading history polylines: $e');
    }
      update();
  }

  /// Chooses the most relevant initial map position:
  /// 1. Current GPS position if available.
  /// 2. Last recorded location from history.
  /// 3. Fallback to the hardcoded default position.
  Future<LatLng> _getSuitableInitialPosition() async {
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
        : initialMapPosition.value;
  }

  /// Groups the location history by geofence title for easier route rendering.
  Map<String, List<LocationHistoryEntry>> _groupLocationHistory() {
    final grouped = <String, List<LocationHistoryEntry>>{};

    for (var entry in geofenceController.locationHistory) {
      grouped.putIfAbsent(entry.title ?? 'Unknown_${entry.hashCode}', () => []).add(entry);
    }

    return grouped;
  }

  /// Retrieves coordinates for a batch of location history entries.
  /// Utilizes in-memory and SharedPreferences caching for better performance.
  Future<List<LatLng>> _getRouteCoordinates(List<LocationHistoryEntry> batch, String geofenceTitle) async {
    if (batch.length < 2) return [];

    final cacheKey = batch.map((e) => '${e.latitude},${e.longitude}').join('|');
    if (_routeCoordinateCache.containsKey(cacheKey)) return _routeCoordinateCache[cacheKey]!;

    final cachedData = _prefs?.getString('polyline_$cacheKey');
    if (cachedData != null) {
      final cachedCoordinates = (jsonDecode(cachedData) as List<dynamic>)
          .map((e) => LatLng(e['latitude'], e['longitude']))
          .toList();
      _routeCoordinateCache[cacheKey] = cachedCoordinates;
      return cachedCoordinates;
    }

    final coordinates = batch.map((e) => LatLng(e.latitude, e.longitude)).toList();

    _routeCoordinateCache[cacheKey] = coordinates;
    await _prefs?.setString('polyline_$cacheKey', jsonEncode(coordinates
        .map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
        .toList()));

    return coordinates;
  }

  /// Adds a series of markers to the map for the provided route entries.
  void _addRouteMarkers(List<LocationHistoryEntry> entries, String title, Color color) {
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

  /// Adds a polyline to the map for visualizing the path between points.
  void _addPolylineToMap(List<LatLng> coordinates, String title, Color color) {
    final id = PolylineId('poly_$title');
    routePolylines[id] = Polyline(
      polylineId: id,
      color: color,
      points: coordinates,
      width: 10,
      visible: true,
      geodesic: true,
    );
  }

  /// Adjusts the map's camera view to fit all provided coordinates into the viewport.
  Future<void> _focusMapOnCoordinates(List<LatLng> coordinates) async {
    final controller = googleMapController.value;
    if (controller == null || coordinates.isEmpty) return;

    final bounds = _calculateCoordinateBounds(coordinates);
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  /// Calculates the bounding box (LatLngBounds) to cover all specified coordinates.
  LatLngBounds _calculateCoordinateBounds(List<LatLng> coordinates) {
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

  void deleteHistory(LocationHistoryEntry entry) {
    geofenceController.locationHistory.remove(entry);
  }
}
