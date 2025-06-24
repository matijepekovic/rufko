import 'package:flutter/material.dart';
import 'rufko_buttons.dart';

/// Standard dialog action buttons for consistent dialog layouts
class RufkoDialogActions extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String cancelText;
  final String confirmText;
  final bool isDangerousAction;

  const RufkoDialogActions({
    super.key,
    this.onCancel,
    required this.onConfirm,
    this.cancelText = 'Cancel',
    this.confirmText = 'OK',
    this.isDangerousAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onCancel != null) ...[
          RufkoTextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          const SizedBox(width: 8),
        ],
        if (isDangerousAction)
          RufkoDangerButton(
            onPressed: onConfirm,
            child: Text(confirmText),
          )
        else
          RufkoPrimaryButton(
            onPressed: onConfirm,
            child: Text(confirmText),
          ),
      ],
    );
  }
}

/// Simple cancel/OK dialog actions
class SimpleDialogActions extends StatelessWidget {
  final VoidCallback? onOk;
  final String okText;

  const SimpleDialogActions({
    super.key,
    required this.onOk,
    this.okText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return RufkoDialogActions(
      onCancel: () => Navigator.pop(context),
      onConfirm: onOk ?? () => Navigator.pop(context),
      confirmText: okText,
    );
  }
}