import 'package:get/get.dart';
import '../controller/add_geo_fence_controller.dart';
import '../controller/geo_fence_Controller.dart';
import '../controller/geo_history_controller.dart';

class GlobalBinding extends Bindings {

  /// Controller registration

  @override
  void dependencies() {
    Get.lazyPut(()=>GeofenceController(),fenix:true);
    Get.lazyPut(()=>AddGeoFenceController(),fenix:true);
    Get.lazyPut(()=>MovementHistoryController(),fenix:true);
  }
}