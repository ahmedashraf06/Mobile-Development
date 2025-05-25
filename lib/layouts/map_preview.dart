import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPreview extends StatelessWidget {
  final String locationUrl;

  const MapPreview({Key? key, required this.locationUrl}) : super(key: key);

  LatLng? _parseLatLngFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Try query param `?q=lat,lng`
    final query = uri.queryParameters['q'];
    if (query != null) {
      final parts = query.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }

    // Fallback to last path segment
    final lastSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final parts = lastSegment.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = _parseLatLngFromUrl(locationUrl);

    if (coordinates == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No location data available',
          style: TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(locationUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the map')),
          );
        }
      },
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: coordinates,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: coordinates,
                  ),
                },
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                liteModeEnabled: true,
                onTap: (_) async {
                  final uri = Uri.tryParse(locationUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch map')),
                    );
                  }
                },
              ),

              // Optional: Add a blur overlay or marker
            ],
          ),
        ),
      ),
    );
  }
}
