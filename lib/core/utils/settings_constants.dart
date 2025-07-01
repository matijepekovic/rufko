import 'package:flutter/material.dart';

/// Application version displayed in the settings screen.
const String appVersionString = '1.0.0 (Modern Build)';

/// Help dialog content.
const String helpText = '''
Rufko helps streamline roofing estimates with enhanced product management, flexible discounting, and comprehensive quote generation.

Key Features:
• Dynamic product categories and units
• Advanced 3-tier pricing system
• Professional quote generation
• Customer relationship management
• Photo documentation
• RoofScope PDF data extraction
• Flexible discount system

For technical support or feature requests, please contact our development team.
''';

/// Data model describing a premium feature that can be displayed in
/// [PremiumFeatureDialog].
class PremiumFeature {
  const PremiumFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.details,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> details;
}

/// Definitions for the premium features used in the settings UI.
const automaticTaxLookup = PremiumFeature(
  icon: Icons.auto_awesome,
  color: Colors.amber,
  title: 'Automatic Tax Lookup',
  details: [
    'Complete Washington State database',
    'ZIP code specific tax rates',
    'City and county tax lookup',
    'Regular database updates',
    'Instant rate detection',
    'Tax rate analytics and reporting',
  ],
);

const twoWayCommunication = PremiumFeature(
  icon: Icons.forum,
  color: Colors.purple,
  title: '2-Way Communication',
  details: [
    'Send & receive SMS directly in app',
    'Full email integration with responses',
    'Automatic response capture & logging',
    'Read receipts and delivery confirmations',
    'Automated follow-up sequences',
    'Professional business phone numbers',
    'Communication analytics and tracking',
  ],
);

const organizationProfiles = PremiumFeature(
  icon: Icons.business_center,
  color: Colors.teal,
  title: 'Organization Profiles',
  details: [
    'Multiple user profiles & roles',
    'Permission-based access control',
    'Team performance analytics',
    'Department & branch management',
    'Approval workflows',
    'Manager oversight & reporting',
    'Data sharing between team members',
  ],
);
