import 'package:flutter/material.dart';
import '../../../app/theme/rufko_theme.dart';

/// Standard primary button for main actions
class RufkoPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final ButtonSize size;
  final bool isFullWidth;

  const RufkoPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = ButtonSize.medium,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: _getIconSize()),
            label: child,
            style: _getButtonStyle(),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: _getButtonStyle(),
            child: child,
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: _getPadding(),
      minimumSize: Size(88, _getHeight()),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonPaddingLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonPaddingMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonPaddingSmall;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonHeightLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonHeightMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonHeightSmall;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.large:
        return 20;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.small:
        return 16;
    }
  }
}

/// Standard secondary button for alternative actions
class RufkoSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final ButtonSize size;
  final bool isFullWidth;

  const RufkoSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = ButtonSize.medium,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: _getIconSize()),
            label: child,
            style: _getButtonStyle(),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: _getButtonStyle(),
            child: child,
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  ButtonStyle _getButtonStyle() {
    return OutlinedButton.styleFrom(
      padding: _getPadding(),
      minimumSize: Size(88, _getHeight()),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonPaddingLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonPaddingMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonPaddingSmall;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonHeightLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonHeightMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonHeightSmall;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.large:
        return 20;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.small:
        return 16;
    }
  }
}

/// Standard text button for tertiary actions
class RufkoTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final ButtonSize size;

  const RufkoTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: _getIconSize()),
            label: child,
            style: _getButtonStyle(),
          )
        : TextButton(
            onPressed: onPressed,
            style: _getButtonStyle(),
            child: child,
          );
  }

  ButtonStyle _getButtonStyle() {
    return TextButton.styleFrom(
      padding: _getPadding(),
      minimumSize: Size(88, _getHeight()),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonPaddingLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonPaddingMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonPaddingSmall;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonHeightLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonHeightMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonHeightSmall;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.large:
        return 20;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.small:
        return 16;
    }
  }
}

/// Danger button for destructive actions
class RufkoDangerButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final ButtonSize size;

  const RufkoDangerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: _getIconSize()),
            label: child,
            style: _getButtonStyle(),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: _getButtonStyle(),
            child: child,
          );
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      padding: _getPadding(),
      minimumSize: Size(88, _getHeight()),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonPaddingLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonPaddingMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonPaddingSmall;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonHeightLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonHeightMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonHeightSmall;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.large:
        return 20;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.small:
        return 16;
    }
  }
}

/// Icon-only button for compact actions
class RufkoIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final ButtonSize size;
  final Color? color;

  const RufkoIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = ButtonSize.medium,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(0),
        minimumSize: Size(_getSize(), _getSize()),
        shape: RoundedRectangleBorder(
          borderRadius: RufkoTheme.buttonBorderRadius,
        ),
      ),
      child: Icon(
        icon,
        size: _getIconSize(),
        color: color,
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case ButtonSize.large:
        return RufkoTheme.buttonHeightLarge;
      case ButtonSize.medium:
        return RufkoTheme.buttonHeightMedium;
      case ButtonSize.small:
        return RufkoTheme.buttonHeightSmall;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.large:
        return 24;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.small:
        return 16;
    }
  }
}

enum ButtonSize { large, medium, small }