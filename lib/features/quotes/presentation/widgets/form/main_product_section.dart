// lib/widgets/quote_form/main_product_section.dart

import 'package:flutter/material.dart';

import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../main_product_selection.dart';
import '../quote_type_selector.dart';
import '../../../../../data/models/business/product.dart';

class MainProductSection extends StatelessWidget
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin {
  final String quoteType;
  final Product? mainProduct;
  final double mainQuantity;
  final ValueChanged<Product?> onProductChanged;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onQuoteTypeChanged;

  const MainProductSection({
    super.key,
    required this.quoteType,
    required this.mainProduct,
    required this.mainQuantity,
    required this.onProductChanged,
    required this.onQuantityChanged,
    required this.onQuoteTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuoteTypeSelector(
          quoteType: quoteType,
          onQuoteTypeChanged: onQuoteTypeChanged,
        ),
        SizedBox(height: spacingXL(context)),
        MainProductSelection(
          mainProduct: mainProduct,
          mainQuantity: mainQuantity,
          quoteType: quoteType,
          onProductChanged: onProductChanged,
          onQuantityChanged: onQuantityChanged,
        ),
      ],
    );
  }
}
