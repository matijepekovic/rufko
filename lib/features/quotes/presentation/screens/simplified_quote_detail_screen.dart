// lib/screens/simplified_quote_detail_screen.dart - ENHANCED WITH DISCOUNTS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/pdf_generation_controller.dart';
import '../controllers/quote_detail_controller.dart';
import '../controllers/quote_totals_controller.dart';
import '../controllers/quote_status_ui_controller.dart';
import '../widgets/quote_detail/quote_detail_handler.dart';
import 'pdf_preview_screen.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_text_mixin.dart';
import '../../../../core/mixins/ui/responsive_widget_mixin.dart';
import '../widgets/sections/discounts_section.dart';
import '../widgets/cards/level_details_card.dart';
import '../widgets/cards/level_selector_card.dart';
import '../widgets/cards/quote_header_card.dart';
import '../widgets/cards/quote_total_card.dart';
import '../widgets/sections/addons_section.dart';
import '../widgets/dialogs/quote_version_history_dialog.dart';

import 'simplified_quote_screen.dart';

class SimplifiedQuoteDetailScreen extends StatefulWidget {
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  final bool isHistoricalVersion;

  const SimplifiedQuoteDetailScreen({
    super.key,
    required this.quote,
    required this.customer,
    this.isHistoricalVersion = false,
  });

  @override
  State<SimplifiedQuoteDetailScreen> createState() =>
      _SimplifiedQuoteDetailScreenState();
}

