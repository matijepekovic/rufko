mixin FieldTypeMixin {
  static const List<String> fieldTypesConst = [
    'text',
    'number',
    'email',
    'phone',
    'multiline',
    'date',
    'currency',
    'checkbox',
  ];

  static const Map<String, String> fieldTypeNamesConst = {
    'text': 'Text',
    'number': 'Number',
    'email': 'Email',
    'phone': 'Phone',
    'multiline': 'Multi-line Text',
    'date': 'Date',
    'currency': 'Currency',
    'checkbox': 'Checkbox',
  };

  List<String> get fieldTypes => fieldTypesConst;
  Map<String, String> get fieldTypeNames => fieldTypeNamesConst;
}
