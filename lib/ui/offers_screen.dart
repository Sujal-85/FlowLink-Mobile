import 'package:flutter/material.dart';
import 'package:flowlink_mobile/utils/responsive.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    // Compute tile height from available width for better responsiveness
    final columns = r.isLarge ? 3 : 2;
    final horizontalPadding = r.scale(16) * 2;
    final spacing = r.scale(12) * (columns - 1);
    final tileWidth = (r.width - horizontalPadding - spacing) / columns;
    final double tileExtent = () {
      // Height tuned per breakpoint to prevent overflow
      if (r.isLarge) return tileWidth * 0.90;
      if (r.isMedium) return tileWidth * 1.30;
      return tileWidth * 1.40; // tallest on small screens
    }();
    final offers = <_Offer>[
      _Offer(
        title: 'Buy 1 Get 1 Free',
        subtitle: 'On selected snacks',
        color: const Color(0xFFFFE4B3),
        badge: 'Today only',
      ),
      _Offer(
        title: 'Weekend Deals',
        subtitle: 'Up to 40% off dairy',
        color: const Color(0xFFE6F4EA),
        badge: 'Weekend',
      ),
      _Offer(
        title: 'Flash Sale',
        subtitle: 'Limited time ⏰',
        color: const Color(0xFFFFCDD2),
        badge: '2h left',
      ),
      _Offer(
        title: 'Fresh Produce',
        subtitle: 'Save on fruits & veggies',
        color: const Color(0xFFE3F2FD),
        badge: 'Top picks',
      ),
      _Offer(
        title: 'Bakery & Dairy',
        subtitle: 'Bundle discounts',
        color: const Color(0xFFFFF3E0),
        badge: 'Bundles',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: EdgeInsets.fromLTRB(r.scale(16), r.scale(16), r.scale(16), r.scale(24)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: () {
            if (r.isLarge) return 3;
            // Keep 2 columns for small and medium to give tiles more room
            return 2;
          }(),
          mainAxisSpacing: r.scale(12),
          crossAxisSpacing: r.scale(12),
          mainAxisExtent: tileExtent,
        ),
        itemCount: offers.length,
        itemBuilder: (_, i) => _OfferCard(data: offers[i]),
      ),
    );
  }
}

class _Offer {
  final String title;
  final String subtitle;
  final Color color;
  final String badge;
  const _Offer({required this.title, required this.subtitle, required this.color, required this.badge});
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.data});
  final _Offer data;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isSmall = r.isSmall;
    final mq = MediaQuery.of(context);
    final clampedMq = mq.copyWith(textScaler: TextScaler.linear(mq.textScaleFactor.clamp(0.9, 1.0)));
    return MediaQuery(
      data: clampedMq,
      child: Container(
      decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(16)),
      padding: EdgeInsets.all(isSmall ? r.scale(12) : r.scale(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? r.scale(8) : r.scale(10), vertical: isSmall ? r.scale(4) : r.scale(6)),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(999)),
            child: Text(data.badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          SizedBox(height: isSmall ? r.scale(6) : r.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: isSmall ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: r.sp(isSmall ? 13 : 15)),
                ),
                SizedBox(height: isSmall ? r.scale(4) : r.scale(6)),
                Text(
                  data.subtitle,
                  maxLines: isSmall ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black87, fontSize: r.sp(isSmall ? 11 : 12)),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: isSmall
                ? TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      minimumSize: Size(r.scale(36), r.scale(30)),
                      padding: EdgeInsets.all(r.scale(8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Icon(Icons.local_offer_outlined, size: 18),
                  )
                : TextButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      minimumSize: Size(r.scale(64), r.scale(34)),
                      padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.local_offer_outlined, size: 18),
                    label: const Text('View'),
                  ),
          ),
        ],
      ),
    ));
  }
}
