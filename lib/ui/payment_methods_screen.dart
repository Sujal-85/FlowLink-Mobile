import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<String> _cards = [];
  final TextEditingController _number = TextEditingController();
  final TextEditingController _expiry = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_cards_v1') ?? [];
    setState(() => _cards.addAll(list));
  }

  Future<void> _save() async {
    final n = _number.text.trim();
    final e = _expiry.text.trim();
    if (n.length < 12 || e.isEmpty) return;
    final masked = '•••• ${n.substring(n.length - 4)}  ($e)';
    setState(() => _cards.add(masked));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_cards_v1', _cards);
    _number.clear();
    _expiry.clear();
  }

  Future<void> _remove(int index) async {
    setState(() => _cards.removeAt(index));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_cards_v1', _cards);
  }

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Saved Cards', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_cards.isEmpty)
            const Text('No saved cards yet', style: TextStyle(color: Colors.black54))
          else
            ...List.generate(_cards.length, (i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: Text(_cards[i]),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(i)),
                  ),
                )),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Card number'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _expiry,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(hintText: 'Expiry MM/YY'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Card'),
            ),
          ),
        ],
      ),
    );
  }
}
