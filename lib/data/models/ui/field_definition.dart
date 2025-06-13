class FieldDefinition {
  final String appDataType;
  final String displayName;
  final String category;
  final String source;

  const FieldDefinition({
    required this.appDataType,
    required this.displayName,
    required this.category,
    required this.source,
  });

  factory FieldDefinition.fromMap(Map<String, dynamic> map) {
    return FieldDefinition(
      appDataType: map['appDataType'] ?? '',
      displayName: map['displayName'] ?? '',
      category: map['category'] ?? '',
      source: map['source'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appDataType': appDataType,
      'displayName': displayName,
      'category': category,
      'source': source,
    };
  }
}

List<FieldDefinition> generateBaseFieldDefinitions() {
  final defs = <FieldDefinition>[];

  const customerFields = {
    'name': 'Name',
    'streetAddress': 'Street',
    'city': 'City',
    'stateAbbreviation': 'State/Pr.',
    'zipCode': 'Zip/Postal',
    'phone': 'Phone',
    'email': 'Email',
  };
  customerFields.forEach((key, label) {
    defs.add(FieldDefinition(
      appDataType: 'customer${_capitalize(key)}',
      displayName: 'Customer $label',
      category: 'Customer Information',
      source: 'customer.$key',
    ));
  });

  // Derived fields from the full customer name
  defs.addAll(const [
    FieldDefinition(
      appDataType: 'customerFirstName',
      displayName: 'Customer First Name',
      category: 'Customer Information',
      source: 'customer.firstName',
    ),
    FieldDefinition(
      appDataType: 'customerLastName',
      displayName: 'Customer Last Name',
      category: 'Customer Information',
      source: 'customer.lastName',
    ),
  ]);

  const companyFields = {
    'companyName': 'Company Name',
    'companyAddress': 'Company Address',
    'companyPhone': 'Company Phone',
    'companyEmail': 'Company Email',
  };
  companyFields.forEach((key, label) {
    defs.add(FieldDefinition(
      appDataType: key,
      displayName: label,
      category: 'Company Information',
      source: 'settings.$key',
    ));
  });

  const quoteFields = {
    'quoteNumber': 'Quote Number',
    'quoteDate': 'Quote Date',
    'validUntil': 'Valid Until',
    'quoteStatus': 'Quote Status',
    'todaysDate': "Today's Date",
  };
  quoteFields.forEach((key, label) {
    final source = key == 'todaysDate' ? 'system.date' : 'quote.$key';
    defs.add(FieldDefinition(
      appDataType: key,
      displayName: label,
      category: 'Quote Information',
      source: source,
    ));
  });

  for (int i = 1; i <= 3; i++) {
    defs.addAll([
      FieldDefinition(
        appDataType: 'level${i}Name',
        displayName: 'Level $i Name',
        category: 'Quote Levels (3 levels)',
        source: 'quote.level$i.name',
      ),
      FieldDefinition(
        appDataType: 'level${i}Subtotal',
        displayName: 'Level $i Subtotal',
        category: 'Quote Levels (3 levels)',
        source: 'quote.level$i.subtotal',
      ),
      FieldDefinition(
        appDataType: 'level${i}Tax',
        displayName: 'Level $i Tax',
        category: 'Quote Levels (3 levels)',
        source: 'quote.level$i.tax',
      ),
      FieldDefinition(
        appDataType: 'level${i}TotalWithTax',
        displayName: 'Level $i Total',
        category: 'Quote Levels (3 levels)',
        source: 'quote.level$i.total',
      ),
    ]);
  }

  const totals = {
    'subtotal': 'Subtotal',
    'taxRate': 'Tax Rate (%)',
    'taxAmount': 'Tax Amount',
    'discount': 'Discount',
    'grandTotal': 'Grand Total',
  };
  totals.forEach((key, label) {
    defs.add(FieldDefinition(
      appDataType: key,
      displayName: label,
      category: 'Calculations & Totals',
      source: 'quote.$key',
    ));
  });

  const textFields = {
    'notes': 'Notes/Scope',
    'terms': 'Terms & Conditions',
    'upgradeQuoteText': 'Upgrade Quote Details',
  };
  textFields.forEach((key, label) {
    defs.add(FieldDefinition(
      appDataType: key,
      displayName: label,
      category: 'Text & Notes',
      source: 'quote.${key == 'upgradeQuoteText' ? 'upgradeText' : key}',
    ));
  });

  const custom = {
    'customText1': 'Custom Text 1',
    'customText2': 'Custom Text 2',
    'customText3': 'Custom Text 3',
    'customNumeric1': 'Custom Numeric 1',
    'customNumeric2': 'Custom Numeric 2',
    'customDate1': 'Custom Date 1',
    'customDate2': 'Custom Date 2',
    'customBoolean1_for_checkbox': 'Custom Checkbox 1',
    'customBoolean2_for_checkbox': 'Custom Checkbox 2',
  };
  custom.forEach((key, label) {
    defs.add(FieldDefinition(
      appDataType: key,
      displayName: label,
      category: 'Fields',
      source: 'settings.$key',
    ));
  });

  return defs;
}

String _capitalize(String key) => key.isEmpty ? '' : key[0].toUpperCase() + key.substring(1);
