import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_toast.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final String _whatsappNumber = '2349067063781'; // International format
  final String _supportEmail = 'support@plokitch.app';

  Future<void> _launchWhatsApp() async {
    final urlString = 'https://wa.me/$_whatsappNumber';
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (_) {
      if (mounted) {
        PlokitchToast.show(
          context,
          'Could not open WhatsApp. Please save Gombe Customer Line: 09067063781',
          isError: true,
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final urlString = 'mailto:$_supportEmail?subject=Plokitch%20Support%20Request';
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch Email client');
      }
    } catch (_) {
      if (mounted) {
        PlokitchToast.show(
          context,
          'Could not open Email client. Contact support email: $_supportEmail',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Help & Support',
        showMenu: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Frequently Asked Questions',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'How do I place an order?',
            'Browse the market, add items to your cart, specify your delivery details at checkout, and confirm your payment method.',
            textTheme,
            colorScheme,
          ),
          _buildFAQItem(
            'How can I track my delivery?',
            'Go to the Order History tab, click on your active order, and view the real-time preparation and delivery tracking status.',
            textTheme,
            colorScheme,
          ),
          _buildFAQItem(
            'What payment methods are supported?',
            'We support Visa, Mastercard, and Verve cards. You can save multiple cards for checkout in your Profile under Payment Methods.',
            textTheme,
            colorScheme,
          ),
          _buildFAQItem(
            'Can I cancel my order?',
            'Orders can be cancelled before the kitchen begins preparing them. Once the kitchen accepts and starts cooking, cancellation is unavailable.',
            textTheme,
            colorScheme,
          ),
          const SizedBox(height: 32),
          Text(
            'Contact Support',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp Support',
            subtitle: 'Chat directly with Gombe customer line',
            detailText: '09067063781',
            colorScheme: colorScheme,
            textTheme: textTheme,
            onTap: _launchWhatsApp,
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.mail_outline_rounded,
            title: 'Email Support',
            subtitle: 'Send us an email query',
            detailText: _supportEmail,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onTap: _launchEmail,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Plokitch Support Team is available 24/7',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
    String question,
    String answer,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Text(
                answer,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String detailText,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detailText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
