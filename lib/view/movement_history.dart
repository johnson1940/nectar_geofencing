import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nectar_geofencing/helper/toaster.dart';
import '../constants/color_constants.dart';
import '../controller/geo_fence_Controller.dart';
import '../controller/geo_history_controller.dart';
import '../globalWidgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class MovementHistoryScreen extends StatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  final GeofenceController geofenceController = Get.find<GeofenceController>();
  final MovementHistoryController movementHistoryController = Get.find<MovementHistoryController>();

  @override
  void initState() {
    super.initState();
    movementHistoryController.renderHistoricalRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: ColorConstants.secondaryColor,
        title: CustomTextWidget(
          text: 'Movement History',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Obx(() {
      return GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: CameraPosition(
          target: movementHistoryController.initialMapPosition.value,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          movementHistoryController.googleMapController.value = controller;
        },
        polylines: movementHistoryController.routePolylines.values.toSet(),
        markers: movementHistoryController.markers.values.toSet(),
        circles: _buildGeofenceCircles(),
      );
    });
  }

  Set<Circle> _buildGeofenceCircles() {
    if (geofenceController.geoFencesList.isEmpty) return {};
    return geofenceController.geoFencesList.map((geofence) {
      return Circle(
        circleId: CircleId(geofence.title),
        center: LatLng(geofence.latitude, geofence.longitude),
        radius: geofence.radius.clamp(10, 1000),
        fillColor: ColorConstants.primaryColor.withOpacity(0.3),
        strokeColor: ColorConstants.secondaryColor,
        strokeWidth: 2,
      );
    }).toSet();
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.secondaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (geofenceController.locationHistory.isEmpty) {
                    return Center(
                      child: CustomTextWidget(
                        text: "Looks like there's nothing here yet",
                        color: ColorConstants.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: geofenceController.locationHistory.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = geofenceController.locationHistory.length - 1 - index;
                      final entry = geofenceController.locationHistory[reversedIndex];
                      final formattedTime = DateFormat('hh:mm a').format(entry.timestamp);
                      final formattedDate = DateFormat('MMM dd, yyyy').format(entry.timestamp);

                      return Dismissible(
                        key: Key(entry.timestamp.toIso8601String()), // Unique key for each item
                        direction: DismissDirection.endToStart, // Swipe right to left
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          movementHistoryController.deleteHistory(entry);
                          Toast.showToast('History deleted');
                        },
                        child: Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: CustomTextWidget(
                                        text: entry.title ?? "Unknown Geofence",
                                        color: ColorConstants.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: entry.status.toLowerCase() == "entered"
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: entry.status.toLowerCase() == "entered"
                                              ? ColorConstants.green
                                              : ColorConstants.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: CustomTextWidget(
                                        text: entry.status.toUpperCase(),
                                        color: entry.status.toLowerCase() == "entered"
                                            ? ColorConstants.green
                                            : ColorConstants.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CustomTextWidget(
                                  text: '$formattedDate | $formattedTime',
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                                const SizedBox(height: 4),
                                CustomTextWidget(
                                  text:
                                  'Lat: ${entry.latitude.toStringAsFixed(4)}, Long: ${entry.longitude.toStringAsFixed(4)}',
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
