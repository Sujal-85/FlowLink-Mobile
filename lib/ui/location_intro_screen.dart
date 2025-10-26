import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flowlink_mobile/services/location_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/location_select_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
import 'package:flowlink_mobile/widgets/loading_overlay.dart';

class LocationIntroScreen extends StatefulWidget {
  const LocationIntroScreen({super.key});

  @override
  State<LocationIntroScreen> createState() => _LocationIntroScreenState();
}

class _LocationIntroScreenState extends State<LocationIntroScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _current;
  bool _loading = true;
  String? _address;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _current = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      final addr = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) setState(() => _address = addr);
    } catch (_) {
      // Fallback to a default coordinate if permissions denied (San Francisco)
      setState(() {
        _current = const LatLng(37.7749, -122.4194);
        _loading = false;
      });
      final addr = await LocationService.reverseGeocode(37.7749, -122.4194);
      if (mounted) setState(() => _address = addr);
    }
  }

  Future<void> _useCurrentLocation() async {
    final p = _current;
    if (p == null) return;
    LoadingOverlay.show(context, message: 'Setting your location...');
    await LocationService.updateAddressFromCoordinates(p.latitude, p.longitude);
    if (!mounted) return;
    // Go to Home (products) after confirming location
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 4),

              // Title
              const Text(
                'Choose your location',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's find your unforgettable event. Choose a location below to get started.",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.4),
              ),
              const SizedBox(height: 20),

              // Search
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search location',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),

              // Set on Map button
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined, color: AppColors.greenPrimary),
                label: const Text('Set Location on Map', style: TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.greenPrimary, width: 1.5),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final result = await pushSlideFade<Map<String, dynamic>>(
                    context,
                    const LocationSelectScreen(),
                    withLoader: true,
                    loadingMessage: 'Opening map...'
                  );
                  if (!mounted) return;
                  if (result != null) {
                    final map = result;
                    final lat = (map['lat'] as num?)?.toDouble();
                    final lng = (map['lng'] as num?)?.toDouble();
                    final addr = map['address'] as String?;
                    if (lat != null && lng != null) {
                      setState(() {
                        _current = LatLng(lat, lng);
                        _address = addr ?? _address;
                      });
                    }
                  }
                },
              ),

              const SizedBox(height: 24),
              const Text('Current Location', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Small map preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      if (_loading || _current == null)
                        Container(
                          color: theme.cardColor,
                          child: const Center(child: CircularProgressIndicator()),
                        )
                      else
                        GoogleMap(
                          initialCameraPosition: CameraPosition(target: _current!, zoom: 14),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          onMapCreated: (c) => _controller.complete(c),
                          markers: {
                            Marker(
                              markerId: const MarkerId('current'),
                              position: _current!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            )
                          },
                        ),

                      // Address pill overlay
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 16,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: theme.brightness == Brightness.light
                                  ? const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Text(
                              (_address == null || _address!.isEmpty) ? 'Select a location' : _address!,
                              style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              // Use current location button
              ElevatedButton(
                onPressed: _useCurrentLocation,
                child: const Text('Use Current Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
