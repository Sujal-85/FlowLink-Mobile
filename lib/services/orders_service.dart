import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderStatus {
  static const String pending = 'Pending';
  static const String packed = 'Packed';
  static const String shipped = 'Shipped';
  static const String outForDelivery = 'Out for Delivery';
  static const String delivered = 'Delivered';

  static const List<String> stages = [
    pending,
    packed,
    shipped,
    outForDelivery,
    delivered,
  ];
}

class OrderItem {
  final String id;
  final String productName;
  final String imageUrl;
  final double price;
  final DateTime expectedDate;
  final int stageIndex; // 0..4
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  const OrderItem({
    required this.id,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.expectedDate,
    required this.stageIndex,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  String get status => OrderStatus.stages[stageIndex.clamp(0, OrderStatus.stages.length - 1)];

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'imageUrl': imageUrl,
        'price': price,
        'expectedDate': expectedDate.toIso8601String(),
        'stageIndex': stageIndex,
        'originLat': originLat,
        'originLng': originLng,
        'destLat': destLat,
        'destLng': destLng,
      };

  factory OrderItem.fromJson(Map<String, dynamic> m) => OrderItem(
        id: (m['id'] ?? '').toString(),
        productName: (m['productName'] ?? '').toString(),
        imageUrl: (m['imageUrl'] ?? '').toString(),
        price: _asDouble(m['price']),
        expectedDate: DateTime.tryParse((m['expectedDate'] ?? '').toString()) ?? DateTime.now(),
        stageIndex: _asInt(m['stageIndex']),
        originLat: _asDouble(m['originLat']),
        originLng: _asDouble(m['originLng']),
        destLat: _asDouble(m['destLat']),
        destLng: _asDouble(m['destLng']),
      );
}

class OrdersService {
  OrdersService._();
  static final OrdersService instance = OrdersService._();
  static const String _storageKey = 'orders_v1';

  final ValueNotifier<List<OrderItem>> orders = ValueNotifier<List<OrderItem>>(<OrderItem>[]);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is List) {
          final list = data.map((e) => OrderItem.fromJson((e as Map).cast<String, dynamic>())).toList();
          orders.value = list;
        }
      }
    } catch (_) {
      orders.value = const <OrderItem>[];
    }
  }

  Future<void> addOrders(List<OrderItem> newOnes) async {
    final list = [...orders.value, ...newOnes];
    orders.value = list;
    await _persist();
  }

  Future<void> addOrder(OrderItem item) async {
    await addOrders([item]);
  }

  Future<void> clear() async {
    orders.value = const <OrderItem>[];
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(orders.value.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
