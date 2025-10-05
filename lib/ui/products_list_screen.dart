import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/product_detail_screen.dart';
import 'package:flowlink_mobile/services/cart_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                resolveImageUrl(
                  product.imageUrl.isNotEmpty
                      ? product.imageUrl
                      : 'https://via.placeholder.com/300x300.png?text=No+Image',
                ),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text('(${product.brand})', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(product.quantity, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    (product.discountPrice > 0 && product.discountPrice < product.price)
                        ? '₹${product.discountPrice.toStringAsFixed(0)}'
                        : '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8F26A),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      onPressed: () {
                        CartService.instance.add(product);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
