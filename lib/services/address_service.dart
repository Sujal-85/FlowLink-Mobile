import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Address {
  final String name;
  final String mobile;
  final String? altMobile;
  final String? email;
  final String pincode;
  final String city;
  final String state;
  final String landmark;
  final bool isDefault;
  final double? lat;
  final double? lng;
  final String? addressLine;
  final String? addressLine2;
  final String? instructions;
  final String? type; // e.g., home, work, other

  const Address({
    required this.name,
    required this.mobile,
    this.altMobile,
    this.email,
    required this.pincode,
    required this.city,
    required this.state,
    required this.landmark,
    this.isDefault = false,
    this.lat,
    this.lng,
    this.addressLine,
    this.addressLine2,
    this.instructions,
    this.type,
  });

  Address copyWith({
    String? name,
    String? mobile,
    String? altMobile,
    String? email,
    String? pincode,
    String? city,
    String? state,
    String? landmark,
    bool? isDefault,
    double? lat,
    double? lng,
    String? addressLine,
    String? addressLine2,
    String? instructions,
    String? type,
  }) => Address(
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        altMobile: altMobile ?? this.altMobile,
        email: email ?? this.email,
        pincode: pincode ?? this.pincode,
        city: city ?? this.city,
        state: state ?? this.state,
        landmark: landmark ?? this.landmark,
        isDefault: isDefault ?? this.isDefault,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        addressLine: addressLine ?? this.addressLine,
        addressLine2: addressLine2 ?? this.addressLine2,
        instructions: instructions ?? this.instructions,
        type: type ?? this.type,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobile': mobile,
        if (altMobile != null && altMobile!.isNotEmpty) 'altMobile': altMobile,
        if (email != null && email!.isNotEmpty) 'email': email,
        'pincode': pincode,
        'city': city,
        'state': state,
        'landmark': landmark,
        'isDefault': isDefault,
        'lat': lat,
        'lng': lng,
        'addressLine': addressLine,
        if (addressLine2 != null && addressLine2!.isNotEmpty) 'addressLine2': addressLine2,
        if (instructions != null && instructions!.isNotEmpty) 'instructions': instructions,
        if (type != null && type!.isNotEmpty) 'type': type,
      };

  factory Address.fromJson(Map<String, dynamic> m) => Address(
        name: (m['name'] ?? '').toString(),
        mobile: (m['mobile'] ?? '').toString(),
        altMobile: (m['altMobile'] ?? '').toString().isEmpty ? null : (m['altMobile'] ?? '').toString(),
        email: (m['email'] ?? '').toString().isEmpty ? null : (m['email'] ?? '').toString(),
        pincode: (m['pincode'] ?? '').toString(),
        city: (m['city'] ?? '').toString(),
        state: (m['state'] ?? '').toString(),
        landmark: (m['landmark'] ?? '').toString(),
        isDefault: m['isDefault'] == true,
        lat: _asDoubleOrNull(m['lat']),
        lng: _asDoubleOrNull(m['lng']),
        addressLine: (m['addressLine'] ?? '').toString().isEmpty ? null : (m['addressLine'] ?? '').toString(),
        addressLine2: (m['addressLine2'] ?? '').toString().isEmpty ? null : (m['addressLine2'] ?? '').toString(),
        instructions: (m['instructions'] ?? '').toString().isEmpty ? null : (m['instructions'] ?? '').toString(),
        type: (m['type'] ?? '').toString().isEmpty ? null : (m['type'] ?? '').toString(),
      );

  @override
  String toString() {
    if ((addressLine ?? '').trim().isNotEmpty) {
      final line2 = (addressLine2 ?? '').trim();
      final addr = line2.isNotEmpty ? '$addressLine\n$line2' : '$addressLine';
      return '$name, $mobile\n$addr\n$city, $state - $pincode';
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
