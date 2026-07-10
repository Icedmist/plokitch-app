import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../models/vendor_model.dart';
import '../services/location_service.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  bool _isSheetExpanded = false;
  String _locationLabel = 'Gombe, Gombe State';
  String? _locationError;
  bool _loading = true;
  List<VendorModel> _vendors = [];
  LatLng _currentCenter = const LatLng(10.2896, 11.1679);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _refreshLocation();
    await _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _loading = true);
    try {
      final fetched = await ApiService.fetchVendors();
      if (mounted) {
        setState(() {
          _vendors = fetched.cast<VendorModel>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to load kitchens';
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      final addr = await LocationService.reverseGeocode(pos);
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(pos.latitude, pos.longitude);
          _locationLabel = [addr['street'], addr['city']].where((s) => s != null && s.isNotEmpty).join(', ');
          if (_locationLabel.isEmpty) _locationLabel = 'Current Location';
          _locationError = null;
        });
        _mapController.move(_currentCenter, 14);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _locationError = 'Unable to detect location. Using default.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Gombe State Map Background ──────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentCenter,
                zoom: 14,
                minZoom: 10,
                maxZoom: 18,
                interactiveFlags: InteractiveFlag.all,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'app.plokitch',
                ),
                MarkerLayer(
                  markers: [
                    // User Location Marker
                    Marker(
                      width: 40,
                      height: 40,
                      point: _currentCenter,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Vendor Markers
                    ..._vendors.where((v) => v.location != null && v.location!['lat'] != null).map((v) {
                      final lat = (v.location!['lat'] as num).toDouble();
                      final lng = (v.location!['lng'] as num).toDouble();
                      return Marker(
                        width: 120,
                        height: 60,
                        point: LatLng(lat, lng),
                        builder: (context) => _buildMapPin(v.businessName, colorScheme, textTheme, vendorId: v.id),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),

          // ── 3. Top Bar ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // ── Location Banner ──────────────────────────────────────
                  GestureDetector(
                    onTap: _refreshLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: colorScheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationLabel,
                                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_locationError != null)
                                  Text(
                                    _locationError!,
                                    style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.refresh, size: 14, color: colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. FABs ────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              children: [
                _buildFloatingIcon(Icons.my_location, colorScheme, onTap: _refreshLocation),
              ],
            ),
          ),

          // ── 5. Draggable Bottom Sheet ───────────────────────────────────
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (n) {
              setState(() => _isSheetExpanded = n.extent > 0.45);
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.4, 0.85],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nearby Kitchens', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary)),
                          IconButton(
                            icon: Icon(Icons.notifications_none, color: colorScheme.onSurfaceVariant),
                            onPressed: () => Navigator.pushNamed(context, '/notifications'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_vendors.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No kitchens found nearby'),
                        ))
                      else
                        ..._vendors.map((v) => _buildVendorListCard(v, colorScheme, textTheme)).toList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(String label, ColorScheme colorScheme, TextTheme textTheme, {required String vendorId}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'id': vendorId}),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, ColorScheme colorScheme, {VoidCallback? onTap}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: IconButton(icon: Icon(icon, color: colorScheme.onSurfaceVariant), onPressed: onTap),
    );
  }

  Widget _buildVendorListCard(VendorModel vendor, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: vendor.imageUrl != null 
            ? Image.network(vendor.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
            : Container(width: 60, height: 60, color: colorScheme.surfaceContainerHigh, child: const Icon(Icons.storefront)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(vendor.businessName, style: textTheme.titleMedium)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: vendor.isOpenNow ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                vendor.isOpenNow ? 'Open' : 'Closed',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vendor.description ?? 'Local Kitchen', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                const Text('4.8 · 1.2km away', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
        onTap: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'id': vendor.id}),
      ),
    );
  }
}
