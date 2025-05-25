// lib/services/pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion; // For PDF text extraction
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

import '../models/customer.dart';
import '../models/quote.dart' as legacy_quote_model; // For OLD Quote PDF
import '../models/simplified_quote.dart'; // NEW SimplifiedMultiLevelQuote
import '../models/roof_scope_data.dart';
// import '../models/multi_level_quote.dart' as old_mlq; // OLD - REMOVED

class PdfService {
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  // --- NEW: PDF for SimplifiedMultiLevelQuote ---
  Future<String> generateSimplifiedMultiLevelQuotePdf(
      SimplifiedMultiLevelQuote quote,
      Customer customer, {
        String? selectedLevelId, // Optional: To highlight or show only a specific selected level
        List<String>? selectedAddonIds, // Optional: To show which addons were selected
      }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => _buildPdfHeader(quote.quoteNumber, quote.status), // Common header
          footer: (pw.Context context) => _buildPdfFooter(), // Common footer
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            content.add(_buildPdfCustomerInfo(customer));
            content.add(pw.SizedBox(height: 20));
            content.add(_buildSimplifiedQuoteGeneralInfo(quote));
            content.add(pw.SizedBox(height: 20));

            // Option 1: Show all levels for comparison
            if (selectedLevelId == null) {
              content.add(pw.Text("Quote Options:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)));
              content.add(pw.SizedBox(height: 10));
              for (final level in quote.levels) {
                content.add(_buildPdfQuoteLevelSection(level, quote.taxRate, quote.discount));
                content.add(pw.SizedBox(height: 15));
              }
            }
            // Option 2: Show only the selected level (if one is "accepted" or chosen for PDF)
            else {
              final selectedLevel = quote.levels.firstWhere((l) => l.id == selectedLevelId, orElse: () => quote.levels.first); // Fallback
              content.add(pw.Text("Selected Option: ${selectedLevel.name}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)));
              content.add(pw.SizedBox(height: 10));
              content.add(_buildPdfQuoteLevelSection(selectedLevel, quote.taxRate, quote.discount, isSelected: true));
              content.add(pw.SizedBox(height: 15));
            }

            // Addons
            List<legacy_quote_model.QuoteItem> addonsToDisplay = quote.addons;
            if (selectedAddonIds != null && selectedAddonIds.isNotEmpty) {
              addonsToDisplay = quote.addons.where((addon) => selectedAddonIds.contains(addon.productId)).toList(); // Or however addons are identified
            }

            if (addonsToDisplay.isNotEmpty) {
              content.add(pw.SizedBox(height: 10));
              content.add(_buildPdfAddonsSection(addonsToDisplay));
            }

            // Final Total (if a specific configuration is selected)
            if(selectedLevelId != null) {
              content.add(pw.SizedBox(height: 20));
              content.add(_buildPdfFinalTotal(quote, selectedLevelId, addonsToDisplay));
            }


            content.add(pw.SizedBox(height: 30));
            content.add(_buildPdfTermsAndConditions());

            return content;
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'quote_${quote.quoteNumber.replaceAll(RegExp(r'[^\w\s]+'),'_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      if (kDebugMode) print('Generated PDF: ${file.path}');
      return file.path;

    } catch (e) {
      if (kDebugMode) print('Error generating SimplifiedMultiLevelQuote PDF: $e');
      rethrow;
    }
  }

  pw.Widget _buildPdfHeader(String quoteNumber, String status) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Column(
          children: [
            pw.Text('Your Company Name LLC', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.Text('123 Main Street, Your City, ST 12345 | (555) 123-4567 | your@email.com', style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(height: 25, thickness: 1),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ESTIMATE / QUOTE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Quote #: $quoteNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Status: ${status.toUpperCase()}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ]
                  )
                ]
            ),
            pw.SizedBox(height:10),
          ]
      ),
    );
  }

