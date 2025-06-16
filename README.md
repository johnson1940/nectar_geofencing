# 🛰️ Geofence Tracker App (Nectar Mobile Assignment - #GTA)

The **Geofence Tracker App** is a powerful and user-friendly mobile application that allows users to monitor their movements in relation to predefined geofences. It stores geofence data locally, tracks user location periodically (even in the background), and provides real-time alerts when entering or exiting geofenced areas.

---

## 📱 Features

- Add, edit, and delete geofences.
- Display geofences and user location on Google Maps.
- Background location tracking every 2 minutes or on significant movement.
- Push notifications and in-app alerts for entry/exit events.
- Movement history tracking with plotted routes.
- Smooth UI/UX with map animations and toasts.

---

## 🧭 Screens

### 🏠 Home Screen
- List all saved geofences.
- Display whether user is inside/outside each geofence.
- Edit and delete options.
- Button to add new geofence.

### ➕ Add Geofence Screen
- Enter geofence title and radius.
- Select geofence center location on map.

### 🕒 Movement History Screen
- View location update history with timestamps and geofence status.
- Visualize movement with polylines.
- Map with plotted user routes and geofence areas.

---

## 📦 Packages Used

| Category                     | Package                           | Purpose                                             |
|-----------------------------|-----------------------------------|-----------------------------------------------------|
| **UI / UX**                 | `cupertino_icons`                 | iOS-style icons                                     |
|                             | `fluttertoast`                    | Toast-style in-app alerts                           |
|                             | `flutter_native_splash`           | Custom splash screen                                |
| **State Management**        | `get`                             | Routing & reactive state management                 |
|                             | `rxdart`                          | Advanced reactive programming                       |
| **Utilities**               | `logger`                          | Logging/debugging                                   |
|                             | `shared_preferences`              | Local key-value storage                             |
|                             | `intl`                            | Date/time formatting                                |
| **Location & Maps**        | `geolocator`, `location`          | Real-time and background location                   |
|                             | `google_maps_flutter`             | Map integration                                     |
|                             | `flutter_polyline_points`         | Decode and draw route polylines                     |
| **Permissions & Background**| `permission_handler`              | Handle runtime permissions                          |
|                             | `flutter_background_service`      | Background location polling                         |
| **Notifications**           | `flutter_local_notifications`     | Local push notifications                            |

---

## 📲 Android Setup

### 🛡️ Required Permissions

Add the following to your `AndroidManifest.xml`:

```xml
<!-- Location Permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
