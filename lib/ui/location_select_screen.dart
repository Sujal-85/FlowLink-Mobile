import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flowlink_mobile/services/location_service.dart';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LatLng? _picked;
  bool _loading = true;
  String? _pickedAddress;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _picked = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      await _resolvePickedAddress();
    } catch (_) {
      // Fallback to a default coordinate if permissions denied (San Francisco)
      setState(() {
        _picked = const LatLng(37.7749, -122.4194);
        _loading = false;
      });
      await _resolvePickedAddress();
    }
  }

  Future<void> _resolvePickedAddress() async {
    final p = _picked;
    if (p == null) return;
    setState(() => _resolvingAddress = true);
    final addr = await LocationService.reverseGeocode(p.latitude, p.longitude);
    if (!mounted) return;
    setState(() {
      _pickedAddress = addr;
      _resolvingAddress = false;
    });
  }

  Future<void> _confirm() async {
    final p = _picked;
    if (p == null) return;
    if (!mounted) return;
    Navigator.pop(context, {
      'lat': p.latitude,
      'lng': p.longitude,
      'address': _pickedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _picked == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final mapHeight = size.height * 0.6;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: mapHeight,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _picked!, zoom: 14),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (c) => _controller.complete(c),
              onTap: (latLng) {
                setState(() => _picked = latLng);
                _resolvePickedAddress();
              },
              markers: {
                Marker(
                  markerId: const MarkerId('picked'),
                  position: _picked!,
                  draggable: true,
                  onDragEnd: (p) {
                    setState(() => _picked = p);
                    _resolvePickedAddress();
                  },
                ),
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _circleIcon(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Choose Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _circleIcon(icon: Icons.my_location_rounded, onTap: () async {
                    try {
                      final pos = await LocationService.getCurrentPosition();
                      final ctrl = await _controller.future;
                      final target = LatLng(pos.latitude, pos.longitude);
                      setState(() => _picked = target);
                      ctrl.animateCamera(CameraUpdate.newLatLng(target));
                    } catch (_) {}
                  }),
                  const SizedBox(width: 8),
                  _circleIcon(icon: Icons.more_vert, onTap: () {}),
                ],
              ),
            ),
          ),
          // Bottom panel
          Positioned(
            top: mapHeight - 18,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Scrollable content area so the list/card is always visible
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const Text('Selected Location', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _confirm,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.place_rounded, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _resolvingAddress
                                              ? 'Fetching address...'
                                              : (_pickedAddress ?? 'Tap on map to pick a location'),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Popular Locations', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const _LocationTile(title: 'Ratnagiri', subtitle: 'Maharashtra, India', distance: '3.2 KM'),
                          const _LocationTile(title: 'Mirjole', subtitle: 'Ratnagiri, Maharashtra', distance: '5.6 KM'),
                          const _LocationTile(title: 'Nachane', subtitle: 'Ratnagiri, Maharashtra', distance: '8.1 KM'),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _confirm,
                        child: const Text('Confirm Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _mapPin() {
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      border: Border.all(color: AppColors.primary, width: 3),
    ),
  );
}

Widget _circleIcon({required IconData icon, VoidCallback? onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Icon(icon, color: Colors.black87, size: 20),
    ),
  );
}

class _LocationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String distance;
  const _LocationTile({required this.title, required this.subtitle, required this.distance});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: const Icon(Icons.location_on, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, overflow: TextOverflow.ellipsis, maxLines: 1),
      trailing: Text(distance, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      onTap: () {
        // For now, just close if used anywhere.
        Navigator.of(context).pop();
      },
    );
  }
}
