import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';

class ShippingDetailScreen extends StatefulWidget {
  const ShippingDetailScreen({super.key, required this.order});
  final OrderItem order;

  @override
  State<ShippingDetailScreen> createState() => _ShippingDetailScreenState();
}

class _ShippingDetailScreenState extends State<ShippingDetailScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  late LatLng _vehicle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _vehicle = LatLng(widget.order.originLat, widget.order.originLng);
    _startMockMovement();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMockMovement() {
    final dest = LatLng(widget.order.destLat, widget.order.destLng);
    final rnd = Random();
    _timer = Timer.periodic(const Duration(seconds: 2), (t) async {
      final lat = _vehicle.latitude + (dest.latitude - _vehicle.latitude) * 0.12 + (rnd.nextDouble() - 0.5) * 0.001;
      final lng = _vehicle.longitude + (dest.longitude - _vehicle.longitude) * 0.12 + (rnd.nextDouble() - 0.5) * 0.001;
      setState(() => _vehicle = LatLng(lat, lng));
    });
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final status = o.status;
    final eta = '${o.expectedDate.day}/${o.expectedDate.month}';

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Status')),
      body: ListView(
        children: [
          _productOverview(o, status, eta),
          const SizedBox(height: 8),
          _timeline(o.stageIndex),
          const SizedBox(height: 12),
          _liveMap(o),
          const SizedBox(height: 12),
          _extraInfo(o),
        ],
      ),
    );
  }

  Widget _productOverview(OrderItem o, String status, String eta) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              resolveImageUrl(o.imageUrl.isNotEmpty ? o.imageUrl : 'https://via.placeholder.com/300x300.png?text=Product'),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(o.id, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Row(children: [
                _statusBadge(status),
                const SizedBox(width: 8),
                Text('ETA: $eta', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('₹${o.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _timeline(int stageIndex) {
    final stages = OrderStatus.stages;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: List.generate(stages.length, (i) {
          final active = i <= stageIndex;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: active ? AppColors.primaryGradient : null,
                      color: active ? null : Colors.grey.shade300,
                    ),
                  ),
                  if (i != stages.length - 1)
                    Container(width: 2, height: 28, color: active ? Colors.teal : Colors.grey.shade300),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stages[i], style: TextStyle(fontWeight: FontWeight.w800, color: active ? Colors.black87 : Colors.black54)),
                  const SizedBox(height: 4),
                  Text('Updated ${DateTime.now().subtract(Duration(hours: (stages.length - i) * 3)).hour}:00', style: const TextStyle(color: Colors.black54)),
                ]),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _liveMap(OrderItem o) {
    final origin = LatLng(o.originLat, o.originLng);
    final dest = LatLng(o.destLat, o.destLng);
    final markers = <Marker>{
      Marker(markerId: const MarkerId('store'), position: origin, infoWindow: const InfoWindow(title: 'Origin')),
      Marker(markerId: const MarkerId('user'), position: dest, infoWindow: const InfoWindow(title: 'Destination')),
      Marker(markerId: const MarkerId('vehicle'), position: _vehicle, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'Courier')),
    };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: origin, zoom: 12),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: markers,
              onMapCreated: (c) => _controller.complete(c),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(999)),
                child: Row(children: const [Icon(Icons.schedule, size: 14, color: Colors.white), SizedBox(width: 6), Text('ETA 25 min', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _extraInfo(OrderItem o) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [CircleAvatar(backgroundColor: Colors.black12, child: Icon(Icons.person, color: Colors.black54)), SizedBox(width: 10), Text('Ravi Kumar • Courier')]),
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton.icon(onPressed: () => launchUrlString('tel:+910000000000'), icon: const Icon(Icons.call), label: const Text('Call')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => launchUrlString('sms:+910000000000'), icon: const Icon(Icons.sms), label: const Text('Message')),
            const Spacer(),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_outlined), label: const Text('Invoice')),
          ]),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.store_mall_directory_outlined),
            title: const Text('Origin: FlowLink Warehouse'),
            subtitle: const Text('BKC, Mumbai'),
            trailing: TextButton(onPressed: () => launchUrlString('https://maps.google.com?q=FlowLink+Warehouse,Mumbai'), child: const Text('View Map')),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AssistantBottomSheet(),
                );
              },
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('Need Help? Ask Assistant'),
            ),
          ),
        ],
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
