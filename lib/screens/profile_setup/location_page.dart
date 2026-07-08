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

  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _findMe() async {
    setState(() => _locating = true);
    try {
      final addr = await LocationService.locateAndReverse();
      if (!mounted) return;
      setState(() {
        _street = addr['street'] as String?;
        _city = addr['city'] as String?;
        _state = addr['state'] as String?;
        _streetController.text = _street ?? '';
        _cityController.text = _city ?? '';
        _stateController.text = _state ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location detected — confirm or edit then save')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location failed: $e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _saveAddress() async {
    setState(() => _saving = true);
    try {
      final address = {
        'street': _streetController.text,
        'city': _cityController.text,
        'state': _stateController.text,
      };
      await LocationService.saveAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved')));
      widget.onNext();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
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
            controller: _streetController,
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
            controller: _cityController,
            decoration: InputDecoration(filled: true, fillColor: colorScheme.surfaceContainerHigh),
          ),
          const SizedBox(height: 12),
          Text('State', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: _stateController,
            decoration: InputDecoration(filled: true, fillColor: colorScheme.surfaceContainerHigh),
          ),

          const Spacer(),
          PlokitchButton(
            text: _saving ? 'Saving...' : 'Save Location',
            onPressed: _saving ? null : _saveAddress,
          ),
        ],
      ),
    );
  }
}
