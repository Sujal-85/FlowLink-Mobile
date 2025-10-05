import 'package:flutter/material.dart';
  import 'package:flowlink_mobile/ui/app_theme.dart';
  import 'package:flowlink_mobile/services/cart_service.dart';
  import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';
  import 'package:flowlink_mobile/ui/share_bottom_sheet.dart';
  import 'package:flowlink_mobile/ui/order_preview_screen.dart';
  import 'package:flowlink_mobile/services/favorites_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final ProductItem product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _wish = false;
  final PageController _imgController = PageController();
  int _imgPage = 0;

  @override
  void initState() {
    super.initState();
    _wish = FavoritesService.instance.isFavorite(widget.product);
  }

  @override
  void dispose() {
    _imgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final price = (p.discountPrice > 0 && p.discountPrice < p.price) ? p.discountPrice : p.price;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageCarousel(p),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.brand.isEmpty ? '—' : p.brand, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (p.discountPrice > 0 && p.discountPrice < p.price) ...[
                          Text('₹${p.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.black54, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                        ],
                        Text('₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _qtySelector(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.quantity, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    _tabsSection(p),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _recommendations(title: 'You may also like', base: p),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(price: price, product: p),
    );
  }

  Widget _imageCarousel(ProductItem p) {
    final images = <String>[
      p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/600x600.png?text=No+Image',
      // Duplicate once to allow swiping; in real data, attach more URLs
      p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/600x600.png?text=No+Image',
    ];
    return AspectRatio(
      aspectRatio: 1.2,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.grey.shade100,
              child: PageView.builder(
                controller: _imgController,
                onPageChanged: (i) => setState(() => _imgPage = i),
                itemCount: images.length,
                itemBuilder: (_, i) {
                  final url = images[i];
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        resolveImageUrl(url),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Dots
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _imgPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? Colors.black87 : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Floating quick actions
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _circleAction(
                  icon: Icons.smart_toy_rounded,
                  gradient: AppColors.primaryGradient,
                  onTap: _openAssistant,
                ),
                const SizedBox(height: 10),
                _circleAction(
                  icon: _wish ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  iconColor: _wish ? Colors.redAccent : Colors.black87,
                  onTap: () {
                    FavoritesService.instance.toggle(widget.product);
                    setState(() => _wish = FavoritesService.instance.isFavorite(widget.product));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_wish ? 'Added to favorites' : 'Removed from favorites')),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _circleAction(
                  icon: Icons.ios_share_rounded,
                  color: Colors.white,
                  iconColor: Colors.black87,
                  onTap: _openShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    Gradient? gradient,
    Color? color,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    final decoration = gradient != null
        ? BoxDecoration(shape: BoxShape.circle, gradient: gradient, boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
          ])
        : BoxDecoration(shape: BoxShape.circle, color: color ?? Colors.white, boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
          ]);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: decoration,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }

  Widget _qtySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() => _qty = (_qty > 1) ? _qty - 1 : 1),
          ),
          Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _qty += 1),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar({required double price, required ProductItem product}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.black87, width: 1.2),
                ),
                onPressed: () {
                  CartService.instance.add(product, qty: _qty);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} added to cart')),
                  );
                },
                child: const Text('Add to cart'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderPreviewScreen(product: product, qty: _qty)),
                  );
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text('Buy Now • ₹${(price * _qty).toStringAsFixed(0)}'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendations({required String title, required ProductItem base}) {
    return FutureBuilder<List<ProductItem>>(
      future: DummyProductsLoader.loadAll(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <ProductItem>[];
        final similar = list.where((e) {
          final sameCategory = e.category.trim().toLowerCase() == base.category.trim().toLowerCase();
          final sameBrand = base.brand.isNotEmpty && e.brand.trim().toLowerCase() == base.brand.trim().toLowerCase();
          return (sameCategory || sameBrand) && e.name != base.name;
        }).take(12).toList();
        if (similar.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final it = similar[i];
                  return _RecommendedCard(product: it, onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: it)),
                    );
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabsSection(ProductItem p) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const TabBar(
              isScrollable: true,
              labelColor: Colors.black87,
              tabs: [
                Tab(text: 'Details'),
                Tab(text: 'Specs'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Delicious and fresh ${p.name}. Sourced from premium vendors. This is a placeholder description to illustrate the Details tab.\n\nBrand: ${p.brand.isEmpty ? '-' : p.brand}',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _specRow('Quantity', p.quantity),
                      _specRow('Category', p.category),
                      _specRow('Sub-Category', p.subCategory),
                      _specRow('Origin', 'Varies'),
                    ],
                  ),
                ),
                ListView.separated(
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(['A','B','C','D'][i % 4])),
                    title: const Text('Great quality!'),
                    subtitle: Text('Reviewed by User #${i + 1}'),
                    trailing: const Icon(Icons.star, color: Colors.orange),
                  ),
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemCount: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: Colors.black87)),
          const Spacer(),
          Text(v.isEmpty ? '-' : v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _openAssistant() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AssistantBottomSheet(),
    );
  }

  Future<void> _openShare() async {
    final p = widget.product;
    final link = p.productUrl.isNotEmpty ? p.productUrl : 'https://flowlink.example/product?name=${Uri.encodeComponent(p.name)}';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareBottomSheet(title: p.name, link: link),
    );
  }

}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.product, required this.onTap});
  final ProductItem product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = (product.discountPrice > 0 && product.discountPrice < product.price)
        ? product.discountPrice
        : product.price;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolveImageUrl(
                  product.imageUrl.isNotEmpty
                      ? product.imageUrl
                      : 'https://via.placeholder.com/300x300.png?text=No+Image',
                ),
                width: 120,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 120,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
