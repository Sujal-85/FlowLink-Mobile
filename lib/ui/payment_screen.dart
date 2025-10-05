import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/widgets/success_dialog.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/services/address_service.dart';
import 'package:flowlink_mobile/services/cart_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.total});
  final double total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  // UPI
  String _upiProvider = '';// 'gpay' | 'phonepe' | 'paytm' | ''
  final TextEditingController _upiId = TextEditingController();

  // Card
  int _savedCardIndex = -1; // -1 none selected
  final List<String> _savedCards = const ['•••• 4242 (Visa)', '•••• 1111 (Mastercard)'];
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _cardExpiry = TextEditingController();
  final TextEditingController _cardCvv = TextEditingController();
  bool _saveCard = true;

  // NetBanking
  String _bank = '';
  final List<String> _banks = const ['HDFC', 'ICICI', 'SBI', 'Axis', 'Kotak'];

  // COD
  bool _codAgree = false;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _upiId.addListener(_refresh);
    _cardNumber.addListener(_refresh);
    _cardExpiry.addListener(_refresh);
    _cardCvv.addListener(_refresh);
  }

  @override
  void dispose() {
    _upiId.dispose();
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text('Secure Checkout 🔒', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black87,
                tabs: const [
                  Tab(text: 'UPI'),
                  Tab(text: 'Card'),
                  Tab(text: 'Net Banking'),
                  Tab(text: 'Cash on Delivery'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _upiTab(),
                  _cardTab(),
                  _netBankingTab(),
                  _codTab(),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------------- UPI ----------------
  Widget _upiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Choose UPI App', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          _upiAppButton(
            label: 'GPay',
            value: 'gpay',
            icon: Image.asset('assets/images/google.png', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_outlined)),
          ),
          const SizedBox(width: 8),
          _upiAppButton(
            label: 'PhonePe',
            value: 'phonepe',
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.deepPurple),
          ),
          const SizedBox(width: 8),
          _upiAppButton(
            label: 'Paytm',
            value: 'paytm',
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Or enter UPI ID', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: _upiId,
          decoration: const InputDecoration(hintText: 'yourname@upi'),
        ),
      ],
    );
  }

  Widget _upiChip(String label, String value) {
    final active = _upiProvider == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _upiProvider = value),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? Colors.white : Colors.grey.shade100,
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? Colors.black87 : Colors.black54)),
          ),
        ),
      ),
    );
  }

  // ---------------- Card ----------------
  Widget _cardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_savedCards.isNotEmpty) ...[
          const Text('Saved Cards', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...List.generate(_savedCards.length, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: RadioListTile<int>(
                value: i,
                groupValue: _savedCardIndex,
                onChanged: (v) => setState(() => _savedCardIndex = v ?? -1),
                title: Text(_savedCards[i]),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
        const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _cardNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Card Number'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiry,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(hintText: 'MM/YY'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cardCvv,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'CVV'),
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Checkbox(value: _saveCard, onChanged: (v) => setState(() => _saveCard = v ?? true)),
            const Text('Save card for future payments'),
          ],
        ),
      ],
    );
  }

  // ------------- Net Banking -------------
  Widget _netBankingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Select Bank', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _banks.map((b) {
            final active = _bank == b;
            return ChoiceChip(
              label: Text(b),
              selected: active,
              onSelected: (_) => setState(() => _bank = b),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ------------- COD -------------
  Widget _codTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Pay with cash upon delivery. Please ensure someone is available to receive the order.'),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(value: _codAgree, onChanged: (v) => setState(() => _codAgree = v ?? false)),
            const Expanded(child: Text('I agree to have the exact amount ready.')),
          ],
        ),
      ],
    );
  }

  // Bottom bar
  Widget _bottomBar() {
    final canPay = _canPay();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppColors.primaryGradient,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: canPay ? _payNow : null,
                child: Text('Pay Now • ₹${widget.total.toStringAsFixed(0)}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canPay() {
    switch (_tabController.index) {
      case 0: // UPI
        return _upiProvider.isNotEmpty || _upiId.text.trim().isNotEmpty;
      case 1: // Card
        final savedSelected = _savedCardIndex >= 0;
        final newCardFilled = _cardNumber.text.trim().length >= 12 && _cardExpiry.text.trim().isNotEmpty && _cardCvv.text.trim().length >= 3;
        return savedSelected || newCardFilled;
      case 2: // Net Banking
        return _bank.isNotEmpty;
      case 3: // COD
        return _codAgree;
      default:
        return false;
    }
  }

  Future<void> _payNow() async {
    // Create orders from current cart entries
    final address = AddressService.instance.selected.value;
    final entries = CartService.instance.entries.value;
    final now = DateTime.now();
    final created = <OrderItem>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      created.add(OrderItem(
        id: '#FL-${now.millisecondsSinceEpoch}-${i + 1}',
        productName: e.item.name,
        imageUrl: e.item.imageUrl.isNotEmpty ? e.item.imageUrl : 'https://via.placeholder.com/300x300.png?text=Product',
        price: e.lineTotal,
        expectedDate: now.add(const Duration(days: 2)),
        stageIndex: 0,
        originLat: 19.0760,
        originLng: 72.8777,
        destLat: address?.lat ?? 0.0,
        destLng: address?.lng ?? 0.0,
      ));
    }
    if (created.isNotEmpty) {
      await OrdersService.instance.addOrders(created);
      CartService.instance.clear();
    }

    await showSuccessDialog(
      context,
      title: 'Payment Successful',
      message: 'Your order has been placed successfully. Thank you for shopping with FlowLink!',
      buttonText: 'View Orders',
      onContinue: () {
        // Close PaymentScreen and go to Orders
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/orders');
      },
    );
  }

  // UPI app pill with icon
  Widget _upiAppButton({required String label, required String value, Widget? icon}) {
    final active = _upiProvider == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _upiProvider = value),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? Colors.white : Colors.grey.shade100,
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon, const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? Colors.black87 : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
