import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
        // fallthrough to lat/long fallback
      }
      return 'California, USA';
    } on LocationPermissionException {
      return 'California, USA';
    } on LocationServiceException {
      return 'California, USA';
    } catch (_) {
      return 'California, USA';
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
        addressNotifier.value = parts.isNotEmpty ? parts.join(', ') : 'California, USA';
        return;
      }
    } catch (_) {}
    addressNotifier.value = 'California, USA';
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
    return 'California, USA';
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
