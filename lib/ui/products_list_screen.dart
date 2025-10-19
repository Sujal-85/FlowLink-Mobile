import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/product_detail_screen.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/services/favorites_service.dart';
import 'package:flowlink_mobile/utils/responsive.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key, this.title = 'Products', this.categoryFilter, this.initialQuery});
  final String title;
  final String? categoryFilter;
  final String? initialQuery;

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _search.text = widget.initialQuery!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(r.scale(16), r.scale(12), r.scale(16), r.scale(8)),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductItem>>(
              future: DummyProductsLoader.loadAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? const <ProductItem>[];
                final query = _search.text.trim().toLowerCase();
                final category = widget.categoryFilter?.trim().toLowerCase();

                final filtered = items.where((p) {
                  final matchesCategory = category == null || category.isEmpty
                      ? true
                      : p.category.trim().toLowerCase() == category;
                  final matchesQuery = query.isEmpty
                      ? true
                      : p.name.toLowerCase().contains(query) || p.brand.toLowerCase().contains(query);
                  return matchesCategory && matchesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                // Columns tuned for small phones (e.g., Samsung M01): 1–2 columns on narrow widths
                final cols = () {
                  if (r.width < 340) return 1;   // ultra small devices
                  if (r.width < 480) return 2;   // most small phones -> 2 columns
                  if (r.width < 720) return 3;   // medium/large phones
                  return 4;                      // wide screens/tablets
                }();

                // Make tiles tall enough so the "Add" button is always visible
                // Smaller aspect ratio => taller card (height = width / aspect)
                final childAspect = () {
                  if (cols <= 2) return 0.56;    // extra tall cards for 1–2 column layouts
                  if (cols == 3) return 0.70;    // medium
                  return 0.78;                   // wide
                }();

                final spacing = r.scale(cols <= 2 ? 10 : 12);

                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(8)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspect,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ProductTile(product: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final hasDiscount = product.discountPrice > 0 && product.discountPrice < product.price;
    final double newPrice = hasDiscount ? product.discountPrice : product.price;
    final double oldPrice = product.price;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Image with overlays (flexible to avoid overflow)
            Flexible(
              flex: 6,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.network(
                        resolveImageUrl(
                          product.imageUrl.isNotEmpty ? product.imageUrl : 'https://via.placeholder.com/300x300.png?text=No+Image',
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: r.scale(8),
                      left: r.scale(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(4)),
                        decoration: BoxDecoration(color: const Color(0xFFEAF6DB), borderRadius: BorderRadius.circular(999)),
                        child: Text('-${(100 - (newPrice / oldPrice * 100)).round()}%', style: TextStyle(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: r.sp(11))),
                      ),
                    ),
                  Positioned(
                    top: r.scale(8),
                    right: r.scale(8),
                    child: ValueListenableBuilder<List<ProductItem>>(
                      valueListenable: FavoritesService.instance.favorites,
                      builder: (_, __, ___) {
                        final isFav = FavoritesService.instance.isFavorite(product);
                        return _FavButtonSmall(isFav: isFav, onTap: () => FavoritesService.instance.toggle(product));
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Info section (flexible) with button pinned at bottom
            Flexible(
              flex: 7,
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.scale(10), r.scale(10), r.scale(10), r.scale(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(14))),
                    SizedBox(height: r.scale(2)),
                    Text(product.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black54, fontSize: r.sp(12))),
                    SizedBox(height: r.scale(2)),
                    Text(product.quantity, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black54, fontSize: r.sp(12))),
                    SizedBox(height: r.scale(8)),
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text('₹${oldPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.black54, fontSize: r.sp(12), decoration: TextDecoration.lineThrough)),
                          SizedBox(width: r.scale(6)),
                        ],
                        Text('₹${newPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: r.sp(16))),
                      ],
                    ),
                    SizedBox(height: r.scale(6)),
                    const Spacer(),
                    ValueListenableBuilder<List<CartEntry>>(
                      valueListenable: CartService.instance.entries,
                      builder: (context, entries, _) {
                        int qty = 0;
                        for (final e in entries) {
                          final a = e.item;
                          final matchByUrl = a.productUrl.isNotEmpty && product.productUrl.isNotEmpty && a.productUrl == product.productUrl;
                          final matchByFields = a.productUrl.isEmpty && product.productUrl.isEmpty &&
                              a.name == product.name && a.brand == product.brand && a.quantity == product.quantity && a.imageUrl == product.imageUrl;
                          if (matchByUrl || matchByFields) {
                            qty = e.qty;
                            break;
                          }
                        }
                        if (qty <= 0) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                CartService.instance.add(product);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC8F26A),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.symmetric(vertical: r.scale(10)),
                                textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(12)),
                              ),
                            ),
                          );
                        }
                        return Container(
                          height: r.scale(36),
                          decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _QtyBtn(icon: Icons.remove, onTap: () => CartService.instance.decrement(product)),
                              Text('$qty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(14))),
                              _QtyBtn(icon: Icons.add, onTap: () => CartService.instance.add(product)),
                            ],
                          ),
                        );
                      },
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

class _FavButtonSmall extends StatelessWidget {
  const _FavButtonSmall({required this.isFav, required this.onTap});
  final bool isFav;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Material(
      color: Colors.white,
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
            size: r.scale(20),
            color: isFav ? Colors.redAccent : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: r.scale(40), child: Center(child: Icon(icon, size: r.scale(18)))),
    );
  }
}
