import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackRepository {
  FeedbackRepository._();
  static final FeedbackRepository instance = FeedbackRepository._();

  final _db = FirebaseFirestore.instance;

  Future<void> submit({
    required List<String> orderIds,
    required int rating, // 1..5
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final now = FieldValue.serverTimestamp();
    await _db.collection('feedback').add({
      'uid': user.uid,
      'orderIds': orderIds,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': now,
    });
  }
}
