import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';
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
  final Map<String, List<MenuItemModel>> _vendorMenus = {};
  LatLng _currentCenter = const LatLng(10.2896, 11.1679);
  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _avatarUrl;

  bool _aiLoading = false;
  AiSearchResult? _aiResult;
  List<String>? _aiMatchedVendorIds;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VendorModel> get _filteredVendors {
    if (_aiMatchedVendorIds != null && _aiMatchedVendorIds!.isNotEmpty) {
      return _vendors.where((v) => _aiMatchedVendorIds!.contains(v.id)).toList();
    }
    if (_searchQuery.trim().isEmpty) return _vendors;
    final q = _searchQuery.toLowerCase();
    return _vendors.where((v) {
      final nameMatches = v.businessName.toLowerCase().contains(q);
      final descMatches = (v.description ?? '').toLowerCase().contains(q);
      return nameMatches || descMatches;
    }).toList();
  }

  Future<void> _initData() async {
    _loadUserProfile();
    await _refreshLocation();
    await _loadVendors();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _avatarUrl = profile['image'] as String? ?? profile['avatarUrl'] as String? ?? profile['avatar_url'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVendors() async {
    setState(() => _loading = true);
    try {
      final fetched = (await ApiService.fetchVendors()).cast<VendorModel>();
      if (mounted) {
        setState(() {
          _vendors = fetched;
          _loading = false;
        });
      }
      for (final v in fetched) {
        try {
          final menu = (await ApiService.fetchVendorMenu(v.id)).cast<MenuItemModel>();
          _vendorMenus[v.id] = menu;
        } catch (_) {}
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

  void _centerMapOnVendors(List<VendorModel> matches) {
    final validLocations = matches
        .where((v) => v.location != null && v.location!['lat'] != null)
        .map((v) => LatLng((v.location!['lat'] as num).toDouble(), (v.location!['lng'] as num).toDouble()))
        .toList();

    if (validLocations.isNotEmpty) {
      _mapController.move(validLocations.first, 15);
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _aiResult = null;
      _aiMatchedVendorIds = null;
    });

    final matches = _filteredVendors;
    if (matches.isNotEmpty) {
      _centerMapOnVendors(matches);
    }
  }

  Future<void> _handleSearchSubmit(String val) async {
    final query = val.trim();
    if (query.isEmpty) return;

    // 1. Direct kitchen match check
    final matches = _vendors.where((v) => v.businessName.toLowerCase().contains(query.toLowerCase())).toList();
    if (matches.isNotEmpty) {
      _centerMapOnVendors(matches);
      return;
    }

    // 2. Location Geocoding check
    final loc = await LocationService.forwardGeocode(query);
    if (loc != null) {
      final target = LatLng(loc['lat'] as double, loc['lng'] as double);
      if (mounted) {
        setState(() {
          _currentCenter = target;
          _locationLabel = loc['name'] as String? ?? query;
        });
        _mapController.move(target, 15);
      }
      return;
    }

    // 3. AI Natural Language & Typo search via Qwen 3.6 27B
    await _triggerAiSearch(query);
  }

  Future<void> _triggerAiSearch(String query) async {
    setState(() {
      _aiLoading = true;
      _aiResult = null;
      _aiMatchedVendorIds = null;
    });

    final result = await AiService.searchAssistant(
      query: query,
      vendors: _vendors,
      vendorMenus: _vendorMenus,
    );

    if (mounted) {
      setState(() {
        _aiLoading = false;
        _aiResult = result;
        if (result.matchedVendorIds.isNotEmpty) {
          _aiMatchedVendorIds = result.matchedVendorIds;
        }
      });

      if (_filteredVendors.isNotEmpty) {
        _centerMapOnVendors(_filteredVendors);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _aiResult = null;
      _aiMatchedVendorIds = null;
      _aiLoading = false;
    });
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
                initialCenter: _currentCenter,
                initialZoom: 14,
                minZoom: 10,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
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
                      child: Container(
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
                    ..._filteredVendors.where((v) => v.location != null && v.location!['lat'] != null).map((v) {
                      final lat = (v.location!['lat'] as num).toDouble();
                      final lng = (v.location!['lng'] as num).toDouble();
                      return Marker(
                        width: 120,
                        height: 60,
                        point: LatLng(lat, lng),
                        child: _buildMapPin(v.businessName, colorScheme, textTheme, vendorId: v.id),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // ── 3. Top Bar: Search Bar, Notifications Icon, Profile Icon ────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // 1. Search Bar
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              onSubmitted: _handleSearchSubmit,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Search kitchens, dishes, or location...',
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: _clearSearch,
                              child: Icon(Icons.close, size: 18, color: colorScheme.outline),
                            )
                          else
                            GestureDetector(
                              onTap: _refreshLocation,
                              child: Tooltip(
                                message: _locationLabel,
                                child: Icon(Icons.location_on, size: 18, color: colorScheme.primary.withValues(alpha: 0.8)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 2. Notification Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurfaceVariant),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                      tooltip: 'Notifications',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 3. Profile Icon (with User Avatar)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                _avatarUrl!,
                                fit: BoxFit.cover,
                                width: 48,
                                height: 48,
                                errorBuilder: (_, _, _) => Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
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
                          if (_searchQuery.isNotEmpty)
                            Text(
                              '${_filteredVendors.length} found',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── AI Loading State ─────────────────────────
                      if (_aiLoading)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '🤖 Plokitch AI is analyzing kitchens & menus...',
                                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ── AI Assistant Response Card ───────────────
                      if (_aiResult != null && !_aiLoading)
                        Card(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Plokitch AI Assistant',
                                      style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _aiResult = null;
                                          _aiMatchedVendorIds = null;
                                        });
                                      },
                                      child: Icon(Icons.close, size: 18, color: colorScheme.outline),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _aiResult!.textResponse,
                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface, height: 1.4),
                                ),
                                if (_aiResult!.suggestedCorrection != null) ...[
                                  const SizedBox(height: 10),
                                  ActionChip(
                                    avatar: const Icon(Icons.touch_app, size: 16),
                                    label: Text('Did you mean "${_aiResult!.suggestedCorrection}"?'),
                                    backgroundColor: colorScheme.surface,
                                    onPressed: () {
                                      _searchController.text = _aiResult!.suggestedCorrection!;
                                      _onSearchChanged(_aiResult!.suggestedCorrection!);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_filteredVendors.isEmpty && !_aiLoading)
                        Center(child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _searchQuery.isNotEmpty ? 'No kitchens match "$_searchQuery"' : 'No kitchens found nearby',
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty && _aiResult == null) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('Ask Plokitch AI Assistant'),
                                  onPressed: () => _triggerAiSearch(_searchQuery),
                                ),
                              ],
                            ],
                          ),
                        ))
                      else
                        ..._filteredVendors.map((v) => _buildVendorListCard(v, colorScheme, textTheme)),
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
            ? Image.network(vendor.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(width: 60, height: 60, color: colorScheme.surfaceContainerHigh, child: const Icon(Icons.storefront)))
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
