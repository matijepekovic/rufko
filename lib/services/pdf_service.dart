import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/quote.dart';
import '../models/roof_scope_data.dart';
import '../models/multi_level_quote.dart';

class PdfService {
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  // Generate PDF quote
  Future<String> generateQuotePdf(Quote quote, Customer customer) async {
    try {
      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 20),
              _buildQuoteInfo(quote),
              pw.SizedBox(height: 20),
              _buildItemsTable(quote),
              pw.SizedBox(height: 20),
              _buildTotalsSection(quote),
              pw.SizedBox(height: 30),
              _buildTermsAndConditions(),
              pw.Spacer(),
              _buildFooter(),
            ];
          },
        ),
      );

      // Save PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'quote_${quote.quoteNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      return file.path;
    } catch (e) {
      debugPrint('Error generating PDF quote: $e');
      rethrow;
    }
  }

  // Generate PDF for multi-level quote
  Future<String> generateMultiLevelQuotePdf(MultiLevelQuote quote, Customer customer) async {
    try {
      final pdf = pw.Document();

      // Sort levels by number
      final sortedLevels = quote.levels.values.toList()
        ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 20),
              _buildMultiLevelQuoteInfo(quote),
              pw.SizedBox(height: 20),
              _buildMultiLevelComparison(quote, sortedLevels),
              if (quote.commonItems.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildCommonItemsTable(quote),
              ],
              if (quote.addons.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildAddonsTable(quote),
              ],
              pw.SizedBox(height: 30),
              _buildTermsAndConditions(),
              pw.Spacer(),
              _buildFooter(),
            ];
          },
        ),
      );

      // Save PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'multi_level_quote_${quote.quoteNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('Error generating multi-level quote PDF: $e');
      rethrow;
    }
  }

  // Build PDF header
  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RUFKO ROOFING',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Professional Roofing Solutions',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.Divider(thickness: 2, color: PdfColors.blue800),
        ],
      ),
    );
  }

  // Build customer information section
  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILL TO:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            customer.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (customer.address != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 12)),
          ],
          if (customer.phone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 12)),
          ],
          if (customer.email != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  // Build quote information section
  pw.Widget _buildQuoteInfo(Quote quote) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'QUOTE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Quote #: ${quote.quoteNumber}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 4),
            pw.Text('Date: ${_dateFormat.format(quote.createdAt)}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 4),
            pw.Text('Valid Until: ${_dateFormat.format(quote.validUntil)}',
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // Build multi-level quote info section
  pw.Widget _buildMultiLevelQuoteInfo(MultiLevelQuote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Quote Information',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Quote #: ${quote.quoteNumber}'),
                  pw.Text('Date: ${_dateFormat.format(quote.createdAt)}'),
                  pw.Text('Valid Until: ${_dateFormat.format(quote.validUntil)}'),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: _getStatusColor(quote.status),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  quote.status.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build multi-level comparison table
  pw.Widget _buildMultiLevelComparison(MultiLevelQuote quote, List<LevelQuote> levels) {
    if (levels.isEmpty) {
      return pw.Container();
    }

    // Collect all unique product IDs across all levels
    final allProducts = <String, Map<String, QuoteItem>>{};
    for (final level in levels) {
      for (final item in level.items) {
        if (!allProducts.containsKey(item.productId)) {
          allProducts[item.productId] = {};
        }
        allProducts[item.productId]![level.levelId] = item;
      }
    }

    // Calculate column widths (first column 40%, remaining columns evenly split remaining 60%)
    final levelColumnWidth = (0.60 / levels.length);
    final List<pw.TableColumnWidth> columnWidths = [
      const pw.FlexColumnWidth(0.40),
      ...List.generate(levels.length, (_) => pw.FlexColumnWidth(levelColumnWidth)),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Compare Options',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            for (int i = 0; i < columnWidths.length; i++) i: columnWidths[i],
          },
          children: [
            // Header row with level names and prices
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Product',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                ...levels.map((level) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          level.levelName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _currencyFormat.format(quote.getLevelTotal(level.levelId)),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            // Product rows
            ...allProducts.entries.map((entry) {
              final levelItems = entry.value;
              final firstLevelWithProduct = levelItems.values.first;

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(firstLevelWithProduct.productName),
                  ),
                  ...levels.map((level) {
                    final hasProduct = levelItems.containsKey(level.levelId);
                    if (hasProduct) {
                      final item = levelItems[level.levelId]!;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${item.quantity} ${item.unit}'),
                      );
                    } else {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('—'),
                      );
                    }
                  }),
                ],
              );
            }),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                ...levels.map((level) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _currencyFormat.format(quote.getLevelTotal(level.levelId)),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Build table for common items
  pw.Widget _buildCommonItemsTable(MultiLevelQuote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Common Items (Included in All Options)',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.4),
            1: pw.FlexColumnWidth(0.2),
            2: pw.FlexColumnWidth(0.2),
            3: pw.FlexColumnWidth(0.2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Item rows
            ...quote.commonItems.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(item.productName),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${item.quantity} ${item.unit}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_currencyFormat.format(item.unitPrice)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_currencyFormat.format(item.totalPrice)),
                ),
              ],
            )),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Common Items Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(),
                pw.Container(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _currencyFormat.format(quote.commonSubtotal),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Build table for add-on items
  pw.Widget _buildAddonsTable(MultiLevelQuote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Optional Add-ons',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.4),
            1: pw.FlexColumnWidth(0.2),
            2: pw.FlexColumnWidth(0.2),
            3: pw.FlexColumnWidth(0.2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Add-on', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Add-on rows
            ...quote.addons.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(item.productName),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${item.quantity} ${item.unit}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_currencyFormat.format(item.unitPrice)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_currencyFormat.format(item.totalPrice)),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  // Build items table
  pw.Widget _buildItemsTable(Quote quote) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Description
        1: const pw.FlexColumnWidth(1), // Qty
        2: const pw.FlexColumnWidth(1), // Unit
        3: const pw.FlexColumnWidth(1.5), // Unit Price
        4: const pw.FlexColumnWidth(1.5), // Total
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Qty', isHeader: true, alignment: pw.Alignment.center),
            _buildTableCell('Unit', isHeader: true, alignment: pw.Alignment.center),
            _buildTableCell('Unit Price', isHeader: true, alignment: pw.Alignment.centerRight),
            _buildTableCell('Total', isHeader: true, alignment: pw.Alignment.centerRight),
          ],
        ),
        // Data rows
        ...quote.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.productName),
            _buildTableCell(item.quantity.toStringAsFixed(2), alignment: pw.Alignment.center),
            _buildTableCell(item.unit, alignment: pw.Alignment.center),
            _buildTableCell(_currencyFormat.format(item.unitPrice), alignment: pw.Alignment.centerRight),
            _buildTableCell(_currencyFormat.format(item.totalPrice), alignment: pw.Alignment.centerRight),
          ],
        )),
      ],
    );
  }

  // Build table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Build totals section
  pw.Widget _buildTotalsSection(Quote quote) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow('Subtotal:', quote.subtotal),
            if (quote.discount > 0)
              _buildTotalRow('Discount:', -quote.discount),
            if (quote.taxRate > 0) ...[
              _buildTotalRow('Tax (${quote.taxRate.toStringAsFixed(1)}%):', quote.taxAmount),
            ],
            pw.Divider(),
            _buildTotalRow('TOTAL:', quote.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  // Build total row
  pw.Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Build terms and conditions
  pw.Widget _buildTermsAndConditions() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Terms & Conditions:',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '• Quote valid for 30 days from date issued\n'
              '• 50% deposit required upon acceptance\n'
              '• Balance due upon completion\n'
              '• Materials and workmanship warranty included\n'
              '• Weather delays may affect schedule',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  // Build footer
  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'Thank you for choosing Rufko Roofing!',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  // Extract RoofScope data from PDF
  Future<RoofScopeData?> extractRoofScopeData(String filePath, String customerId) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Load PDF document
      final document = syncfusion.PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        extractedText += syncfusion.PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
      }

      document.dispose();

      // Parse extracted text for roofing measurements
      final roofScopeData = _parseRoofScopeText(extractedText, customerId, file.path);

      return roofScopeData;
    } catch (e) {
      debugPrint('Error extracting RoofScope data: $e');
      return null;
    }
  }

  // Parse RoofScope text for measurements
  RoofScopeData _parseRoofScopeText(String text, String customerId, String sourceFile) {
    final data = RoofScopeData(
      customerId: customerId,
      sourceFileName: sourceFile.split('/').last,
    );

    // Convert to lowercase for easier matching
    final lowerText = text.toLowerCase();

    // Extract roof area (various patterns)
    final roofAreaPatterns = [
      RegExp(r'roof area[:\s]*([0-9,]+\.?[0-9]*)\s*sq\.?\s*ft'),
      RegExp(r'total area[:\s]*([0-9,]+\.?[0-9]*)\s*sq\.?\s*ft'),
      RegExp(r'area[:\s]*([0-9,]+\.?[0-9]*)\s*sq\.?\s*ft'),
    ];

    for (final pattern in roofAreaPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final areaStr = match.group(1)?.replaceAll(',', '') ?? '0';
        data.roofArea = double.tryParse(areaStr) ?? 0.0;
        break;
      }
    }

    // Extract pitch/slope
    final pitchPatterns = [
      RegExp(r'pitch[:\s]*([0-9]+\.?[0-9]*)[/:]([0-9]+)'),
      RegExp(r'slope[:\s]*([0-9]+\.?[0-9]*)[/:]([0-9]+)'),
      RegExp(r'([0-9]+\.?[0-9]*)[/:]([0-9]+)\s*pitch'),
    ];

    for (final pattern in pitchPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final rise = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        final run = double.tryParse(match.group(2) ?? '12') ?? 12.0;
        data.pitch = rise / run * 12; // Convert to pitch per 12"
        break;
      }
    }

    // Extract linear measurements
    final measurements = {
      'ridge': ['ridge', 'ridges'],
      'valley': ['valley', 'valleys'],
      'hip': ['hip', 'hips'],
      'eave': ['eave', 'eaves'],
      'gutter': ['gutter', 'gutters'],
      'perimeter': ['perimeter', 'edge'],
      'flashing': ['flashing', 'flash'],
    };

    measurements.forEach((key, keywords) {
      for (final keyword in keywords) {
        final pattern = RegExp('${keyword}s?[:\\s]*([0-9,]+\\.?[0-9]*)\\s*(?:lin\\.?\\s*)?ft');
        final match = pattern.firstMatch(lowerText);
        if (match != null) {
          final valueStr = match.group(1)?.replaceAll(',', '') ?? '0';
          final value = double.tryParse(valueStr) ?? 0.0;

          switch (key) {
            case 'ridge':
              data.ridgeLength = value;
              break;
            case 'valley':
              data.valleyLength = value;
              break;
            case 'hip':
              data.hipLength = value;
              break;
            case 'eave':
              data.eaveLength = value;
              break;
            case 'gutter':
              data.gutterLength = value;
              break;
            case 'perimeter':
              data.perimeterLength = value;
              break;
            case 'flashing':
              data.flashingLength = value;
              break;
          }
          break;
        }
      }
    });

    // Extract counts
    final chimneyPattern = RegExp(r'chimneys?[:\s]*([0-9]+)');
    final chimneyMatch = chimneyPattern.firstMatch(lowerText);
    if (chimneyMatch != null) {
      data.chimneyCount = int.tryParse(chimneyMatch.group(1) ?? '0') ?? 0;
    }

    final skylightPattern = RegExp(r'skylights?[:\s]*([0-9]+)');
    final skylightMatch = skylightPattern.firstMatch(lowerText);
    if (skylightMatch != null) {
      data.skylightCount = int.tryParse(skylightMatch.group(1) ?? '0') ?? 0;
    }

    // Calculate squares if we have roof area
    if (data.roofArea > 0) {
      data.calculateSquares();
    }

    return data;
  }

  // Validate if PDF is a RoofScope report
  Future<bool> isRoofScopePdf(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      final document = syncfusion.PdfDocument(inputBytes: bytes);

      // Extract text from first page
      String firstPageText = '';
      if (document.pages.count > 0) {
        firstPageText = syncfusion.PdfTextExtractor(document).extractText(startPageIndex: 0, endPageIndex: 0);
      }

      document.dispose();

      // Check for RoofScope indicators
      final lowerText = firstPageText.toLowerCase();
      final roofScopeIndicators = [
        'roofscope',
        'roof scope',
        'aerial measurement',
        'roof report',
        'measurement report',
      ];

      return roofScopeIndicators.any((indicator) => lowerText.contains(indicator));
    } catch (e) {
      debugPrint('Error validating RoofScope PDF: $e');
      return false;
    }
  }

  // Get PDF info
  Future<Map<String, dynamic>> getPdfInfo(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      document.dispose();

      return {
        'fileName': file.uri.pathSegments.last,
        'fileSize': bytes.length,
        'pageCount': pageCount,
        'isRoofScope': await isRoofScopePdf(filePath),
      };
    } catch (e) {
      debugPrint('Error getting PDF info: $e');
      rethrow;
    }
  }

  // Helper function to get color for status
  PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return PdfColors.grey;
      case 'sent':
        return PdfColors.blue;
      case 'accepted':
        return PdfColors.green;
      case 'declined':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }
}