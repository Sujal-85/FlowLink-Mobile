import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/payment_repository.dart';
import 'package:card_scanner/card_scanner.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<CardSummary> _cards = [];
  bool _loading = true;

  // Manual entry controllers
  final _pan = TextEditingController();
  final _exp = TextEditingController(); // MM/YY
  final _holder = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await PaymentRepository.instance.listCards();
    if (!mounted) return;
    setState(() {
      _cards
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pan.dispose();
    _exp.dispose();
    _holder.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenPrimary, Color(0xFF0F4D42)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      const BackButton(color: Colors.white),
                      const Expanded(
                        child: Center(
                          child: Text('Payment Method', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      if (!kIsWeb)
                        IconButton(
                          onPressed: _onScanCard,
                          icon: const Icon(Icons.document_scanner_outlined, color: Colors.white),
                        )
                      else
                        const SizedBox(width: 48, height: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : (_cards.isEmpty ? _emptyState(context) : _cardsList(context)),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showAddCardSheet,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenPrimary),
                        child: const Text('Add Card'),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: theme.brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card, size: 72, color: theme.brightness == Brightness.dark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 16),
              Text('Card Empty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: on)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "It appears that you haven't acquired a credit or debit card as of yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: on.withOpacity(0.75)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardsList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...List.generate(_cards.length, (i) {
          final c = _cards[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.greenPrimary, Color(0xFF0F4D42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: Theme.of(context).brightness == Brightness.light
                    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.brand, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white70),
                        onPressed: () async {
                          await PaymentRepository.instance.removeCard(c.id);
                          await _refresh();
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text('•••• ${c.last4}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('VALID THRU  ${c.expMonth.toString().padLeft(2, '0')}/${(c.expYear % 100).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (c.holder != null) Flexible(child: Text(c.holder!.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ],
              ),
            ),
          );
        })
      ],
    );
  }

  Future<void> _onScanCard() async {
    // Let user choose between camera scan and manual entry
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Add Card', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined, color: Colors.deepOrange),
              title: const Text('Scan Card'),
              subtitle: const Text('Use camera to detect card number & expiry'),
              onTap: () async {
                Navigator.pop(ctx);
                await _scanViaCamera();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
              title: const Text('Enter Manually'),
              onTap: () {
                Navigator.pop(ctx);
                _pan.text = '';
                _exp.text = '';
                _holder.text = '';
                _cvv.text = '';
                _showManualEntrySheet();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _scanViaCamera() async {
    try {
      final options = CardScanOptions(
        scanCardHolderName: true,
        validCardsToScanBeforeFinishingScan: 1,
      );
      final details = await CardScanner.scanCard(scanOptions: options);
      if (details == null) {
        await _showManualEntrySheet();
        return;
      }
      final rawNumber = (details.cardNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      if (rawNumber.isEmpty) {
        await _showManualEntrySheet();
        return;
      }
      // Prefill fields and open manual confirmation sheet
      _pan.text = _groupPan(rawNumber);
      final exp = (details.expiryDate ?? '').trim();
      _exp.text = _normalizeExpiry(exp);
      _holder.text = (details.cardHolderName ?? '').trim();
      await _showManualEntrySheet();
    } catch (_) {
      await _showManualEntrySheet();
    }
  }

  Future<void> _scanNotAvailableDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scanner unavailable'),
        content: const Text('Card scanner can be enabled by adding the card_scanner dependency. For now, please enter details manually.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showAddCardSheet() => _onScanCard();

  Future<void> _showManualEntrySheet() async {
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
                const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.greenPrimary, Color(0xFF0F4D42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.light
                        ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))]
                        : null,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          _brandFor(_pan.text),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _pan.text.isEmpty ? '•••• •••• •••• ••••' : _pan.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('VALID THRU  ${_exp.text.isEmpty ? 'MM/YY' : _exp.text}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Flexible(child: Text((_holder.text.isEmpty ? 'CARD HOLDER' : _holder.text).toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pan,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Card Number'),
                  onChanged: (v) => _formatPan(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _exp,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(hintText: 'MM/YY'),
                      onChanged: (v) => _formatExpiry(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvv,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'CVV'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _holder,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Card holder (optional)'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final pan = _digitsOnly(_pan.text);
                      final exp = _exp.text.trim();
                      if (pan.length < 12 || !_validExpiry(exp)) return;
                      final parts = exp.split('/');
                      final month = int.tryParse(parts[0]) ?? 0;
                      final year = int.tryParse(parts[1].length == 2 ? '20${parts[1]}' : parts[1]) ?? 0;
                      final saved = await PaymentRepository.instance.addCard(
                        pan: pan,
                        expMonth: month,
                        expYear: year,
                        holder: _holder.text.trim().isEmpty ? null : _holder.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      setState(() => _cards.insert(0, saved));
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

  void _formatPan() {
    final digits = _digitsOnly(_pan.text);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final newText = buf.toString();
    if (newText != _pan.text) {
      final sel = newText.length;
      _pan.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: sel));
    }
    setState(() {});
  }

  String _groupPan(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  void _formatExpiry() {
    var d = _digitsOnly(_exp.text);
    if (d.length > 4) d = d.substring(0, 4);
    if (d.length >= 3) {
      d = '${d.substring(0, 2)}/${d.substring(2)}';
    }
    if (d != _exp.text) {
      _exp.value = TextEditingValue(text: d, selection: TextSelection.collapsed(offset: d.length));
    }
    setState(() {});
  }

  String _normalizeExpiry(String exp) {
    var s = exp.replaceAll(RegExp(r'[^0-9/]'), '');
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length >= 2) {
        final mm = parts[0].padLeft(2, '0').substring(0, 2);
        var yy = parts[1];
        if (yy.length == 4 && yy.startsWith('20')) yy = yy.substring(2);
        if (yy.length > 2) yy = yy.substring(0, 2);
        return '$mm/$yy';
      }
    }
    // If plain digits like MMYY
    final d = s.replaceAll('/', '');
    if (d.length >= 4) {
      return '${d.substring(0, 2)}/${d.substring(2, 4)}';
    }
    return s;
  }

  bool _validExpiry(String v) {
    final parts = v.split('/');
    if (parts.length != 2) return false;
    final mm = int.tryParse(parts[0]) ?? -1;
    final yy = int.tryParse(parts[1]) ?? -1;
    if (mm < 1 || mm > 12 || yy < 0) return false;
    return true;
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _brandFor(String panGrouped) {
    final d = _digitsOnly(panGrouped);
    if (RegExp(r'^4').hasMatch(d)) return 'Visa';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(d)) return 'Amex';
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(d)) return 'Discover';
    if (RegExp(r'^35').hasMatch(d)) return 'JCB';
    return 'Card';
  }
}
