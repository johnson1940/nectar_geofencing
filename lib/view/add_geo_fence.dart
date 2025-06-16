import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../constants/color_constants.dart';
import '../controller/add_geo_fence_controller.dart';
import '../controller/geo_fence_Controller.dart';
import '../globalWidgets/custom_text_field.dart';
import '../model/geo_fence_model.dart';

class AddGeofenceScreen extends StatelessWidget {
  final Geofence? geofence;
  final int? index;

  AddGeofenceScreen({super.key, this.geofence, this.index});

  final _formKey = GlobalKey<FormState>();

  final AddGeoFenceController addGeoFenceController = Get.find();
  final GeofenceController geofenceController = Get.find();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return GetBuilder<AddGeoFenceController>(
      initState: (_) => _initializeControllers(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: _buildAppBar(screenSize),
          body: _buildBody(screenSize, controller),
          bottomNavigationBar: _buildSubmitButton(screenSize, controller),
        );

      },
    );
  }

  void _initializeControllers() {
    addGeoFenceController.titleController.text = geofence?.title ?? '';
    addGeoFenceController.radiusController.text = geofence?.radius.toString() ?? '';
    addGeoFenceController.selectedLocation.value = geofence != null
        ? LatLng(geofence!.latitude, geofence!.longitude)
        : null;

    geofenceController.requestPermissions().then((_) {
      geofenceController.startLocationTracking();
    });

    addGeoFenceController.getInitialPosition();
  }

  PreferredSizeWidget _buildAppBar(Size screenSize) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConstants.secondaryColor,
      title: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back_ios, color: ColorConstants.blackColor, size: 26),
          ),
          SizedBox(width: screenSize.width * 0.04),
          CustomTextWidget(
            text: geofence == null ? 'Add Geofence' : 'Edit Geofence',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Size screenSize, AddGeoFenceController controller) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenSize.height * 0.01),
              _buildTitleInput(controller),
              SizedBox(height: screenSize.height * 0.04),
              _buildRadiusInput(controller),
              SizedBox(height: screenSize.height * 0.04),
              _buildTextFieldLocation(),
              SizedBox(height: screenSize.height * 0.01),
              _buildMap(screenSize, controller),
            ],
          ),

        ),
      ),
    );
  }


  Widget _buildTitleInput(AddGeoFenceController controller) {
    return TextFormField(
      controller: controller.titleController,
      cursorColor: ColorConstants.blackColor,
      style: TextStyle(
        color: ColorConstants.blackColor,
        fontSize: 12,
      ),
      decoration: _buildInputDecoration('Title'),
      validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
    );
  }

  Widget _buildTextFieldLocation() {
    return CustomTextWidget(
      text: 'Choose Location',
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
  }

  Widget _buildMap(Size screenSize, AddGeoFenceController controller) {
    return SizedBox(
      height: screenSize.height * 0.4,
      child: Obx(() {
        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ColorConstants.grey, width: 0.3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GoogleMap(
              buildingsEnabled: true,
              compassEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: true,
              initialCameraPosition: CameraPosition(
                target: controller.initialPosition.value,
                zoom: 15,
              ),
              onMapCreated: (mapController) {
                controller.googleMapController.value = mapController;
                if (controller.selectedLocation.value != null) {
                  mapController.animateCamera(
                    CameraUpdate.newLatLng(controller.selectedLocation.value!),
                  );
                }
              },
              onTap: (LatLng location) {
                controller.selectedLocation.value = location;
              },
              markers: controller.selectedLocation.value != null
                  ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: controller.selectedLocation.value!,
                ),
              }
                  : {},
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRadiusInput(AddGeoFenceController controller) {
    return TextFormField(
      controller: controller.radiusController,
      keyboardType: TextInputType.number,
      cursorColor: ColorConstants.primaryColor,
      style: TextStyle(
        color: ColorConstants.blackColor,
        fontSize: 12,
      ),
      decoration: _buildInputDecoration('Enter the radius (meters)'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a radius';
        if (double.tryParse(value) == null) return 'Please enter a valid number';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(Size screenSize, AddGeoFenceController controller) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16),
        child: SizedBox(
          width: screenSize.width,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,  // Button background color
              foregroundColor: ColorConstants.secondaryColor, // Text/Icon color
              padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            onPressed: () {
              if (_formKey.currentState!.validate() && controller.selectedLocation.value != null) {
                final newGeofence = Geofence(
                  title: controller.titleController.text,
                  latitude: controller.selectedLocation.value!.latitude,
                  longitude: controller.selectedLocation.value!.longitude,
                  radius: double.parse(controller.radiusController.text),
                );

                if (geofence == null) {
                  addGeoFenceController.saveNewGeofence(newGeofence);
                } else {
                  addGeoFenceController.updateGeofence(index!, newGeofence);
                }

                Get.back();
              } else if (controller.selectedLocation.value == null) {
                Get.snackbar('Error', 'Please select a location on the map');
              }
            },
            child: Text(
              geofence == null ? 'Create' : 'Update',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }


  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: ColorConstants.blackColor,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7.0),
        borderSide: const BorderSide(color: ColorConstants.lightGrey, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7.0),
        borderSide: BorderSide(color: ColorConstants.lightGrey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7.0),
        borderSide: BorderSide(color: ColorConstants.lightGrey, width: 1.0),
      ),
    );
  }
}
