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

class IBeaconProximity {
  final String uuid;
  final int majorId;
  final int minorId;
  final BeaconProximity beaconProximity;

  IBeaconProximity(this.uuid, this.majorId, this.minorId, this.beaconProximity);

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'majorId': majorId,
      'minorId': minorId,
      'beaconProximity': beaconProximity.index
    };
  }
}

enum BeaconProximity { Far, Immediate, Near, Unknown }

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
