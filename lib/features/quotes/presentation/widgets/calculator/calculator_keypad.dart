import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_constants.dart';

class CalculatorKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final Function(String) onOperatorPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onFxPressed;
  final VoidCallback? onDone;

  const CalculatorKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onOperatorPressed,
    required this.onBackspace,
    required this.onClear,
    required this.onFxPressed,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final keyHeight = context.calculatorKeyHeight;
    final spacing = context.keySpacing;
    
    return Column(
      children: [
        // Row 1: [7] [8] [9] [÷] [%]
        SizedBox(
          height: keyHeight,
          child: Row(
            children: [
              _buildKey(context, '7', KeyType.number, spacing),
              _buildKey(context, '8', KeyType.number, spacing),
              _buildKey(context, '9', KeyType.number, spacing),
              _buildKey(context, '÷', KeyType.operator, spacing),
              _buildKey(context, '%', KeyType.operator, spacing),
            ],
          ),
        ),
        
        SizedBox(height: spacing),
        
        // Row 2: [4] [5] [6] [×] [Clear]
        SizedBox(
          height: keyHeight,
          child: Row(
            children: [
              _buildKey(context, '4', KeyType.number, spacing),
              _buildKey(context, '5', KeyType.number, spacing),
              _buildKey(context, '6', KeyType.number, spacing),
              _buildKey(context, '×', KeyType.operator, spacing),
              _buildSpecialKey(context, 'Clear', null, onClear, KeyType.clear, spacing),
            ],
          ),
        ),
        
        SizedBox(height: spacing),
        
        // Row 3: [1] [2] [3] [−] [⌫]
        SizedBox(
          height: keyHeight,
          child: Row(
            children: [
              _buildKey(context, '1', KeyType.number, spacing),
              _buildKey(context, '2', KeyType.number, spacing),
              _buildKey(context, '3', KeyType.number, spacing),
              _buildKey(context, '−', KeyType.operator, spacing),
              _buildSpecialKey(context, '⌫', Icons.backspace_outlined, onBackspace, KeyType.backspace, spacing),
            ],
          ),
        ),
        
        SizedBox(height: spacing),
        
        // Row 4: [fx] [0] [.] [+] [Done]
        SizedBox(
          height: keyHeight,
          child: Row(
            children: [
              _buildKey(context, 'fx', KeyType.function, spacing),
              _buildKey(context, '0', KeyType.number, spacing),
              _buildKey(context, '.', KeyType.number, spacing),
              _buildKey(context, '+', KeyType.operator, spacing),
              _buildSpecialKey(context, 'Done', null, onDone ?? () {}, KeyType.done, spacing),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(BuildContext context, String label, KeyType type, double spacing) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(spacing),
        child: _CalculatorKey(
          label: label,
          type: type,
          onPressed: () => _handleKeyPress(label, type),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(
    BuildContext context,
    String label,
    IconData? icon,
    VoidCallback onPressed,
    KeyType type,
    double spacing,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(spacing),
        child: _CalculatorKey(
          label: label,
          icon: icon,
          type: type,
          onPressed: onPressed,
        ),
      ),
    );
  }

  void _handleKeyPress(String label, KeyType type) {
    switch (type) {
      case KeyType.number:
        onNumberPressed(label);
        break;
      case KeyType.operator:
        onOperatorPressed(label);
        break;
      case KeyType.function:
        if (label == 'fx') {
          onFxPressed();
        }
        break;
      case KeyType.clear:
      case KeyType.backspace:
      case KeyType.done:
        // Handled by special keys
        break;
    }
  }
}

class _CalculatorKey extends StatefulWidget {
  final String label;
  final IconData? icon;
  final KeyType type;
  final VoidCallback onPressed;

  const _CalculatorKey({
    required this.label,
    this.icon,
    required this.type,
    required this.onPressed,
  });

  @override
  State<_CalculatorKey> createState() => _CalculatorKeyState();
}

class _CalculatorKeyState extends State<_CalculatorKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _resetPress();
  }

  void _onTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color backgroundColor;
    Color foregroundColor;
    Color pressedColor;

    switch (widget.type) {
      case KeyType.number:
        backgroundColor = colorScheme.surfaceContainerHigh;
        foregroundColor = colorScheme.onSurface;
        pressedColor = colorScheme.surfaceContainer;
        break;
      case KeyType.operator:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        pressedColor = colorScheme.primary.withAlpha((0.8 * 255).toInt());
        break;
      case KeyType.function:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.onSecondary;
        pressedColor = colorScheme.secondary.withAlpha((0.8 * 255).toInt());
        break;
      case KeyType.clear:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        pressedColor = colorScheme.errorContainer.withAlpha((0.8 * 255).toInt());
        break;
      case KeyType.backspace:
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurface;
        pressedColor = colorScheme.surfaceContainer;
        break;
      case KeyType.done:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        pressedColor = colorScheme.primary.withAlpha((0.8 * 255).toInt());
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed ? pressedColor : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isPressed
                ? null
                : [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(
                    widget.icon,
                    color: foregroundColor,
                    size: 24,
                  )
                : Text(
                    widget.label,
                    style: (widget.type == KeyType.done || widget.type == KeyType.clear)
                        ? textTheme.labelLarge?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          )
                        : textTheme.headlineSmall?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: widget.type == KeyType.operator ? 'monospace' : null,
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum KeyType {
  number,
  operator,
  function,
  clear,
  backspace,
  done,
}