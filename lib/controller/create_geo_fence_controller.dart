import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nectar_geofencing/helper/toaster.dart';
import '../helper/logger.dart';

class AddGeoFenceController extends GetxController{

  final Rx<LatLng?> selectedLocation = Rxn<LatLng>();

  final Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();

  final Rx<LatLng> initialPosition = const LatLng(0.0, 0.0).obs;

  final titleController = TextEditingController();

  final radiusController = TextEditingController();

  ///Initial Position
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