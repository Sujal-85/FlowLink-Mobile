import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFA = false;
  bool _biometric = false;
  bool _alerts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _twoFA = prefs.getBool('sec_two_fa') ?? false;
      _biometric = prefs.getBool('sec_bio') ?? false;
      _alerts = prefs.getBool('sec_alerts') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sec_two_fa', _twoFA);
    await prefs.setBool('sec_bio', _biometric);
    await prefs.setBool('sec_alerts', _alerts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Two-Factor Authentication'),
            value: _twoFA,
            onChanged: (v) => setState(() => _twoFA = v),
          ),
          SwitchListTile(
            title: const Text('Biometric Unlock'),
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          SwitchListTile(
            title: const Text('Security Alerts'),
            value: _alerts,
            onChanged: (v) => setState(() => _alerts = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await _save();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security settings saved')));
                }
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
