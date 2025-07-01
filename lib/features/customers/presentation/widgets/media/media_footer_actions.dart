import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

class MediaFooterActions extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onUpload;
  final VoidCallback onEnterSelection;
  final bool hasMedia;

  const MediaFooterActions({
    super.key,
    required this.onTakePhoto,
    required this.onUpload,
    required this.onEnterSelection,
    required this.hasMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: RufkoPrimaryButton(
                onPressed: onTakePhoto,
                icon: Icons.camera_alt,
                size: ButtonSize.medium,
                child: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: RufkoSecondaryButton(
                onPressed: onUpload,
                icon: Icons.upload,
                size: ButtonSize.medium,
                child: const Text('Upload'),
              ),
            ),
            const SizedBox(width: 6),
            RufkoIconButton(
              onPressed: hasMedia ? onEnterSelection : null,
              icon: Icons.checklist,
              size: ButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }
}