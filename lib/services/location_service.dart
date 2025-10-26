import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final ValueNotifier<String> addressNotifier = ValueNotifier<String>('');

  /// Checks service and permission, then returns a [Position].
  static Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<Position> getCurrentPosition() => _determinePosition();

  /// Returns a human-readable address if reverse geocoding succeeds, otherwise
  /// a friendly fallback label (no raw lat/lng shown).
  static Future<String> getReadableAddress() async {
    try {
      final pos = await _determinePosition();
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            if ((p.street ?? '').trim().isNotEmpty) p.street,
            if ((p.locality ?? '').trim().isNotEmpty) p.locality,
            if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea,
            if ((p.country ?? '').trim().isNotEmpty) p.country,
          ].whereType<String>().toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      } catch (_) {
        // fallthrough to web API fallback
      }
      final viaOsm = await _reverseViaOsm(pos.latitude, pos.longitude);
      if (viaOsm != null && viaOsm.isNotEmpty) return viaOsm;
      return 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
    } on LocationPermissionException {
      return 'Select delivery location';
    } on LocationServiceException {
      return 'Select delivery location';
    } catch (_) {
      return 'Select delivery location';
    }
  }

  /// Initialize the current address once; safe to call multiple times.
  static Future<void> initCurrentAddress() async {
    final current = addressNotifier.value.trim();
    final looksLikeLatLng = current.startsWith('Lat:') || current.contains('Lng:');
    final isFallback = current.isEmpty ||
        current.toLowerCase().contains('unable') ||
        current.toLowerCase().contains('location services') ||
        current.toLowerCase().contains('permissions');
    if (current.isNotEmpty && !looksLikeLatLng && !isFallback) return;
    final addr = await getReadableAddress();
    addressNotifier.value = addr;
  }

  /// Reverse geocode and update the notifier with the new address.
  static Future<void> updateAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if ((p.street ?? '').trim().isNotEmpty) p.street,
          if ((p.locality ?? '').trim().isNotEmpty) p.locality,
          if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea,
          if ((p.country ?? '').trim().isNotEmpty) p.country,
        ].whereType<String>().toList();
        addressNotifier.value = parts.isNotEmpty ? parts.join(', ') : 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        return;
      }
    } catch (_) {}
    final viaOsm = await _reverseViaOsm(lat, lng);
    addressNotifier.value = (viaOsm != null && viaOsm.isNotEmpty)
        ? viaOsm
        : 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  /// Reverse geocode coordinates to a human-readable address, without
  /// modifying [addressNotifier]. Falls back to a lat/lng string on failure.
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if ((p.street ?? '').trim().isNotEmpty) p.street,
          if ((p.locality ?? '').trim().isNotEmpty) p.locality,
          if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea,
          if ((p.country ?? '').trim().isNotEmpty) p.country,
        ].whereType<String>().toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    final viaOsm = await _reverseViaOsm(lat, lng);
    if (viaOsm != null && viaOsm.isNotEmpty) return viaOsm;
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  // OpenStreetMap Nominatim fallback for web / geocoding failures
  static Future<String?> _reverseViaOsm(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
      final res = await http.get(url, headers: {
        'User-Agent': 'FlowLink/1.0 (reverse-geocode)'
      }).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final disp = (data['display_name'] ?? '').toString();
        if (disp.isNotEmpty) return disp;
        final addr = (data['address'] as Map?)?.cast<String, dynamic>();
        if (addr != null) {
          final parts = [
            addr['road'], addr['suburb'], addr['city'], addr['state'], addr['country']
          ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
    } catch (_) {}
    return null;
  }
}

class LocationPermissionException implements Exception {
  final String message;
  const LocationPermissionException(this.message);
  @override
  String toString() => message;
}

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);
  @override
  String toString() => message;
}
