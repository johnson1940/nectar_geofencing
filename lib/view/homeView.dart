import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/color_constants.dart';
import '../controller/geo_fence_Controller.dart';
import '../globalWidgets/custom_text_field.dart';
import '../model/geo_fence_model.dart';
import 'addGeofenceScreenView.dart';
import 'historyView.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GeofenceController geofenceController = Get.find<GeofenceController>();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return GetBuilder<GeofenceController>(
      initState: (_) {
        geofenceController.requestPermissions().then(
              (_) => geofenceController.startLocationTracking(),
        );
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: _buildAppBar(screenSize),
          body: Obx(() {
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
          onPressed: () => Get.to(() => HistoryScreen()),
        ),
        SizedBox(width: screenSize.width * 0.02),
      ],
    );
  }

  /// Widget to show when there is no data
  Widget _buildEmptyState(Size screenSize) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: screenSize.height * 0.06),
        child: CustomTextWidget(
          text: 'No data at this moment',
          color: ColorConstants.blackColor,
          fontSize: 16,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the list of geofences
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
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- Title and Status Dot
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: geofence.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: geofence.isInside ? Colors.green : ColorConstants.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      geofence.isInside ? "Inside" : "Outside",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: geofence.isInside ? Colors.green : ColorConstants.grey,
                      ),
                    )
                  ],
                )
              ],
            ),

            const SizedBox(height: 14),

            /// --- Lat, Long, Radius
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Latitude", geofence.latitude.toStringAsFixed(4)),
                const SizedBox(height: 4),
                _buildInfoRow("Longitude", geofence.longitude.toStringAsFixed(4)),
                const SizedBox(height: 4),
                _buildInfoRow("Radius", "${geofence.radius} m"),
              ],
            ),

            const SizedBox(height: 16),

            /// --- Edit & Delete Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _iconButton(
                  icon: Icons.edit,
                  tooltip: "Edit",
                  color: ColorConstants.primaryColor,
                  onTap: () => Get.to(() => AddGeofenceScreen(geofence: geofence, index: index)),
                ),
                const SizedBox(width: 16),
                _iconButton(
                  icon: Icons.delete,
                  tooltip: "Delete",
                  color: Colors.red,
                  onTap: () => geofenceController.deleteGeofence(index),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: ColorConstants.blackColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: ColorConstants.blackColor,
            ),
          ),
        ),
      ],
    );
  }


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
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
      ),
    );
  }

}
