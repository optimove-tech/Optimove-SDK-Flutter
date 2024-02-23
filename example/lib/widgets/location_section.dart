import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:optimove_flutter/optimove_flutter.dart' as optimove;

class LocationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 167, 184, 204),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
                onPressed: _sendLocation,
                child: const Text('Request location')),
          ],
        ),
      ),
    );
  }

  void _sendLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    optimove.Optimove.sendLocationUpdate(optimove.Location(locationData.longitude!, locationData.latitude!, locationData.time!));
  }
}
