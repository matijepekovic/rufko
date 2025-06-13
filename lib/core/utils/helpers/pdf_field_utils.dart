import 'package:flutter/material.dart';

Icon getCategoryIcon(String categoryName) {
  IconData iconData;
  Color iconColor;

  if (categoryName.contains('Customer')) {
    iconData = Icons.person;
    iconColor = Colors.blue.shade600;
  } else if (categoryName.contains('Company')) {
    iconData = Icons.business;
    iconColor = Colors.indigo.shade600;
  } else if (categoryName.contains('Quote')) {
    iconData =
        categoryName.contains('Levels') ? Icons.layers : Icons.description;
    iconColor = Colors.purple.shade600;
  } else if (categoryName.contains('Products')) {
    iconData = Icons.inventory;
    iconColor = Colors.green.shade600;
  } else if (categoryName.contains('Calculations')) {
    iconData = Icons.calculate;
    iconColor = Colors.orange.shade600;
  } else if (categoryName.contains('Text')) {
    iconData = Icons.text_fields;
    iconColor = Colors.teal.shade600;
  } else {
    iconData = Icons.settings;
    iconColor = Colors.grey.shade600;
  }
  return Icon(iconData, size: 18, color: iconColor);
}

String formatPdfFieldName(String name) {
  return name.replaceAll('_', ' ').trim();
}
