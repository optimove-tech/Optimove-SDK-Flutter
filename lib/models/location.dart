class Location {
  final double longitude;
  final double latitude;
  final double time;

  Location(this.longitude, this.latitude, this.time);

  Map<String, dynamic> toMap() {
    return {
      'longitude': longitude,
      'latitude': latitude,
      'time': time,
    };
  }
}
