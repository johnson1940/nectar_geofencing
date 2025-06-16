import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nectar_geofencing/controller/add_geo_fence_controller.dart';
import '../constants/color_constants.dart';
import '../controller/geo_fence_Controller.dart';
import '../globalWidgets/custom_text_field.dart';
import '../model/geo_fence_model.dart';
import 'add_geo_fence.dart';
import 'movement_history.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GeofenceController geofenceController = Get.find<GeofenceController>();
  final AddGeoFenceController addGeoFenceController = Get.find<AddGeoFenceController>();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return GetBuilder<GeofenceController>(
      initState: (_) {
        geofenceController.requestPermissions().then((_) => geofenceController.startLocationTracking());
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: _buildAppBar(screenSize),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return controller.geoFencesList.isEmpty
                ? _buildEmptyState(screenSize)
                : _buildGeofenceList(controller, screenSize);
          }),
        );
      },
    );
  }

  /// App Bar with Title and History Button
  AppBar _buildAppBar(Size screenSize) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConstants.secondaryColor,
      title: CustomTextWidget(
        text: 'GeoFence Dashboard',
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, size: 30, color: ColorConstants.secondaryColor),
          onPressed: () => Get.to(() => MovementHistoryScreen()),
        ),
        SizedBox(width: screenSize.width * 0.02),
      ],
    );
  }

  /// Widget to show when there is no data
  Widget _buildEmptyState(Size screenSize) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: ColorConstants.grey, size: 70),
            const SizedBox(height: 15),
            CustomTextWidget(
              text: "Looks like you haven't added any locations yet. Try adding one!",
              fontSize: 16,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of geo-fences
  Widget _buildGeofenceList(GeofenceController controller, Size screenSize) {
    return ListView.builder(
      padding: EdgeInsets.all(screenSize.width * 0.02),
      itemCount: controller.geoFencesList.length,
      itemBuilder: (context, index) {
        final geofence = controller.geoFencesList[index];
        return _buildGeofenceCard(geofence, index);
      },
    );
  }

  /// Card for each Geofence item
  Widget _buildGeofenceCard(Geofence geofence, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: geofence.title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: geofence.isInside ? Colors.green : ColorConstants.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    CustomTextWidget(
                      text: geofence.isInside ? "Inside" : "Outside",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: geofence.isInside ? Colors.green : ColorConstants.grey,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// --- Lat, Long, Radius
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Latitude", geofence.latitude.toStringAsFixed(4)),
                _buildInfoRow("Longitude", geofence.longitude.toStringAsFixed(4)),
                _buildInfoRow("Radius", "${geofence.radius} m"),
              ],
            ),

            const SizedBox(height: 10),

            /// --- Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _iconButton(
                  icon: Icons.edit,
                  tooltip: "Edit",
                  color: ColorConstants.primaryColor,
                  onTap: () => Get.to(() => AddGeofenceScreen(geofence: geofence, index: index)),
                ),
                const SizedBox(width: 12),
                _iconButton(
                  icon: Icons.delete,
                  tooltip: "Delete",
                  color: ColorConstants.red,
                  onTap: () => addGeoFenceController.deleteGeofence(index, geofence),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Row for Label & Value
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: CustomTextWidget(
              text: "$label:",
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorConstants.blackColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CustomTextWidget(
              text: value,
              fontSize: 13,
              color: ColorConstants.blackColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Circle Icon Buttons
  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
