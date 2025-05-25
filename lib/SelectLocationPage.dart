import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? selectedLatLng;
  late GoogleMapController mapController;
  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Animate camera to user's location
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );

    setState(() {
      selectedLatLng = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(30.0444, 31.2357),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            onTap: (latLng) {
              setState(() => selectedLatLng = latLng);
            },
            markers:
                selectedLatLng != null
                    ? {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: selectedLatLng!,
                      ),
                    }
                    : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // we will reposition it manually
          ),

          /// Custom top AppBar (iOS style)
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          /// My Location Button
          Positioned(
            bottom: bottom + 100,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.white,
                elevation: 3,
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.black),
                  onPressed: _goToMyLocation,
                ),
              ),
            ),
          ),

          /// Confirm Button
          if (selectedLatLng != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: bottom + 24,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () {
                  final url =
                      'https://www.google.com/maps?q=${selectedLatLng!.latitude},${selectedLatLng!.longitude}';
                  Navigator.pop(context, url);
                },
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
