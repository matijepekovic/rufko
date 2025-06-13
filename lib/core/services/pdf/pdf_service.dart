// lib/services/pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion; // Add this line
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/templates/pdf_template.dart';
import '../template_service.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/models/business/quote.dart' as legacy_quote_model;
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/roof_scope_data.dart';
import '../database/database_service.dart';

class PdfService {
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  // --- NEW: PDF for SimplifiedMultiLevelQuote ---
  Future<String> generateSimplifiedMultiLevelQuotePdf(
      SimplifiedMultiLevelQuote quote,
      Customer customer, {
        String? selectedLevelId, // Optional: To highlight or show only a specific selected level
        List<
            String>? selectedAddonIds, // Optional: To show which addons were selected
      }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) =>
              _buildPdfHeader(quote.quoteNumber, quote.status),
          // Common header
          footer: (pw.Context context) => _buildPdfFooter(),
          // Common footer
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            content.add(_buildPdfCustomerInfo(customer));
            content.add(pw.SizedBox(height: 20));
            content.add(_buildSimplifiedQuoteGeneralInfo(quote));
            content.add(pw.SizedBox(height: 20));

            // Option 1: Show all levels for comparison
            if (selectedLevelId == null) {
              content.add(pw.Text("Quote Options:", style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 16)));
              content.add(pw.SizedBox(height: 10));
              for (final level in quote.levels) {
                content.add(_buildPdfQuoteLevelSection(
                    level, quote.taxRate, quote.discount));
                content.add(pw.SizedBox(height: 15));
              }
            }
            // Option 2: Show only the selected level (if one is "accepted" or chosen for PDF)
            else {
              final selectedLevel = quote.levels.firstWhere((l) =>
              l.id == selectedLevelId,
                  orElse: () => quote.levels.first); // Fallback
              content.add(pw.Text("Selected Option: ${selectedLevel.name}",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)));
              content.add(pw.SizedBox(height: 10));
              content.add(_buildPdfQuoteLevelSection(
                  selectedLevel, quote.taxRate, quote.discount,
                  isSelected: true));
              content.add(pw.SizedBox(height: 15));
            }

            // Addons
            List<legacy_quote_model.QuoteItem> addonsToDisplay = quote.addons;
            if (selectedAddonIds != null && selectedAddonIds.isNotEmpty) {
              addonsToDisplay = quote.addons
                  .where((addon) =>
                  selectedAddonIds.contains(addon.productId))
                  .toList(); // Or however addons are identified
            }

            if (addonsToDisplay.isNotEmpty) {
              content.add(pw.SizedBox(height: 10));
              content.add(_buildPdfAddonsSection(addonsToDisplay));
            }

            // Final Total (if a specific configuration is selected)
            if (selectedLevelId != null) {
              content.add(pw.SizedBox(height: 20));
              content.add(
                  _buildPdfFinalTotal(quote, selectedLevelId, addonsToDisplay));
            }


            content.add(pw.SizedBox(height: 30));
            content.add(_buildPdfTermsAndConditions());

            return content;
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'quote_${quote.quoteNumber.replaceAll(
          RegExp(r'[^\w\s]+'), '_')}_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      if (kDebugMode) debugPrint('Generated PDF: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Error generating SimplifiedMultiLevelQuote PDF: $e');
      }
      rethrow;
    }
  }

  pw.Widget _buildPdfHeader(String quoteNumber, String status) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Column(
          children: [
            pw.Text('Your Company Name LLC', style: pw.TextStyle(fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800)),
            pw.Text(
                '123 Main Street, Your City, ST 12345 | (555) 123-4567 | your@email.com',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(height: 25, thickness: 1),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ESTIMATE / QUOTE', style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Quote #: $quoteNumber', style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold)),
                        pw.Text('Status: ${status.toUpperCase()}',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      ]
                  )
                ]
            ),
            pw.SizedBox(height: 10),
          ]
      ),
    );
  }

  pw.Widget _buildPdfCustomerInfo(Customer customer) {
    final String displayAddress = customer.fullDisplayAddress; // Use the new getter

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Prepared For:', style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        pw.Text(customer.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),

        // Use the combined displayAddress
        if (displayAddress.isNotEmpty && displayAddress != 'No address provided')
          pw.Text(displayAddress),

        if (customer.phone != null && customer.phone!.isNotEmpty)
          pw.Text('Phone: ${customer.phone}'),
        if (customer.email != null && customer.email!.isNotEmpty)
          pw.Text('Email: ${customer.email}'),
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
              pw.Text('Date: ${_dateFormat.format(quote.createdAt)}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Valid Until: ${_dateFormat.format(quote.validUntil)}',
                  style: const pw.TextStyle(fontSize: 10)),
              if(quote.taxRate > 0) pw.Text(
                  'Tax Rate: ${quote.taxRate.toStringAsFixed(2)}%',
                  style: const pw.TextStyle(fontSize: 10)),
              if(quote.discount > 0) pw.Text(
                  'Discount Applied: ${_currencyFormat.format(quote.discount)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.green700)),
            ],
          )
        ]
    );
  }


  pw.Widget _buildPdfQuoteLevelSection(QuoteLevel level, double taxRate,
      double overallDiscount, {bool isSelected = false}) {
    final levelSubtotal = level.subtotal;
    final levelTax = levelSubtotal * (taxRate / 100);
    // Assuming overallDiscount applies after tax for simplicity of display per level
    // A more accurate total if selected is calculated separately.
    final levelDisplayTotal = levelSubtotal + levelTax;


    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
            color: isSelected ? PdfColors.blue700 : PdfColors.grey400,
            width: isSelected ? 1.5 : 0.5),
        borderRadius: pw.BorderRadius.circular(5),
        color: isSelected ? PdfColors.blue50 : PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(level.name, style: pw.TextStyle(fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: isSelected ? PdfColors.blue700 : PdfColors.black)),
          pw.SizedBox(height: 5),
          pw.Text('Base Product Price for this Level: ${_currencyFormat.format(
              level.basePrice)}', style: const pw.TextStyle(fontSize: 10)),
          if (level.includedItems.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text('Included Items/Features:', style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2)
              },
              headers: ['Item', 'Qty', 'Unit Price', 'Total'],
              data: level.includedItems.map((item) =>
              [
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
              pw.Text('Level Subtotal: ', style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(_currencyFormat.format(levelSubtotal),
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if(taxRate > 0) pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Tax (${taxRate.toStringAsFixed(1)}%): ',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(_currencyFormat.format(levelTax),
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Level Total (w/Tax): ', style: pw.TextStyle(fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: isSelected ? PdfColors.blue700 : PdfColors.black)),
              pw.Text(_currencyFormat.format(levelDisplayTotal),
                  style: pw.TextStyle(fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: isSelected ? PdfColors.blue700 : PdfColors.black)),
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
        pw.Text("Optional Add-ons:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4, vertical: 2),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 9),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2)
          },
          headers: ['Add-on', 'Qty', 'Unit Price', 'Total'],
          data: addons.map((item) =>
          [
            item.productName,
            item.quantity.toStringAsFixed(1),
            _currencyFormat.format(item.unitPrice),
            _currencyFormat.format(item.totalPrice),
          ]).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFinalTotal(SimplifiedMultiLevelQuote quote,
      String selectedLevelId,
      List<legacy_quote_model.QuoteItem> selectedAddons) {
    final finalTotal = quote.calculateFinalTotal(
        selectedLevelId: selectedLevelId, selectedAddons: selectedAddons);
    return pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (quote.discount > 0)
                pw.Text('Quote Discount Applied: -${_currencyFormat.format(
                    quote.discount)}', style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.green700)),
              pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 5, horizontal: 10),
                  color: PdfColors.blueGrey50,
                  child: pw.Text('FINAL QUOTE TOTAL: ${_currencyFormat.format(
                      finalTotal)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: PdfColors.blueGrey800)
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
        pw.Text('Terms & Conditions:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
        style: pw.TextStyle(fontSize: 10,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey),
      ),
    );
  }