  pw.Widget _buildPdfCustomerInfo(Customer customer) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Prepared For:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        pw.Text(customer.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        if (customer.address != null && customer.address!.isNotEmpty) pw.Text(customer.address!),
        if (customer.phone != null && customer.phone!.isNotEmpty) pw.Text('Phone: ${customer.phone}'),
        if (customer.email != null && customer.email!.isNotEmpty) pw.Text('Email: ${customer.email}'),
      ],
    );
  }

  pw.Widget _buildSimplifiedQuoteGeneralInfo(SimplifiedMultiLevelQuote quote) {
    return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Date: ${_dateFormat.format(quote.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Valid Until: ${_dateFormat.format(quote.validUntil)}', style: const pw.TextStyle(fontSize: 10)),
              if(quote.taxRate > 0) pw.Text('Tax Rate: ${quote.taxRate.toStringAsFixed(2)}%', style: const pw.TextStyle(fontSize: 10)),
              if(quote.discount > 0) pw.Text('Discount Applied: ${_currencyFormat.format(quote.discount)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
            ],
          )
        ]
    );
  }


  pw.Widget _buildPdfQuoteLevelSection(QuoteLevel level, double taxRate, double overallDiscount, {bool isSelected = false}) {
    final levelSubtotal = level.subtotal;
    final levelTax = levelSubtotal * (taxRate / 100);
    // Assuming overallDiscount applies after tax for simplicity of display per level
    // A more accurate total if selected is calculated separately.
    final levelDisplayTotal = levelSubtotal + levelTax;


    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: isSelected ? PdfColors.blue700 : PdfColors.grey400, width: isSelected ? 1.5 : 0.5),
        borderRadius: pw.BorderRadius.circular(5),
        color: isSelected ? PdfColors.blue50 : PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(level.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isSelected ? PdfColors.blue700 : PdfColors.black)),
          pw.SizedBox(height: 5),
          pw.Text('Base Product Price for this Level: ${_currencyFormat.format(level.basePrice)}', style: const pw.TextStyle(fontSize: 10)),
          if (level.includedItems.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text('Included Items/Features:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1.2), 3: const pw.FlexColumnWidth(1.2)
              },
              headers: ['Item', 'Qty', 'Unit Price', 'Total'],
              data: level.includedItems.map((item) => [
                item.productName,
                item.quantity.toStringAsFixed(1),
                _currencyFormat.format(item.unitPrice),
                _currencyFormat.format(item.totalPrice),
              ]).toList(),
            ),
          ],
          pw.Divider(height: 10, thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Level Subtotal: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(_currencyFormat.format(levelSubtotal), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if(taxRate > 0) pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Tax (${taxRate.toStringAsFixed(1)}%): ', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(_currencyFormat.format(levelTax), style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Level Total (w/Tax): ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isSelected ? PdfColors.blue700 : PdfColors.black)),
              pw.Text(_currencyFormat.format(levelDisplayTotal), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isSelected ? PdfColors.blue700 : PdfColors.black)),
            ],
          )
        ],
      ),
    );
  }

  pw.Widget _buildPdfAddonsSection(List<legacy_quote_model.QuoteItem> addons) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Optional Add-ons:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1.2), 3: const pw.FlexColumnWidth(1.2)
          },
          headers: ['Add-on', 'Qty', 'Unit Price', 'Total'],
          data: addons.map((item) => [
            item.productName,
            item.quantity.toStringAsFixed(1),
            _currencyFormat.format(item.unitPrice),
            _currencyFormat.format(item.totalPrice),
          ]).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFinalTotal(SimplifiedMultiLevelQuote quote, String selectedLevelId, List<legacy_quote_model.QuoteItem> selectedAddons) {
    final finalTotal = quote.calculateFinalTotal(selectedLevelId: selectedLevelId, selectedAddons: selectedAddons);
    return pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (quote.discount > 0)
                pw.Text('Quote Discount Applied: -${_currencyFormat.format(quote.discount)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
              pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: PdfColors.blueGrey50,
                  child: pw.Text('FINAL QUOTE TOTAL: ${_currencyFormat.format(finalTotal)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey800)
                  )
              )
            ]
        )
    );
  }


  pw.Widget _buildPdfTermsAndConditions() {
    // ... (same as your existing _buildTermsAndConditions or adapt as needed)
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(
          '• This quote is valid for 30 days from the date of issue.\n'
              '• All work to be completed in a workmanlike manner according to standard practices.\n'
              '• Any alteration or deviation from above specifications involving extra costs will be executed only upon written orders, and will become an extra charge over and above the estimate.\n'
              '• Payment terms: 50% deposit upon acceptance, balance due upon completion.',
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    // ... (same as your existing _buildFooter or adapt as needed)
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20.0),
      child: pw.Text(
        'Thank you for your business!',
        style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey),
      ),
    );
  }


  // --- PDF Text Extraction for RoofScopeData (seems fine as is) ---
  Future<RoofScopeData?> extractRoofScopeData(String filePath, String customerId) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        extractedText += syncfusion.PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
      }
      document.dispose();
      final roofScopeData = _parseRoofScopeText(extractedText, customerId, file.path.split('/').last);
      return roofScopeData;
    } catch (e) {
      if (kDebugMode) print('Error extracting RoofScope data: $e');
      return null;
    }
  }

  RoofScopeData _parseRoofScopeText(String text, String customerId, String sourceFileName) {
    // Your existing parsing logic - ensure it's robust
    final data = RoofScopeData(customerId: customerId, sourceFileName: sourceFileName);
    final lowerText = text.toLowerCase();

    // Example parsing (make this more comprehensive based on actual RoofScope PDF formats)
    final areaMatch = RegExp(r'(?:total area|roof area)[:\s]*([0-9,]+\.?[0-9]*)\s*sq\.?\s*ft').firstMatch(lowerText);
    if (areaMatch != null) data.roofArea = double.tryParse(areaMatch.group(1)!.replaceAll(',', '')) ?? 0.0;

    final pitchMatch = RegExp(r'pitch[:\s]*([0-9]+(?:\.[0-9]+)?)[/:]([0-9]+)').firstMatch(lowerText);
    if (pitchMatch != null) {
      final rise = double.tryParse(pitchMatch.group(1) ?? '0') ?? 0.0;
      // final run = double.tryParse(pitchMatch.group(2) ?? '12') ?? 12.0; // Assuming run is always 12 if not specified differently
      data.pitch = rise; // Store the rise directly, assuming /12 pitch
    }

    // Add more robust regex for other fields: ridge, valley, hip, eave, gutter, perimeter, flashing
    // Example for ridge:
    final ridgeMatch = RegExp(r'ridge(?:s)?[:\s]*([0-9,]+\.?[0-9]*)\s*(?:lin\.?\s*ft|ft)').firstMatch(lowerText);
    if (ridgeMatch != null) data.ridgeLength = double.tryParse(ridgeMatch.group(1)!.replaceAll(',', '')) ?? 0.0;

    // ... (add regex for valley, hip, eave, gutter, perimeter, flashing, chimney, skylight) ...

    if (data.roofArea > 0) data.calculateSquares();
    return data;
  }
// ... (isRoofScopePdf and getPdfInfo methods can remain if they don't need specific model knowledge) ...
}