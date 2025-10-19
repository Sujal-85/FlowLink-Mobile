import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/payment_screen.dart';
import 'package:flowlink_mobile/ui/address_selection_sheet.dart';
import 'package:flowlink_mobile/services/address_service.dart';
import 'package:flowlink_mobile/utils/responsive.dart';
import 'package:share_plus/share_plus.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _headerColor = AppColors.darkBlue;
  static const _textGrey = Color(0xFF7A7F85);
  // Cart is managed by CartService

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background removed to match new clean white header
            const SizedBox.shrink(),
            // Content
            Column(
              children: [
                _topBar(context),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, r.isSmall ? 160 : 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _savingsBanner(),
                        const SizedBox(height: 12),
                        _applyCouponCard(),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                size: 18,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              const Text('Review Items', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<List<CartEntry>>(
                          valueListenable: CartService.instance.entries,
                          builder: (context, entries, _) {
                            if (entries.isEmpty) {
                              return _emptyCart();
                            }
                            return Column(
                              children: [
                                for (final e in entries)
                                  Dismissible(
                                    key: ValueKey<String>(
                                      e.item.productUrl.isNotEmpty
                                          ? e.item.productUrl
                                          : '${e.item.name}|${e.item.brand}|${e.item.quantity}|${e.item.imageUrl}',
                                    ),
                                    direction: DismissDirection.endToStart,
                                    background: Container(),
                                    secondaryBackground: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white12
                                            : AppColors.greenPrimary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete_outline, color: AppColors.greenPrimary, size: 26),
                                    ),
                                    onDismissed: (_) {
                                      CartService.instance.remove(e.item);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Item removed from cart')),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _cartItem(e),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.history_toggle_off, size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black54),
                            const SizedBox(width: 8),
                            const Text('Your last minute add-ons', style: TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _addonsCarousel(),
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
              child: _bottomCheckoutPanel(),
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
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home', (route) => false);
              }
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                'Your Cart',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: IconButton(
              onPressed: () {
                final link = 'https://flowlink.app/share/cart?ts=${DateTime.now().millisecondsSinceEpoch}';
                final message = 'Join my FlowLink cart:\n$link';
                Share.share(message, subject: 'Share cart');
              },
              icon: const Icon(Icons.ios_share, color: AppColors.greenPrimary),
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
        color: AppColors.blueSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.darkBlue,
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
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(88, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () async {
                final link = 'https://flowlink.app/share/cart?ts=${DateTime.now().millisecondsSinceEpoch}';
                final message = 'Share your FlowLink cart:\n$link';
                await Share.share(message, subject: 'Share cart');
              },
              child: const Text('Share cart'),
            ),
          )
        ],
      ),
    );
  }

  // Savings banner like the mock
  Widget _savingsBanner() {
    return ValueListenableBuilder<List<CartEntry>>(
      valueListenable: CartService.instance.entries,
      builder: (context, entries, _) {
        final original = entries.fold<double>(0.0, (s, e) => s + e.item.price * e.qty);
        final effective = entries.fold<double>(0.0, (s, e) => s + e.lineTotal);
        final savings = (original - effective).clamp(0.0, double.infinity);
        if (entries.isEmpty || savings <= 0) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: AppColors.greenSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: AppColors.greenDark),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      const TextSpan(text: '₹', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: savings.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w900)),
                      const TextSpan(text: '  savings on this order'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _applyCouponCard() {
    final r = Responsive.of(context);
    final dense = r.isSmall;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CouponSheet(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 10 : 14),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.greenPrimary : Colors.black87,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Apply Coupon', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _cartItem(CartEntry entry) {
    final p = entry.item;
    final hasDiscount = p.discountPrice > 0 && p.discountPrice < p.price;
    final r = Responsive.of(context);
    final bool dense = r.isSmall;
    return Container(
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              resolveImageUrl(
                p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/120.png?text=No+Image',
              ),
              width: dense ? 52 : 56,
              height: dense ? 52 : 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: dense ? 52 : 56,
                height: dense ? 52 : 56,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
              ),
            ),
          ),
          SizedBox(width: dense ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 13 : 14),
                ),
                SizedBox(height: dense ? 2 : 2),
                Text(p.quantity, style: TextStyle(color: _textGrey, fontSize: dense ? 11 : 12)),
                SizedBox(height: dense ? 4 : 6),
                _qtyControl(entry),
              ],
            ),
          ),
          SizedBox(width: dense ? 10 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount)
                Text('₹${p.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _textGrey,
                      decoration: TextDecoration.lineThrough,
                      fontSize: dense ? 11 : 12,
                    )),
              Text(
                '₹${entry.unitPrice.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: dense ? 14 : 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyControl(CartEntry entry) {
    final p = entry.item;
    final r = Responsive.of(context);
    final dense = r.isSmall;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white24 : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconPillButton(Icons.remove, () => CartService.instance.decrement(p)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 6 : 8),
            child: Text('${entry.qty}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 13 : 14)),
          ),
          _iconPillButton(Icons.add, () => CartService.instance.add(p)),
        ],
      ),
    );
  }

  Widget _iconPillButton(IconData icon, VoidCallback onTap) {
    final r = Responsive.of(context);
    final dense = r.isSmall;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: dense ? 32 : 36,
        height: dense ? 32 : 36,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: dense ? 16 : 18, color: Theme.of(context).colorScheme.onSurface),
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

  // Add-ons horizontal carousel
  Widget _addonsCarousel() {
    final r = Responsive.of(context);
    final dense = r.isSmall;
    return FutureBuilder<List<ProductItem>>(
      future: DummyProductsLoader.loadAll(limit: 10),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ProductItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: dense ? 140 : 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: dense ? 10 : 12),
            itemBuilder: (_, i) => _addonCard(items[i]),
          ),
        );
      },
    );
  }

  Widget _addonCard(ProductItem p) {
    final hasDiscount = p.discountPrice > 0 && p.discountPrice < p.price;
    final r = Responsive.of(context);
    final dense = r.isSmall;
    return Container(
      width: dense ? 120 : 130,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      padding: EdgeInsets.all(dense ? 8 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  resolveImageUrl(p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/200x200.png?text=Item'),
                  width: double.infinity,
                  height: dense ? 62 : 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: dense ? 62 : 70, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: InkWell(
                  onTap: () => CartService.instance.add(p),
                  child: Container(
                    width: dense ? 26 : 28,
                    height: dense ? 26 : 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: Theme.of(context).brightness == Brightness.light
                          ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              if (hasDiscount)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('15% OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          SizedBox(height: dense ? 6 : 8),
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: dense ? 11 : 12)),
          const Spacer(),
          Row(
            children: [
              if (hasDiscount)
                Text('₹${p.price.toStringAsFixed(0)}', style: TextStyle(fontSize: dense ? 10 : 11, color: _textGrey, decoration: TextDecoration.lineThrough)),
              SizedBox(width: dense ? 4 : 6),
              Text(
                '₹${(hasDiscount ? p.discountPrice : p.price).toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: dense ? 12 : 13),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _bottomCheckoutPanel() {
    final r = Responsive.of(context);
    final bool dense = r.isSmall;
    return Container(
      padding: EdgeInsets.fromLTRB(12, dense ? 6 : 10, 12, dense ? 10 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: ValueListenableBuilder<List<CartEntry>>(
        valueListenable: CartService.instance.entries,
        builder: (context, entries, _) {
          final original = entries.fold<double>(0.0, (s, e) => s + e.item.price * e.qty);
          final effective = entries.fold<double>(0.0, (s, e) => s + e.lineTotal);
          final savings = (original - effective).clamp(0.0, double.infinity);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary row
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 6 : 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : AppColors.blueSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'To Pay:  ₹${effective.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: dense ? 14 : 16),
                    ),
                    const SizedBox(width: 8),
                    if (original > effective && !dense)
                      Text('₹${original.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: _textGrey)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showBillSheet(original: original, total: effective, savings: savings),
                      child: Text(dense ? 'Bill' : 'View Detailed Bill'),
                    )
                  ],
                ),
              ),
              SizedBox(height: dense ? 6 : 8),
              // Delivery info row
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 6 : 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ValueListenableBuilder<Address?>(
                        valueListenable: AddressService.instance.selected,
                        builder: (context, addr, __) {
                          final title = addr == null ? 'Add delivery address' : 'Deliver to ${addr.city}';
                          final subtitle = addr?.addressLine ?? addr?.landmark ?? '';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 13 : 14)),
                              if (subtitle.isNotEmpty)
                                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _textGrey, fontSize: dense ? 11 : 12)),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 4 : 6),
                      child: Text('10 mins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 12 : 14, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.secondary),
              ],
              ),
              ),
              SizedBox(height: dense ? 8 : 10),
              SizedBox(
                width: double.infinity,
                height: dense ? 44 : 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 13 : 15),
                  ),
                  onPressed: entries.isEmpty ? null : () => _onCheckoutPressed(effective),
                  child: const Text('Proceed to Pay'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBillSheet({required double original, required double total, required double savings}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bill Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              _billRow('Items total', '₹${original.toStringAsFixed(0)}'),
              _billRow('Savings', '- ₹${savings.toStringAsFixed(0)}', fg: Colors.green.shade700),
              _billRow('Delivery', 'Free'),
              const Divider(height: 24),
              _billRow('To Pay', '₹${total.toStringAsFixed(0)}', bold: true),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _billRow(String label, String value, {Color? fg, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: fg ?? Theme.of(context).colorScheme.onSurface, fontWeight: bold ? FontWeight.w800 : FontWeight.w600))),
          Text(value, style: TextStyle(color: fg ?? Theme.of(context).colorScheme.onSurface, fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
        ],
      ),
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

class _CouponSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Apply Coupon', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter coupon code',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          )
        ],
      ),
    );
  }
}