// Replace the extractRoofScopeData method in app_state_provider.dart with this universal version

  Future<RoofScopeData?> extractRoofScopeData(String filePath, String customerId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) debugPrint('PDF file not found: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      String extractedText = '';
      syncfusion.PdfDocument? document;

      try {
        document = syncfusion.PdfDocument(inputBytes: bytes);

        if (kDebugMode) {
          debugPrint('📄 PDF Document Info:');
          debugPrint('   File: ${file.path.split('/').last}');
          debugPrint('   Size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
          debugPrint('   Pages: ${document.pages.count}');
        }

        // Try multiple extraction strategies for maximum compatibility

        // Strategy 1: Standard full document extraction
        try {
          final textExtractor = syncfusion.PdfTextExtractor(document);
          extractedText = textExtractor.extractText();
          if (kDebugMode) debugPrint('Strategy 1 - Full document: ${extractedText.length} chars');
        } catch (e) {
          if (kDebugMode) debugPrint('Strategy 1 failed: $e');
        }

        // Strategy 2: Page-by-page extraction
        if (extractedText.trim().isEmpty) {
          try {
            for (int i = 0; i < document.pages.count; i++) {
              final textExtractor = syncfusion.PdfTextExtractor(document);
              String pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
              extractedText += '$pageText\n';
            }
            if (kDebugMode) debugPrint('Strategy 2 - Page-by-page: ${extractedText.length} chars');
          } catch (e) {
            if (kDebugMode) debugPrint('Strategy 2 failed: $e');
          }
        }

        // Strategy 3: Alternative page extraction approach
        if (extractedText.trim().isEmpty) {
          try {
            final textExtractor = syncfusion.PdfTextExtractor(document);
            for (int i = 0; i < document.pages.count; i++) {
              // Try extracting each page individually
              String pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
              if (pageText.isNotEmpty) {
                extractedText += 'PAGE_${i + 1}: $pageText\n';
              }
            }
            if (kDebugMode) debugPrint('Strategy 3 - Individual pages: ${extractedText.length} chars');
          } catch (e) {
            if (kDebugMode) debugPrint('Strategy 3 failed: $e');
          }
        }

        // Strategy 4: Try with different text extractor instances
        if (extractedText.trim().isEmpty) {
          try {
            // Create separate extractor for each attempt
            for (int i = 0; i < document.pages.count; i++) {
              final pageExtractor = syncfusion.PdfTextExtractor(document);

              // Try different extraction approaches
              String pageText1 = pageExtractor.extractText(startPageIndex: i, endPageIndex: i);

              // Create new extractor instance
              final fullExtractor = syncfusion.PdfTextExtractor(document);
              String fullText = fullExtractor.extractText();

              if (pageText1.isNotEmpty) {
                extractedText += '$pageText1\n';
              } else if (fullText.isNotEmpty && i == 0) {
                extractedText = fullText;
                break;
              }
            }
            if (kDebugMode) debugPrint('Strategy 4 - Multiple extractors: ${extractedText.length} chars');
          } catch (e) {
            if (kDebugMode) debugPrint('Strategy 4 failed: $e');
          }
        }

      } catch (e) {
        if (kDebugMode) debugPrint('❌ PDF document loading failed: $e');
      } finally {
        document?.dispose();
      }

      // Clean and process the extracted text
      extractedText = extractedText.trim();

      if (kDebugMode) {
        debugPrint('=== FINAL EXTRACTION RESULTS ===');
        debugPrint('Total text length: ${extractedText.length}');

        if (extractedText.isNotEmpty) {
          // Show relevant portions of text
          debugPrint('Text sample (first 300 chars):');
          debugPrint(extractedText.substring(0, extractedText.length > 300 ? 300 : extractedText.length));

          // Check for key RoofScope indicators
          final indicators = [
            'RoofScope', 'Total Roof Area', 'Project Totals', 'SQ', 'LF',
            'Ridge', 'Hip', 'Valley', 'Eave', 'Perimeter', 'Flashing',
            'Roof Planes', 'Structures'
          ];

          debugPrint('\nKey indicators found:');
          for (final indicator in indicators) {
            if (extractedText.toUpperCase().contains(indicator.toUpperCase())) {
              debugPrint('✅ $indicator');
            }
          }
        } else {
          debugPrint('❌ NO TEXT EXTRACTED');
          debugPrint('💡 This PDF may contain images/graphics only');
        }
        debugPrint('================================');
      }

      // Parse the extracted text regardless of length (even empty text gets processed)
      final roofScopeData = _parseRoofScopeText(extractedText, customerId, file.path.split('/').last);

      // If no data was extracted, still return the object but mark it appropriately
      if (extractedText.isEmpty) {
        roofScopeData.addMeasurement('extraction_status', 'no_text_found');
        roofScopeData.addMeasurement('requires_manual_entry', true);
      }

      return roofScopeData;

    } catch (e) {
      if (kDebugMode) debugPrint('❌ Critical error in extractRoofScopeData: $e');
      return null;
    }
  }

