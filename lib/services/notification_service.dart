import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _emailUrl = String.fromEnvironment('EMAIL_WELCOME_URL', defaultValue: '');
  static const String _smsUrl = String.fromEnvironment('SMS_WELCOME_URL', defaultValue: '');
  static const String _apiKey = String.fromEnvironment('NOTIFY_API_KEY', defaultValue: '');

  Future<void> sendWelcomeEmail({required String toEmail, required String displayName}) async {
    if (_emailUrl.isEmpty || toEmail.trim().isEmpty) {
      if (kDebugMode) {
        print('[NotificationService] Skipping email, EMAIL_WELCOME_URL or toEmail empty');
      }
      return;
    }
    final payload = {
      'to': toEmail,
      'subject': 'Welcome to FlowLink',
      'message': 'Hello $displayName,\n\nWelcome to FlowLink! We are excited to have you on board.\n\nRegards,\nSujal Khedekar (Owner)\nFlowLink',
      'fromName': 'FlowLink',
    };
    try {
      final res = await http.post(
        Uri.parse(_emailUrl),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 400 && kDebugMode) {
        print('[NotificationService] Email send failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Email send error: $e');
      }
    }
  }

  Future<void> sendWelcomeSms({required String phoneNumber, required String displayName}) async {
    if (_smsUrl.isEmpty || phoneNumber.trim().isEmpty) {
      if (kDebugMode) {
        print('[NotificationService] Skipping SMS, SMS_WELCOME_URL or phone empty');
      }
      return;
    }
    final payload = {
      'to': phoneNumber,
      'message': 'Hi $displayName, welcome to FlowLink! - Sujal Khedekar (Owner)',
    };
    try {
      final res = await http.post(
        Uri.parse(_smsUrl),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 400 && kDebugMode) {
        print('[NotificationService] SMS send failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] SMS send error: $e');
      }
    }
  }
}
