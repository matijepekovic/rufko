import 'package:flutter/material.dart';
import '../../../app/theme/rufko_theme.dart';

/// Standardized footer action bar for consistent bottom button placement
class RufkoFooterActionBar extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  const RufkoFooterActionBar({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: mainAxisAlignment,
          children: _buildChildrenWithSpacing(),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    if (children.isEmpty) return [];
    
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      if (children[i] is Expanded || children[i] is Flexible) {
        result.add(children[i]);
      } else {
        result.add(Flexible(
          flex: 1,
          child: children[i],
        ));
      }
      
      if (i < children.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }
}

/// Full-width variant for single button footers
class RufkoFullWidthFooter extends StatelessWidget {
  final Widget child;

  const RufkoFullWidthFooter({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: SizedBox(
          width: double.infinity,
          height: RufkoTheme.buttonHeightLarge,
          child: child,
        ),
      ),
    );
  }
}