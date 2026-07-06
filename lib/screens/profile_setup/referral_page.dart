import 'package:flutter/material.dart';
import '../../widgets/plokitch_button.dart';

class ReferralPage extends StatefulWidget {
  final VoidCallback onNext;

  const ReferralPage({super.key, required this.onNext});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String? _selectedReferral;

  final List<Map<String, dynamic>> _options = [
    {'id': 'social', 'title': 'Social Media', 'icon': Icons.thumb_up_outlined},
    {'id': 'friend', 'title': 'Friend or Family', 'icon': Icons.people_outline},
    {'id': 'billboard', 'title': 'Billboard/Ad', 'icon': Icons.campaign_outlined},
    {'id': 'other', 'title': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where did you hear about us?',
            style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand how you found Plokitch.',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = _options[index];
                final isSelected = _selectedReferral == option['id'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReferral = option['id'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.surfaceContainerHigh : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? colorScheme.primaryContainer : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option['icon'],
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option['title'],
                            style: textTheme.titleMedium?.copyWith(
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? colorScheme.primaryContainer : colorScheme.outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.primaryContainer,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          PlokitchButton(
            text: 'Continue',
            onPressed: _selectedReferral != null ? widget.onNext : () {},
          ),
        ],
      ),
    );
  }
}
