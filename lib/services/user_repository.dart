import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:flowlink_mobile/services/cloudinary_service.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final _db = FirebaseFirestore.instance;

  Future<void> ensureUserDoc(User? user) async {
    if (user == null) return;
    final uid = user.uid;
    final doc = _db.collection('users').doc(uid);
    final now = FieldValue.serverTimestamp();
    await doc.set({
      'uid': uid,
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'providers': user.providerData.map((p) => p.providerId).toList(),
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> updateProfile({String? firstName, String? lastName, String? displayName, String? email, String? username, String? phone}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final now = FieldValue.serverTimestamp();
    final name = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : [firstName?.trim() ?? '', lastName?.trim() ?? ''].where((s) => s.isNotEmpty).join(' ').trim();
    final data = <String, dynamic>{
      if (firstName != null) 'firstName': firstName.trim(),
      if (lastName != null) 'lastName': lastName.trim(),
      if (email != null) 'email': email.trim(),
      if (username != null) 'username': username.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (name.isNotEmpty) 'displayName': name,
      'updatedAt': now,
    };
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    if (name.isNotEmpty) {
      try {
        await user.updateDisplayName(name);
      } catch (_) {}
    }
  }

  Future<String> uploadProfilePhoto(Uint8List data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final url = await CloudinaryService.instance.uploadImageBytes(
      data,
      folder: 'flowlink/users/${user.uid}',
      fileName: 'profile.jpg',
    );
    try {
      await _db.collection('users').doc(user.uid).set({
        'photoURL': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
    try {
      await user.updatePhotoURL(url);
    } catch (_) {}
    return url;
  }
}
