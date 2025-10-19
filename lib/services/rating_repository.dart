import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:flowlink_mobile/services/db_service.dart';

class RatingRepository {
  RatingRepository._();
  static final RatingRepository instance = RatingRepository._();

  final _db = FirebaseFirestore.instance;

  Future<void> submit({
    required int rating, // 1..5
    String comment = '',
  }) async {
    // Attempt Firestore first
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _db.collection('app_ratings').add({
        'uid': user?.uid,
        'rating': rating.clamp(1, 5),
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    } catch (_) {
      // Fallback to local Hive box
      try {
        final Box box = DbService.instance.ratings;
        await box.add({
          'rating': rating.clamp(1, 5),
          'comment': comment.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // swallow any final error
      }
    }
  }
}
