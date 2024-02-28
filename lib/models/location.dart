class Location {
  final double longitude;
  final double latitude;
  final double time;

  Location({required this.longitude, required this.latitude, required this.time});

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

  EddystoneBeaconProximity({ required this.hexNamespace, required this.hexInstance, required this.distanceMetres});

  Map<String, dynamic> toMap() {
    return {
      'hexNamespace': hexNamespace,
      'hexInstance': hexInstance,
      'distanceMetres': distanceMetres,
    };
  }
}
