import 'package:flutter/material.dart';
import '../../widgets/plokitch_button.dart';
import '../../services/location_service.dart';

class LocationPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LocationPage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

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
                onPressed: onBack,
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
                image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'), // Mapish image
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
                    onPressed: () async {
                      try {
                        // attempt to locate and save
                        await LocationService.locateAndSave();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location saved')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location failed: $e')));
                      }
                    },
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Find me on Map'),
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
          Text('Detailed Address', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. 15 Aminu Kano Way, Wuse 2\nOpposite the big supermarket',
              hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 32.0), // Align to top
                child: Icon(Icons.home_work_outlined, color: colorScheme.onSurfaceVariant),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          
          const Spacer(),
          PlokitchButton(
            text: 'Continue',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
