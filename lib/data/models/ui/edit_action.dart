class EditAction {
  final String fieldName;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;

  EditAction({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'Edit: $fieldName "$oldValue" → "$newValue"';
}
