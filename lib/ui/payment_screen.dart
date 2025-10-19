import 'package:flutter/material.dart';
import 'package:flowlink_mobile/widgets/success_dialog.dart';
import 'package:flowlink_mobile/widgets/feedback_dialog.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/services/address_service.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/utils/upi_payment.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.total});
  final double total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // UPI
  String _upiProvider = '';// 'gpay' | 'phonepe' | 'paytm' | ''
  final TextEditingController _upiId = TextEditingController();

  // Card
  int _savedCardIndex = -1; // -1 none selected
  final List<String> _savedCards = ['•••• 4242 (Visa)', '•••• 1111 (Mastercard)'];
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _cardExpiry = TextEditingController();
  final TextEditingController _cardCvv = TextEditingController();
  final bool _saveCard = true;

  // NetBanking
  final String _bank = '';
  final List<String> _banks = const ['HDFC', 'ICICI', 'SBI', 'Axis', 'Kotak'];

  // COD
  final bool _codAgree = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = CartService.instance.entries.value;
    final itemsCount = entries.fold<int>(0, (acc, e) => acc + e.qty);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Options', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('$itemsCount items. Total: ₹${widget.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            _addressSummary(),
            const SizedBox(height: 12),
            _promoBanner(),
            const SizedBox(height: 12),
            _preferredPaymentCard(),
            const SizedBox(height: 16),
            _upiOptionsCard(),
            const SizedBox(height: 16),
            _cardsListCard(),
            const SizedBox(height: 16),
            _morePaymentOptions(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ---------------- Header helpers ----------------
  Widget _addressSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<Address?>(
                valueListenable: AddressService.instance.selected,
                builder: (context, addr, _) {
                  final title = addr == null ? 'Add delivery address' : addr.addressLine ?? addr.landmark ?? addr.city;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Delivery in 10 mins', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _promoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.local_offer_outlined, color: Colors.deepOrange),
            SizedBox(width: 10),
            Expanded(
              child: Text('Avail single-click payments, instant refunds and cashbacks!'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------- Preferred Payment ---------------
  Widget _preferredPaymentCard() {
    final card = _savedCards.isNotEmpty ? _savedCards.first : 'Add Card';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferred Payment', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 14, backgroundColor: Colors.blue, child: Text('V', style: TextStyle(color: Colors.white))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(card, style: const TextStyle(fontWeight: FontWeight.w700))),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cardCvv,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'CVV'),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _cardCvv.text.trim().length >= 3 ? _payNow : null,
                        child: Text('PAY  ₹${widget.total.toStringAsFixed(0)}'),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UPI Section ----------------
  Widget _upiOptionsCard() {
    final upiIds = <String>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UPI', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                ...upiIds.map((id) => RadioListTile<String>(
                      value: id,
                      groupValue: _upiProvider,
                      onChanged: (v) => setState(() => _upiProvider = v ?? ''),
                      title: Text(id),
                    )),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.deepOrange),
                  title: const Text('Add New UPI ID'),
                  onTap: _showAddUpiIdSheet,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (_upiProvider.isNotEmpty || _upiId.text.trim().isNotEmpty)
                          ? () async {
                              // Determine the UPI ID to use: selected provider value or entered ID
                              // final vpa = (_upiProvider.isNotEmpty ? _upiProvider : _upiId.text).trim();
                              // Use order total as amount and a readable merchant/payee name
                              final amount = widget.total.toStringAsFixed(2);
                              const name = 'FlowLink Store';
                              const String vpa = 'khedekarsujay5-1@okicici';

                              await initiateUpiPayment(
                                context,
                                upiId: vpa,
                                name: name,
                                amount: amount,
                                // note defaults to 'FlowLink Payment'
                              );
                            }
                          : null,
                      child: Text('Pay with UPI  •  ₹${widget.total.toStringAsFixed(0)}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUpiIdSheet() async {
    final controller = TextEditingController(text: _upiId.text);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add UPI ID', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(controller: controller, decoration: const InputDecoration(hintText: 'yourname@upi')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _upiId.text = controller.text.trim();
                        _upiProvider = _upiId.text;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------- Cards Section ---------------
  Widget _cardsListCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Credit & Debit cards', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                ...List.generate(_savedCards.length, (i) => RadioListTile<int>(
                      value: i,
                      groupValue: _savedCardIndex,
                      onChanged: (v) => setState(() => _savedCardIndex = v ?? -1),
                      title: Text(_savedCards[i]),
                    )),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.deepOrange),
                  title: const Text('Add New Card'),
                  onTap: _showAddCardSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCardSheet() async {
    _cardNumber.clear();
    _cardExpiry.clear();
    _cardCvv.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(alignment: Alignment.centerLeft, child: Text('Add New Card', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                const SizedBox(height: 12),
                TextField(controller: _cardNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Card Number')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _cardExpiry, keyboardType: TextInputType.datetime, decoration: const InputDecoration(hintText: 'MM/YY'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _cardCvv, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'CVV'), obscureText: true)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final last4 = _cardNumber.text.trim().padLeft(4, '•').substring(_cardNumber.text.trim().length - 4);
                      setState(() { _savedCards.add('•••• $last4'); });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Card'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------- More options ---------------
  Widget _morePaymentOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('More Payment Options', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Wallets'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.credit_card), title: const Text('Sodexo'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.account_balance_outlined), title: const Text('Netbanking'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.local_shipping_outlined), title: const Text('Pay on Delivery'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
              ],
            ),
          ),
        ],
      ),
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

  // Removed tab-based sections; the new design uses a single scrollable page

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
      buttonText: 'Continue',
      onContinue: () {
        final ids = created.map((o) => o.id).toList();
        Future.microtask(() async {
          await showFeedbackDialog(context, orderIds: ids);
          if (!context.mounted) return;
          // Close PaymentScreen and go to Orders after feedback
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/orders');
        });
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
