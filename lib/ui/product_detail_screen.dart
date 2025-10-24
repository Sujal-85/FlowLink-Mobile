import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
  import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';
import 'package:flowlink_mobile/ui/order_preview_screen.dart';
import 'package:flowlink_mobile/services/favorites_service.dart';
import 'package:flowlink_mobile/services/reviews_service.dart';
  import 'package:share_plus/share_plus.dart';

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
  late final String _productKey;
  late final ValueListenable<List<Review>> _reviews;

  @override
  void initState() {
    super.initState();
    _wish = FavoritesService.instance.isFavorite(widget.product);
    _productKey = widget.product.productUrl.isNotEmpty ? widget.product.productUrl : widget.product.name;
    _reviews = ReviewsService.instance.bind(_productKey);
  }

  @override
  void dispose() {
    _imgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.product;
    final price = (p.discountPrice > 0 && p.discountPrice < p.price) ? p.discountPrice : p.price;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageCarousel(context, p),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.brand.isEmpty ? '—' : p.brand, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 6),
                    Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    ValueListenableBuilder<List<Review>>(
                      valueListenable: _reviews,
                      builder: (context, list, _) {
                        final count = list.length;
                        final avg = count == 0 ? 4.6 : (list.map((e) => e.rating).fold<double>(0.0, (a, b) => a + b) / count);
                        return Row(
                          children: [
                            _stars(avg.isNaN ? 4.6 : avg.clamp(0.0, 5.0), size: 16),
                            const SizedBox(width: 6),
                            Text((avg.isNaN ? 4.6 : avg).toStringAsFixed(1), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Text('$count ratings', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (p.discountPrice > 0 && p.discountPrice < p.price) ...[
                          Text('₹${p.price.toStringAsFixed(0)}',
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                        ],
                        Text('₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _qtySelector(context),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.quantity, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _benefitChip(Icons.local_shipping_outlined, 'Fast Delivery'),
                        _benefitChip(Icons.verified_user_outlined, 'Assured Quality'),
                        _benefitChip(Icons.refresh_outlined, 'Easy Returns'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _trustBadge(Icons.security, 'Secure Payments'),
                        _trustBadge(Icons.inventory_2_outlined, 'Fresh Stock'),
                        _trustBadge(Icons.support_agent_outlined, 'Support'),
                      ],
                    ),
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

  Widget _imageCarousel(BuildContext context, ProductItem p) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
              color: isDark ? theme.cardColor : Colors.grey.shade100,
              child: PageView.builder(
                controller: _imgController,
                onPageChanged: (i) => setState(() => _imgPage = i),
                itemCount: images.length,
                itemBuilder: (_, i) {
                  final url = images[i];
                  return GestureDetector(
                    onTap: () => _openGallery(images, i),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          resolveImageUrl(url),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => Container(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            child: Icon(Icons.broken_image, color: isDark ? Colors.white54 : Colors.grey, size: 48),
                          ),
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
                    color: active
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white24 : Colors.black26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Badge: discount or bestseller
          Positioned(
            left: 12,
            top: 12,
            child: Builder(
              builder: (_) {
                final hasDiscount = p.discountPrice > 0 && p.discountPrice < p.price;
                final off = hasDiscount ? (((p.price - p.discountPrice) / p.price) * 100).round() : 0;
                final label = hasDiscount ? '$off% OFF' : 'Best Seller';
                final bg = hasDiscount ? Colors.redAccent : Colors.orange;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                );
              },
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
                  color: Theme.of(context).cardColor,
                  iconColor: _wish ? Colors.redAccent : Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).cardColor,
                  iconColor: Theme.of(context).colorScheme.onSurface,
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

  Widget _qtySelector(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.7), width: 1.2),
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: TabBar(
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.onSurface,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Specs'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delicious and fresh ${p.name}. Carefully sourced from trusted suppliers and handled with cold-chain where required to retain freshness. Ideal for daily cooking and meal prep.',
                        style: const TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Text('Highlights', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text('• Brand: ${p.brand.isEmpty ? '-' : p.brand}\n• Quantity: ${p.quantity}\n• Category: ${p.category} > ${p.subCategory.isEmpty ? '-' : p.subCategory}\n• Storage: Keep in a cool, dry place\n• Best before: Refer to pack'),
                    ],
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
                ValueListenableBuilder<List<Review>>(
                  valueListenable: _reviews,
                  builder: (context, list, _) {
                    final avg = list.isEmpty ? 0.0 : list.map((e) => e.rating).reduce((a, b) => a + b) / list.length;
                    final counts = List<int>.filled(5, 0);
                    for (final r in list) {
                      final i = r.rating.clamp(1, 5).round();
                      counts[i - 1] += 1;
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text((avg == 0 ? '0.0' : avg.toStringAsFixed(1)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                            const SizedBox(width: 8),
                            _stars(avg == 0 ? 0 : avg, size: 18),
                            const SizedBox(width: 8),
                            Text('${list.length} ratings', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
                          ]),
                          const SizedBox(height: 12),
                          Column(
                            children: List.generate(5, (idx) {
                              final star = 5 - idx;
                              final c = (star >= 1 && star <= 5) ? counts[star - 1] : 0;
                              final pct = list.isEmpty ? 0.0 : c / list.length;
                              return _ratingBar(star, pct);
                            }),
                          ),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _filterChip('Most recent', selected: true),
                            _filterChip('With images'),
                            _filterChip('Verified'),
                          ]),
                          const SizedBox(height: 12),
                          if (list.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            )
                          else
                            ...List.generate(list.length, (i) {
                              final r = list[i];
                              return Column(children: [
                                _ReviewItem(r: r),
                                if (i != list.length - 1) const Divider(height: 16),
                              ]);
                            }),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _showWriteReviewSheet,
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text('Write a review'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
          Text(k, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const Spacer(),
          Text(v.isEmpty ? '-' : v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).dividerColor),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))],
      ),
    );
  }

  Future<void> _openGallery(List<String> images, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _GalleryViewer(images: images, initialIndex: index)),
    );
  }

  Widget _reviewsHeader() {
    return Row(
      children: [
        Text('4.6', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        const SizedBox(width: 8),
        _stars(4.6, size: 18),
        const SizedBox(width: 8),
        Text('1.2k ratings', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
      ],
    );
  }

  Widget _ratingDistribution() {
    final entries = [
      {'s': 5, 'v': 0.62},
      {'s': 4, 'v': 0.22},
      {'s': 3, 'v': 0.10},
      {'s': 2, 'v': 0.04},
      {'s': 1, 'v': 0.02},
    ];
    return Column(
      children: entries.map((e) => _ratingBar(e['s'] as int, e['v'] as double)).toList(),
    );
  }

  Widget _ratingBar(int stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 18, child: Text('$stars')),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: pct, minHeight: 8),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text('${(pct * 100).round()}%', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, {bool selected = false}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
    );
  }

  Widget _reviewCard({required String user, required double rating, required String date, required String text, List<String>? images}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatar = user.isNotEmpty ? user[0].toUpperCase() : 'U';
    final imgs = (images ?? []).where((e) => e.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text(avatar)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _stars(rating, size: 16),
                    const SizedBox(width: 6),
                    Text(date, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.verified, color: Colors.green),
          ],
        ),
        const SizedBox(height: 8),
        Text(text),
        if (imgs.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imgs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(resolveImageUrl(imgs[i]), width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 72, height: 72, color: Colors.grey.shade200)),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_up_alt_outlined)),
            const Text('Helpful'),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          ],
        ),
      ],
    );
  }

  Widget _stars(double rating, {double size = 16}) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(full, (_) => Icon(Icons.star, color: Colors.orange, size: size)),
        ...List.generate(half, (_) => Icon(Icons.star_half, color: Colors.orange, size: size)),
        ...List.generate(empty, (_) => Icon(Icons.star_border, color: Colors.orange, size: size)),
      ],
    );
  }

  Future<void> _showWriteReviewSheet() async {
    double rating = 5;
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx2, set) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Write a review', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        final idx = i + 1;
                        final filled = idx <= rating;
                        return IconButton(
                          onPressed: () => set(() => rating = idx.toDouble()),
                          icon: Icon(filled ? Icons.star : Icons.star_border, color: Colors.orange, size: 28),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text('Your rating: ${rating.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(controller: controller, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Share your experience')),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          final text = controller.text.trim();
                          await ReviewsService.instance.addReview(productKey: _productKey, rating: rating, text: text);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thanks for your ${rating.toStringAsFixed(0)}★ review')));
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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
    final message = 'Check this on FlowLink: ${p.name}\n$link';
    await Share.share(message, subject: p.name);
  }

}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_page + 1}/${widget.images.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _page = i),
        itemCount: widget.images.length,
        itemBuilder: (_, i) {
          final url = widget.images[i];
          return Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                resolveImageUrl(url),
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            ),
          );
        },
      ),
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
          color: Theme.of(context).cardColor,
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenPrimary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    CartService.instance.add(product);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                  },
                  child: const Text('Add'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatefulWidget {
  const _ReviewItem({required this.r});
  final Review r;

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> with SingleTickerProviderStateMixin {
  bool _liked = false;

  Widget _stars(double rating, {double size = 16}) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(full, (_) => Icon(Icons.star, color: Colors.orange, size: size)),
        ...List.generate(half, (_) => Icon(Icons.star_half, color: Colors.orange, size: size)),
        ...List.generate(empty, (_) => Icon(Icons.star_border, color: Colors.orange, size: size)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imgs = const <String>[]; // placeholder for images if later added
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text((r.user.isNotEmpty ? r.user[0] : 'U').toUpperCase())),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.user.isEmpty ? 'Anonymous' : r.user, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _stars(r.rating, size: 16),
                    const SizedBox(width: 6),
                    Text(_formatDate(r.createdAt), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.verified, color: Colors.green),
          ],
        ),
        const SizedBox(height: 8),
        Text(r.text.isEmpty ? 'No comment' : r.text),
        if (imgs.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imgs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(resolveImageUrl(imgs[i]), width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 72, height: 72, color: Colors.grey.shade200)),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _liked
                  ? null
                  : () async {
                      setState(() => _liked = true);
                      await ReviewsService.instance.incrementHelpful(r.key);
                    },
              child: AnimatedScale(
                scale: _liked ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Row(children: [
                  Icon(_liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Helpful (${r.helpful + (_liked ? 1 : 0)})'),
                ]),
              ),
            ),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
