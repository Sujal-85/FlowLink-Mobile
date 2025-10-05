import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/purchase_history_service.dart';

class CartEntry {
  CartEntry({required this.item, this.qty = 1});
  final ProductItem item;
  int qty;

  double get unitPrice => (item.discountPrice > 0 && item.discountPrice < item.price)
      ? item.discountPrice
      : item.price;
  double get lineTotal => unitPrice * qty;
}

/// In-memory cart with aggregated quantities
class CartService {
  CartService._();
  static final CartService instance = CartService._();
  static const String _storageKey = 'cart_entries_v1';

  /// Total quantity of items across all entries
  final ValueNotifier<int> count = ValueNotifier<int>(0);

  /// Current entries (unique products with quantities)
  final ValueNotifier<List<CartEntry>> entries = ValueNotifier<List<CartEntry>>(<CartEntry>[]);

  final Map<String, CartEntry> _entriesMap = <String, CartEntry>{};

  /// Initialize from local storage
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _emit();
        return;
      }
      final data = jsonDecode(raw);
      if (data is List) {
        _entriesMap.clear();
        for (final e in data) {
          if (e is Map) {
            final m = e.cast<String, dynamic>();
            final qty = (m['qty'] is int) ? (m['qty'] as int) : int.tryParse('${m['qty']}') ?? 1;
            final item = ProductItem.fromJson(m);
            final key = _keyFor(item);
            _entriesMap[key] = CartEntry(item: item, qty: qty);
          }
        }
      }
      _emit();
    } catch (_) {
      // Ignore corrupt storage
      _emit();
    }
  }

  String _keyFor(ProductItem p) {
    if (p.productUrl.isNotEmpty) return p.productUrl;
    return '${p.name}|${p.brand}|${p.quantity}|${p.imageUrl}';
  }

  void add(ProductItem item, {int qty = 1}) {
    final key = _keyFor(item);
    final existing = _entriesMap[key];
    if (existing != null) {
      existing.qty += qty;
    } else {
      _entriesMap[key] = CartEntry(item: item, qty: qty);
    }
    _emit();
    // Record towards frequently purchased history (fire-and-forget)
    try {
      // ignore: discarded_futures
      PurchaseHistoryService.instance.record(item, qty: qty);
    } catch (_) {}
  }

  void decrement(ProductItem item, {int qty = 1}) {
    final key = _keyFor(item);
    final existing = _entriesMap[key];
    if (existing == null) return;
    existing.qty -= qty;
    if (existing.qty <= 0) {
      _entriesMap.remove(key);
    }
    _emit();
  }

  void remove(ProductItem item) {
    final key = _keyFor(item);
    _entriesMap.remove(key);
    _emit();
  }

  void clear() {
    _entriesMap.clear();
    _emit();
  }

  double get total => entries.value.fold<double>(0.0, (sum, e) => sum + e.lineTotal);

  int get uniqueItemCount => entries.value.length;

  void _emit() {
    final list = _entriesMap.values.toList(growable: false);
    list.sort((a, b) => a.item.name.compareTo(b.item.name));
    entries.value = list;
    count.value = list.fold<int>(0, (acc, e) => acc + e.qty);
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = entries.value.map((e) {
        final p = e.item;
        return {
          'ProductName': p.name,
          'Brand': p.brand,
          'Price': p.price,
          'DiscountPrice': p.discountPrice,
          'Image_Url': p.imageUrl,
          'Quantity': p.quantity,
          'Category': p.category,
          'SubCategory': p.subCategory,
          'Absolute_Url': p.productUrl,
          'qty': e.qty,
        };
      }).toList(growable: false);
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {
      // ignore write errors
    }
  }
}
