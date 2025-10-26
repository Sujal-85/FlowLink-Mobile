import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowlink_mobile/services/user_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flowlink_mobile/services/user_repository.dart';
import 'package:flowlink_mobile/services/notification_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  bool _initialized = false;
  // True when a default FirebaseApp is available and FirebaseAuth may be used safely.
  bool _firebaseReady = false;

  Future<void> init() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        // Initialize with provided web credentials
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBHna-sAWDDJw03gBLnC1B2clrgYUo5MV8",
            authDomain: "flowlink-24f55.firebaseapp.com",
            projectId: "flowlink-24f55",
            storageBucket: "flowlink-24f55.firebasestorage.app",
            messagingSenderId: "789325270587",
            appId: "1:789325270587:web:8a33dd627cca10af96961e",
            measurementId: "G-361JXWJTKF"
          ),
        );
      } else {
        // For Android/iOS/desktop, expects platform configs (google-services files).
        // If not present, this call will throw. Surround with try to avoid crash and keep app usable.
        try {
          await Firebase.initializeApp();
        } catch (_) {
          // No native config present; continue without Firebase.
        }
      }
    }
    // Determine if Firebase was successfully initialized on this platform.
    _firebaseReady = Firebase.apps.isNotEmpty;
    _initialized = true;

    // If Firebase is not ready (e.g. missing google-services.json), skip auth wiring gracefully.
    if (!_firebaseReady) {
      return;
    }

    // Sync initial display name if already logged in
    try {
      final u = _auth.currentUser;
      if (u != null) {
        final name = (u.displayName ?? u.email ?? '').trim();
        UserService.instance.setUser(
          name: name,
          emailAddress: u.email ?? '',
          photo: u.photoURL ?? '',
          phoneNumber: u.phoneNumber ?? '',
        );
      }
    } catch (_) {}

    // Listen for auth state changes and keep displayName in sync
    try {
      _auth.userChanges().listen((user) {
        final name = ((user?.displayName?.trim().isNotEmpty ?? false)
                ? user!.displayName!
                : (user?.email ?? ''))
            .trim();
        UserService.instance.setUser(
          name: name,
          emailAddress: user?.email ?? '',
          photo: user?.photoURL ?? '',
          phoneNumber: user?.phoneNumber ?? '',
        );
      });
    } catch (_) {}
  }

  void _syncName(User? u) {
    final name = ((u?.displayName?.trim().isNotEmpty ?? false) ? u!.displayName : (u?.email ?? ''))?.trim() ?? '';
    UserService.instance.setUser(
      name: name,
      emailAddress: u?.email ?? '',
      photo: u?.photoURL ?? '',
      phoneNumber: u?.phoneNumber ?? '',
    );
    try {
      UserRepository.instance.ensureUserDoc(u);
    } catch (_) {}
  }

  Future<UserCredential> signInWithEmailPassword({required String email, required String password}) async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    _syncName(cred.user);
    return cred;
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
    }
    _syncName(cred.user);
    return cred;
  }

  Future<void> signOut() async {
    if (!_firebaseReady) {
      // No-op when auth is unavailable
      UserService.instance.setDisplayName('');
      return;
    }
    await _auth.signOut();
    UserService.instance.setDisplayName('');
  }

  User? get currentUser {
    if (!_firebaseReady) return null;
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Google sign-in
  Future<UserCredential> signInWithGoogle() async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.setCustomParameters({'prompt': 'select_account'});
      final cred = await _auth.signInWithPopup(provider);
      _syncName(cred.user);
      try {
        final user = cred.user;
        final to = user?.email ?? '';
        final displayName = ((user?.displayName?.trim().isNotEmpty ?? false)
                ? user!.displayName!.trim()
                : (to.isNotEmpty ? to.split('@').first : 'there'));
        await NotificationService.instance.sendWelcomeEmail(toEmail: to, displayName: displayName);
      } catch (_) {}
      return cred;
    } else {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        throw Exception('Sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      _syncName(cred.user);
      try {
        final user = cred.user;
        final to = user?.email ?? '';
        final displayName = ((user?.displayName?.trim().isNotEmpty ?? false)
                ? user!.displayName!.trim()
                : (to.isNotEmpty ? to.split('@').first : 'there'));
        await NotificationService.instance.sendWelcomeEmail(toEmail: to, displayName: displayName);
      } catch (_) {}
      return cred;
    }
  }

  // Microsoft sign-in (OAuth)
  Future<UserCredential> signInWithMicrosoft() async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    final provider = OAuthProvider('microsoft.com');
    provider.addScope('User.Read');
    provider.setCustomParameters({'tenant': 'common'});
    if (kIsWeb) {
      final cred = await _auth.signInWithPopup(provider);
      _syncName(cred.user);
      return cred;
    } else {
      final cred = await _auth.signInWithProvider(provider);
      _syncName(cred.user);
      return cred;
    }
  }

  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
    int? forceResendingToken,
  }) async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (cred) async {
        try {
          if (_auth.currentUser != null) {
            await _auth.currentUser!.linkWithCredential(cred);
          } else {
            await _auth.signInWithCredential(cred);
          }
        } catch (_) {}
      },
      verificationFailed: onError,
      codeSent: (id, token) => onCodeSent(id, token),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> signInWithSmsCode({required String verificationId, required String smsCode}) async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    if (_auth.currentUser != null && _auth.currentUser!.phoneNumber == null) {
      try {
        final linked = await _auth.currentUser!.linkWithCredential(cred);
        _syncName(linked.user);
        try {
          final user = linked.user;
          final phone = user?.phoneNumber ?? '';
          final displayName = ((user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName!.trim() : 'there');
          await NotificationService.instance.sendWelcomeSms(phoneNumber: phone, displayName: displayName);
        } catch (_) {}
        return linked;
      } catch (_) {}
    }
    final signed = await _auth.signInWithCredential(cred);
    _syncName(signed.user);
    try {
      final user = signed.user;
      final phone = user?.phoneNumber ?? '';
      final displayName = ((user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName!.trim() : 'there');
      await NotificationService.instance.sendWelcomeSms(phoneNumber: phone, displayName: displayName);
    } catch (_) {}
    return signed;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword({required String currentPassword, required String newPassword}) async {
    if (!_firebaseReady) {
      throw Exception('Authentication is not configured for this build.');
    }
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not signed in');
    if (u.email != null && u.email!.isNotEmpty) {
      final cred = EmailAuthProvider.credential(email: u.email!, password: currentPassword);
      await u.reauthenticateWithCredential(cred);
    }
    await u.updatePassword(newPassword);
    await u.reload();
  }
}
