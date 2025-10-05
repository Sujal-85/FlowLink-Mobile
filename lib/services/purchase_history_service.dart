import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

/// Stores lightweight purchase history for quick reorders and recommendations.
class PurchaseHistoryService {
  PurchaseHistoryService._();
  static final PurchaseHistoryService instance = PurchaseHistoryService._();

  static const String _prefsKey = 'purchase_history_v1';

  /// Map key -> payload ({count:int, ...product fields})
  final Map<String, Map<String, dynamic>> _history = <String, Map<String, dynamic>>{};
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is Map) {
          data.forEach((k, v) {
            if (v is Map) {
              _history[k] = v.cast<String, dynamic>();
            }
          });
        }
      }
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
  }

  String _keyFor(ProductItem p) {
    if (p.productUrl.isNotEmpty) return p.productUrl;
    return '${p.name}|${p.brand}|${p.quantity}|${p.imageUrl}';
  }

  Future<void> record(ProductItem p, {int qty = 1}) async {
    if (!_loaded) await init();
    final key = _keyFor(p);
    final existing = _history[key];
    if (existing == null) {
      _history[key] = <String, dynamic>{
        'count': qty,
        'ProductName': p.name,
        'Brand': p.brand,
        'Price': p.price,
        'DiscountPrice': p.discountPrice,
        'Image_Url': p.imageUrl,
        'Quantity': p.quantity,
        'Category': p.category,
        'SubCategory': p.subCategory,
        'Absolute_Url': p.productUrl,
      };
    } else {
      final c = (existing['count'] is int) ? existing['count'] as int : int.tryParse('${existing['count']}') ?? 0;
      existing['count'] = c + qty;
    }
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_history));
    } catch (_) {}
  }

  /// Returns most frequently purchased items (descending by count).
  Future<List<ProductItem>> topProducts({int limit = 10}) async {
    if (!_loaded) await init();
    final entries = _history.entries.toList()
      ..sort((a, b) {
        final ca = (a.value['count'] is int) ? a.value['count'] as int : int.tryParse('${a.value['count']}') ?? 0;
        final cb = (b.value['count'] is int) ? b.value['count'] as int : int.tryParse('${b.value['count']}') ?? 0;
        return cb.compareTo(ca);
      });
    final list = <ProductItem>[];
    for (final e in entries.take(limit)) {
      list.add(ProductItem.fromJson(e.value));
    }
    return list;
  }
}
