import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardSummary {
  final String id;
  final String last4;
  final String brand;
  final int expMonth;
  final int expYear;
  final String? holder;

  const CardSummary({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
    this.holder,
  });

  String get maskedLabel => '•••• $last4  (${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')})  ·  $brand';

  Map<String, dynamic> toJson() => {
        'id': id,
        'last4': last4,
        'brand': brand,
        'expMonth': expMonth,
        'expYear': expYear,
        if (holder != null) 'holder': holder,
      };

  factory CardSummary.fromJson(Map<String, dynamic> json) => CardSummary(
        id: (json['id'] ?? '').toString(),
        last4: (json['last4'] ?? '').toString(),
        brand: (json['brand'] ?? '').toString(),
        expMonth: (json['expMonth'] ?? 0) is int
            ? json['expMonth'] as int
            : int.tryParse(json['expMonth'].toString()) ?? 0,
        expYear: (json['expYear'] ?? 0) is int
            ? json['expYear'] as int
            : int.tryParse(json['expYear'].toString()) ?? 0,
        holder: (json['holder'] ?? '').toString().isEmpty ? null : (json['holder'] ?? '').toString(),
      );
}

class PaymentRepository {
  PaymentRepository._();
  static final PaymentRepository instance = PaymentRepository._();

  static bool get _firebaseReady => Firebase.apps.isNotEmpty;
  final _spKey = 'saved_cards_v2';

  Future<List<CardSummary>> listCards() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_firebaseReady && user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((d) {
          final data = d.data();
          return CardSummary(
            id: d.id,
            last4: (data['last4'] ?? '').toString(),
            brand: (data['brand'] ?? '').toString(),
            expMonth: (data['expMonth'] ?? 0) is int
                ? data['expMonth'] as int
                : int.tryParse(data['expMonth'].toString()) ?? 0,
            expYear: (data['expYear'] ?? 0) is int
                ? data['expYear'] as int
                : int.tryParse(data['expYear'].toString()) ?? 0,
            holder: (data['holder'] ?? '').toString().isEmpty ? null : (data['holder']).toString(),
          );
        }).toList();
      }
    } catch (_) {}

    // Fallback to local
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? const <String>[];
    return list
        .map((s) {
          try {
            return CardSummary.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<CardSummary>()
        .toList();
  }

  Future<CardSummary> addCard({
    required String pan,
    required int expMonth,
    required int expYear,
    String? holder,
  }) async {
    final last4 = pan.replaceAll(RegExp(r'\s+'), '').padLeft(4, '0').substring(pan.replaceAll(RegExp(r'\s+'), '').length - 4);
    final brand = _detectBrand(pan);

    // Remote first if possible
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_firebaseReady && user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .add({
          'last4': last4,
          'brand': brand,
          'expMonth': expMonth,
          'expYear': expYear,
          if (holder != null && holder.trim().isNotEmpty) 'holder': holder.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return CardSummary(
          id: doc.id,
          last4: last4,
          brand: brand,
          expMonth: expMonth,
          expYear: expYear,
          holder: holder?.trim().isEmpty == true ? null : holder?.trim(),
        );
      }
    } catch (_) {}

    // Fallback to local storage (no PAN is persisted)
    final item = CardSummary(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      last4: last4,
      brand: brand,
      expMonth: expMonth,
      expYear: expYear,
      holder: holder?.trim().isEmpty == true ? null : holder?.trim(),
    );
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? <String>[];
    list.insert(0, jsonEncode(item.toJson()));
    await sp.setStringList(_spKey, list);
    return item;
  }

  Future<void> removeCard(String id) async {
    // Try remote
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_firebaseReady && user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .doc(id)
            .delete();
        return;
      }
    } catch (_) {}

    // Local fallback
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? <String>[];
    final filtered = list.where((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return (m['id'] ?? '') != id;
      } catch (_) {
        return true;
      }
    }).toList();
    await sp.setStringList(_spKey, filtered);
  }

  String _detectBrand(String pan) {
    final d = pan.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'^4[0-9]{6,}$').hasMatch(d)) return 'Visa';
    if (RegExp(r'^(5[1-5][0-9]{5,}|2(22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7([01][0-9]|20))[0-9]{3,})$').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^3[47][0-9]{5,}$').hasMatch(d)) return 'Amex';
    if (RegExp(r'^(6011|65|64[4-9])[0-9]{5,}$').hasMatch(d)) return 'Discover';
    if (RegExp(r'^(35)[0-9]{6,}$').hasMatch(d)) return 'JCB';
    return 'Card';
  }
}
