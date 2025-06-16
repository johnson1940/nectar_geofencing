# 🛰️ Geofence Tracker App (Nectar Mobile Assignment - #GTA)

The **Geofence Tracker App** is a powerful and user-friendly mobile application that allows users to monitor their movements in relation to predefined geofences. It stores geofence data locally, tracks user location periodically, and provides real-time alerts when entering or exiting geofenced areas.

---

## 📱 Features

- Add, edit, and delete geo-fences.
- Visual geo-fences on Google Maps.
- Periodic background location tracking.
- Entry/exit detection with push notifications.
- Movement history with route rendering.
- Smooth UI/UX with map animations and toast messages.

---

## 📸 Screens

### 🏠 Home Screen
- Lists all saved geo-fences.
- Displays geofence status (Inside / Outside).
- Options to edit/delete geo-fences.
- Button to add a new geofence.

### Add Geofence Screen
- Add title, radius, and select location on map.
- Save data to local storage.

###  Movement History Screen
- List of recorded location events.
- Map displaying routes and geo-fenced areas.
- The user's movement history as plotted poly-lines (routes).

### Packages Used and their Use cases
| Package                          | Purpose                                     |
| -------------------------------- | ------------------------------------------- |
| **UI / UX**                      |                                             |
| `cupertino_icons`                | iOS-style icons                             |
| `fluttertoast`                   | Toast-style in-app alerts                   |
| `flutter_native_splash`          | Launch splash screen                        |
| **State Management & Utilities** |                                             |
| `get`                            | Routing and reactive state management       |
| `logger`                         | Debug and logging utility                   |
| `shared_preferences`             | Local key-value data storage                |
| `intl`                           | Timestamp and date formatting               |
| `rxdart`                         | Advanced reactive programming               |
| **Location & Maps**              |                                             |
| `geolocator`                     | Real-time and background location services  |
| `location`                       | Location access abstraction                 |
| `google_maps_flutter`            | Google Maps rendering                       |
| `flutter_polyline_points`        | Decoding polylines for routes               |
| **Permissions & Background**     |                                             |
| `permission_handler`             | Runtime permission requests                 |
| `flutter_background_service`     | Keep location tracking active in background |
| **Notifications**                |                                             |
| `flutter_local_notifications`    | Local notifications on geofence triggers    |

### Platform Setup Instructions

### Android setup 

#### Permissions:
- Add the following permissions to your android/app/src/main/AndroidManifest.xml file:

- <!-- Location Permissions -->
- <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
- <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
- <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

- <!-- Foreground Service -->
- <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

- <!-- Notification Permission (for Android 13+) -->
- <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

# Background Service Configuration:
- Inside the <application> tag in AndroidManifest.xml, add:

- <service
- android:name="id.flutter.flutter_background_service.BackgroundService"
- android:foregroundServiceType="location"
- android:exported="false"
- tools:replace="android:exported,android:foregroundServiceType" />

# Add Google Maps API Key:
- <meta-data
- android:name="com.google.android.geo.API_KEY"
- android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

# Splash Screen
- flutter pub run flutter_native_splash:create
