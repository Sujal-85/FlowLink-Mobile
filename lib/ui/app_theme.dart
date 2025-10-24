import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary brand: Greens
  static const Color greenPrimary = Color(0xFF1DB954); // primary green
  static const Color greenDark = Color(0xFF1B5E20); // deep green for icons/text
  static const Color greenSurface = Color(0xFFEAF6DB); // soft green backgrounds
  // Pre-home background (matches the light, fresh green the user prefers)
  static const Color preHomeBackground = Color(0xFFF1F8E9); // Material LightGreen 50

  // Secondary brand: Dark Blue (aligned with existing header tone used across app)
  static const Color darkBlue = Color(0xFF0F4D42); // teal-leaning dark blue
  static const Color blueSurface = Color(0xFFE6EEF0);

  // Neutrals
  static const Color lightGrey = Color(0xFFF2F4F7);
  static const Color textGrey = Color(0xFF7A7F85);

  // Gradients restricted to green/blue family
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [greenPrimary, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient profileGradient = LinearGradient(
    colors: [greenPrimary, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppGradients {
  static LinearGradient orangeTop(Brightness _) {
    return const LinearGradient(
      colors: [Color(0xFFFFE8CC), Color(0x00FFE8CC)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

/// Returns a URL that is safe to load on Flutter Web by proxying external
/// images through a CORS-friendly endpoint. Mobile platforms return the URL
/// unchanged.
///
/// On web, we normalize schemeless URLs and ensure HTTPS sources are proxied
/// via the SSL-aware form supported by images.weserv.nl to avoid upstream 40x
/// issues.
String resolveImageUrl(String url) {
  if (url.isEmpty) return url;
  if (!kIsWeb) return url;
  // Normalize common forms like //host/path or host/path
  var u = url.trim();
  if (u.startsWith('//')) u = 'https:$u';
  if (!u.startsWith('http')) u = 'https://$u';
  final uri = Uri.tryParse(u);
  if (uri == null || uri.host.isEmpty) return url;
  final hostPath = '${uri.host}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
  final prefix = uri.scheme == 'https' ? 'ssl:' : '';
  return 'https://images.weserv.nl/?url=$prefix$hostPath';
}

ThemeData buildTheme() {
  const radius = 24.0;
  final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.greenPrimary).copyWith(
    primary: AppColors.greenPrimary,
    secondary: AppColors.darkBlue,
    tertiary: AppColors.greenDark,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
  );

  return base.copyWith(
    // Modern, readable font across the app
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    }),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        // Use a finite minimum size. Size.fromHeight(56) sets width to infinity,
        // which breaks in unbounded Row layouts. This ensures buttons can be
        // placed inside Row/Column without forcing infinite width.
        minimumSize: const Size(88, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.greenSurface,
      selectedColor: colorScheme.primary.withOpacity(0.12),
      disabledColor: AppColors.lightGrey,
      labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: AppColors.textGrey),
      labelStyle: const TextStyle(color: AppColors.textGrey),
    ),
  );
}

ThemeData buildDarkTheme() {
  const radius = 24.0;
  final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.greenPrimary, brightness: Brightness.dark).copyWith(
    primary: AppColors.greenPrimary,
    secondary: AppColors.darkBlue,
    tertiary: AppColors.greenDark,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF0F1115),
  );

  return base.copyWith(
    cardColor: const Color(0xFF141820),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: const Color(0x1FFFFFFF), // white10
      selectedColor: colorScheme.primary.withOpacity(0.18),
      disabledColor: Colors.white24,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Colors.white24),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    }),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(88, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1D23),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: Colors.white70),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
  );
}

// ------------------------------
// Dummy Product model and loader
// ------------------------------

class ProductItem {
  final String name;
  final String brand;
  final double price;
  final double discountPrice;
  final String imageUrl;
  final String quantity;
  final String category;
  final String subCategory;
  final String productUrl;

