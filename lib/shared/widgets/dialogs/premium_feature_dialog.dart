import 'package:flutter/material.dart';
import '../../../core/utils/settings_constants.dart';

/// Generic dialog to present information about premium features.
class PremiumFeatureDialog extends StatelessWidget {
  const PremiumFeatureDialog({super.key, required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(feature.icon, color: feature.color),
          ),
          const SizedBox(width: 12),
          Text(feature.title),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: feature.details
              .map((d) => _buildFeatureItem(d))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Helper to open the dialog.
Future<void> showPremiumFeatureDialog(
    BuildContext context, PremiumFeature feature) async {
  return showDialog(
    context: context,
    builder: (c) => PremiumFeatureDialog(feature: feature),
  );
}

Future<void> showAutomaticTaxInfo(BuildContext context) {
  return showPremiumFeatureDialog(context, automaticTaxLookup);
}

Future<void> showTwoWayCommunicationInfo(BuildContext context) {
  return showPremiumFeatureDialog(context, twoWayCommunication);
}

Future<void> showOrganizationProfilesInfo(BuildContext context) {
  return showPremiumFeatureDialog(context, organizationProfiles);
}
