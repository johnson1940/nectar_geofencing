# 🛡️ Geofence Tracker App (Nectar Mobile Assignment - #GTA)

The **Geofence Tracker App** is a user-friendly mobile application that allows users to define geofences, track their location in real-time (including background tracking), and receive notifications upon entering or exiting geofenced areas.

---

### Features

*  **Add**,  **Edit**, **Delete** geofences.
*  Display geo-fences and current user location on Google Maps.
*  Background location tracking on significant movement.
*  Push notifications and in-app toasts for entry/exit events.
*  Movement history with plotted routes on maps.
*  Smooth UI/UX with map animations, reactive updates.

---

## Screens Overview

###  Home Screen

* Lists all saved geo-fences.
* Shows status: **Inside** / **Outside**.
* Provides Edit/Delete options.
* Add Geofence button.

###  Add Geofence Screen

* Enter **Geofence Title** and **Radius (in meters)**.
* Select center point of geofence via Google Maps.

###  Movement History Screen

* Displays timestamped location history.
* Visualizes user movement using poly-lines.
* Overlays geofence boundaries for reference.

---

## Packages Used

| Category                     | Package                       | Purpose                         |
| ---------------------------- | ----------------------------- | ------------------------------- |
| **UI / UX**                  | `cupertino_icons`             | iOS-style icons                 |
|                              | `fluttertoast`                | Toast messages                  |
|                              | `flutter_native_splash`       | Custom splash screen            |
| **State Management**         | `get`                         | Routing & state management      |
| **Utilities**                | `logger`                      | Debugging and logs              |
|                              | `shared_preferences`          | Persistent local storage        |
|                              | `intl`                        | Date formatting                 |
| **Location & Maps**          | `geolocator`, `location`      | Real-time & background location |
|                              | `google_maps_flutter`         | Display Google Maps             |
|                              | `flutter_polyline_points`     | Decode and draw polylines       |
| **Permissions & Background** | `permission_handler`          | Handle runtime permissions      |
|                              | `flutter_background_service`  | Run tasks in the background     |
| **Notifications**            | `flutter_local_notifications` | Local push notifications        |

---

## Platform-Specific Setup

###  Android

1. **Google Maps API Key**
   Get your API key from the [Google Cloud Console](https://console.cloud.google.com/) and add it to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

   ```xml
   <meta-data
     android:name="com.google.android.geo.API_KEY"
     android:value="YOUR_API_KEY"/>
   ```

2. **Background Location (If Using)**
   Add the following permissions to `AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   ```

3. **Build APK**

```bash
flutter build apk
```

---

###  iOS

1. **System Requirements**

    * macOS with [Xcode](https://developer.apple.com/xcode/) installed

2. **Google Maps API Key**
   Add the following line to `ios/Runner/AppDelegate.swift`:

   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

3. **Update Info.plist**
   Add required permissions to `ios/Runner/Info.plist`:

   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs access to your location.</string>
   <key>NSLocationAlwaysUsageDescription</key>
   <string>This app needs background location access.</string>
   ```

4. **Install CocoaPods**

```bash
cd ios
pod install
cd ..
```

5. **Run the App**

    * Open `ios/Runner.xcworkspace` in Xcode
    * Choose a simulator or device
    * Click ▶️ to build and run

---

##  Project Structure

```
lib/
 ├─ main.dart
 ├─ controllers/      # GetX Controllers (e.g., GeofenceController)
 ├─ models/           # Data models (e.g., Geofence, Movement)
 ├─ view/          # Home, Add Geofence, History screens
 ├─ services/         # Location services, Notification handling
 └─ globalWidgets/          # Custom reusable widgets
```

---

##  Usage Flow

1. **Home Screen** → Tap **➕ Add Geofence**.
2. **Add Geofence Screen** → Select location → Enter radius → Save.
3. Allow **Location** & **Background** permissions.
4. Move into or out of the geofence → ✅ **Receive notification**.

---


## Testing Guidelines

##  Testing Checklist

* **Geofence Triggering**

    * Add a geofence and simulate entering or exiting it.
    * Check if notifications are received.
    * Verify geofence area rendering on map.

* **Movement Visualization**

    * Move across different areas and confirm polylines are drawn correctly.
    * Ensure polylines stay visible when navigating screens.

* **Background Tracking**

    * Minimize the app and test location tracking in the background.
    * Confirm location updates are visible in the **Movement History**.

* **Permission Handling**

    * Deny location permission and verify that the app gracefully prompts the user.
    * Revoke background permissions and ensure re-authorization flow works.

* **UI/UX**

    * Check responsiveness on different screen sizes.
    * Ensure that toasts and notifications appear promptly.

* **Android Platform Coverage**

    * Testing has been focused on Android devices.

