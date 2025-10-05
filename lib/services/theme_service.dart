import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _key = 'theme_mode_v1';

  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      switch (v) {
        case 'light':
          mode.value = ThemeMode.light;
          break;
        case 'dark':
          mode.value = ThemeMode.dark;
          break;
        default:
          mode.value = ThemeMode.system;
      }
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = switch (m) { ThemeMode.light => 'light', ThemeMode.dark => 'dark', _ => 'system' };
      await prefs.setString(_key, v);
    } catch (_) {}
  }
}
