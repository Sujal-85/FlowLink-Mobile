import 'package:flutter/material.dart';
  import 'package:flutter/foundation.dart';
  import 'dart:convert';
  import 'package:flutter/services.dart' show rootBundle;
  import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF5E7A4D); // earthy green
  static const Color lightGrey = Color(0xFFF2F4F7);
  static const Color textGrey = Color(0xFF7A7F85);
  static const Color gradientTeal = Color(0xFF00BFA5);
  static const Color gradientBlue = Color(0xFF1E88E5);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientTeal, gradientBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Returns a URL that is safe to load on Flutter Web by proxying external
/// images through a CORS-friendly endpoint. Mobile platforms return the URL
/// unchanged.
String resolveImageUrl(String url) {
  if (url.isEmpty) return url;
  if (!kIsWeb) return url;
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (!uri.hasScheme || uri.host.isEmpty) return url;
  final hostPath = '${uri.host}${uri.path}';
  final qs = uri.query.isNotEmpty ? '?${uri.query}' : '';
  return 'https://images.weserv.nl/?url=$hostPath$qs';
}

ThemeData buildTheme() {
  const radius = 24.0;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Use a finite minimum size. Size.fromHeight(56) sets width to infinity,
        // which breaks in unbounded Row layouts. This ensures buttons can be
        // placed inside Row/Column without forcing infinite width.
        minimumSize: const Size(88, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
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
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF0F1115),
  );

  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(88, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
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
    double _asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ProductItem(
      name: (json['ProductName'] ?? '').toString(),
      brand: (json['Brand'] ?? '').toString(),
      price: _asDouble(json['Price']),
      discountPrice: _asDouble(json['DiscountPrice']),
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

  /// Loads all products from the JSON asset. Results are cached in-memory.
  static Future<List<ProductItem>> loadAll({int? limit}) async {
    if (_cache != null && _cache!.isNotEmpty) {
      final list = _cache!;
      if (limit != null && limit > 0 && limit < list.length) {
        return list.sublist(0, limit);
      }
      return list;
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw);
      if (data is List) {
        final items = <ProductItem>[];
        for (final e in data) {
          if (e is Map<String, dynamic>) {
            items.add(ProductItem.fromJson(e));
          } else if (e is Map) {
            items.add(ProductItem.fromJson(e.cast<String, dynamic>()));
          }
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
}
