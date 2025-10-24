import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flowlink_mobile/services/db_service.dart';

class Review {
  final dynamic key;
  final String productKey;
  final double rating;
  final String text;
  final int helpful;
  final String user;
  final DateTime createdAt;

  Review({this.key, required this.productKey, required this.rating, required this.text, required this.helpful, required this.user, required this.createdAt});

  factory Review.fromMap(dynamic key, Map map) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return Review(
      key: key,
      productKey: (map['product'] ?? '').toString(),
      rating: asDouble(map['rating']),
      text: (map['text'] ?? '').toString(),
      helpful: asInt(map['helpful']),
      user: (map['user'] ?? 'Anonymous').toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() => {
        'product': productKey,
        'rating': rating,
        'text': text,
        'helpful': helpful,
        'user': user,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

class ReviewsService {
  ReviewsService._();
  static final ReviewsService instance = ReviewsService._();

  final ValueNotifier<List<Review>> _reviews = ValueNotifier<List<Review>>(<Review>[]);
  String _productKey = '';
  StreamSubscription? _sub;

  ValueListenable<List<Review>> bind(String productKey) {
    _productKey = productKey;
    _reload();
    _sub?.cancel();
    _sub = DbService.instance.ratings.watch().listen((_) => _reload());
    return _reviews;
  }

  Future<void> _reload() async {
    await DbService.instance.init();
    final box = DbService.instance.ratings;
    final list = <Review>[];
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is Map) {
        final r = Review.fromMap(k, Map<String, dynamic>.from(v));
        if (r.productKey == _productKey) list.add(r);
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _reviews.value = list;
  }

  Future<void> addReview({required String productKey, required double rating, required String text, String user = 'Anonymous'}) async {
    await DbService.instance.init();
    final box = DbService.instance.ratings;
    await box.add({
      'product': productKey,
      'rating': rating,
      'text': text,
      'user': user,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'helpful': 0,
    });
    _reload();
  }

  Future<void> incrementHelpful(dynamic key) async {
    await DbService.instance.init();
    final box = DbService.instance.ratings;
    final raw = box.get(key);
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final c = (m['helpful'] is int) ? m['helpful'] as int : int.tryParse('${m['helpful'] ?? 0}') ?? 0;
      m['helpful'] = c + 1;
      await box.put(key, m);
      _reload();
    }
  }
}
