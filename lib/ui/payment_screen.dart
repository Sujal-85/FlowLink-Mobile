import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flowlink_mobile/widgets/success_dialog.dart';
import 'package:flowlink_mobile/widgets/feedback_dialog.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/services/address_service.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/services/upi_repository.dart';
import 'package:flowlink_mobile/ui/payment_upi_pending_screen.dart';
import 'package:flowlink_mobile/utils/upi_payment.dart';
import 'package:flowlink_mobile/services/payment_repository.dart';
import 'package:flowlink_mobile/ui/payment_methods_screen.dart';
import 'package:flowlink_mobile/utils/razorpay_stub.dart'
      if (dart.library.io) 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.total});
  final double total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // UPI
  String _upiProvider = '';// holds selected UPI ID (VPA)
  final TextEditingController _upiId = TextEditingController();
  List<String> _savedUpiIds = <String>[];
  Map<String, bool> _installedUpiApps = {'gpay': false, 'phonepe': false, 'paytm': false};
  String _selectedApp = '';

  // Card
  int _savedCardIndex = -1; // index into _cards, -1 none selected
  List<CardSummary> _cards = <CardSummary>[];
  final TextEditingController _cardCvv = TextEditingController();

  // NetBanking
  final String _bank = '';
  final List<String> _banks = const ['HDFC', 'ICICI', 'SBI', 'Axis', 'Kotak'];

  // COD
  final bool _codAgree = false;

  Razorpay? _razorpay;
  final String _razorpayKey = const String.fromEnvironment('RAZORPAY_KEY', defaultValue: '');

  bool get _rzpSupported {
    final p = defaultTargetPlatform;
    return !kIsWeb && (p == TargetPlatform.android || p == TargetPlatform.iOS);
  }

  double get _onlineDiscount => widget.total >= 300 ? 20.0 : 10.0;
  double _payableOnline() => (widget.total - _onlineDiscount).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _upiId.addListener(_refresh);
    _cardCvv.addListener(_refresh);
    _loadUpiAndApps();
    _loadCards();
    if (_rzpSupported) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRzpSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onRzpError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRzpExternal);
    }
  }

  @override
  void dispose() {
    _upiId.dispose();
    _cardCvv.dispose();
    try { _razorpay?.clear(); } catch (_) {}
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUpiAndApps() async {
    try {
      final ids = await UpiRepository.instance.listUpiIds();
      if (!mounted) return;
      setState(() {
        _savedUpiIds = ids;
        if (_upiProvider.isEmpty && ids.isNotEmpty) _upiProvider = ids.first;
      });
    } catch (_) {}
    try {
      final apps = await detectInstalledUpiApps();
      if (!mounted) return;
      setState(() => _installedUpiApps = apps);
    } catch (_) {}
  }

  Future<void> _loadCards() async {
    try {
      final list = await PaymentRepository.instance.listCards();
      if (!mounted) return;
      setState(() {
        _cards = list;
        if (_cards.isNotEmpty && (_savedCardIndex < 0 || _savedCardIndex >= _cards.length)) {
          _savedCardIndex = 0;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final entries = CartService.instance.entries.value;
    final itemsCount = entries.fold<int>(0, (acc, e) => acc + e.qty);
    final bottomBarH = 68.0;
    final bottomPad = 24 + MediaQuery.of(context).padding.bottom + bottomBarH;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Options', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('$itemsCount items. Total: ₹${widget.total.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.onSurface),
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
                      Text('Delivery in 10 mins', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontSize: 12)),
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
          color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.withOpacity(0.16) : const Color(0xFFFFF0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined, color: Colors.deepOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Pay online and get ₹${_onlineDiscount.toStringAsFixed(0)} OFF instantly. Not applicable on COD.'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------- Preferred Payment ---------------
  Widget _preferredPaymentCard() {
    final hasCards = _cards.isNotEmpty;
    final card = hasCards
        ? _cards[(_savedCardIndex >= 0 && _savedCardIndex < _cards.length) ? _savedCardIndex : 0].maskedLabel
        : 'Add Card';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferred Payment', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: Theme.of(context).colorScheme.primary, child: const Text('V', style: TextStyle(color: Colors.white))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(card, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (hasCards) const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _rzpSupported ? _startRazorpayCheckout : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online card/netbanking checkout is only available on Android/iOS'))),
                        child: Text('Pay Online  •  ₹${_payableOnline().toStringAsFixed(0)}'),
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
    final upiIds = _savedUpiIds;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UPI', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                if (_installedUpiApps.values.any((v) => v))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Row(
                      children: [
                        if (_installedUpiApps['gpay'] == true)
                          _upiAppPill(label: 'GPay', code: 'gpay', icon: const Icon(Icons.payments_outlined)),
                        if (_installedUpiApps['phonepe'] == true) ...[
                          const SizedBox(width: 8),
                          _upiAppPill(label: 'PhonePe', code: 'phonepe', icon: const Icon(Icons.account_balance_wallet_outlined)),
                        ],
                        if (_installedUpiApps['paytm'] == true) ...[
                          const SizedBox(width: 8),
                          _upiAppPill(label: 'Paytm', code: 'paytm', icon: const Icon(Icons.account_balance_outlined)),
                        ],
                      ],
                    ),
                  ),
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
                              final vpa = (_upiProvider.isNotEmpty ? _upiProvider : _upiId.text).trim();
                              final amount = _payableOnline().toStringAsFixed(2);
                              const name = 'FlowLink Store';

                              if (_selectedApp.isNotEmpty && (_installedUpiApps[_selectedApp] == true)) {
                                await initiateUpiPaymentViaApp(
                                  context,
                                  upiId: vpa,
                                  name: name,
                                  amount: amount,
                                  app: _selectedApp,
                                );
                              } else {
                                await initiateUpiPayment(
                                  context,
                                  upiId: vpa,
                                  name: name,
                                  amount: amount,
                                );
                              }

                              final entries = CartService.instance.entries.value;
                              final itemsCount = entries.fold<int>(0, (acc, e) => acc + e.qty);
                              final confirmed = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UpiPendingScreen(total: _payableOnline(), itemsCount: itemsCount),
                                ),
                              );
                              if (confirmed == true) {
                                await _payNow();
                              }
                            }
                          : null,
                      child: Text('Pay with UPI  •  ₹${_payableOnline().toStringAsFixed(0)}'),
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
                    onPressed: () async {
                      final v = controller.text.trim();
                      if (v.isEmpty) return;
                      await UpiRepository.instance.addUpiId(v);
                      if (!mounted) return;
                      setState(() {
                        _upiId.text = v;
                        _upiProvider = v;
                        if (!_savedUpiIds.contains(v)) _savedUpiIds.insert(0, v);
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                ...List.generate(_cards.length, (i) => RadioListTile<int>(
                      value: i,
                      groupValue: _savedCardIndex,
                      onChanged: (v) => setState(() => _savedCardIndex = v ?? -1),
                      title: Text(_cards[i].maskedLabel),
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
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
    await _loadCards();
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                // ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Wallets'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                // const Divider(height: 1),
                // ListTile(leading: const Icon(Icons.credit_card), title: const Text('Sodexo'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                // const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: const Text('Netbanking'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _rzpSupported ? _startRazorpayCheckout : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Netbanking is only available on Android/iOS'))),
                ),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.local_shipping_outlined), title: const Text('Pay on Delivery'), trailing: const Icon(Icons.chevron_right), onTap: _showCodSheet),
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
            color: active ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
            boxShadow: Theme.of(context).brightness == Brightness.light && active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withOpacity(active ? 0.9 : 0.6))),
          ),
        ),
      ),
    );
  }

  // Removed tab-based sections; the new design uses a single scrollable page

  Future<void> _payNow({String title = 'Payment Successful', String message = 'Your order has been placed successfully. Thank you for shopping with FlowLink!',}) async {
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
      title: title,
      message: message,
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
            color: active ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
            boxShadow: Theme.of(context).brightness == Brightness.light && active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon, const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withOpacity(active ? 0.9 : 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  // App selector pill for UPI app preference
  Widget _upiAppPill({required String label, required String code, Widget? icon}) {
    final active = _selectedApp == code;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _selectedApp = active ? '' : code),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
            boxShadow: Theme.of(context).brightness == Brightness.light && active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon, const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withOpacity(active ? 0.9 : 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  void _startRazorpayCheckout() {
    final key = _razorpayKey.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online payments unavailable: configure RAZORPAY_KEY.')));
      return;
    }
    final amountPaise = (_payableOnline() * 100).round();
    final addr = AddressService.instance.selected.value;
    final options = {
      'key': key,
      'amount': amountPaise,
      'name': 'FlowLink',
      'description': 'Order Payment',
      'timeout': 300,
      'prefill': {
        'contact': addr?.mobile ?? '',
        'email': '',
      },
      'theme': {'color': '#1DB954'},
    };
    try {
      _razorpay?.open(options);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to start online payment')));
    }
  }

  void _onRzpSuccess(PaymentSuccessResponse r) async {
    await _payNow();
  }

  void _onRzpError(PaymentFailureResponse r) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed or cancelled')));
  }

  void _onRzpExternal(ExternalWalletResponse r) {}

  Future<void> _showCodSheet() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                Widget buttons;
                if (isNarrow) {
                  buttons = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _payNow(title: 'Order Placed', message: 'You chose Cash on Delivery. Please keep cash ready.');
                          },
                          child: Text('Place Order  •  ₹${widget.total.toStringAsFixed(0)}'),
                        ),
                      ),
                    ],
                  );
                } else {
                  buttons = Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _payNow(title: 'Order Placed', message: 'You chose Cash on Delivery. Please keep cash ready.');
                            },
                            child: Text('Place Order  •  ₹${widget.total.toStringAsFixed(0)}'),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Online payment discount is not applicable for COD.'),
                    const SizedBox(height: 12),
                    buttons,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
