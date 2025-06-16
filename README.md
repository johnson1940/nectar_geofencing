# 🛡️ Geofence Tracker App (Nectar Mobile Assignment - #GTA)

The **Geofence Tracker App** is a user-friendly mobile application that allows users to define geofences, track their location in real-time (including background tracking), and receive notifications upon entering or exiting geofenced areas.

---

## 📱 Features

* ➕ **Add**, ✏️ **Edit**, ❌ **Delete** geofences.
* 🗸️ Display geofences and current user location on Google Maps.
* 📍 Background location tracking every 2 minutes or on significant movement.
* 🔔 Push notifications and in-app toasts for entry/exit events.
* 🕒 Movement history with plotted routes on maps.
* 📌 Display polylines for movement history.
* 🗺️ Visualize geofence areas directly on the map.
* ⚡ Smooth UI/UX with map animations, reactive updates.

---

## 🧱 Screens Overview

### 🏠 Home Screen

* Lists all saved geofences.
* Shows status: **Inside** / **Outside**.
* Provides Edit/Delete options.
* Add Geofence button.

### ➕ Add Geofence Screen

* Enter **Geofence Title** and **Radius (in meters)**.
* Select center point of geofence via Google Maps.

### 🕒 Movement History Screen

* Displays timestamped location history.
* Visualizes user movement using polylines.
* Overlays geofence boundaries for reference.

---

## 📦 Packages Used

| Category                     | Package                       | Purpose                         |
| ---------------------------- | ----------------------------- | ------------------------------- |
| **UI / UX**                  | `cupertino_icons`             | iOS-style icons                 |
|                              | `fluttertoast`                | Toast messages                  |
|                              | `flutter_native_splash`       | Custom splash screen            |
| **State Management**         | `get`                         | Routing & state management      |
|                              | `rxdart`                      | Advanced reactive programming   |
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

## 📲 Android Setup

### 📜 Required Permissions (`AndroidManifest.xml`)

Add these **before `<application>`**:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

### ⚙️ Service Declaration (Inside `<application>`)

```xml
<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    android:exported="false"
    android:foregroundServiceType="location"
    tools:replace="android:exported,android:foregroundServiceType" />
```

---

### 🔔 Notification Channel (Optional but Recommended)

In `res/values/strings.xml`:

```xml
<string name="default_notification_channel_id" translatable="false">Geofence Tracker</string>
```

---

## 🚀 Getting Started

### ✅ Clone the Repository

```bash
git clone https://github.com/your-username/geofence-tracker.git
cd geofence-tracker
```

### 📦 Install Dependencies

```bash
flutter pub get
```

### 🗼️ Configure Splash Screen (Optional)

```bash
dart run flutter_native_splash:create
```

### ▶️ Run the App

```bash
flutter run
```

---

## 🔖 Project Structure

```
lib/
 ├─ main.dart
 ├─ controllers/      # GetX Controllers (e.g., GeofenceController)
 ├─ models/           # Data models (e.g., Geofence, Movement)
 ├─ screens/          # Home, Add Geofence, History screens
 ├─ services/         # Location services, Notification handling
 └─ widgets/          # Custom reusable widgets
```

---

## 📌 Usage Flow

1. **Home Screen** → Tap **➕ Add Geofence**.
2. **Add Geofence Screen** → Select location → Enter radius → Save.
3. Allow **Location** & **Background** permissions.
4. Move into or out of the geofence → ✅ **Receive notification**.

---

## 🔧 Commands Reference

| Task                           | Command                                 |
| ------------------------------ | --------------------------------------- |
| Install dependencies           | `flutter pub get`                       |
| Run app                        | `flutter run`                           |
| Build APK (release)            | `flutter build apk --release`           |
| Setup splash screen (optional) | `dart run flutter_native_splash:create` |

---

## ✅ Testing Checklist

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

---

## 🔖 Example API Response (If Required)

```json
{
  "id": "1",
  "title": "Office",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "radius": 200,
  "status": "inside",
  "timestamp": "2025-06-16T12:34:56Z"
}
```

---

## 📖 License

This repository is intended for educational and assignment purposes for Nectar Mobile.

---

### 🙌 Contributing

PRs and improvements are welcome. Please fork and open a pull request.