  const ProductItem({
    required this.name,
    required this.brand,
    required this.price,
    required this.discountPrice,
    required this.imageUrl,
    required this.quantity,
    required this.category,
    required this.subCategory,
    required this.productUrl,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ProductItem(
      name: (json['ProductName'] ?? '').toString(),
      brand: (json['Brand'] ?? '').toString(),
      price: asDouble(json['Price']),
      discountPrice: asDouble(json['DiscountPrice']),
      imageUrl: (json['Image_Url'] ?? '').toString(),
      quantity: (json['Quantity'] ?? '').toString(),
      category: (json['Category'] ?? '').toString(),
      subCategory: (json['SubCategory'] ?? '').toString(),
      productUrl: (json['Absolute_Url'] ?? '').toString(),
    );
  }
}

class DummyProductsLoader {
  static const String _assetPath = 'assets/images/csvjson.json';
  static List<ProductItem>? _cache;
  static bool _cacheValidated = false;

  /// Loads all products from the JSON asset. Results are cached in-memory.
  /// If [validateImages] is true, only items whose image URLs are reachable
  /// (and are an image/* content-type) will be returned. If [bustCache] is
  /// true, the cache is cleared and data is reloaded from assets.
  static Future<List<ProductItem>> loadAll({int? limit, bool validateImages = false, bool bustCache = false}) async {
    if (bustCache) _cache = null;
    if (_cache != null && _cache!.isNotEmpty) {
      var list = _cache!;
      if (validateImages && !_cacheValidated) {
        final validated = await _filterReachableImages(list);
        // Fallback: if validation eliminates most items (e.g., offline/CORS), keep unvalidated list
        if (validated.length >= 5) {
          list = validated;
          _cache = list;
          _cacheValidated = true;
        } else {
          _cacheValidated = false;
        }
      }
      if (limit != null && limit > 0 && limit < list.length) {
        return list.sublist(0, limit);
      }
      return list;
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw);
      if (data is List) {
        var items = <ProductItem>[];
        for (final e in data) {
          if (e is Map<String, dynamic>) {
            items.add(ProductItem.fromJson(e));
          } else if (e is Map) {
            items.add(ProductItem.fromJson(e.cast<String, dynamic>()));
          }
        }
        items = items.where((it) => _looksLikeImageUrl(it.imageUrl)).toList();
        if (validateImages) {
          final validated = await _filterReachableImages(items);
          if (validated.length >= 5) {
            items = validated;
            _cacheValidated = true;
          } else {
            _cacheValidated = false; // keep unvalidated items to avoid empty UI
          }
        } else {
          _cacheValidated = false;
        }
        _cache = items;
        if (limit != null && limit > 0 && limit < items.length) {
          return items.sublist(0, limit);
        }
        return items;
      }
      return const <ProductItem>[];
    } catch (_) {
      // If anything goes wrong, return empty list.
      return const <ProductItem>[];
    }
  }

  static bool _looksLikeImageUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return false;
    if (!(u.startsWith('http://') || u.startsWith('https://'))) return false;
    // Allow common image types; if no extension present, still allow.
    const exts = ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'];
    final hasExt = exts.any((e) => u.contains(e));
    return hasExt || Uri.tryParse(u)?.hasAbsolutePath == true;
  }

  static Future<List<ProductItem>> _filterReachableImages(List<ProductItem> items) async {
    final out = <ProductItem>[];
    const concurrency = 8;
    var i = 0;
    Future<void> worker() async {
      while (true) {
        late final int index;
        if (i >= items.length) break;
        index = i;
        i += 1;
        final p = items[index];
        final ok = await _isImageReachable(p.imageUrl);
        if (ok) out.add(p);
      }
    }
    final tasks = List.generate(concurrency, (_) => worker());
    await Future.wait(tasks);
    return out;
  }

  static Future<bool> _isImageReachable(String url) async {
    try {
      final testUrl = kIsWeb ? resolveImageUrl(url) : url;
      final uri = Uri.tryParse(testUrl);
      if (uri == null) return false;
      final head = await http.head(uri).timeout(const Duration(seconds: 5));
      if (head.statusCode >= 200 && head.statusCode < 400) {
        final ct = head.headers['content-type'] ?? '';
        if (ct.startsWith('image/')) return true;
      }
      if (head.statusCode == 405 || head.statusCode == 403) {
        final get = await http.get(uri, headers: const {'Range': 'bytes=0-0'}).timeout(const Duration(seconds: 5));
        if (get.statusCode >= 200 && get.statusCode < 400) {
          final ct = get.headers['content-type'] ?? '';
          if (ct.startsWith('image/')) return true;
        }
      }
    } catch (_) {}
    return false;
  }
}
