import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/address_service.dart';
import 'package:flowlink_mobile/services/location_service.dart';
import 'package:flowlink_mobile/ui/location_select_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressSelectionSheet extends StatefulWidget {
  const AddressSelectionSheet({super.key});

  @override
  State<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<AddressSelectionSheet> {
  bool _showForm = false;
  bool _default = false;

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _pincode = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _landmark = TextEditingController();
  double? _lat;
  double? _lng;
  String? _addrLine;
  // Header map (current location) state
  double? _headerLat;
  double? _headerLng;
  String? _headerAddr;

  @override
  void initState() {
    super.initState();
    _loadHeaderCurrentLoc();
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _pincode.dispose();
    _city.dispose();
    _state.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Widget _headerMapCard() {
    final hasLoc = _headerLat != null && _headerLng != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: hasLoc ? LatLng(_headerLat!, _headerLng!) : const LatLng(19.0760, 72.8777),
                  zoom: hasLoc ? 14 : 11,
                ),
                myLocationEnabled: hasLoc,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                markers: {
                  if (hasLoc) Marker(markerId: const MarkerId('me'), position: LatLng(_headerLat!, _headerLng!)),
                },
              ),
            ),
          ),
          if (_headerAddr != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_headerAddr!, maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadHeaderCurrentLoc() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      final addr = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _headerLat = pos.latitude;
        _headerLng = pos.longitude;
        _headerAddr = addr;
      });
    } catch (_) {
      // leave header map to default city center
      if (!mounted) return;
      setState(() {
        _headerLat = 19.0760;
        _headerLng = 72.8777;
        _headerAddr = 'Current location unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Scaffold(
            backgroundColor: Theme.of(context).cardColor.withOpacity(0.96),
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Select Delivery Address'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(AddressService.instance.selected.value),
                  child: const Text('Done'),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _addressList()),
                  const Divider(height: 1),
                  _addNewEntry(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressList() {
    return ValueListenableBuilder<List<Address>>(
      valueListenable: AddressService.instance.addresses,
      builder: (context, list, _) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _headerMapCard();
            }
            final a = list[i - 1];
            return ValueListenableBuilder<Address?>(
              valueListenable: AddressService.instance.selected,
              builder: (context, selected, __) {
                final selectedIdx = selected != null ? list.indexOf(selected) : -1;
                final isSelected = selectedIdx == (i - 1);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => AddressService.instance.selected.value = a,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? Colors.teal.withOpacity(0.06) : Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: selectedIdx + 1,
                          onChanged: (_) => AddressService.instance.selected.value = a,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  ),
                                  if (a.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(a.toString(), style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => AddressService.instance.setDefault(i - 1),
                                    child: const Text('Set default'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => AddressService.instance.remove(i - 1),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: list.length + 1,
        );
      },
    );
  }

  Widget _addNewEntry() {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(16, 12, 16, (_showForm ? kb : 0) + 24),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: Icon(_showForm ? Icons.expand_more_rounded : Icons.add_rounded),
                onPressed: () => setState(() => _showForm = !_showForm),
              ),
            ],
          ),
          if (_showForm) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location pick row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pin Location', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _useCurrentLoc,
                                  icon: const Icon(Icons.my_location_rounded),
                                  label: const Text('Use current location'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickOnMap,
                                  icon: const Icon(Icons.map_rounded),
                                  label: const Text('Pick on map'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_addrLine != null || _lat != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place_rounded, color: Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _addrLine ?? 'Lat: ${_lat?.toStringAsFixed(5)}, Lng: ${_lng?.toStringAsFixed(5)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 160,
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_lat ?? 19.0760, _lng ?? 72.8777),
                                    zoom: 14,
                                  ),
                                  myLocationEnabled: false,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  markers: {
                                    if (_lat != null && _lng != null)
                                      Marker(markerId: const MarkerId('addr'), position: LatLng(_lat!, _lng!)),
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row(
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(hintText: 'Name'),
                      ),
                      TextField(
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: 'Mobile'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row(
                      TextField(
                        controller: _pincode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Pincode'),
                      ),
                      TextField(
                        controller: _city,
                        decoration: const InputDecoration(hintText: 'City'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row(
                      TextField(
                        controller: _state,
                        decoration: const InputDecoration(hintText: 'State'),
                      ),
                      TextField(
                        controller: _landmark,
                        decoration: const InputDecoration(hintText: 'Landmark'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(value: _default, onChanged: (v) => setState(() => _default = v ?? false)),
                        const Text('Set as default'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save Address'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _row(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _mobile.text.trim().isEmpty || _pincode.text.trim().isEmpty || _city.text.trim().isEmpty || _state.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    final addr = Address(
      name: _name.text.trim(),
      mobile: _mobile.text.trim(),
      pincode: _pincode.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      landmark: _landmark.text.trim(),
      isDefault: _default,
      lat: _lat,
      lng: _lng,
      addressLine: _addrLine,
    );
    await AddressService.instance.add(addr);
    setState(() {
      _showForm = false;
      _default = false;
      _name.clear();
      _mobile.clear();
      _pincode.clear();
      _city.clear();
      _state.clear();
      _landmark.clear();
      _lat = null;
      _lng = null;
      _addrLine = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved')));
  }

  Future<void> _useCurrentLoc() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      final line = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _addrLine = line;
        if (_pincode.text.isEmpty) _pincode.text = '';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to get current location')));
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>?>(context, MaterialPageRoute(builder: (_) => const LocationSelectScreen()));
    if (result == null) return;
    setState(() {
      _lat = (result['lat'] as num).toDouble();
      _lng = (result['lng'] as num).toDouble();
      _addrLine = (result['address'] ?? '') as String?;
    });
  }
}
