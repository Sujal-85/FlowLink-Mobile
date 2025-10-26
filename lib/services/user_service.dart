import 'package:flutter/foundation.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  // Reactive display name for the currently logged-in user.
  // Update this after login to reflect the correct name in the UI.
  final ValueNotifier<String> displayName = ValueNotifier<String>('');
  // Reactive email for the current user
  final ValueNotifier<String> email = ValueNotifier<String>('');
  // Reactive photo url for the current user
  final ValueNotifier<String> photoUrl = ValueNotifier<String>('');
  // Reactive phone for the current user
  final ValueNotifier<String> phone = ValueNotifier<String>('');

  void setDisplayName(String name) {
    displayName.value = name.trim();
  }

  void setEmail(String value) {
    email.value = value.trim();
  }

  void setPhotoUrl(String value) {
    photoUrl.value = value.trim();
  }

  void setPhone(String value) {
    phone.value = value.trim();
  }

  void setUser({String? name, String? emailAddress, String? photo, String? phoneNumber}) {
    if (name != null) setDisplayName(name);
    if (emailAddress != null) setEmail(emailAddress);
    if (photo != null) setPhotoUrl(photo);
    if (phoneNumber != null) setPhone(phoneNumber);
  }
}
