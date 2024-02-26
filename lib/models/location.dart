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

class EddystoneBeaconProximity {
  final String hexNamespace;
  final String hexInstance;
  final double? distanceMetres;

  EddystoneBeaconProximity(this.hexNamespace, this.hexInstance, this.distanceMetres);

  Map<String, dynamic> toMap() {
    return {
      'hexNamespace': hexNamespace,
      'hexInstance': hexInstance,
      'distanceMetres': distanceMetres,
    };
  }
}
