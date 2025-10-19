import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  late Box _notifications;
  late Box _contacts;
  late Box _faqs;
  late Box _ratings;
  bool _inited = false;

  Box get notifications => _notifications;
  Box get contacts => _contacts;
  Box get faqs => _faqs;
  Box get ratings => _ratings;

  Future<void> init() async {
    if (_inited) return;
    await Hive.initFlutter();
    _notifications = await Hive.openBox('notifications');
    _contacts = await Hive.openBox('contacts');
    _faqs = await Hive.openBox('faqs');
    _ratings = await Hive.openBox('ratings');
    _inited = true;
  }
}
