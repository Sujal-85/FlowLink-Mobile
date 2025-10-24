import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpiRepository {
  UpiRepository._();
  static final UpiRepository instance = UpiRepository._();

  static bool get _firebaseReady => Firebase.apps.isNotEmpty;
  final String _spKey = 'saved_upi_ids_v1';

  Future<List<String>> listUpiIds() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_firebaseReady && user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('upi_ids')
            .orderBy('createdAt', descending: true)
            .get();
        final ids = <String>[];
        for (final d in snap.docs) {
          final v = (d.data()['vpa'] ?? '').toString().trim();
          if (v.isNotEmpty) ids.add(v);
        }
        return ids;
      }
    } catch (_) {}

    // Local fallback
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? const <String>[];
    // Stored as plain strings; if legacy JSON, attempt decode
    final result = <String>[];
    for (final s in list) {
      if (s.trim().isEmpty) continue;
      try {
        final m = jsonDecode(s);
        if (m is Map && (m['vpa'] ?? '').toString().isNotEmpty) {
          result.add((m['vpa']).toString());
          continue;
        }
      } catch (_) {}
      result.add(s);
    }
    return result;
  }

  Future<void> addUpiId(String vpa) async {
    final v = vpa.trim();
    if (v.isEmpty) return;

    // Remote preferred
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_firebaseReady && user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('upi_ids')
            .add({
          'vpa': v,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }
    } catch (_) {}

    // Local fallback
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? <String>[];
    // Avoid duplicates
    if (!list.contains(v)) list.insert(0, v);
    await sp.setStringList(_spKey, list);
  }

  Future<void> removeUpiId(String vpa) async {
    final v = vpa.trim();
    if (v.isEmpty) return;

    // Remote preferred
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_firebaseReady && user != null) {
        final q = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('upi_ids')
            .where('vpa', isEqualTo: v)
            .get();
        for (final d in q.docs) {
          await d.reference.delete();
        }
        return;
      }
    } catch (_) {}

    // Local fallback
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? <String>[];
    list.removeWhere((s) => s.trim() == v);
    await sp.setStringList(_spKey, list);
  }
}
