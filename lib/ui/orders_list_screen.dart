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
  String _query = '';

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
          SliverToBoxAdapter(child: _searchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _quickActions(context)),
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
              if (_query.trim().isNotEmpty) {
                final q = _query.toLowerCase();
                list = list
                    .where((o) => o.productName.toLowerCase().contains(q) || o.id.toLowerCase().contains(q))
                    .toList();
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
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _favoritesSection()),
        ],
      ),
    );
  }

  // Attractive header with gradient + imagery
  Widget _headerBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxWidth * 0.38; // responsive height based on width
          return Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                resolveImageUrl('https://cdn.shopify.com/s/files/1/0576/9579/7455/files/Track_your_order_1.png?v=1693293697'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search orders by name or ID',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Reorder last'),
                onPressed: () {
                  final list = OrdersService.instance.orders.value;
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No orders yet')));
                    return;
                  }
                  final latest = list.reduce((a, b) => a.expectedDate.isAfter(b.expectedDate) ? a : b);
                  CartService.instance.add(_toProduct(latest));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Track latest'),
                onPressed: () {
                  final list = OrdersService.instance.orders.value;
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No orders to track')));
                    return;
                  }
                  final latest = list.reduce((a, b) => a.expectedDate.isAfter(b.expectedDate) ? a : b);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingDetailScreen(order: latest)));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  ProductItem _toProduct(OrderItem o) {
    return ProductItem(
      name: o.productName,
      brand: '',
      price: o.price,
      discountPrice: 0.0,
      imageUrl: o.imageUrl,
      quantity: '1 unit',
      category: 'Orders',
      subCategory: '',
      productUrl: '',
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

  Widget _favoritesSection() {
    return ValueListenableBuilder<List<ProductItem>>(
      valueListenable: FavoritesService.instance.favorites,
      builder: (context, favs, _) {
        final items = favs;
        if (items.isEmpty) return const SizedBox.shrink();
        final list = items.length > 12 ? items.sublist(0, 12) : items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Text('Your favourites', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 216,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _productCardSmall(list[i]),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        label: const Text('Track'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingDetailScreen(order: o))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Reorder'),
                        onPressed: () {
                          CartService.instance.add(_toProduct(o));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                        },
                      ),
                    ],
                  ),
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
