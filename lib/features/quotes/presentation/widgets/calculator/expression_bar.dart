import 'package:flutter/material.dart';
import '../../../../../core/models/calculator/calculator_expression.dart';
import '../../../../../core/utils/responsive_constants.dart';

class ExpressionBar extends StatefulWidget {
  final CalculatorExpression expression;
  final Function(String) onExpressionChanged;

  const ExpressionBar({
    super.key,
    required this.expression,
    required this.onExpressionChanged,
  });

  @override
  State<ExpressionBar> createState() => _ExpressionBarState();
}

class _ExpressionBarState extends State<ExpressionBar> {
  late ScrollController _scrollController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController(text: widget.expression.expression);
  }

  @override
  void didUpdateWidget(ExpressionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression.expression != widget.expression.expression) {
      _textController.text = widget.expression.expression;
      // Auto-scroll to end when expression changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Calculate if we need 2 rows based on text length
    final textStyle = (context.isPhone ? textTheme.titleMedium : textTheme.headlineSmall)?.copyWith(
      color: colorScheme.onInverseSurface,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w500,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(text: widget.expression.expression, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - (context.contentPadding * 2) - 16);
    
    final needsTwoRows = textPainter.didExceedMaxLines || 
                        textPainter.size.height > context.expressionBarHeight * 0.6;
    final dynamicHeight = needsTwoRows ? context.expressionBarHeight * 2 : context.expressionBarHeight;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.contentPadding),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: BoxConstraints(
        minHeight: context.expressionBarHeight,
        maxHeight: dynamicHeight,
      ),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.expression.isValid 
              ? colorScheme.outline.withValues(alpha: 0.3)
              : colorScheme.error,
          width: widget.expression.isValid ? 1 : 2,
        ),
      ),
      child: Row(
        children: [
          // Expression input area
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: widget.onExpressionChanged,
              style: textStyle,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Enter expression...',
                hintStyle: TextStyle(
                  color: colorScheme.onInverseSurface.withValues(alpha: 0.5),
                ),
              ),
              readOnly: false,
              maxLines: needsTwoRows ? 2 : 1,
              minLines: 1,
              scrollController: _scrollController,
            ),
          ),
          
          // Error indicator or result display
          if (widget.expression.error != null)
            Icon(
              Icons.error_outline,
              size: 20,
              color: colorScheme.error,
            )
          else if (widget.expression.hasResult)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '=',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.expression.formattedResult,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}