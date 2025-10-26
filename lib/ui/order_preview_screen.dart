import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/payment_screen.dart';
import 'package:flowlink_mobile/ui/address_selection_sheet.dart';
import 'package:flowlink_mobile/services/address_service.dart';

class OrderPreviewScreen extends StatefulWidget {
  const OrderPreviewScreen({super.key, required this.product, required this.qty});
  final ProductItem product;
  final int qty;

  @override
  State<OrderPreviewScreen> createState() => _OrderPreviewScreenState();
}

class _OrderPreviewScreenState extends State<OrderPreviewScreen> {
  static const double deliveryBaseCharge = 49;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final unit = (p.discountPrice > 0 && p.discountPrice < p.price) ? p.discountPrice : p.price;
    final subtotal = unit * widget.qty;
    final delivery = subtotal >= 150 ? 0.0 : deliveryBaseCharge;
    final total = subtotal + delivery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Preview'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _orderCard(p, unit),
                  const SizedBox(height: 16),
                  _addressCard(),
                  const SizedBox(height: 16),
                  _charges(subtotal: subtotal, total: total, delivery: delivery),
                ],
              ),
            ),
            _bottomBar(total: total),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(ProductItem p, double unit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              resolveImageUrl(p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/200x200.png?text=No+Image'),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (c, _, __) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(p.quantity, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: isDark ? theme.inputDecorationTheme.fillColor : Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
                      child: Text('Qty: ${widget.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text('₹${unit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _addressCard() {
    return ValueListenableBuilder<Address?>(
      valueListenable: AddressService.instance.selected,
      builder: (context, sel, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (sel == null)
                      Text('No address selected. Add one to continue.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))
                    else
                      Text(sel.toString()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _openAddressSheet(),
                child: Text(sel == null ? 'Add' : 'Change'),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _charges({required double subtotal, required double total, required double delivery}) {
    final estimate = DateTime.now().add(const Duration(days: 2));
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _row('Items total', '₹${subtotal.toStringAsFixed(0)}'),
          _row('Delivery charge', delivery <= 0 ? 'Free' : '₹${_format(delivery)}'),
          _row('Est. delivery date', '${estimate.day}/${estimate.month}/${estimate.year}'),
          const Divider(height: 16),
          Row(
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const Spacer(),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _bottomBar({required double total}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: theme.cardColor, boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PaymentScreen(total: total)),
                  );
                },
                child: const Text('Proceed to Payment'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double v) => v.toStringAsFixed(0);

  Future<void> _openAddressSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddressSelectionSheet(),
    );
    setState(() {});
  }
}
