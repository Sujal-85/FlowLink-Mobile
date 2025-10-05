import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/payment_screen.dart';
import 'package:flowlink_mobile/ui/address_selection_sheet.dart';
import 'package:flowlink_mobile/services/address_service.dart';
import 'package:flowlink_mobile/ui/share_bottom_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _headerColor = Color(0xFF0F4D42);
  static const _textGrey = Color(0xFF7A7F85);
  // Cart is managed by CartService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Header background
            Container(
              height: 150,
              decoration: const BoxDecoration(
                color: _headerColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
            // Content
            Column(
              children: [
                _topBar(context),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shareBanner(),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<List<CartEntry>>(
                          valueListenable: CartService.instance.entries,
                          builder: (context, entries, _) {
                            if (entries.isEmpty) {
                              return Column(
                                children: [
                                  _storeSection(
                                    context,
                                    name: 'Your Cart',
                                    eta: 'Add items to get started',
                                    expanded: true,
                                    child: _emptyCart(),
                                  ),
                                  const SizedBox(height: 16),
                                  _promoField(),
                                ],
                              );
                            }
                            // Group entries by Brand (as store-like grouping)
                            final Map<String, List<CartEntry>> groups = <String, List<CartEntry>>{};
                            for (final e in entries) {
                              final brand = (e.item.brand.isNotEmpty) ? e.item.brand : 'Other';
                              groups.putIfAbsent(brand, () => <CartEntry>[]).add(e);
                            }

                            final groupWidgets = <Widget>[];
                            groups.forEach((brand, list) {
                              groupWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _storeSection(
                                    context,
                                    name: brand,
                                    eta: 'Delivery in 15 minute',
                                    expanded: true,
                                    child: Column(
                                      children: [
                                        for (final e in list)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: _cartItem(e),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });

                            return Column(
                              children: [
                                ...groupWidgets,
                                const SizedBox(height: 16),
                                _promoField(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom checkout bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ValueListenableBuilder<List<CartEntry>>(
                    valueListenable: CartService.instance.entries,
                    builder: (context, entries, _) {
                      final total = entries.fold<double>(0.0, (sum, e) => sum + e.lineTotal);
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8F26A),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        onPressed: entries.isEmpty ? null : () => _onCheckoutPressed(total),
                        child: Text('Checkout  ₹ ${total.toStringAsFixed(0)}'),
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          const Text(' ', style: TextStyle(color: Colors.white)),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.ios_share, color: _headerColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF8A2BE2),
            radius: 16,
            child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gromuse • Shop together with new shared cart',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                minimumSize: const Size(88, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () async {
                final link = 'https://flowlink.app/share/cart?ts=${DateTime.now().millisecondsSinceEpoch}';
                if (!context.mounted) return;
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ShareBottomSheet(title: 'Share your cart', link: link),
                );
              },
              child: const Text('Share cart'),
            ),
          )
        ],
      ),
    );
  }

  Widget _storeSection(BuildContext context,
      {required String name, required String eta, required bool expanded, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.redAccent, radius: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(eta, style: const TextStyle(color: _textGrey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _cartItem(CartEntry entry) {
    final p = entry.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  resolveImageUrl(
                    p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/120.png?text=No+Image',
                  ),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.name} (${p.brand})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(p.quantity, style: const TextStyle(color: _textGrey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('${entry.unitPrice.toStringAsFixed(2)}\$',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _qtyButton(Icons.remove, () => CartService.instance.decrement(p)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${entry.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        _qtyButton(Icons.add, () => CartService.instance.add(p)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E6EA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _emptyCart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: const [
          Icon(Icons.shopping_cart_outlined, color: _textGrey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your cart is empty. Add items from the home screen.',
              style: TextStyle(color: _textGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoField() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Add Promo',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {},
            child: const Text('Apply'),
          ),
        )
      ],
    );
  }

  Future<void> _onCheckoutPressed(double total) async {
    // Guard: no items
    if (CartService.instance.entries.value.isEmpty) return;

    // Ensure an address is selected
    var selected = AddressService.instance.selected.value;
    if (selected == null) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddressSelectionSheet(),
      );
      selected = AddressService.instance.selected.value;
    }

    if (!mounted) return;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add/select a delivery address to continue')),
      );
      return;
    }

    // Proceed to payment
    // ignore: use_build_context_synchronously
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentScreen(total: total)),
    );
  }
}