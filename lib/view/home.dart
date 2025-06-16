import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nectar_geofencing/constants/color_constants.dart';
import 'package:nectar_geofencing/view/add_geo_fence.dart';
import '../controller/nav_bar_controller.dart';
import 'movement_history.dart';
import 'home_screen.dart';


class MainScreen extends StatelessWidget {
  final NavigationController navController = Get.put(NavigationController());

  final List<Widget> screens = [
    HomeScreen(),
    Placeholder(), /// Center '+' doesn't use this
    MovementHistoryScreen(),
  ];

  MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: screens[navController.currentIndex.value],
      bottomNavigationBar: navController.currentIndex.value == 1
          ? null // Hide when '+' is selected
          : BottomNavigationBar(
        currentIndex: navController.currentIndex.value,
        onTap: (index) {
          if (index == 1) {
            // Navigate to Add Screen (no bottom nav)
            Get.to(() => AddGeofenceScreen());
          } else {
            navController.changeIndex(index);
          }
        },
        backgroundColor: ColorConstants.secondaryColor, // Change background color here
        selectedItemColor: ColorConstants.primaryColor,     // Active icon/text color
        unselectedItemColor: Colors.grey, // Inactive icon/text color
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30,), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, color:ColorConstants.primaryColor,size: 55), label: "",),
          BottomNavigationBarItem(icon: Icon(Icons.history, size: 30,), label: "History"),
        ],
      ),
    ));
  }
}