class _SimplifiedQuoteDetailScreenState
    extends State<SimplifiedQuoteDetailScreen>
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin {
  late final QuoteDetailController _controller;
  late PDFGenerationController _pdfController;
  late QuoteTotalsController _totalsController;
  late QuoteStatusUIController _statusController;
  
  // Key to access the QuoteDetailHandler methods
  final GlobalKey<State<QuoteDetailHandler>> _detailHandlerKey = GlobalKey();
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _controller = QuoteDetailController(
      quote: widget.quote,
      customer: widget.customer,
      context: context,
    );
    _totalsController = QuoteTotalsController(
      quote: widget.quote,
      selectedLevelId: _controller.selectedLevelId ?? '',
    );
    _pdfController = PDFGenerationController(
      quote: widget.quote,
      customer: widget.customer,
      selectedLevelId: _controller.selectedLevelId,
    );
    _statusController = QuoteStatusUIController.fromContext(context);
    
    // Add listener for status changes to refresh the UI
    _statusController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    _controller.addListener(() {
      setState(() {});
      _pdfController.selectedLevelId = _controller.selectedLevelId;
      if (_controller.selectedLevelId != null) {
        _totalsController.selectedLevelId = _controller.selectedLevelId!;
      }
      
      // Handle PDF generation results
      final pdfResult = _controller.uiController.lastGeneratedPdf;
      if (pdfResult != null) {
        // Navigate to PDF preview screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  pdfPath: pdfResult.pdfPath,
                  suggestedFileName: pdfResult.suggestedFileName,
                  quote: widget.quote,
                  customer: widget.customer,
                  templateId: pdfResult.templateId,
                  selectedLevelId: _controller.selectedLevelId,
                  originalCustomData: pdfResult.customData,
                ),
              ),
            );
            // Clear the result after navigation
            _controller.uiController.clearMessages();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        // Get the latest version of the quote from the app state
        final latestQuote = appState.simplifiedQuotes.firstWhere(
          (q) => q.id == widget.quote.id,
          orElse: () => widget.quote,
        );
        
        return _controller.createQuoteDetailHandler(
          key: _detailHandlerKey,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: false,
                    pinned: true,
                    backgroundColor: RufkoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              RufkoTheme.primaryColor,
                              RufkoTheme.primaryDarkColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                    title: Text('Quote ${latestQuote.quoteNumber} v${latestQuote.version}'),
                    actions: widget.isHistoricalVersion 
                      ? [] // No actions for historical versions
                      : [
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: () => _showVersionHistory(latestQuote),
                        color: Colors.white,
                        tooltip: 'View Version History',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _editQuote,
                        color: Colors.white,
                        tooltip: 'Edit Quote',
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (action) {
                          final handlerState = _detailHandlerKey.currentState;
                          if (handlerState != null) {
                            (handlerState as dynamic).handleMenuAction(action);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Rename'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Quote',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ];
              },
              body: SingleChildScrollView(
                padding: EdgeInsets.all(spacingSM(context) * 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuoteHeader(latestQuote),
                    SizedBox(height: spacingXL(context)),
                    _buildLevelSelector(latestQuote),
                    SizedBox(height: spacingXL(context)),
                    if (_controller.selectedLevelId != null)
                      _buildSelectedLevelDetails(latestQuote),
                    SizedBox(height: spacingXL(context)),
                    AddonsSection(
                        quote: latestQuote, currencyFormat: _currencyFormat),
                    SizedBox(height: spacingXL(context)),
                    _buildDiscountsSection(latestQuote),
                    SizedBox(height: spacingXL(context)),
                    _buildTotalSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(latestQuote),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuoteHeader(SimplifiedMultiLevelQuote quote) {
    return QuoteHeaderCard(
      quote: quote,
      customer: widget.customer,
    );
  }

  Widget _buildLevelSelector(SimplifiedMultiLevelQuote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LevelSelectorCard(
          levels: quote.levels,
          selectedLevelId: _controller.selectedLevelId,
          onLevelSelected: _controller.selectLevel,
          currencyFormat: _currencyFormat,
          getTotalForLevel: quote.getDisplayTotalForLevel,
        ),
        const SizedBox(height: 16),
        if (_controller.selectedLevelId != null && quote.levels.length > 1)
          Center(
            child: ElevatedButton.icon(
              onPressed: _controller.uiController.isProcessing ? null : () => _extractLevel(),
              icon: _controller.uiController.isProcessing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.content_copy),
              label: Text(_controller.uiController.isProcessing ? 'Extracting...' : 'Extract for contract'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedLevelDetails(SimplifiedMultiLevelQuote quote) {
    final level = quote.levels
        .firstWhere((l) => l.id == _controller.selectedLevelId!);
    return LevelDetailsCard(
      level: level,
      quote: quote,
      currencyFormat: _currencyFormat,
    );
  }

  Widget _buildDiscountsSection(SimplifiedMultiLevelQuote quote) {
    return DiscountsSection(
      discounts: quote.discounts,
      selectedLevelId: _controller.selectedLevelId,
      quote: quote,
      // No add/remove callbacks - read-only in detail view
      currencyFormat: _currencyFormat,
    );
  }

  // Discount item and summary UI moved to DiscountsSection widget

  Widget _buildTotalSection() {
    if (_controller.selectedLevelId == null) return const SizedBox.shrink();
    return QuoteTotalCard(
      controller: _totalsController,
      currencyFormat: _currencyFormat,
    );
  }

  Widget _buildActionButtons(SimplifiedMultiLevelQuote quote) {
    final status = quote.status.toLowerCase();
    
    switch (status) {
      case 'draft':
        return _buildDraftActions(quote);
      case 'pdf_generated':
        return _buildPdfGeneratedActions(quote);
      case 'sent':
        return _buildSentActions(quote);
      case 'accepted':
        return _buildAcceptedActions(quote);
      case 'declined':
        return _buildDeclinedActions(quote);
      case 'complete':
        return _buildCompleteActions(quote);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDraftActions(SimplifiedMultiLevelQuote quote) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _controller.uiController.generatePdf(context: context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfGeneratedActions(SimplifiedMultiLevelQuote quote) {
    // Check if PDF is outdated - if so, show Generate PDF instead of Preview
    final bool isPdfOutdated = quote.isPdfOutdated;
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPdfOutdated 
                ? () => _controller.uiController.generatePdf(context: context)
                : _previewPdf,
            icon: Icon(isPdfOutdated ? Icons.picture_as_pdf : Icons.preview),
            label: Text(isPdfOutdated ? 'Generate PDF' : 'Preview PDF'),
          ),
        ),
        SizedBox(width: spacingMD(context)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _controller.uiController.sendPdfViaEmail(context),
            icon: const Icon(Icons.email),
            label: const Text('Send to Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSentActions(SimplifiedMultiLevelQuote quote) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _statusController.handleMarkAccepted(context, quote),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark Accepted'),
          ),
        ),
        SizedBox(width: spacingMD(context)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _statusController.handleMarkDeclined(context, quote),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.cancel),
            label: const Text('Mark Declined'),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptedActions(SimplifiedMultiLevelQuote quote) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _statusController.handleMarkComplete(context, quote),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.done_all),
            label: const Text('Mark Complete'),
          ),
        ),
      ],
    );
  }

  Widget _buildDeclinedActions(SimplifiedMultiLevelQuote quote) {
    // No main buttons for declined quotes - use Edit Quote in top bar
    return const SizedBox.shrink();
  }

  Widget _buildCompleteActions(SimplifiedMultiLevelQuote quote) {
    // No main buttons for complete quotes - job is done
    return const SizedBox.shrink();
  }


  void _editQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteScreen(
          customer: widget.customer,
          existingQuote: widget.quote, // Pass the quote to edit
          roofScopeData: widget.quote.roofScopeDataId != null
              ? context
                  .read<AppStateProvider>()
                  .roofScopeDataList
                  .where((rs) => rs.id == widget.quote.roofScopeDataId)
                  .firstOrNull
              : null,
        ),
      ),
    );
  }

  // PDF preview method using smart preview logic
  Future<void> _previewPdf() async {
    // Use the smart preview method - checks for existing PDF first
    // This will trigger the listener which handles navigation
    await _controller.uiController.previewExistingOrGeneratePdf(context: context);
  }


  /// Show version history dialog
  Future<void> _showVersionHistory(SimplifiedMultiLevelQuote quote) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuoteVersionHistoryDialog(
          quote: quote,
          customer: widget.customer,
        );
      },
    );
  }

  /// Extract the selected level as a new single-level quote
  Future<void> _extractLevel() async {
    final confirmed = await _showExtractConfirmationDialog();
    if (!confirmed) return;

    try {
      final extractedQuote = await _controller.uiController.extractLevel();
      
      if (extractedQuote != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Level extracted as new quote: ${extractedQuote.quoteNumber}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SimplifiedQuoteDetailScreen(
                      quote: extractedQuote,
                      customer: widget.customer,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to extract level: No quote was created'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extraction timed out. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to extract level';
        if (e.toString().contains('database')) {
          errorMessage = 'Database error. Please try again in a moment.';
        } else if (e.toString().contains('locked')) {
          errorMessage = 'Database busy. Please wait and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage\n\nError: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _extractLevel(),
            ),
          ),
        );
      }
    }
  }

  /// Show confirmation dialog before extracting level
  Future<bool> _showExtractConfirmationDialog() async {
    final selectedLevel = widget.quote.levels.firstWhere(
      (level) => level.id == _controller.selectedLevelId,
    );

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Extract Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will create a new quote with only the selected level:'),
              const SizedBox(height: 8),
              Text(
                '• Level: ${selectedLevel.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Price: ${_currencyFormat.format(widget.quote.getDisplayTotalForLevel(selectedLevel.id))}'),
              const SizedBox(height: 12),
              const Text(
                'The original multi-level quote will remain unchanged.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Extract Level'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // PDF generation, template selection and status updates are handled
  // by the dedicated controllers for clarity.
}
