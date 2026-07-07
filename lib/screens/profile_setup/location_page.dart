import 'package:flutter/material.dart';
import '../../widgets/plokitch_button.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';

class LocationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LocationPage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool _locating = false;
  bool _saving = false;
  String? _street;
  String? _city;
  String? _state;

  Future<void> _findMe() async {
    setState(() => _locating = true);
    try {
      final addr = await LocationService.locateAndReverse();
      setState(() {
        _street = addr['street'] as String?;
        _city = addr['city'] as String?;
        _state = addr['state'] as String?;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location detected — confirm or edit then save')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location failed: $e')));
    } finally {
      setState(() => _locating = false);
    }
  }

  Future<void> _saveAddress() async {
    setState(() => _saving = true);
    try {
      final address = {
        'street': _street ?? '',
        'city': _city ?? '',
        'state': _state ?? '',
      };
      await LocationService.saveAddress(address);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved')));
      widget.onNext();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Your Location',
                  style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This helps our riders find you faster.',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Map Placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_on, size: 48, color: colorScheme.primaryContainer),
                Positioned(
                  bottom: 16,
                  child: ElevatedButton.icon(
                    onPressed: _locating ? null : _findMe,
                    icon: const Icon(Icons.my_location, size: 16),
                    label: Text(_locating ? 'Detecting...' : 'Find me on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.primary,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Address Input
          Text('Street', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _street),
            onChanged: (v) => _street = v,
            decoration: InputDecoration(
              hintText: 'Street address',
              hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Icon(Icons.home_work_outlined, color: colorScheme.onSurfaceVariant),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Text('City', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _city),
            onChanged: (v) => _city = v,
            decoration: InputDecoration(filled: true, fillColor: colorScheme.surfaceContainerHigh),
          ),
          const SizedBox(height: 12),
          Text('State', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _state),
            onChanged: (v) => _state = v,
            decoration: InputDecoration(filled: true, fillColor: colorScheme.surfaceContainerHigh),
          ),

          const Spacer(),
          PlokitchButton(
            text: _saving ? 'Saving...' : 'Save Location',
            onPressed: (_street == null && _city == null && _state == null) || _saving ? null : _saveAddress,
          ),
        ],
      ),
    );
  }
}