// Enhanced parsing method that handles various RoofScope PDF formats
  RoofScopeData _parseRoofScopeText(String text, String customerId, String sourceFileName) {
    final data = RoofScopeData(customerId: customerId, sourceFileName: sourceFileName);

    if (kDebugMode) debugPrint('🏠 Parsing RoofScope data from: $sourceFileName');

    try {
      // Normalize text for better pattern matching
      String cleanText = text
          .replaceAll(RegExp(r'\s+'), ' ')  // Multiple spaces to single space
          .replaceAll(RegExp(r'\n+'), ' ')  // Line breaks to spaces
          .replaceAll(RegExp(r'\t+'), ' ')  // Tabs to spaces
          .trim()
          .toLowerCase();

      if (cleanText.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ No text to parse - creating empty template');
        data.addMeasurement('parse_status', 'empty_text');
        return data;
      }

      bool foundAnyData = false;

      // === COMPREHENSIVE PATTERN MATCHING FOR ALL ROOFSCOPE FORMATS ===

      // 1. TOTAL ROOF AREA - Multiple patterns to handle different RoofScope layouts
      final roofAreaPatterns = [
        // Standard format: "Total Roof Area - 15.73 SQ"
        RegExp(r'total\s+roof\s+area\s*[-:]\s*([0-9]+\.?[0-9]*)\s*sq'),
        // Compact format: "Total Roof Area 15.73 SQ"
        RegExp(r'total\s+roof\s+area\s+([0-9]+\.?[0-9]*)\s*sq'),
        // Project totals format: "Project Totals Total Roof Area - 15.73 SQ"
        RegExp(r'project\s+totals.*?total\s+roof\s+area\s*[-:]\s*([0-9]+\.?[0-9]*)\s*sq'),
        // Simple format: "15.73 SQ" following roof area context
        RegExp(r'roof\s+area.*?([0-9]+\.?[0-9]*)\s*sq'),
        // Backwards format: "15.73 SQ Total Roof Area"
        RegExp(r'([0-9]+\.?[0-9]*)\s*sq.*?total\s+roof\s+area'),
      ];

      for (final pattern in roofAreaPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final area = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (area > 0) {
            data.roofArea = area;
            data.numberOfSquares = area; // In roofing, squares = roof area
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Total Roof Area: ${data.roofArea} SQ');
            break;
          }
        }
      }

      // 2. ROOF PLANES - Various formats
      final planesPatterns = [
        RegExp(r'roof\s+planes\s*[-:]\s*([0-9]+)'),
        RegExp(r'planes\s*[-:]\s*([0-9]+)'),
        RegExp(r'([0-9]+)\s+planes'),
        RegExp(r'roof\s+planes\s+([0-9]+)'),
      ];

      for (final pattern in planesPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final planes = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (planes > 0) {
            data.addMeasurement('roof_planes', planes);
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Roof Planes: $planes');
            break;
          }
        }
      }

      // 3. STRUCTURES COUNT
      final structuresPatterns = [
        RegExp(r'structures\s*[-:]\s*([0-9]+)'),
        RegExp(r'structure\s*[-:]\s*([0-9]+)'),
        RegExp(r'([0-9]+)\s+structures?'),
      ];

      for (final pattern in structuresPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final structures = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (structures >= 0) { // 0 is valid for structures
            data.addMeasurement('structures_count', structures);
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Structures: $structures');
            break;
          }
        }
      }

      // 4. LINEAR MEASUREMENTS (LF) - Ridge, Hip, Valley, Eave, Perimeter

      // RIDGE
      final ridgePatterns = [
        RegExp(r'ridge\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'([0-9]+\.?[0-9]*)\s*lf.*ridge'),
        RegExp(r'ridge\s+([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in ridgePatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final ridge = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (ridge > 0) {
            data.ridgeLength = ridge;
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Ridge: ${data.ridgeLength} LF');
            break;
          }
        }
      }

      // HIP
      final hipPatterns = [
        RegExp(r'hip\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'([0-9]+\.?[0-9]*)\s*lf.*hip'),
        RegExp(r'hip\s+([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in hipPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final hip = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (hip > 0) {
            data.hipLength = hip;
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Hip: ${data.hipLength} LF');
            break;
          }
        }
      }

      // VALLEY
      final valleyPatterns = [
        RegExp(r'valley\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'([0-9]+\.?[0-9]*)\s*lf.*valley'),
        RegExp(r'valley\s+([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in valleyPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final valley = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (valley > 0) {
            data.valleyLength = valley;
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Valley: ${data.valleyLength} LF');
            break;
          }
        }
      }

      // EAVE (also used for gutter calculations)
      final eavePatterns = [
        RegExp(r'eave\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'([0-9]+\.?[0-9]*)\s*lf.*eave'),
        RegExp(r'eave\s+([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in eavePatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final eave = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (eave > 0) {
            data.eaveLength = eave;
            data.gutterLength = eave; // Eave length typically equals gutter length
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Eave/Gutter: ${data.eaveLength} LF');
            break;
          }
        }
      }

      // RAKE EDGE (alternative to eave in some reports)
      final rakeEdgePatterns = [
        RegExp(r'rake\s+edge\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'rake\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in rakeEdgePatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null && data.eaveLength == 0) { // Only use if eave not found
          final rake = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (rake > 0) {
            data.eaveLength = rake;
            data.gutterLength = rake;
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Rake Edge (as Eave): ${data.eaveLength} LF');
            break;
          }
        }
      }

      // TOTAL PERIMETER
      final perimeterPatterns = [
        RegExp(r'total\s+perimeter\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'perimeter\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'([0-9]+\.?[0-9]*)\s*lf.*perimeter'),
      ];

      for (final pattern in perimeterPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final perimeter = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (perimeter > 0) {
            data.perimeterLength = perimeter;
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Perimeter: ${data.perimeterLength} LF');
            break;
          }
        }
      }

      // 5. FLASHING MEASUREMENTS
      double totalFlashing = 0.0;

      // Step Flashing
      final stepFlashingPatterns = [
        RegExp(r'step\s+flashing\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'step\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in stepFlashingPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final step = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          totalFlashing += step;
          if (step > 0 && kDebugMode) debugPrint('✅ Step Flashing: $step LF');
          break;
        }
      }

      // Headwall Flashing
      final headwallFlashingPatterns = [
        RegExp(r'headwall\s+flashing\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
        RegExp(r'headwall\s*[-:]\s*([0-9]+\.?[0-9]*)\s*lf'),
      ];

      for (final pattern in headwallFlashingPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final headwall = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          totalFlashing += headwall;
          if (headwall > 0 && kDebugMode) debugPrint('✅ Headwall Flashing: $headwall LF');
          break;
        }
      }

      if (totalFlashing > 0) {
        data.flashingLength = totalFlashing;
        foundAnyData = true;
        if (kDebugMode) debugPrint('✅ Total Flashing: ${data.flashingLength} LF');
      }

      // 6. PITCH/SLOPE INFORMATION
      final pitchPatterns = [
        RegExp(r'pitch\s*[-:]\s*([0-9]+\.?[0-9]*)', caseSensitive: false),
        RegExp(r'slope\s*[-:]\s*([0-9]+\.?[0-9]*)', caseSensitive: false),
        RegExp(r'([0-9]+\.?[0-9]*)\s*:\s*12', caseSensitive: false), // 6:12 format
        RegExp(r'([0-9]+\.?[0-9]*)/12', caseSensitive: false), // 6/12 format
      ];

      for (final pattern in pitchPatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          final pitch = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          if (pitch > 0) {
            data.pitch = pitch;
            foundAnyData = true;
            if (kDebugMode) debugPrint('✅ Pitch: ${data.pitch}/12');
            break;
          }
        }
      }

      // Mark parsing status
      data.addMeasurement('parse_status', foundAnyData ? 'successful' : 'no_data_found');
      data.addMeasurement('text_length', cleanText.length);

      // === FINAL SUMMARY ===
      if (foundAnyData) {
        if (kDebugMode) {
          debugPrint('🎉 RoofScope parsing SUCCESSFUL!');
          debugPrint('📊 Extracted Data Summary:');
          debugPrint('   • Roof Area: ${data.roofArea} SQ');
          debugPrint('   • Ridge: ${data.ridgeLength} LF');
          debugPrint('   • Hip: ${data.hipLength} LF');
          debugPrint('   • Valley: ${data.valleyLength} LF');
          debugPrint('   • Eave/Gutters: ${data.eaveLength} LF');
          debugPrint('   • Perimeter: ${data.perimeterLength} LF');
          debugPrint('   • Flashing: ${data.flashingLength} LF');
          debugPrint('   • Pitch: ${data.pitch}/12');
          debugPrint('   • Planes: ${data.additionalMeasurements['roof_planes'] ?? 'Not found'}');
          debugPrint('   • Structures: ${data.additionalMeasurements['structures_count'] ?? 'Not found'}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ No RoofScope data found in text');
          debugPrint('💡 Text length: ${cleanText.length} characters');
          if (cleanText.isNotEmpty) {
            debugPrint('💡 Sample text: ${cleanText.substring(0, cleanText.length > 100 ? 100 : cleanText.length)}...');
          }
        }
        data.addMeasurement('extraction_issue', 'no_patterns_matched');
      }

      return data;

    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error parsing RoofScope text: $e');
      data.addMeasurement('parse_status', 'error');
      data.addMeasurement('error_message', e.toString());
      return data;
    }
  }
  Future<String> generateQuotePdfFromTemplate({
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    try {
      // Get the template
      final template = await DatabaseService.instance.getPDFTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      if (!template.isActive) {
        throw Exception('Template is not active: ${template.templateName}');
      }

      // Generate PDF using template service
      final pdfPath = await TemplateService.instance.generatePDFFromTemplate(
        template: template,
        quote: quote,
        customer: customer,
        selectedLevelId: selectedLevelId,
        customData: customData,
      );

      if (kDebugMode) {
        debugPrint('📄 Generated template-based PDF: $pdfPath');
      }

      return pdfPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating template-based PDF: $e');
      }
      rethrow;
    }
  }

  /// Enhanced quote PDF generation with template selection
  Future<String> generateSimplifiedMultiLevelQuotePdfEnhanced(
      SimplifiedMultiLevelQuote quote,
      Customer customer, {
        String? selectedLevelId,
        List<String>? selectedAddonIds,
        String? templateId, // NEW: Optional template ID
        Map<String, String>? customData, // NEW: Custom data override
      }) async {
    try {
      // If template ID is provided, use template-based generation
      if (templateId != null) {
        if (kDebugMode) {
          debugPrint('🎨 Using template-based PDF generation with template: $templateId');
        }

        return await generateQuotePdfFromTemplate(
          templateId: templateId,
          quote: quote,
          customer: customer,
          selectedLevelId: selectedLevelId,
          customData: customData,
        );
      }

      // Otherwise, fall back to the existing PDF generation method
      if (kDebugMode) {
        debugPrint('📝 Using standard PDF generation (no template)');
      }

      return await generateSimplifiedMultiLevelQuotePdf(
        quote,
        customer,
        selectedLevelId: selectedLevelId,
        selectedAddonIds: selectedAddonIds,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in enhanced PDF generation: $e');
      }
      rethrow;
    }
  }

  /// Get available templates for quote generation
  Future<List<PDFTemplate>> getAvailableQuoteTemplates() async {
    try {
      final templates = await DatabaseService.instance.getPDFTemplatesByType('quote');
      return templates.where((t) => t.isActive).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting available quote templates: $e');
      }
      return [];
    }
  }

  /// Validate that a template is suitable for quote generation
  Future<bool> validateQuoteTemplate(String templateId) async {
    try {
      final template = await DatabaseService.instance.getPDFTemplate(templateId);
      if (template == null || !template.isActive) {
        return false;
      }

      // Check if template has essential quote fields
      final essentialFields = [
        'customerName',
        'quoteNumber',
        'grandTotal',
      ];

      final templateFields = template.fieldMappings.map((f) => f.appDataType).toList();
      final hasEssentialFields = essentialFields.every((field) => templateFields.contains(field));

      if (!hasEssentialFields && kDebugMode) {
        debugPrint('⚠️ Template missing essential fields: $templateId');
      }

      return hasEssentialFields;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error validating quote template: $e');
      }
      return false;
    }
  }

  /// Generate preview of how a quote would look with a specific template
  Future<String> generateQuoteTemplatePreview({
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
  }) async {
    try {
      final customData = <String, String>{
        'preview': 'true',
        'watermark': 'PREVIEW ONLY',
      };

      return await generateQuotePdfFromTemplate(
        templateId: templateId,
        quote: quote,
        customer: customer,
        selectedLevelId: selectedLevelId,
        customData: customData,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating quote template preview: $e');
      }
      rethrow;
    }
  }

// Template usage analytics
  Future<Map<String, dynamic>> getTemplateUsageStats() async {
    try {
      // This would track which templates are used most frequently
      // For now, return basic stats
      final templates = await getAvailableQuoteTemplates();

      return {
        'totalActiveTemplates': templates.length,
        'templatesByType': {
          'quote': templates.where((t) => t.templateType == 'quote').length,
          'invoice': templates.where((t) => t.templateType == 'invoice').length,
          'estimate': templates.where((t) => t.templateType == 'estimate').length,
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template usage stats: $e');
      }
      return {};
    }
  }

}


