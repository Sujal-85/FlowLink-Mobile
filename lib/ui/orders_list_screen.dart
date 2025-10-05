import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
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
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: ValueListenableBuilder<List<OrderItem>>(
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
                  return const Center(child: Text('No orders'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _orderCard(list[i]),
                );
              },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
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
                  Text(o.id, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusBadge(o.status),
                      const Spacer(),
                      Text('₹${o.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Expected by $expected', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Delivered':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'Shipped':
      case 'Out for Delivery':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case 'Packed':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.black87;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
