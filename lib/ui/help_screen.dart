import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'How can we assist you?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text('• Use the search to find products.'),
            SizedBox(height: 6),
            Text('• Tap a category to browse.'),
            SizedBox(height: 6),
            Text('• Add items to cart and checkout.'),
            SizedBox(height: 20),
            Text('If you need more help, contact support at support@flowlink.app'),
          ],
        ),
      ),
    );
  }
}
