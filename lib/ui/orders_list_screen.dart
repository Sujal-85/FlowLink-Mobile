import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/services/favorites_service.dart';
import 'package:flowlink_mobile/services/purchase_history_service.dart';
import 'package:flowlink_mobile/ui/shipping_detail_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  String _statusFilter = 'All';
  String _sort = 'Date'; // Date | Price

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
              PopupMenuItem(value: 'Price', child: Text('Sort by Price')),
            ],
            icon: const Icon(Icons.sort),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _headerBanner(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _filters()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _recommendedSection()),
          ValueListenableBuilder<List<OrderItem>>(
            valueListenable: OrdersService.instance.orders,
            builder: (context, orders, _) {
              var list = orders;
              if (_statusFilter != 'All') {
                list = list.where((o) => o.status == _statusFilter).toList();
              }
              if (_sort == 'Price') {
                list.sort((a, b) => b.price.compareTo(a.price));
              } else {
                list.sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
              }
              if (list.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No orders')),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i.isOdd) return const SizedBox(height: 12);
                      final idx = i ~/ 2;
                      return _orderCard(list[idx]);
                    },
                    childCount: list.length * 2 - 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Attractive header with gradient + imagery
  Widget _headerBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.primaryGradient,
          image: const DecorationImage(
            image: AssetImage('assets/images/onboarding_bg.jpg'),
            fit: BoxFit.cover,
            opacity: 0.25,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 16,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Track your orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 6),
                  Text('Stay updated with live status and ETA', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
                child: Image.asset('assets/images/vegetables.png', width: 120, height: 110, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recommended products horizontal list
  Widget _recommendedSection() {
    return FutureBuilder<List<ProductItem>>(
      future: _loadRecommended(),
      builder: (context, snap) {
        final items = snap.data ?? const <ProductItem>[];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Text('Recommended for you', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 216,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length.clamp(0, 12),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _productCardSmall(items[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<ProductItem>> _loadRecommended() async {
    final hist = await PurchaseHistoryService.instance.topProducts(limit: 12);
    if (hist.isNotEmpty) return hist;
    return DummyProductsLoader.loadAll(limit: 12);
  }

  Widget _productCardSmall(ProductItem p) {
    final isFav = FavoritesService.instance.isFavorite(p);
    final theme = Theme.of(context);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: theme.brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            child: Image.network(
              resolveImageUrl(p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/400x400.png?text=Product'),
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 90, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('₹${p.discountPrice > 0 && p.discountPrice < p.price ? p.discountPrice.toStringAsFixed(0) : p.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      onPressed: () {
                        FavoritesService.instance.toggle(p);
                        setState(() {});
                      },
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            CartService.instance.add(p);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                          },
                          child: const Text('Add'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final statuses = ['All', ...OrderStatus.stages];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = statuses[i];
          final active = _statusFilter == label;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            onSelected: (_) => setState(() => _statusFilter = label),
          );
        },
      ),
    );
  }
  Widget _orderCard(OrderItem o) {
    final expected = '${o.expectedDate.day}/${o.expectedDate.month}';
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingDetailScreen(order: o))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolveImageUrl(o.imageUrl.isNotEmpty
                    ? o.imageUrl
                    : 'https://via.placeholder.com/300x300.png?text=Product'),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(o.id, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusBadge(o.status),
                      const Spacer(),
                      Text('₹${o.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Expected by $expected', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    switch (status) {
      case 'Delivered':
        bg = dark ? Colors.green.withOpacity(0.18) : Colors.green.shade50;
        fg = dark ? Colors.green.shade300 : Colors.green.shade700;
        break;
      case 'Shipped':
      case 'Out for Delivery':
        bg = dark ? Colors.blue.withOpacity(0.18) : Colors.blue.shade50;
        fg = dark ? Colors.blue.shade300 : Colors.blue.shade700;
        break;
      case 'Packed':
        bg = dark ? Colors.orange.withOpacity(0.18) : Colors.orange.shade50;
        fg = dark ? Colors.orange.shade300 : Colors.orange.shade700;
        break;
      default:
        bg = dark ? Colors.white12 : Colors.grey.shade200;
        fg = dark ? Colors.white : Colors.black87;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
