import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:optimove_flutter/optimove_flutter.dart' as optimove;

class LocationSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LocationState();
  }
}

class _LocationState extends State<LocationSection> {
  late final TextEditingController hexNamespaceTextController;
  late final TextEditingController hexInstanceTextController;
  late final TextEditingController distanceMetresTextController;

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
                onPressed: () {
                  optimove.Optimove.trackEddystoneBeaconProximity(optimove.EddystoneBeaconProximity(
                      hexNamespace: hexInstanceTextController.text, hexInstance: hexInstanceTextController.text, distanceMetres:  double.tryParse(distanceMetresTextController.text)));
                },
                child: const Text('Send location update')),
            TextField(
                controller: hexNamespaceTextController,
                decoration: const InputDecoration(
                  hintText: 'hexNamespace',
                )),
            TextField(
                controller: hexInstanceTextController,
                decoration: const InputDecoration(
                  hintText: 'hexInstance',
                )),
            TextField(
                controller: distanceMetresTextController,
                decoration: const InputDecoration(
                  hintText: 'distanceMetres',
                )),
            ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
                onPressed: _sendLocation,
                child: const Text('Send location update')),
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

    optimove.Optimove.sendLocationUpdate(optimove.Location(longitude: locationData.longitude!, latitude: locationData.latitude!, time: locationData.time!));
  }
}
