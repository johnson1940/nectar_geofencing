import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:nectar_geofencing/view/home.dart';
import 'package:nectar_geofencing/view/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'globalWidgets/binding.dart';
import 'helper/logger.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  /// Initialize SharedPreferences
  await SharedPreferences.getInstance();

  /// Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // Use launcher icon
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            initialBinding: GlobalBinding(),
            useInheritedMediaQuery: true,
            title: 'Locatr',
            darkTheme: ThemeData.dark(),
            initialRoute: '/',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            defaultTransition: Transition.rightToLeft,
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key,});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {


  @override
  Widget build(BuildContext context) {
    return MainScreen();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister as observer
    super.dispose();
  }
}


