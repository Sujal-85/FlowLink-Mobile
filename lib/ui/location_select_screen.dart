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
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if ((_pickedAddress ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded, color: AppColors.greenPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _resolvingAddress ? 'Fetching address...' : _pickedAddress!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        child: const Text('Confirm Location'),
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
      border: Border.all(color: AppColors.greenPrimary, width: 3),
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
      leading: const Icon(Icons.location_on, color: AppColors.greenPrimary),
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
