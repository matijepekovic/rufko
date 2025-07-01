import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/business/customer.dart';

class RecentCustomersService {
  static const String _recentCustomersKey = 'recent_customers';
  static const int _maxRecentCustomers = 10;

  // Get recent customer IDs from storage
  static Future<List<String>> _getRecentCustomerIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentCustomersKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  // Save recent customer IDs to storage
  static Future<void> _saveRecentCustomerIds(List<String> customerIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(customerIds);
      await prefs.setString(_recentCustomersKey, jsonString);
    } catch (e) {
      // Silently handle storage errors
    }
  }

  // Add a customer to recent list
  static Future<void> addRecentCustomer(String customerId) async {
    final recentIds = await _getRecentCustomerIds();
    
    // Remove if already exists (to move to front)
    recentIds.remove(customerId);
    
    // Add to front
    recentIds.insert(0, customerId);
    
    // Limit to max count
    if (recentIds.length > _maxRecentCustomers) {
      recentIds.removeRange(_maxRecentCustomers, recentIds.length);
    }
    
    await _saveRecentCustomerIds(recentIds);
  }

  // Get recent customers from a list of all customers
  static Future<List<Customer>> getRecentCustomers(List<Customer> allCustomers) async {
    final recentIds = await _getRecentCustomerIds();
    final recentCustomers = <Customer>[];
    
    // Find customers by ID in order of recency
    for (final id in recentIds) {
      try {
        final customer = allCustomers.firstWhere((c) => c.id == id);
        recentCustomers.add(customer);
      } catch (e) {
        // Customer not found (may have been deleted), continue
      }
    }
    
    return recentCustomers;
  }

  // Remove a customer from recent list
  static Future<void> removeRecentCustomer(String customerId) async {
    final recentIds = await _getRecentCustomerIds();
    recentIds.remove(customerId);
    await _saveRecentCustomerIds(recentIds);
  }

  // Clear all recent customers
  static Future<void> clearRecentCustomers() async {
    await _saveRecentCustomerIds([]);
  }

  // Check if a customer is in recent list
  static Future<bool> isRecentCustomer(String customerId) async {
    final recentIds = await _getRecentCustomerIds();
    return recentIds.contains(customerId);
  }

  // Get count of recent customers
  static Future<int> getRecentCustomerCount() async {
    final recentIds = await _getRecentCustomerIds();
    return recentIds.length;
  }

  // Clean up recent customers (remove deleted customer IDs)
  static Future<void> cleanupRecentCustomers(List<Customer> allCustomers) async {
    final recentIds = await _getRecentCustomerIds();
    final validIds = allCustomers.map((c) => c.id).toSet();
    
    // Keep only IDs that still exist
    final cleanedIds = recentIds.where((id) => validIds.contains(id)).toList();
    
    if (cleanedIds.length != recentIds.length) {
      await _saveRecentCustomerIds(cleanedIds);
    }
  }
}