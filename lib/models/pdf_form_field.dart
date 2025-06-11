import 'dart:ui';

class PDFFormField {
  final String name;
  final String type;
  final String currentValue;
  final Rect bounds;
  final int pageNumber;
  final bool isRequired;
  final List<String>? options;

  PDFFormField({
    required this.name,
    required this.type,
    required this.currentValue,
    required this.bounds,
    required this.pageNumber,
    this.isRequired = false,
    this.options,
  });

  PDFFormField copyWith({
    String? name,
    String? type,
    String? currentValue,
    Rect? bounds,
    int? pageNumber,
    bool? isRequired,
    List<String>? options,
  }) {
    return PDFFormField(
      name: name ?? this.name,
      type: type ?? this.type,
      currentValue: currentValue ?? this.currentValue,
      bounds: bounds ?? this.bounds,
      pageNumber: pageNumber ?? this.pageNumber,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
    );
  }

  @override
  String toString() => 'PDFFormField($name: $currentValue)';
}
