import 'dart:math';
import 'package:intl/intl.dart';
import '../../../data/models/business/customer.dart';

/// Service for generating consistent naming across quotes and PDFs
/// Ensures both follow the same pattern with configurable separators
class NamingService {
  
  /// Generate a standardized identifier for quotes and PDFs
  /// Format: customer-name-yyyy-MM-dd-NNNNN
  /// 
  /// [customer] - The customer object to extract name from
  /// [separator] - Character to use between parts (default: '-' for quotes, '_' for PDFs)
  /// 
  /// Returns: Formatted identifier string
  static String generateIdentifier(Customer customer, {String separator = '-'}) {
    // Process customer name: lowercase, remove special chars, replace spaces
    final customerName = customer.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(' ', separator); // Replace spaces with separator
    
    // Format date as yyyy-MM-dd
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Generate 5-digit random code (10000-99999)
    final random = Random();
    final randomCode = (10000 + random.nextInt(90000)).toString();
    
    // Combine all parts with separator
    return '$customerName$separator$dateStr$separator$randomCode';
  }
  
  /// Generate quote number using hyphen separator
  /// Format: customer-name-yyyy-MM-dd-NNNNN
  static String generateQuoteNumber(Customer customer) {
    return generateIdentifier(customer, separator: '-');
  }
  
  /// Generate PDF filename using underscore separator
  /// Format: customer_name_yyyy-MM-dd_NNNNN.pdf
  static String generatePdfFileName(Customer customer) {
    return '${generateIdentifier(customer, separator: '_')}.pdf';
  }
}