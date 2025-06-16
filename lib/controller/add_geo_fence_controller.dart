import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nectar_geofencing/helper/toaster.dart';
import '../helper/logger.dart';
import '../model/geo_fence_model.dart';
import 'geo_fence_Controller.dart';

class AddGeoFenceController extends GetxController {

  final Rx<LatLng?> selectedLocation = Rxn<LatLng>();

  final Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();

  final Rx<LatLng> initialPosition = const LatLng(0.0, 0.0).obs;

  final titleController = TextEditingController();

  final radiusController = TextEditingController();

  final GeofenceController geofenceController = Get.find<GeofenceController>();


  /// Adds a new geofence to the list and persists it.
  Future<void> saveNewGeofence(Geofence geofence) async {
    try {
      geofenceController.geoFencesList.add(geofence);
      await geofenceController.saveGeoFencesToStorage();
      Toast.showToast('Successfully added "${geofence.title}"!');
    } catch (e) {
      Toast.showToast('Failed to store!');
    }
  }

  /// Updates an existing geofence at the specified index and saves the changes.
  Future<void> updateGeofence(int index, Geofence geofence) async {
    try {
      geofenceController.geoFencesList[index] = geofence;
      await geofenceController.saveGeoFencesToStorage();
      Toast.showToast('Location "${geofence.title}" updated successfully!');
    } catch (e) {
      Toast.showToast('Failed to update!');
    }
  }

  /// Removes a geofence at the specified index and persists the updated list.
  Future<void> deleteGeofence(int index, Geofence geofence) async {
    try {
      geofenceController.geoFencesList[index] = geofence;
      geofenceController.geoFencesList.removeAt(index);
      await geofenceController.saveGeoFencesToStorage();
      Toast.showToast('Location "${geofence.title}" deleted successfully!');
    } catch (e) {
      logger.e('Failed to delete geofence: $e');
    }
  }


  Future<void> getInitialPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      initialPosition.value = LatLng(position.latitude, position.longitude);
      if (selectedLocation.value == null) {
        selectedLocation.value = initialPosition.value;
      }
      logger.i('Initial position: ${initialPosition.value}');
      googleMapController.value?.animateCamera(
        CameraUpdate.newLatLng(initialPosition.value),
      );
    } catch (e) {
      Toast.showToast('Failed to Fetch location');
      initialPosition.value = const LatLng(11.005064, 76.950846);
      selectedLocation.value ??= initialPosition.value;
    }
  }


}