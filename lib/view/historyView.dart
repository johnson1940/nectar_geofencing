import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/color_constants.dart';
import '../controller/geo_fence_Controller.dart';
import '../controller/geo_history_controller.dart';
import '../globalWidgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final GeofenceController geofenceController = Get.find<GeofenceController>();
  final GeoFenceHistoryController geoFenceHistoryController = Get.find<GeoFenceHistoryController>();

  HistoryScreen({super.key});

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
          target: geoFenceHistoryController.mapPosition.value,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          geoFenceHistoryController.googleMapController.value = controller;
        },
        polylines: geoFenceHistoryController.polyLines.values.toSet(),
        markers: geoFenceHistoryController.markers.values.toSet(),
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

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row with Title (left) and Status (right)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.title ?? "Unknown Geofence",
                                      style: TextStyle(
                                        color: ColorConstants.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
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
                                            ? Colors.green
                                            : Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      entry.status.toUpperCase(),
                                      style: TextStyle(
                                        color: entry.status.toLowerCase() == "entered"
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Date, Time
                              Text(
                                '$formattedDate | $formattedTime',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              // Coordinates
                              Text(
                                'Lat: ${entry.latitude.toStringAsFixed(4)}, Long: ${entry.longitude.toStringAsFixed(4)}',
                                style: TextStyle(color: Colors.grey[800], fontSize: 13),
                              ),
                            ],
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
