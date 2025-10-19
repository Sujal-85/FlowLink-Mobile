import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Address {
  final String name;
  final String mobile;
  final String pincode;
  final String city;
  final String state;
  final String landmark;
  final bool isDefault;
  final double? lat;
  final double? lng;
  final String? addressLine;

  const Address({
    required this.name,
    required this.mobile,
    required this.pincode,
    required this.city,
    required this.state,
    required this.landmark,
    this.isDefault = false,
    this.lat,
    this.lng,
    this.addressLine,
  });

  Address copyWith({
    String? name,
    String? mobile,
    String? pincode,
    String? city,
    String? state,
    String? landmark,
    bool? isDefault,
    double? lat,
    double? lng,
    String? addressLine,
  }) => Address(
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        pincode: pincode ?? this.pincode,
        city: city ?? this.city,
        state: state ?? this.state,
        landmark: landmark ?? this.landmark,
        isDefault: isDefault ?? this.isDefault,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        addressLine: addressLine ?? this.addressLine,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobile': mobile,
        'pincode': pincode,
        'city': city,
        'state': state,
        'landmark': landmark,
        'isDefault': isDefault,
        'lat': lat,
        'lng': lng,
        'addressLine': addressLine,
      };

  factory Address.fromJson(Map<String, dynamic> m) => Address(
        name: (m['name'] ?? '').toString(),
        mobile: (m['mobile'] ?? '').toString(),
        pincode: (m['pincode'] ?? '').toString(),
        city: (m['city'] ?? '').toString(),
        state: (m['state'] ?? '').toString(),
        landmark: (m['landmark'] ?? '').toString(),
        isDefault: m['isDefault'] == true,
        lat: _asDoubleOrNull(m['lat']),
        lng: _asDoubleOrNull(m['lng']),
        addressLine: (m['addressLine'] ?? '').toString().isEmpty ? null : (m['addressLine'] ?? '').toString(),
      );

  @override
  String toString() {
    if ((addressLine ?? '').trim().isNotEmpty) {
      return '$name, $mobile\n$addressLine\n$city, $state - $pincode';
    }
    return '$name, $mobile\n$landmark\n$city, $state - $pincode';
  }

  static double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();
  static const String _storeKey = 'addresses_v1';

  final ValueNotifier<List<Address>> addresses = ValueNotifier<List<Address>>(<Address>[]);
  final ValueNotifier<Address?> selected = ValueNotifier<Address?>(null);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is List) {
          final list = data.map((e) => Address.fromJson((e as Map).cast<String, dynamic>())).toList();
          addresses.value = list;
          Address? sel;
          try {
            sel = list.firstWhere((a) => a.isDefault);
          } catch (_) {
            sel = list.isNotEmpty ? list[0] : null;
          }
          selected.value = sel;
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> add(Address a) async {
    final list = [...addresses.value];
    if (a.isDefault) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.add(a);
    addresses.value = list;
    if (a.isDefault) {
      selected.value = a;
    } else {
      selected.value ??= a;
    }
    await _persist();
  }

  Future<void> update(int index, Address a) async {
    final list = [...addresses.value];
    if (index < 0 || index >= list.length) return;
    if (a.isDefault) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list[index] = a;
    addresses.value = list;
    if (a.isDefault) selected.value = a;
    await _persist();
  }

  Future<void> remove(int index) async {
    final list = [...addresses.value];
    if (index < 0 || index >= list.length) return;
    final removed = list.removeAt(index);
    addresses.value = list;
    if (selected.value == removed) {
      selected.value = list.isNotEmpty ? (list.firstWhere((a) => a.isDefault, orElse: () => list[0])) : null;
    }
    await _persist();
  }

  Future<void> setDefault(int index) async {
    final list = [...addresses.value];
    if (index < 0 || index >= list.length) return;
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: i == index);
    }
    addresses.value = list;
    selected.value = list[index];
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storeKey, jsonEncode(addresses.value.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}
