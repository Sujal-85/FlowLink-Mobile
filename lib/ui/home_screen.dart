import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'products_list_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/location_service.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/services/purchase_history_service.dart';
import 'scan_screen.dart';
import 'package:flowlink_mobile/widgets/assistant_fab.dart';
import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flowlink_mobile/utils/responsive.dart';

// Shared colors matching the design
const Color _headerColor = Color(0xFF0F4D42); // deep teal as in design
const Color _lime = Color(0xFFC8F26A); // checkout/add accent
const Color _textGrey = Color(0xFF7A7F85);
const Color _redAccent = Color(0xFFFF6B6B);
const Color _lightGreen = Color(0xFFEAF6DB); // light highlight for selected tabs

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Assistant and navigation helpers
  bool _navigating = false;
  final List<String> _filters = const ['All', 'Deals', 'Top Rated', 'New'];
  int _selectedFilter = 0;
  final PageController _promoController = PageController(viewportFraction: 0.9);
  int _promoPage = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  final List<String> _seasonal = const ['Festive Specials', 'Winter Essentials', 'Healthy Choices'];
  int _selectedSeasonal = 0;
  @override
  void initState() {
    super.initState();
    // Defer address initialization to post-frame to avoid running in build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.initCurrentAddress();
    });
  }

  // Sticky search bar with voice and scan actions
  Widget _stickySearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: _textGrey, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Search for items"),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmitted,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic_none_rounded, color: Colors.black87),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SizedBox(height: 180, child: Center(child: Text('Listening… (stub)'))),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black87),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
                if (result is String && result.isNotEmpty) {
                  _searchCtrl.text = result;
                  _onSearchSubmitted(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchSubmitted(String query) {
    final q = query.trim();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductsListScreen(title: 'Search', initialQuery: q, categoryFilter: null),
      ),
    );
  }

  Future<void> _showNotifications() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: const [
                      ListTile(leading: Icon(Icons.local_offer_outlined), title: Text('New offer on your favorite items'), subtitle: Text('Just now')),
                      Divider(height: 1),
                      ListTile(leading: Icon(Icons.delivery_dining_rounded), title: Text('Order #FL-1123 is on the way'), subtitle: Text('ETA 25 min')),
                      Divider(height: 1),
                      ListTile(leading: Icon(Icons.star_rate_outlined), title: Text('Rate your recent purchase'), subtitle: Text('Yesterday')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Products will be loaded from assets via DummyProductsLoader

    final categories = [
      _Category(
        title: 'Meats',
        image: 'https://picsum.photos/seed/meats/300/300',
        icon: Icons.set_meal,
        color: Color(0xFFFFE4B3),
      ),
      _Category(
        title: 'Veggies',
        image: 'https://picsum.photos/seed/veggies/300/300',
        icon: Icons.eco,
        color: Color(0xFFE8F5E8),
      ),
      _Category(
        title: 'Fruits',
        image: 'https://picsum.photos/seed/fruits/300/300',
        icon: Icons.apple,
        color: Color(0xFFFFE4E1),
      ),
      _Category(
        title: 'Breads',
        image: 'https://picsum.photos/seed/breads/300/300',
        icon: Icons.bakery_dining,
        color: Color(0xFFFFF8DC),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNav(currentIndex: 0),
      floatingActionButton: _assistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: AbsorbPointer(
        absorbing: _navigating,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _topBar(),
              const SizedBox(height: 8),
              _stickySearchBar(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _greetingHeadline(),
                      const SizedBox(height: 16),
                      _promoCarousel(),
                      const SizedBox(height: 8),
                      _promoDots(),
                      const SizedBox(height: 16),
                      _deliveryTrackerCard(),
                      const SizedBox(height: 16),
                      _sectionHeader('Deals & Offers', trailing: 'See All'),
                      const SizedBox(height: 12),
                      _dealsCarousel(),
                      const SizedBox(height: 16),
                      _sectionHeader('Your weekly picks', trailing: 'See All'),
                      const SizedBox(height: 12),
                      _quickReorderSection(),
                      const SizedBox(height: 16),
                      _sectionHeader('Recommended for you', trailing: 'See All'),
                      const SizedBox(height: 12),
                      _recommendedSection(),
                      const SizedBox(height: 16),
                      _seasonalChips(),
                      const SizedBox(height: 16),
                      _sectionHeader(
                        'Popular Store🔥',
                        trailing: 'See All',
                        onTrailingTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProductsListScreen(title: 'Popular Store'),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _popularStoresList(),
                      const SizedBox(height: 16),
                      _sectionHeader(
                        'Top Categories',
                        trailing: 'See All',
                        onTrailingTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _categoriesIconGrid(categories: categories),
                      const SizedBox(height: 16),
                      _recipeInspirationCard(),
                      const SizedBox(height: 16),
                      _walletPointsRow(),
                      const SizedBox(height: 16),
                      _reviewsSection(),
                      const SizedBox(height: 16),
                      _referBanner(),
                      const SizedBox(height: 16),
                      // Existing sections retained below
                      _sectionHeader(
                        'You might need',
                        trailing: 'See all',
                        onTrailingTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProductsListScreen(
                                  title: 'Fruits & Vegetables',
                                  categoryFilter: 'Fruits & Vegetables',
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<ProductItem>>(
                        future: DummyProductsLoader.loadAll(),
                        builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                            return const _ShimmerProductsRow();
                          }
                          final items = snapshot.data ?? const <ProductItem>[];
                          final filtered = items
                              .where((p) => p.category.trim().toLowerCase() == 'fruits & vegetables'.toLowerCase())
                              .toList();
                          return _HorizontalProductList(products: filtered.isNotEmpty ? filtered : items);
                        },
                      ),
                      const SizedBox(height: 24),
                      _PromoRow(),
                      const SizedBox(height: 24),
                      _sectionHeader(
                        'Featured',
                        trailing: 'See all',
                        onTrailingTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProductsListScreen(
                                  title: 'Eggs, Meat & Fish',
                                  categoryFilter: 'Eggs, Meat & Fish',
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<ProductItem>>(
                        future: DummyProductsLoader.loadAll(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              height: 280,
                              child: Center(child: CircularProgressIndicator(color: _headerColor)),
                            );
                          }
                          final items = snapshot.data ?? const <ProductItem>[];
                          final filtered = items
                              .where((p) => p.category.trim().toLowerCase() == 'eggs, meat & fish'.toLowerCase())
                              .toList();
                          final list = (filtered.isNotEmpty ? filtered : items).reversed.toList();
                          return _HorizontalProductList(products: list);
                        },
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader('Top Picks'),
                      const SizedBox(height: 12),
                      FutureBuilder<List<ProductItem>>(
                        future: DummyProductsLoader.loadAll(),
                        builder: (context, snapshot) {
                          final items = snapshot.data ?? const <ProductItem>[];
                          final picks = items.take(10).toList();
                          return _HorizontalProductList(products: picks);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _cartPreviewBar(),
            ],
          ),
        ),
      ),
    );
  }

  // New top bar with location chip and action icons
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: LocationService.addressNotifier,
                      builder: (context, addr, _) {
                        final text = (addr.isEmpty) ? 'Chenango, New York' : addr;
                        return Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _circleIcon(Icons.chat_bubble_outline, onTap: _showAssistant),
          const SizedBox(width: 8),
          _circleIcon(Icons.notifications_none_rounded, onTap: _showNotifications),
          const SizedBox(width: 8),
          _circleIcon(Icons.shopping_cart_outlined, onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
          }),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20)),
      ),
    );
  }

  // Greeting + headline like the reference
  Widget _greetingHeadline() {
    final r = Responsive.of(context);
    final double subSize = r.sp(13);
    final double titleSize = r.isSmall ? r.sp(20) : r.sp(24);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, Jonatan! 👋', style: TextStyle(color: _textGrey, fontSize: subSize, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Fulfill all your daily needs\nwith FlowLink',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800, height: 1.15),
          ),
        ],
      ),
    );
  }

  // Promo carousel with two cards
  Widget _promoCarousel() {
    return SizedBox(
      height: 140,
      child: PageView(
        controller: _promoController,
        onPageChanged: (i) => setState(() => _promoPage = i),
        children: [
          _promoCard(
            bg: const Color(0xFFE6F4EA),
            badge: 'Delivery in 25 min',
            title: 'Get free shipping and 25% discount for today only',
            image: 'assets/images/vegetables.png',
          ),
          _promoCard(
            bg: const Color(0xFFFFF3E0),
            badge: 'Limited time',
            title: 'Fresh deals on bakery & dairy this week',
            image: 'assets/images/meat.png',
          ),
        ],
      ),
    );
  }

  Widget _promoCard({required Color bg, required String badge, required String title, required String image}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(999)),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image.startsWith('assets/')
                    ? Image.asset(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (c, _, __) => Container(color: Colors.white),
                      )
                    : Image.network(
                        resolveImageUrl(image),
                        fit: BoxFit.cover,
                        errorBuilder: (c, _, __) => Container(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i == _promoPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            color: active ? _redAccent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // Delivery tracker shortcut card
  Widget _deliveryTrackerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: const [
            Icon(Icons.delivery_dining_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 12),
            Expanded(
              child: Text('Order on the way · ETA 25 min', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // Deals & Offers carousel
  Widget _dealsCarousel() {
    final deals = [
      ('Buy 1 Get 1 Free', 'On selected snacks', const Color(0xFFFFE4B3)),
      ('Weekend Deals', 'Up to 40% off dairy', const Color(0xFFE6F4EA)),
      ('Flash Sale', 'Limited time ⏰', const Color(0xFFFFCDD2)),
    ];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: deals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final d = deals[i];
          return Container(
            width: 240,
            decoration: BoxDecoration(color: d.$3, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(d.$2, style: const TextStyle(color: _textGrey)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Frequently bought (Quick Reorder)
  Widget _quickReorderSection() {
    return FutureBuilder<List<ProductItem>>(
      future: PurchaseHistoryService.instance.topProducts(limit: 10),
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <ProductItem>[];
        if (list.isEmpty) {
          return FutureBuilder<List<ProductItem>>(
            future: DummyProductsLoader.loadAll(limit: 10),
            builder: (context, s2) {
              final items = s2.data ?? const <ProductItem>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return _HorizontalProductList(products: items);
            },
          );
        }
        return _HorizontalProductList(products: list);
      },
    );
  }

  // Recommended for you (heuristic)
  Widget _recommendedSection() {
    return FutureBuilder<List<ProductItem>>(
      future: DummyProductsLoader.loadAll(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ProductItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final discounted = items.where((p) => p.discountPrice > 0 && p.discountPrice < p.price).toList();
        final list = discounted.isNotEmpty ? discounted.take(10).toList() : items.take(10).toList();
        return _HorizontalProductList(products: list);
      },
    );
  }

  // Seasonal/trending chips
  Widget _seasonalChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) => ChoiceChip(
          label: Text(_seasonal[i]),
          selected: _selectedSeasonal == i,
          onSelected: (_) {
            setState(() => _selectedSeasonal = i);
            _onSearchSubmitted(_seasonal[i]);
          },
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _seasonal.length,
      ),
    );
  }

  // Categories icons grid
  Widget _categoriesIconGrid({required List<_Category> categories}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: () {
            final r = Responsive.of(context);
            return r.isLarge ? 6 : (r.isMedium ? 5 : 4);
          }(),
          mainAxisSpacing: Responsive.of(context).scale(12),
          crossAxisSpacing: Responsive.of(context).scale(12),
          childAspectRatio: 0.8,
        ),
        itemBuilder: (_, i) {
          final c = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductsListScreen(title: c.title, categoryFilter: c.title),
                  ),
                );
              });
            },
            child: Column(
              children: [
                Container(
                  width: Responsive.of(context).scale(56),
                  height: Responsive.of(context).scale(56),
                  decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                  child: Icon(c.icon, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: Responsive.of(context).sp(12), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Recipe Inspiration card
  Widget _recipeInspirationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Make Pasta Today 🍝 – Add all ingredients to cart',
                style: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                final items = await DummyProductsLoader.loadAll();
                final keywords = ['pasta', 'tomato', 'cheese', 'olive oil'];
                final picks = items
                    .where((p) => keywords.any((k) => p.name.toLowerCase().contains(k)))
                    .take(6)
                    .toList();
                final addList = picks.isNotEmpty ? picks : items.take(4).toList();
                for (final p in addList) {
                  CartService.instance.add(p);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingredients added to cart')),
                );
              },
              child: const Text('Add all'),
            )
          ],
        ),
      ),
    );
  }

  // Wallet & Loyalty row
  Widget _walletPointsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Wallet Balance', style: TextStyle(color: _textGrey, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('₹120', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFE4B3), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Loyalty Points', style: TextStyle(color: _textGrey, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('340 ⭐', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Community reviews section
  Widget _reviewsSection() {
    final items = [
      ('Green Grocer', '4.8', '“Fresh and fast!”'),
      ('Daily Bakery', '4.6', '“Loved the croissants”'),
    ];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final it = items[i];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(it.$1, style: const TextStyle(fontWeight: FontWeight.w700))),
                    const Icon(Icons.star_rate_rounded, color: Colors.orange),
                    Text(it.$2),
                  ],
                ),
                const SizedBox(height: 8),
                Text(it.$3, style: const TextStyle(color: _textGrey)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Refer & Earn banner
  Widget _referBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFD1C4E9), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Expanded(
              child: Text('Refer & Earn 🎁  Get ₹100 for each friend', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () {}, child: const Text('Invite')),
          ],
        ),
      ),
    );
  }

  // Bottom sticky cart preview bar
  Widget _cartPreviewBar() {
    return ValueListenableBuilder<List<CartEntry>>(
      valueListenable: CartService.instance.entries,
      builder: (context, entries, _) {
        final count = entries.fold<int>(0, (acc, e) => acc + e.qty);
        final total = entries.fold<double>(0, (acc, e) => acc + e.lineTotal);
        if (count == 0) return const SizedBox(height: 0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              const Text('🛒 ', style: TextStyle(color: Colors.white)),
              Text('$count items', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
                },
                child: const Text('View Cart'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Popular stores section
  Widget _popularStoresList() {
    final stores = [
      {
        'name': 'Sunny Fruits Emporium',
        'tag': 'Fruit Seller',
        'city': 'London, United Kingdom',
        'img': 'assets/images/bananas.jpg',
      },
      {
        'name': 'Sweet Haven Bakery',
        'tag': 'Pastry',
        'city': 'London, United Kingdom',
        'img': 'assets/images/meat.png',
      },
    ];

    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final s = stores[i];
          return SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      (s['img'] as String).startsWith('assets/')
                          ? Image.asset(
                              s['img'] as String,
                              width: 280,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (c, _, __) => Container(width: 280, height: 150, color: Colors.grey.shade200),
                            )
                          : Image.network(
                              resolveImageUrl(s['img'] as String),
                              width: 280,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (c, _, __) => Container(width: 280, height: 150, color: Colors.grey.shade200),
                            ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(999)),
                          child: Text(s['tag'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s['city'] as String,
                        style: const TextStyle(color: _textGrey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemCount: stores.length,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        height: 240,
        decoration: const BoxDecoration(
          color: _headerColor,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Search + cart bubble row
              Row(
                children: [
                  Expanded(child: _searchBar()),
                  const SizedBox(width: 12),
                  _headerCartButton(context),
                ],
              ),
              const SizedBox(height: 8),
              // Location section label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Current Location',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Address + arrow
              ValueListenableBuilder<String>(
                valueListenable: LocationService.addressNotifier,
                builder: (context, addr, _) {
                  final text = (addr.isEmpty) ? 'California, USA' : addr;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.navigation_outlined, color: _lime, size: 18),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search for 'Grocery'",
          hintStyle: TextStyle(color: _textGrey, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: _textGrey, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _filtersRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return ChoiceChip(
            label: Text(_filters[index]),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = index),
            selectedColor: _headerColor.withOpacity(0.12),
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: selected ? _headerColor : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
      ),
    );
  }

  Widget _sectionHeader(String title, {String? trailing, VoidCallback? onTrailingTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          if (trailing != null)
            InkWell(
              onTap: onTrailingTap,
              child: Text(
                trailing,
                style: const TextStyle(
                  color: _redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _dotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: _redAccent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _headerCartButton(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          if (!context.mounted || _navigating) return;
          setState(() => _navigating = true);
          await Future<void>.delayed(const Duration(milliseconds: 1));
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
          if (!mounted) return;
          setState(() => _navigating = false);
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: ValueListenableBuilder<int>(
            valueListenable: CartService.instance.count,
            builder: (context, count, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(child: Icon(Icons.shopping_cart_outlined, color: _headerColor, size: 22)),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: const BoxDecoration(color: _redAccent, shape: BoxShape.circle),
                        child: Center(
                          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAssistant() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssistantBottomSheet(),
    );
  }

  // Floating Assistant Button (circular), offset above cart preview if visible
  Widget _assistantFab() {
    return ValueListenableBuilder<List<CartEntry>>(
      valueListenable: CartService.instance.entries,
      builder: (context, entries, _) {
        final count = entries.fold<int>(0, (acc, e) => acc + e.qty);
        final bottomPad = count > 0 ? 72.0 : 0.0; // lift above sticky cart preview
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: AssistantFab(
            onPressed: _showAssistant,
            size: 60,
          ),
        );
      },
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 50);
    // Smooth concave curve
    path.quadraticBezierTo(size.width * 0.5, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories});
  final List<_Category> categories;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          primary: false,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(width: r.scale(20)),
          itemBuilder: (_, i) {
            final c = categories[i];
            return InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductsListScreen(
                        title: c.title,
                        categoryFilter: c.title,
                      ),
                    ),
                  );
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: c.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        resolveImageUrl(c.image),
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: 68,
                          height: 68,
                          color: c.color,
                          child: Icon(c.icon, size: 28, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HorizontalProductList extends StatelessWidget {
  const _HorizontalProductList({required this.products});
  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return SizedBox(
      height: r.scale(300),
      child: ListView.separated(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: r.scale(16)),  
        itemBuilder: (context, index) => _ProductCard(product: products[index])
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: const Duration(milliseconds: 250))
              .slideY(begin: 0.06, duration: const Duration(milliseconds: 250)),
      ),
      );
    }
  }

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ProductItem product;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final double cardWidth = w < 360 ? 128 : (w >= 480 ? 160 : 140);
    final double imgSize = w < 360 ? 64 : (w >= 480 ? 80 : 72);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Product Image
            Container(
              width: imgSize,
              height: imgSize,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  resolveImageUrl(
                    product.imageUrl.isNotEmpty
                        ? product.imageUrl
                        : 'https://via.placeholder.com/400x400.png?text=No+Image',
                  ),
                  fit: BoxFit.cover,
                  width: imgSize,
                  height: imgSize,
                  errorBuilder: (context, error, stack) => Container(
                    width: imgSize,
                    height: imgSize,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${product.brand})',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.quantity,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Price and Add Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.discountPrice > 0 && product.discountPrice < product.price) ...[
                          Text(
                            '${product.price.toStringAsFixed(0)},₹',
                            style: const TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          (product.discountPrice > 0 && product.discountPrice < product.price)
                              ? '${product.discountPrice.toStringAsFixed(0)},₹'
                              : '${product.price.toStringAsFixed(0)},₹',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                CartService.instance.add(product);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: _headerColor,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF6DB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xFF6AA84F),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerProductsRow extends StatelessWidget {
  const _ShimmerProductsRow();
  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return SizedBox(
      height: r.scale(300),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(width: r.scale(16)),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: r.scale(140),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(width: 72, height: 72, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                const SizedBox(height: 12),
                Container(height: 14, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(height: 12, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(height: 32, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    Widget promo(String title, String time, String subtitle, Color color, String imageUrl) {
      return Expanded(
        child: Container(
          height: r.isSmall ? 90 : 100,
          padding: EdgeInsets.all(r.isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: r.sp(r.isSmall ? 14 : 16),
                        color: Colors.black87,
                      ),
                    ),
                    Text('By $time', style: TextStyle(color: _textGrey, fontSize: r.sp(11))),
                    Text(subtitle, style: TextStyle(color: _textGrey, fontSize: r.sp(11))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: r.isSmall ? 52 : 60,
                height: r.isSmall ? 52 : 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    resolveImageUrl(imageUrl),
                    width: r.isSmall ? 52 : 60,
                    height: r.isSmall ? 52 : 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: r.isSmall ? 52 : 60,
                      height: r.isSmall ? 52 : 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          promo(
            'Grocery',
            '12:15pm',
            'Free delivery',
            const Color(0xFFFFE4B3),
            'https://picsum.photos/seed/grocery1/400/400',
          ),
          const SizedBox(width: 16),
          promo(
            'Wholesale',
            '1:30pm',
            'Free delivery',
            const Color(0xFFFFCDD2),
            'https://picsum.photos/seed/wholesale1/400/400',
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String title;
  final String image;
  final IconData icon;
  final Color color;
  
  _Category({
    required this.title,
    required this.image,
    required this.icon,
    required this.color,
  });
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black45,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.white,
          elevation: 0,
          iconSize: 26,
          onTap: (index) {
            if (index == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              });
            } else if (index == 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              });
            } else if (index == 3) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              });
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              activeIcon: const _ActiveNavIcon(icon: Icons.home_filled),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shopping_cart_outlined),
              activeIcon: const _ActiveNavIcon(icon: Icons.shopping_cart_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border_rounded),
              activeIcon: const _ActiveNavIcon(icon: Icons.favorite_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const _ActiveNavIcon(icon: Icons.person_rounded),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: Colors.black87),
    );
  }
}