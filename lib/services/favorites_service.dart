import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const String _storageKey = 'favorites_v1';

  final ValueNotifier<List<ProductItem>> favorites = ValueNotifier<List<ProductItem>>(<ProductItem>[]);

  final Map<String, ProductItem> _map = <String, ProductItem>{};

  String _keyFor(ProductItem p) {
    if (p.productUrl.isNotEmpty) return p.productUrl;
    return '${p.name}|${p.brand}|${p.quantity}|${p.imageUrl}';
    }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is List) {
          _map.clear();
          for (final e in data) {
            if (e is Map) {
              final item = ProductItem.fromJson((e).cast<String, dynamic>());
              _map[_keyFor(item)] = item;
            }
          }
        }
      }
      _emit();
    } catch (_) {
      _emit();
    }
  }

  bool isFavorite(ProductItem p) => _map.containsKey(_keyFor(p));

  void add(ProductItem p) {
    _map[_keyFor(p)] = p;
    _emit();
  }

  void remove(ProductItem p) {
    _map.remove(_keyFor(p));
    _emit();
  }

  void toggle(ProductItem p) {
    final k = _keyFor(p);
    if (_map.containsKey(k)) {
      _map.remove(k);
    } else {
      _map[k] = p;
    }
    _emit();
  }

  void _emit() {
    final list = _map.values.toList(growable: false);
    list.sort((a, b) => a.name.compareTo(b.name));
    favorites.value = list;
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = favorites.value.map((p) => {
            'ProductName': p.name,
            'Brand': p.brand,
            'Price': p.price,
            'DiscountPrice': p.discountPrice,
            'Image_Url': p.imageUrl,
            'Quantity': p.quantity,
            'Category': p.category,
            'SubCategory': p.subCategory,
            'Absolute_Url': p.productUrl,
          }).toList(growable: false);
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {}
  }
}
