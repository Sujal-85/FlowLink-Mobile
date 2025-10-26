import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'products_list_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'offers_screen.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/location_service.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/services/purchase_history_service.dart';
import 'package:flowlink_mobile/services/user_service.dart';
import 'package:flowlink_mobile/services/favorites_service.dart';
import 'package:flowlink_mobile/utils/upi_payment.dart';
import 'package:flowlink_mobile/ui/payment_upi_pending_screen.dart';
import 'scan_screen.dart';
import 'package:flowlink_mobile/widgets/assistant_fab.dart';
import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flowlink_mobile/utils/responsive.dart';
import 'package:share_plus/share_plus.dart';
import 'location_select_screen.dart';
import 'notifications_screen.dart';

// Shared colors matching the design
const Color _headerColor = AppColors.greenDark; // deep teal as in design
const Color _lime = AppColors.greenPrimary; // checkout/add accent
const Color _textGrey = Color(0xFF7A7F85);
const Color _redAccent = Color(0xFFFF6B6B);
const Color _lightGreen = Color(
  0xFFEAF6DB,
); // light highlight for selected tabs

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showBottomNav = true, this.onOpenCartTab});
  final bool showBottomNav;
  final VoidCallback? onOpenCartTab;

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
  // Speech
  late final stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _listening = false;
  final List<String> _seasonal = const [
    'Festive Specials',
    'Winter Essentials',
    'Healthy Choices',
  ];
  int _selectedSeasonal = 0;
  @override
  void initState() {
    super.initState();
    // Defer address initialization to post-frame to avoid running in build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.initCurrentAddress();
    });
    _initSpeech();
  }

  Future<bool> _handlePaymentScan(String raw) async {
    final s = raw.trim();
    if (s.isEmpty || !mounted) return false;
    final total = CartService.instance.total;
    final itemsCount = CartService.instance.entries.value.fold<int>(
      0,
      (acc, e) => acc + e.qty,
    );

    String? vpa;
    String merchant = 'FlowLink Store';
    if (s.toLowerCase().startsWith('upi:')) {
      final uri = Uri.tryParse(s);
      final pa = uri?.queryParameters['pa']?.trim();
      final pn = uri?.queryParameters['pn']?.trim();
      if (pa == null || pa.isEmpty) return false;
      vpa = pa;
      if (pn != null && pn.isNotEmpty) merchant = pn;
    } else {
      final vpaRe = RegExp(r'^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$');
      if (vpaRe.hasMatch(s)) {
        vpa = s;
      }
    }

    if (vpa == null) return false;
    final amount = total.toStringAsFixed(2);
    await initiateUpiPayment(
      context,
      upiId: vpa,
      name: merchant,
      amount: amount,
      note: 'FlowLink Order · $itemsCount items',
    );
    if (!mounted) return true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpiPendingScreen(total: total, itemsCount: itemsCount),
      ),
    );
    return true;
  }

  Future<void> _openLocationSheet() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select delivery location',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for area, street name...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.my_location,
                    color: AppColors.greenPrimary,
                  ),
                  title: const Text(
                    'Use current location',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: ValueListenableBuilder<String>(
                    valueListenable: LocationService.addressNotifier,
                    builder: (_, addr, __) => Text(
                      addr.isEmpty ? 'Detecting…' : addr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final pos = await LocationService.getCurrentPosition();
                      await LocationService.updateAddressFromCoordinates(
                        pos.latitude,
                        pos.longitude,
                      );
                    } catch (_) {}
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.add_location_alt_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: const Text(
                    'Add new address',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Set location on map'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final result =
                        await Navigator.of(
                          context,
                          rootNavigator: true,
                        ).push<Map<String, dynamic>>(
                          MaterialPageRoute(
                            builder: (_) => const LocationSelectScreen(),
                          ),
                        );
                    if (result != null) {
                      final lat = (result['lat'] as num?)?.toDouble();
                      final lng = (result['lng'] as num?)?.toDouble();
                      if (lat != null && lng != null) {
                        await LocationService.updateAddressFromCoordinates(
                          lat,
                          lng,
                        );
                      }
                    }
                  },
                ),
                // const Divider(height: 1),
                // ListTile(
                //   leading: const Icon(Icons.import_contacts, color: Colors.redAccent),
                //   title: const Text('Import your addresses from Zomato'),
                //   trailing: const Icon(Icons.chevron_right),
                //   onTap: () {
                //     Navigator.of(context).pop();
                //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import from Zomato coming soon')));
                //   },
                // ),
                // const Divider(height: 1),
                // ListTile(
                //   leading: const Icon(Icons.chat, color: Colors.green),
                //   title: const Text('Request address from someone'),
                //   trailing: const Icon(Icons.chevron_right),
                //   onTap: () {
                //     Navigator.of(context).pop();
                //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request address flow coming soon')));
                //   },
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sticky search bar with voice and scan actions
  Widget _stickySearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F2328)
              : const Color(0xFFF7F9FA),
          borderRadius: BorderRadius.circular(999),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                Icons.search,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : _textGrey,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              onPressed: () => _onSearchSubmitted(_searchCtrl.text),
              tooltip: 'Search',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search for items",
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmitted,
              ),
            ),
            IconButton(
              icon: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _listening
                    ? Colors.redAccent
                    : Theme.of(context).colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              tooltip: _listening ? 'Stop listening' : 'Voice search',
              onPressed: _toggleListen,
            ),
            IconButton(
              icon: Icon(
                Icons.qr_code_scanner_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              tooltip: 'Scan to Pay',
              onPressed: () async {
                final result = await Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
                if (result is String && result.isNotEmpty) {
                  final ok = await _handlePaymentScan(result);
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not a UPI payment code')),
                    );
                  }
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
        builder: (_) => ProductsListScreen(
          title: 'Search',
          initialQuery: q,
          categoryFilter: null,
        ),
      ),
    );
  }

  // String _extractSearchFromScan(String raw) {
  //   final s = raw.trim();
  //   if (s.isEmpty) return s;
  //   final lower = s.toLowerCase();
  //   // Handle UPI intent QR: upi://pay?... We pick merchant name (pn) or note (tn)
  //   if (lower.startsWith('upi:')) {
  //     final uri = Uri.tryParse(s);
  //     final pn = uri?.queryParameters['pn']?.trim();
  //     final tn = uri?.queryParameters['tn']?.trim();
  //     if (pn != null && pn.isNotEmpty) return pn;
  //     if (tn != null && tn.isNotEmpty) return tn;
  //     final pa = uri?.queryParameters['pa']?.trim();
  //     if (pa != null && pa.isNotEmpty) return pa.split('@').first;
  //     return 'UPI';
  //   }
  //   // If it's a URL, extract the last meaningful path segment
  //   if (lower.startsWith('http://') || lower.startsWith('https://')) {
  //     final uri = Uri.tryParse(s);
  //     if (uri != null) {
  //       String candidate = '';
  //       if (uri.pathSegments.isNotEmpty) {
  //         candidate = Uri.decodeComponent(uri.pathSegments.last);
  //       }
  //       if (candidate.isEmpty) {
  //         candidate = uri.queryParameters['q'] ?? uri.host;
  //       }
  //       candidate = candidate.replaceAll(RegExp(r'[-_]+'), ' ').replaceAll(RegExp(r'\.[a-zA-Z0-9]{2,4}$'), '').trim();
  //       return candidate.isNotEmpty ? candidate : s;
  //     }
  //   }
  //   return s;
  // }

  Future<void> _showNotifications() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  @override
  void dispose() {
    _promoController.dispose();
    _searchCtrl.dispose();
    if (_listening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'notListening') setState(() => _listening = false);
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _listening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  Future<void> _toggleListen() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice search not available on this device'),
        ),
      );
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'en_IN',
      listenMode: stt.ListenMode.search,
      onResult: (res) {
        final words = res.recognizedWords.trim();
        if (words.isNotEmpty) {
          _searchCtrl.text = words;
        }
        if (res.finalResult && words.isNotEmpty) {
          _onSearchSubmitted(words);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Products will be loaded from assets via DummyProductsLoader

    final categories = [
      _Category(
        title: 'Fruits & Vegetables',
        image:
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600',
        icon: Icons.eco,
        color: const Color(0xFFE8F5E8),
      ),
      _Category(
        title: 'Eggs, Meat & Fish',
        image:
            'https://images.unsplash.com/photo-1604908554007-94025d0f49ad?w=600',
        icon: Icons.set_meal,
        color: const Color(0xFFFFE4B3),
      ),
      _Category(
        title: 'Bakery, Cakes & Dairy',
        image:
            'https://images.unsplash.com/photo-1540479859555-17af45c78602?w=600',
        icon: Icons.bakery_dining,
        color: const Color(0xFFFFF8DC),
      ),
      _Category(
        title: 'Beverages',
        image:
            'https://images.unsplash.com/photo-1517705008128-361805f42e86?w=600',
        icon: Icons.local_drink,
        color: const Color(0xFFE1F5FE),
      ),
      _Category(
        title: 'Beauty & Hygiene',
        image:
            'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=600',
        icon: Icons.spa,
        color: const Color(0xFFF3E5F5),
      ),
      _Category(
        title: 'Cleaning & Household',
        image:
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600',
        icon: Icons.cleaning_services,
        color: const Color(0xFFE8F5E9),
      ),
      _Category(
        title: 'Foodgrains, Oil & Masala',
        image:
            'https://images.unsplash.com/photo-1604909177070-0b095a3c0d9d?w=600',
        icon: Icons.rice_bowl,
        color: const Color(0xFFFFECB3),
      ),
      _Category(
        title: 'Baby Care',
        image:
            'https://images.unsplash.com/photo-1580476262796-c91b6c1a39bd?w=600',
        icon: Icons.child_friendly,
        color: const Color(0xFFE1F5FE),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: widget.showBottomNav
          ? _BottomNav(currentIndex: 0)
          : null,
      floatingActionButton: _assistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // Green header gradient backdrop
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenPrimary, AppColors.greenDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AbsorbPointer(
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
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
                            // _deliveryTrackerCard(),
                            // const SizedBox(height: 16),
                            _sectionHeader(
                              'Deals & Offers',
                              trailing: 'See All',
                              onTrailingTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const OffersScreen(),
                                    ),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _dealsCarousel(),
                            const SizedBox(height: 16),
                            _sectionHeader(
                              'Your weekly picks',
                              trailing: 'See All',
                              onTrailingTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProductsListScreen(
                                        title: 'Your Weekly Picks',
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _quickReorderSection(),
                            const SizedBox(height: 16),
                            _sectionHeader(
                              'Recommended for you',
                              trailing: 'See All',
                              onTrailingTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProductsListScreen(
                                        title: 'Recommended for You',
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _recommendedSection(),
                            const SizedBox(height: 16),
                            // _seasonalChips(),
                            // const SizedBox(height: 16),
                            // _sectionHeader(
                            //   'Popular Store🔥',
                            //   trailing: 'See All',
                            //   onTrailingTap: () {
                            //     WidgetsBinding.instance.addPostFrameCallback((_) {
                            //       if (!context.mounted) return;
                            //       Navigator.of(context).push(
                            //         MaterialPageRoute(
                            //           builder: (_) => const ProductsListScreen(title: 'Popular Store'),
                            //         ),
                            //       );
                            //     });
                            //   },
                            // ),
                            // const SizedBox(height: 12),
                            // _popularStoresList(),
                            const SizedBox(height: 16),
                            _sectionHeader(
                              'Top Categories',
                              trailing: 'See All',
                              onTrailingTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CategoriesScreen(),
                                    ),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _CategoryRow(categories: categories),
                            const SizedBox(height: 16),
                            _recipesSection(),
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
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
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
                              future: DummyProductsLoader.loadAll(
                                validateImages: false,
                                bustCache: true,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const _ShimmerProductsRow();
                                }
                                final items =
                                    snapshot.data ?? const <ProductItem>[];
                                final filtered = items
                                    .where(
                                      (p) =>
                                          p.category.trim().toLowerCase() ==
                                          'fruits & vegetables'.toLowerCase(),
                                    )
                                    .toList();
                                return _HorizontalProductList(
                                  products: filtered.isNotEmpty
                                      ? filtered
                                      : items,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _PromoRow(),
                            const SizedBox(height: 24),
                            _sectionHeader(
                              'Featured',
                              trailing: 'See all',
                              onTrailingTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
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
                              future: DummyProductsLoader.loadAll(
                                validateImages: false,
                                bustCache: true,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox(
                                    height: 280,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _headerColor,
                                      ),
                                    ),
                                  );
                                }
                                final items =
                                    snapshot.data ?? const <ProductItem>[];
                                final filtered = items
                                    .where(
                                      (p) =>
                                          p.category.trim().toLowerCase() ==
                                          'eggs, meat & fish'.toLowerCase(),
                                    )
                                    .toList();
                                final list =
                                    (filtered.isNotEmpty ? filtered : items)
                                        .reversed
                                        .toList();
                                return _HorizontalProductList(products: list);
                              },
                            ),
                            const SizedBox(height: 24),
                            _sectionHeader(
                              'Top Picks',
                              trailing: 'See All',
                              onTrailingTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProductsListScreen(
                                        title: 'Top Picks',
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<List<ProductItem>>(
                              future: DummyProductsLoader.loadAll(
                                validateImages: false,
                                bustCache: true,
                              ),
                              builder: (context, snapshot) {
                                final items =
                                    snapshot.data ?? const <ProductItem>[];
                                final picks = items.take(10).toList();
                                return _HorizontalProductList(products: picks);
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _cartPreviewBar(),
                ],
              ),
            ),
          ),
        ],
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
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: _openLocationSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: LocationService.addressNotifier,
                        builder: (context, addr, _) {
                          final text = (addr.isEmpty)
                              ? 'Select delivery location'
                              : addr;
                          return Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _circleIcon(Icons.chat_bubble_outline, onTap: _showAssistant),
          const SizedBox(width: 8),
          _circleIcon(
            Icons.notifications_none_rounded,
            onTap: _showNotifications,
          ),
          const SizedBox(width: 8),
          _headerCartButton(context),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white12 : Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
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
          ValueListenableBuilder<String>(
            valueListenable: UserService.instance.displayName,
            builder: (_, name, __) {
              final trimmed = name.trim();
              // Show first name if available; otherwise a friendly fallback
              final first = trimmed.isEmpty
                  ? 'there'
                  : trimmed.split(' ').first;
              return Text(
                'Hello, $first! 👋',
                style: TextStyle(
                  color: _textGrey,
                  fontSize: subSize,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Fulfill all your daily needs\nwith FlowLink',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // Promo carousel with two cards
  Widget _promoCarousel() {
    return SizedBox(
      height: 150,
      child: PageView(
        controller: _promoController,
        onPageChanged: (i) => setState(() => _promoPage = i),
        children: [
          _promoCard(
            bg: const Color(0xFFE6F4EA),
            badge: 'Delivery in 25 min',
            title: 'Get free shipping and 25% discount for today only',
            image:
                'https://img.freepik.com/premium-vector/fashionable-woman-mall-show-online-mobile-app-phone-shopping-clothing-store-shop_142963-2032.jpg',
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

  Widget _promoCard({
    required Color bg,
    required String badge,
    required String title,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.biggest.height;
                  final size = (h - 24).clamp(88.0, 140.0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).cardColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow:
                                Theme.of(context).brightness == Brightness.light
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: image.startsWith('assets/')
                                  ? Image.asset(
                                      image,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, _, __) =>
                                          Container(color: Colors.white),
                                    )
                                  : Image.network(
                                      resolveImageUrl(image),
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, _, __) =>
                                          Container(color: Colors.white),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
  // Widget _deliveryTrackerCard() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Container(
  //       height: 64,
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFE8F5E8),
  //         borderRadius: BorderRadius.circular(14),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: Row(
  //         children: [
  //           const Icon(Icons.delivery_dining_rounded, color: AppColors.greenPrimary),
  //           const SizedBox(width: 12),
  //           const Expanded(
  //             child: Text('Order on the way · ETA 25 min', style: TextStyle(fontWeight: FontWeight.w700)),
  //           ),
  //           const Icon(Icons.chevron_right),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _deliveryTrackerCard() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Container(
  //       height: 64,
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFE8F5E8),
  //         borderRadius: BorderRadius.circular(14),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: Row(
  //         children: [
  //           const Icon(Icons.delivery_dining_rounded, color: AppColors.greenPrimary),
  //           const SizedBox(width: 12),
  //           const Expanded(
  //             child: Text('Order on the way · ETA 25 min', style: TextStyle(fontWeight: FontWeight.w700)),
  //           ),
  //           const Icon(Icons.chevron_right),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
            decoration: BoxDecoration(
              color: d.$3,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  d.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerProductsRow();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return FutureBuilder<List<ProductItem>>(
            future: DummyProductsLoader.loadAll(limit: 10),
            builder: (context, s2) {
              if (s2.connectionState == ConnectionState.waiting) {
                return const _ShimmerProductsRow();
              }
              if (s2.hasError || !s2.hasData || s2.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return _HorizontalProductList(products: s2.data!);
            },
          );
        }
        return _HorizontalProductList(products: snapshot.data!);
      },
    );
  }

  // Recommended for you (heuristic)
  Widget _recommendedSection() {
    return FutureBuilder<List<ProductItem>>(
      future: DummyProductsLoader.loadAll(
        validateImages: false,
        bustCache: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerProductsRow();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        final discounted = items
            .where((p) => p.discountPrice > 0 && p.discountPrice < p.price)
            .toList();
        final list = discounted.isNotEmpty
            ? discounted.take(10).toList()
            : items.take(10).toList();
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
          final size = Responsive.of(context).scale(56);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final iconColor = isDark
              ? Colors.white
              : (ThemeData.estimateBrightnessForColor(c.color) == Brightness.dark
                  ? Colors.white
                  : Colors.black87);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
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
              key: ValueKey(c.title),
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: Image.network(
                          resolveImageUrl(c.image),
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            width: size,
                            height: size,
                            color: c.color,
                          ),
                        ),
                      ),
                      if (isDark)
                        ClipOval(
                          child: Container(
                            width: size,
                            height: size,
                            color: Colors.black.withOpacity(0.25),
                          ),
                        ),
                      Icon(c.icon, color: iconColor),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.of(context).sp(12),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // (deprecated) _recipeInspirationCard has been replaced by _recipesSection

  Widget _recipesSection() {
    final list = _recipeList();
    final featured = list.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Recipes',
          trailing: 'See all',
          onTrailingTap: _openRecipesAll,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final r = featured[i];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${r.emoji} ${r.title}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add ingredients',
                            style: TextStyle(color: _textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addRecipeIngredients(r),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openRecipesAll() async {
    final list = _recipeList();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'All Recipes',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = list[i];
                      return ListTile(
                        title: Text(
                          '${r.emoji} ${r.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Tap Add to put ingredients in cart',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _addRecipeIngredients(r),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lime,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addRecipeIngredients(_Recipe r) async {
    final items = await DummyProductsLoader.loadAll(validateImages: false);
    final keys = r.keywords.map((e) => e.toLowerCase()).toList();
    final picks = items
        .where((p) {
          final text = '${p.name} ${p.brand} ${p.category} ${p.subCategory}'
              .toLowerCase();
          return keys.any((k) => text.contains(k));
        })
        .take(8)
        .toList();
    final addList = picks.isNotEmpty ? picks : items.take(4).toList();
    for (final p in addList) {
      CartService.instance.add(p);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${addList.length} items for ${r.title}')),
    );
  }

  List<_Recipe> _recipeList() {
    return [
      _Recipe('Pasta Arrabiata', '🍝', [
        'pasta',
        'penne',
        'tomato',
        'sauce',
        'olive oil',
        'garlic',
        'basil',
        'cheese',
      ]),
      _Recipe('Veg Pizza', '🍕', [
        'pizza',
        'cheese',
        'mozzarella',
        'tomato',
        'capsicum',
        'olives',
      ]),
      _Recipe('Paneer Butter Masala', '🧀', [
        'paneer',
        'butter',
        'masala',
        'tomato',
        'cream',
      ]),
      _Recipe('Dal Tadka', '🥣', ['dal', 'lentil', 'toor', 'ghee', 'cumin']),
      _Recipe('Chole Bhature', '🍛', [
        'chole',
        'chana',
        'chickpea',
        'maida',
        'flour',
      ]),
      _Recipe('Rajma Chawal', '🍛', [
        'rajma',
        'kidney',
        'bean',
        'basmati',
        'rice',
      ]),
      _Recipe('Fried Rice', '🍚', [
        'rice',
        'soy',
        'carrot',
        'beans',
        'spring onion',
      ]),
      _Recipe('Veg Biryani', '🍲', [
        'biryani',
        'basmati',
        'masala',
        'rice',
        'saffron',
      ]),
      _Recipe('Poha', '🥗', [
        'poha',
        'flattened',
        'peanut',
        'mustard',
        'curry',
      ]),
      _Recipe('Upma', '🥣', ['upma', 'sooji', 'semolina', 'rava']),
      _Recipe('Dosa', '🥞', ['dosa', 'idli', 'batter', 'rice', 'urad']),
      _Recipe('Idli Sambar', '🥘', ['idli', 'sambar', 'dal', 'tamarind']),
      _Recipe('Aloo Paratha', '🥙', ['potato', 'aloo', 'atta', 'ghee']),
      _Recipe('Omelette', '🍳', ['egg', 'eggs', 'onion', 'tomato', 'pepper']),
      _Recipe('Pancakes', '🥞', ['pancake', 'flour', 'syrup', 'honey']),
      _Recipe('Masala Chai', '🫖', [
        'tea',
        'milk',
        'ginger',
        'cardamom',
        'sugar',
      ]),
      _Recipe('Coffee Latte', '☕', ['coffee', 'milk', 'sugar']),
      _Recipe('Veg Sandwich', '🥪', [
        'bread',
        'butter',
        'cheese',
        'cucumber',
        'tomato',
      ]),
      _Recipe('Fresh Salad', '🥗', [
        'lettuce',
        'cucumber',
        'tomato',
        'olive oil',
      ]),
      _Recipe('Masala Noodles', '🍜', ['noodles', 'maggi', 'ramen', 'masala']),
    ];
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
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '30-min Delivery',
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'ETA 25 min',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4B3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Free Delivery',
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Orders over ₹299',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
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
      ('Fresh Mart', '4.8', '“Farm-fresh veggies daily”'),
      ('Daily Essentials', '4.6', '“Best prices on staples”'),
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        it.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.star_rate_rounded, color: Colors.orange),
                    Text(
                      it.$2,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(it.$3, style: TextStyle(color: _textGrey)),
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Refer & Earn 🎁  Get ₹100 for each friend',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _shareInvite,
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInvite() async {
    const link = 'https://flowlink.page.link/invite?ref=FL123';
    const message =
        'Join me on FlowLink for fresh groceries delivered fast! Get ₹100 on signup: ';
    await Share.share('$message$link', subject: 'Join me on FlowLink');
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
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '🛒 ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$count items',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  if (widget.onOpenCartTab != null) {
                    widget.onOpenCartTab!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  }
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
                              errorBuilder: (c, _, __) => Container(
                                width: 280,
                                height: 150,
                                color: Colors.grey.shade200,
                              ),
                            )
                          : Image.network(
                              resolveImageUrl(s['img'] as String),
                              width: 280,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (c, _, __) => Container(
                                width: 280,
                                height: 150,
                                color: Colors.grey.shade200,
                              ),
                            ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s['tag'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
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
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
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
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
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
                      const Icon(
                        Icons.navigation_outlined,
                        color: _lime,
                        size: 18,
                      ),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white12
            : const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(999),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearchSubmitted,
        decoration: InputDecoration(
          hintText: "Search for 'Grocery'",
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : _textGrey,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : _textGrey,
            size: 22,
          ),
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        cursorColor: Theme.of(context).colorScheme.primary,
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
            selectedColor: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.12),
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white12 : Colors.white,
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
          if (widget.onOpenCartTab != null) {
            widget.onOpenCartTab!();
          } else {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
          }
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
                  Center(
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: _redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
      useRootNavigator: true,
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
        final bottomPad = count > 0
            ? 72.0
            : 0.0; // lift above sticky cart preview
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: AssistantFab(onPressed: _showAssistant, size: 60),
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
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Recipe {
  final String title;
  final String emoji;
  final List<String> keywords;
  const _Recipe(this.title, this.emoji, this.keywords);
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            resolveImageUrl(c.image),
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              width: 68,
                              height: 68,
                              color: c.color,
                              child: Icon(
                                c.icon,
                                size: 28,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : (ThemeData.estimateBrightnessForColor(c.color) == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                        if (Theme.of(context).brightness == Brightness.dark)
                          ClipOval(
                            child: Container(
                              width: 68,
                              height: 68,
                              color: Colors.black.withOpacity(0.25),
                            ),
                          ),
                        Icon(
                          c.icon,
                          size: 28,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : (ThemeData.estimateBrightnessForColor(c.color) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
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
    if (products.isEmpty) {
      return SizedBox(
        height: r.scale(300),
        child: const Center(child: Text('No products available')),
      );
    }
    return SizedBox(
      height: r.scale(300),
      child: ListView.separated(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: r.scale(16)),
        itemBuilder: (context, index) => _ModernProductCard(
          product: products[index],
          key: ValueKey(
            products[index].productUrl.isNotEmpty
                ? products[index].productUrl
                : '${products[index].name}|${products[index].brand}',
          ),
        ),
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
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 32,
                    ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${product.brand})',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.quantity,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Price and Add Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.discountPrice > 0 &&
                            product.discountPrice < product.price) ...[
                          Text(
                            '${product.price.toStringAsFixed(0)},₹',
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          (product.discountPrice > 0 &&
                                  product.discountPrice < product.price)
                              ? '${product.discountPrice.toStringAsFixed(0)},₹'
                              : '${product.price.toStringAsFixed(0)},₹',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
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
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} added to cart',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
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

// Modernized product card with favorite and cart stepper
class _ModernProductCard extends StatefulWidget {
  const _ModernProductCard({required this.product, super.key});
  final ProductItem product;

  @override
  _ModernProductCardState createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<_ModernProductCard> {
  bool _isLaidOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLaidOut = true);
      }
    });
  }

  String _keyFor(ProductItem p) {
    if (p.productUrl.isNotEmpty) return p.productUrl;
    return '${p.name}|${p.brand}|${p.quantity}|${p.imageUrl}';
  }

  int _qtyInCart(List<CartEntry> entries) {
    final key = _keyFor(widget.product);
    for (final e in entries) {
      final ek = _keyFor(e.item);
      if (ek == key) return e.qty;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final hasDiscount =
        widget.product.discountPrice > 0 &&
        widget.product.discountPrice < widget.product.price;
    final double newPrice = hasDiscount
        ? widget.product.discountPrice
        : widget.product.price;
    final double oldPrice = widget.product.price;
    final int discountPercent = hasDiscount
        ? (100 - (newPrice / oldPrice * 100)).round()
        : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _isLaidOut
          ? () {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: widget.product),
                ),
              );
            }
          : null,
      child: Container(
        width: r.scale(160),
        height: r.scale(160) * 1.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Image.network(
                        resolveImageUrl(
                          widget.product.imageUrl.isNotEmpty
                              ? widget.product.imageUrl
                              : 'https://via.placeholder.com/300x300.png?text=No+Image',
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: r.scale(8),
                      left: r.scale(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.scale(8),
                          vertical: r.scale(4),
                        ),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: TextStyle(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w800,
                            fontSize: r.sp(11),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: r.scale(8),
                    right: r.scale(8),
                    child: ValueListenableBuilder<List<ProductItem>>(
                      valueListenable: FavoritesService.instance.favorites,
                      builder: (_, favorites, __) {
                        final isFav = favorites.any(
                          (item) => _keyFor(item) == _keyFor(widget.product),
                        );
                        return _FavButton(
                          isFav: isFav,
                          onTap: _isLaidOut
                              ? () => FavoritesService.instance.toggle(
                                  widget.product,
                                )
                              : () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.scale(12),
                  r.scale(10),
                  r.scale(12),
                  r.scale(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: r.sp(14),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: r.scale(2)),
                    Text(
                      widget.product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _textGrey, fontSize: r.sp(12)),
                    ),
                    SizedBox(height: r.scale(2)),
                    Text(
                      widget.product.quantity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _textGrey, fontSize: r.sp(12)),
                    ),
                    SizedBox(height: r.scale(8)),
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            '₹${oldPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: r.sp(12),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: r.scale(6)),
                        ],
                        Text(
                          '₹${newPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: r.sp(16),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: r.scale(6)),
                    ValueListenableBuilder<List<CartEntry>>(
                      valueListenable: CartService.instance.entries,
                      builder: (context, entries, _) {
                        final qty = _qtyInCart(entries);
                        if (qty <= 0) {
                          return SizedBox(
                            width: double.infinity,
                            height: r.scale(36),
                            child: ElevatedButton.icon(
                              onPressed: _isLaidOut
                                  ? () {
                                      CartService.instance.add(widget.product);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${widget.product.name} added to cart',
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _lime,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size(double.infinity, r.scale(36)),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(
                          height: r.scale(36),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _IconBtn(
                                icon: Icons.remove,
                                onTap: _isLaidOut
                                    ? () => CartService.instance.decrement(
                                        widget.product,
                                      )
                                    : () {},
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              _IconBtn(
                                icon: Icons.add,
                                onTap: _isLaidOut
                                    ? () => CartService.instance.add(
                                        widget.product,
                                      )
                                    : () {},
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
        ),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  const _FavButton({required this.isFav, required this.onTap});
  final bool isFav;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white12 : Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(r.scale(8.0)),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav
                ? Colors.redAccent
                : (isDark ? Colors.white : Colors.black87),
            size: r.scale(20),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: r.scale(40),
        child: Center(
          child: Icon(
            icon,
            size: r.scale(18),
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
        padding: EdgeInsets.symmetric(horizontal: r.scale(20)),
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
            padding: EdgeInsets.all(r.scale(12)),
            child: Column(
              children: [
                SizedBox(height: r.scale(8)),
                Container(
                  width: r.scale(72),
                  height: r.scale(72),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: r.scale(12)),
                Container(
                  height: r.sp(14),
                  width: r.scale(100),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(height: r.scale(8)),
                Container(
                  height: r.sp(12),
                  width: r.scale(80),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Spacer(),
                Container(
                  height: r.scale(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
    Widget promo(
      String title,
      String time,
      String subtitle,
      Color color,
      String imageUrl,
    ) {
      return Expanded(
        child: Container(
          height: r.isSmall ? 100 : 112,
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
                    Text(
                      'By $time',
                      style: TextStyle(color: _textGrey, fontSize: r.sp(11)),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: _textGrey, fontSize: r.sp(11)),
                    ),
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
    final theme = Theme.of(context);
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: theme.cardColor,
          elevation: 0,
          iconSize: 26,
          onTap: (index) {
            if (index == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
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
              icon: const Icon(Icons.home_outlined),
              activeIcon: const _ActiveNavIcon(icon: Icons.home_filled),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shopping_cart_outlined),
              activeIcon: const _ActiveNavIcon(icon: Icons.shopping_cart),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}
