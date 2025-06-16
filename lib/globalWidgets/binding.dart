import 'package:get/get.dart';
import '../controller/create_geo_fence_controller.dart';
import '../controller/geo_fence_Controller.dart';
import '../controller/geo_history_controller.dart';

class GlobalBinding extends Bindings {

  @override
  void dependencies() {
    Get.lazyPut(()=>GeofenceController(),fenix:true);
    Get.lazyPut(()=>AddGeoFenceController(),fenix:true);
    Get.lazyPut(()=>GeoFenceHistoryController(),fenix:true);
  }
}