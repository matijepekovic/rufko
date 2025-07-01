// lib/widgets/quote_form/quote_products_section.dart

import 'package:flutter/material.dart';

import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/quote.dart';
import '../../../../../data/models/business/product.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/business/quote_extras.dart';
import '../added_products_list.dart';
import '../sections/quote_totals_section.dart';
import '../sections/tax_rate_section.dart';

class QuoteProductsSection extends StatelessWidget
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin {
  final List<QuoteItem> addedProducts;
  final String quoteType;
  final VoidCallback onAddProductPressed;
  final Function(QuoteItem) onRemoveProduct;
  final Function(QuoteItem) onEditProduct;
  final List<QuoteLevel> quoteLevels;
  final Product? mainProduct;
  final double mainQuantity;
  final double taxRate;
  final List<PermitItem> permits;
  final List<CustomLineItem> customLineItems;
  final ValueChanged<double> onTaxRateChanged;
  final VoidCallback onAutoDetectPressed;
  final Customer customer;
  final List<QuoteDiscount> discounts; // NEW: Add discounts parameter

  const QuoteProductsSection({
    super.key,
    required this.addedProducts,
    required this.quoteType,
    required this.onAddProductPressed,
    required this.onRemoveProduct,
    required this.onEditProduct,
    required this.quoteLevels,
    required this.mainProduct,
    required this.mainQuantity,
    required this.taxRate,
    required this.permits,
    required this.customLineItems,
    required this.onTaxRateChanged,
    required this.onAutoDetectPressed,
    required this.customer,
    required this.discounts, // NEW: Required discounts parameter
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddedProductsList(
          addedProducts: addedProducts,
          quoteType: quoteType,
          onAddProductPressed: onAddProductPressed,
          onRemoveProduct: onRemoveProduct,
          onEditProduct: onEditProduct,
        ),
        if (quoteLevels.isNotEmpty) ...[
          SizedBox(height: spacingXL(context)),
          TaxRateSection(
            taxRate: taxRate,
            customer: customer,
            onTaxRateChanged: onTaxRateChanged,
            onAutoDetectPressed: onAutoDetectPressed,
          ),
          SizedBox(height: spacingXL(context)),
          QuoteTotalsSection(
            quoteLevels: quoteLevels,
            mainProduct: mainProduct,
            mainQuantity: mainQuantity,
            taxRate: taxRate,
            permits: permits,
            customLineItems: customLineItems,
            quoteType: quoteType,
            quote: discounts.isNotEmpty ? _createTemporaryQuote() : null, // NEW: Pass temporary quote for discount calculations
          ),
        ],
      ],
    );
  }

  /// Create a temporary quote object with current form data for discount calculations
  SimplifiedMultiLevelQuote _createTemporaryQuote() {
    return SimplifiedMultiLevelQuote(
      customerId: customer.id,
      levels: quoteLevels,
      addons: addedProducts,
      taxRate: taxRate,
      discounts: discounts,
      permits: permits,
      customLineItems: customLineItems,
    );
  }
}
