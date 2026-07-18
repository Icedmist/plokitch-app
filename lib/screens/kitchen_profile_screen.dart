import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/mail_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';
import '../models/review_model.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_back_button.dart';

class KitchenProfileScreen extends StatefulWidget {
  final String? id;

  const KitchenProfileScreen({super.key, this.id});

  @override
  State<KitchenProfileScreen> createState() => _KitchenProfileScreenState();
}

class _KitchenProfileScreenState extends State<KitchenProfileScreen> {
  bool _loading = true;
  String? _error;
  VendorModel? _vendor;
  List<MenuItemModel> _menu = [];
  Map<String, dynamic>? _profile;
  String? _userRole;
  int _retryCount = 0;
  bool _hasLoadedData = false;
  static const int _maxRetries = 2;

  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0;

  final List<ReviewModel> _reviews = [];

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(0, (sum, item) => sum + item.rating);
    return total / _reviews.length;
  }

  void _scrollToTabs() {
    setState(() {
      _selectedTab = 1;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        340,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? argMap;
    if (args is Map<String, dynamic>) {
      argMap = args;
    } else if (args is Map) {
      argMap = Map<String, dynamic>.from(args);
    }

    final profile = await AuthService.getProfile();
    _profile = profile;
    _userRole = profile?['role'] as String? ?? await AuthService.storedRole();

    String? vendorId = widget.id?.trim();
    if (vendorId == null || vendorId.isEmpty) {
      vendorId = argMap?['id']?.toString().trim();
      if (vendorId == null || vendorId.isEmpty) {
        vendorId = argMap?['vendorId']?.toString().trim();
      }
    }
    if (vendorId == null || vendorId.isEmpty) {
      vendorId = profile?['vendorId']?.toString().trim() ?? profile?['vendor_id']?.toString().trim();
      if (vendorId == null || vendorId.isEmpty) {
        final vendorMap = profile?['vendor'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(profile!['vendor'] as Map)
            : null;
        vendorId = vendorMap?['id']?.toString().trim();
      }
    }

    if (vendorId == null || vendorId.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Kitchen ID is missing. Please go back and try again.';
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final vendorData = await ApiService.fetchVendor(vendorId, forceRefresh: true);
      if (vendorData.isEmpty) {
        throw Exception('Invalid vendor data received');
      }
      final menuData = await ApiService.fetchVendorMenu(vendorId, forceRefresh: true);
      final reviewsData = await ApiService.fetchVendorReviews(vendorId, forceRefresh: true);
      
      if (mounted) {
        setState(() {
          _vendor = VendorModel.fromJson(vendorData);
          _menu = menuData.cast<MenuItemModel>();
          _reviews.clear();
          _reviews.addAll(reviewsData);
          _loading = false;
          _error = null;
          _retryCount = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          await Future.delayed(const Duration(milliseconds: 800));
          await _loadData();
        } else {
          setState(() {
            _error = 'Unable to load kitchen details. Please try again later.';
            _loading = false;
          });
        }
      }
    }
  }

  void _retryLoad() {
    _retryCount = 0;
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        appBar: PlokitchAppBar(title: '', showMenu: false),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _vendor == null) {
      return Scaffold(
        appBar: const PlokitchAppBar(title: '', showMenu: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error)  ,
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Kitchen not found',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: const PlokitchBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _vendor!.imageUrl != null
                      ? Image.network(
                          _vendor!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: const Icon(Icons.storefront, size: 64),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.storefront, size: 64),
                        ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kitchen Name
                  Text(
                    _vendor!.businessName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _scrollToTabs,
                          child: _buildInfoChip(
                            icon: Icons.star_rounded,
                            iconColor: Colors.amber.shade700,
                            label: '${_averageRating.toStringAsFixed(1)} Rating',
                            bgColor: Colors.amber.shade50,
                            labelColor: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.directions_bike_rounded,
                          iconColor: colorScheme.primary,
                          label: '1.2 km',
                          bgColor: colorScheme.primaryContainer.withValues(alpha: 0.15),
                          labelColor: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: _vendor!.isOpenNow ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          iconColor: _vendor!.isOpenNow ? Colors.green : Colors.red,
                          label: _vendor!.isOpenNow ? 'Open Now' : 'Closed',
                          bgColor: _vendor!.isOpenNow ? Colors.green.shade50 : Colors.red.shade50,
                          labelColor: _vendor!.isOpenNow ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                        if (_vendor!.openTime != null && _vendor!.closeTime != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.schedule_rounded,
                            iconColor: colorScheme.onSurfaceVariant,
                            label: '${_vendor!.openTime} - ${_vendor!.closeTime}',
                            bgColor: colorScheme.surfaceContainerHigh,
                            labelColor: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _vendor!.description ?? 'Local Kitchen specialized in authentic flavors.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Owner controls (if logged in as chef and viewing their own kitchen)
                  if ((_userRole ?? '').toLowerCase() == 'chef' &&
                      (_profile?['vendorId']?.toString() == _vendor?.id ||
                       _profile?['vendor_id']?.toString() == _vendor?.id ||
                       (_profile?['vendor'] is Map<String, dynamic> && (_profile?['vendor']['id'] as String?) == _vendor?.id))) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/kitchen-settings'),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Kitchen Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contact Card (Email & Phone)
                  if ((_vendor!.email != null && _vendor!.email!.isNotEmpty) ||
                      (_vendor!.phone != null && _vendor!.phone!.isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KITCHEN CONTACT DETAILS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_vendor!.phone != null && _vendor!.phone!.isNotEmpty) ...[
                            _buildContactRow(
                              icon: Icons.phone_android_rounded,
                              value: _vendor!.phone!,
                              colorScheme: colorScheme,
                              context: context,
                            ),
                          ],
                          if (_vendor!.phone != null && _vendor!.phone!.isNotEmpty &&
                              _vendor!.email != null && _vendor!.email!.isNotEmpty)
                            Divider(height: 20, thickness: 0.5, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          if (_vendor!.email != null && _vendor!.email!.isNotEmpty) ...[
                            _buildContactRow(
                              icon: Icons.alternate_email_rounded,
                              value: _vendor!.email!,
                              colorScheme: colorScheme,
                              context: context,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(0, 'Menu (${_menu.length})', colorScheme),
                        ),
                        Expanded(
                          child: _buildTabButton(1, 'Reviews (${_reviews.length})', colorScheme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedTab == 0) ...[
            if (_menu.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No menu items available.'),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _menu[index];
                    return _buildMenuItemCard(item, colorScheme, textTheme);
                  },
                  childCount: _menu.length,
                ),
              ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRatingsSummary(colorScheme, textTheme),
              ),
            ),
            if (_reviews.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No reviews yet. Be the first to write one!'),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final review = _reviews[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildReviewCard(review, colorScheme, textTheme),
                    );
                  },
                  childCount: _reviews.length,
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bgColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required ColorScheme colorScheme,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied "$value" to clipboard'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.copy_rounded, size: 14, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/food-detail', arguments: {
            'foodItem': item.toJson(),
            'kitchen': _vendor?.businessName ?? 'Unknown Kitchen',
            'vendorId': _vendor?.id,
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        (item.images.isNotEmpty ? item.images.first : item.imageUrl) ?? '',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.fastfood_rounded,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    if (item.isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SPECIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.description != null && item.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₦${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
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
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, ColorScheme colorScheme) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final counts = {
      for (var i = 1; i <= 5; i++) i: 0,
    };
    for (var r in _reviews) {
      final intStar = r.rating.round();
      if (counts.containsKey(intStar)) {
        counts[intStar] = counts[intStar]! + 1;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starVal = index + 1;
                        if (_averageRating >= starVal) {
                          return Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18);
                        } else if (_averageRating >= starVal - 0.5) {
                          return Icon(Icons.star_half_rounded, color: Colors.amber.shade700, size: 18);
                        } else {
                          return Icon(Icons.star_outline_rounded, color: Colors.amber.shade700, size: 18);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_reviews.length} reviews',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = counts[stars] ?? 0;
                    final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: colorScheme.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 16,
                            child: Text(
                              '$count',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showWriteReviewBottomSheet(colorScheme),
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Write a Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, ColorScheme colorScheme, TextTheme textTheme) {
    final initials = review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?';
    final isOwnReview = _profile != null && review.customerId == _profile?['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: review.userImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          review.userImage!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            initials,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber.shade700,
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(review.date),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwnReview)
                IconButton(
                  icon: Icon(Icons.edit_rounded, size: 18, color: colorScheme.primary),
                  onPressed: () => _showWriteReviewBottomSheet(colorScheme, existingReview: review),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewBottomSheet(ColorScheme colorScheme, {ReviewModel? existingReview}) {
    double selectedRating = existingReview?.rating ?? 5.0;
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    if (existingReview != null) {
      nameController.text = existingReview.userName;
      commentController.text = existingReview.comment;
    } else {
      final savedName = _profile?['name'] as String?;
      if (savedName != null && savedName.isNotEmpty) {
        nameController.text = savedName;
      }
    }

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingReview == null ? 'Write a Review' : 'Edit Your Review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Tap stars to rate',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final ratingValue = index + 1.0;
                            final isSelected = selectedRating >= ratingValue;
                            return GestureDetector(
                              onTap: isSubmitting ? null : () {
                                setModalState(() {
                                  selectedRating = ratingValue;
                                });
                              },
                              child: Icon(
                                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colors.amber.shade700,
                                size: 40,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (existingReview == null) ...[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Review comment',
                      hintText: 'Share details of your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        final comment = commentController.text.trim();
                        final name = nameController.text.trim();

                        if ((existingReview == null && name.isEmpty) || comment.isEmpty) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            SnackBar(
                              content: const Text('Please fill out all fields.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        try {
                          final payload = <String, dynamic>{
                            'rating': selectedRating.toInt(),
                            'comment': comment,
                          };

                          if (existingReview == null) {
                            await ApiService.addVendorReview(_vendor!.id, payload);

                            final customerName = _profile?['name'] as String? ?? 'A customer';

                            await ApiService.addNotification(
                              title: 'New Review',
                              body: '$customerName left a ${selectedRating.toInt()}-star review',
                              type: 'review',
                              recipientId: _vendor!.userId,
                            );

                            if (_vendor!.email != null) {
                              await MailService.notifyNewReview(
                                vendorName: _vendor!.businessName,
                                vendorEmail: _vendor!.email!,
                                customerName: customerName,
                                rating: selectedRating,
                                comment: comment,
                              );
                            }
                          } else {
                            await ApiService.updateVendorReview(_vendor!.id, existingReview.id, payload);
                          }

                          final reviewsData = await ApiService.fetchVendorReviews(_vendor!.id, forceRefresh: true);
                          final vendorData = await ApiService.fetchVendor(_vendor!.id, forceRefresh: true);

                          if (mounted) {
                            setState(() {
                              _reviews.clear();
                              _reviews.addAll(reviewsData);
                              _vendor = VendorModel.fromJson(vendorData);
                            });
                          }

                          if (mounted) Navigator.pop(modalContext);

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(existingReview == null 
                                    ? 'Thank you! Your review has been added.' 
                                    : 'Your review has been updated successfully.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green.shade800,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save review: $e'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              existingReview == null ? 'Submit Review' : 'Save Changes',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
