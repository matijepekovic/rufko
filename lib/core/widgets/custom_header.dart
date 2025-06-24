import 'package:flutter/material.dart';
import '../../app/theme/rufko_theme.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const CustomHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RufkoTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: RufkoTheme.strokeColor,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (showBackButton) ...[
              IconButton(
                onPressed: onBackPressed ?? () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.grey[800],
              ),
              const SizedBox(width: 8),
            ],
            if (leadingIcon != null && !showBackButton) ...[
              Icon(
                leadingIcon,
                color: RufkoTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }
}