import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/rider_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_toast.dart';

class AssignRiderScreen extends StatefulWidget {
  final OrderModel order;

  const AssignRiderScreen({super.key, required this.order});

  @override
  State<AssignRiderScreen> createState() => _AssignRiderScreenState();
}

class _AssignRiderScreenState extends State<AssignRiderScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RiderModel> _riders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // 'all' or 'available'
  RiderModel? _selectedRider;
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('rider_profile')
          .select('id, user_id, vehicle_type, is_available, is_verified, user:user_id(name, email, phone)')
          .eq('application_status', 'approved');

      final List<dynamic> data = response as List<dynamic>? ?? [];
      final fetched = data.map((e) => RiderModel.fromSupabase(Map<String, dynamic>.from(e as Map))).toList();

      try {
        final profile = await AuthService.getProfile();
        if (profile != null) {
          final userId = profile['id']?.toString();
          if (userId != null && userId.isNotEmpty) {
            final alreadyInList = fetched.any((r) => r.userId == userId);
            if (!alreadyInList) {
              fetched.insert(
                0,
                RiderModel(
                  profileId: 'me-profile-id',
                  userId: userId,
                  name: '${profile['name'] ?? "Me"} (Myself)',
                  email: profile['email'] ?? '',
                  phone: profile['phone'],
                  vehicleType: 'Developer Sandbox',
                  isAvailable: true,
                  isVerified: true,
                ),
              );
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _riders = fetched;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _assignRider() async {
    if (_selectedRider == null) return;

    setState(() {
      _assigning = true;
    });

    try {
      final updated = await ApiService.updateOrderStatus(
        widget.order.id,
        'delivering',
        additionalFields: {
          'solvixRiderName': _selectedRider!.name,
          'riderId': _selectedRider!.userId,
        },
      );

      if (mounted) {
        PlokitchToast.show(context, 'Order successfully assigned to ${_selectedRider!.name}.');
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        PlokitchToast.show(context, 'Failed to assign rider: $e', isError: true);
        setState(() {
          _assigning = false;
        });
      }
    }
  }

  List<RiderModel> get _filteredRiders {
    final query = _searchController.text.toLowerCase().trim();
    return _riders.where((rider) {
      // Role filter
      if (_filter == 'available' && !rider.isAvailable) {
        return false;
      }
      // Search filter
      if (query.isNotEmpty && !rider.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  IconData _getVehicleIcon(String? vehicleType) {
    final type = vehicleType?.toLowerCase() ?? '';
    if (type.contains('bike') || type.contains('bicycle')) {
      return Icons.directions_bike_rounded;
    } else if (type.contains('moto') || type.contains('motorcycle') || type.contains('scooter')) {
      return Icons.two_wheeler_rounded;
    } else if (type.contains('car') || type.contains('auto')) {
      return Icons.directions_car_rounded;
    }
    return Icons.delivery_dining_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Assign Rider',
        showMenu: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Order Summary Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${widget.order.id.substring(0, min(8, widget.order.id.length))}',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₦${widget.order.totalAmount.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customer: ${widget.order.customerName ?? "Guest"}',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Search and Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search riders by name...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.outline),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Riders'),
                    selected: _filter == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'all');
                      }
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: _filter == 'all' ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Available Only'),
                    selected: _filter == 'available',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'available');
                      }
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: _filter == 'available' ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Riders List
            Expanded(
              child: _buildRidersContent(colorScheme, textTheme),
            ),

            // Assign Button at the Bottom
            if (_selectedRider != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: FilledButton(
                  onPressed: _assigning ? null : _assignRider,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _assigning
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Assign ${_selectedRider!.name}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidersContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load riders',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchRiders,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredRiders;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.two_wheeler_rounded, size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No riders found',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try searching for a different name'
                  : 'No active riders matching the filter',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final rider = filtered[index];
        final isSelected = _selectedRider?.profileId == rider.profileId;
        final initials = rider.name.isNotEmpty
            ? rider.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
            : 'R';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.15) : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedRider = null;
                } else {
                  _selectedRider = rider;
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                    child: Text(
                      initials,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rider.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (rider.isVerified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 16, color: colorScheme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _getVehicleIcon(rider.vehicleType),
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rider.vehicleType ?? 'Standard Delivery',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Availability status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (rider.isAvailable ? Colors.green : colorScheme.outline).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: rider.isAvailable ? Colors.green : colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rider.isAvailable ? 'Available' : 'Busy',
                              style: textTheme.labelSmall?.copyWith(
                                color: rider.isAvailable ? Colors.green[800] : colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 8),
                        Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 24),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
