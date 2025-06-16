class LocationHistoryEntry {
  String? title;
  double latitude;
  double longitude;
  String status;
  DateTime timestamp;


  LocationHistoryEntry({
    this.title,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'geofenceTitle': title, // Include in JSON
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> json) => LocationHistoryEntry(
    title: json['geofenceTitle'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    status: json['status'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}