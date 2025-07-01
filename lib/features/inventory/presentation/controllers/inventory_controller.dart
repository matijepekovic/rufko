import 'package:flutter/material.dart';

import '../../../../data/models/business/inventory_item.dart';
import '../../../../data/models/business/inventory_transaction.dart';
import '../../../../data/repositories/inventory_repository.dart';

/// Controller for managing inventory state and operations
/// Handles all inventory-related business logic and state management
class InventoryController extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();

  // State variables
  List<InventoryItem> _inventoryItems = [];
  List<InventoryTransaction> _recentTransactions = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;

  // Getters
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<InventoryTransaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;

  /// Load all inventory items from database
  Future<void> loadInventoryItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _inventoryItems = await _repository.getAllInventoryItems();
      await _loadSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load recent transactions
  Future<void> loadRecentTransactions({int limit = 50}) async {
    try {
      _recentTransactions = await _repository.getRecentTransactions(limit: limit);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load inventory summary statistics
  Future<void> _loadSummary() async {
    try {
      _summary = await _repository.getInventorySummary();
    } catch (e) {
      // Don't set error for summary loading failure
      debugPrint('Failed to load inventory summary: $e');
    }
  }

  /// Add inventory for a product
  Future<bool> addInventory({
    required String productId,
    required int quantity,
    required String reason,
    String? location,
    String? notes,
    int? minimumStock,
    String? userId,
  }) async {
    if (quantity <= 0) {
      _error = 'Quantity must be greater than 0';
      notifyListeners();
      return false;
    }

    try {
      await _repository.addInventoryWithTransaction(
        productId: productId,
        quantityToAdd: quantity,
        reason: reason,
        location: location,
        notes: notes,
        minimumStock: minimumStock,
        userId: userId,
      );

      // Reload inventory to reflect changes
      await loadInventoryItems();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Adjust inventory quantity
  Future<bool> adjustInventory({
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
    String? userId,
  }) async {
    if (newQuantity < 0) {
      _error = 'Quantity cannot be negative';
      notifyListeners();
      return false;
    }

    try {
      await _repository.adjustInventoryWithTransaction(
        inventoryItemId: inventoryItemId,
        newQuantity: newQuantity,
        reason: reason,
        userId: userId,
      );

      // Reload inventory to reflect changes
      await loadInventoryItems();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Quick add to existing inventory
  Future<bool> quickAddInventory({
    required String inventoryItemId,
    required int quantityToAdd,
    String reason = 'Quick add',
    String? userId,
  }) async {
    if (quantityToAdd <= 0) {
      _error = 'Quantity to add must be greater than 0';
      notifyListeners();
      return false;
    }

    try {
      // Get current inventory item to calculate new quantity
      final inventoryItem = await _repository.getInventoryItemById(inventoryItemId);
      if (inventoryItem == null) {
        _error = 'Inventory item not found';
        notifyListeners();
        return false;
      }

      // Use adjustInventoryWithTransaction directly for atomic operation
      await _repository.adjustInventoryWithTransaction(
        inventoryItemId: inventoryItemId,
        newQuantity: inventoryItem.quantity + quantityToAdd,
        reason: reason,
        userId: userId,
      );

      // Reload inventory to reflect changes
      await loadInventoryItems();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Quick remove from existing inventory
  Future<bool> quickRemoveInventory({
    required String inventoryItemId,
    required int quantityToRemove,
    String reason = 'Quick remove',
    String? userId,
  }) async {
    if (quantityToRemove <= 0) {
      _error = 'Quantity to remove must be greater than 0';
      notifyListeners();
      return false;
    }

    try {
      // Get current inventory item to calculate new quantity
      final inventoryItem = await _repository.getInventoryItemById(inventoryItemId);
      if (inventoryItem == null) {
        _error = 'Inventory item not found';
        notifyListeners();
        return false;
      }

      final newQuantity = inventoryItem.quantity - quantityToRemove;
      if (newQuantity < 0) {
        _error = 'Cannot remove more than available quantity (${inventoryItem.quantity})';
        notifyListeners();
        return false;
      }

      // Use adjustInventoryWithTransaction directly for atomic operation
      await _repository.adjustInventoryWithTransaction(
        inventoryItemId: inventoryItemId,
        newQuantity: newQuantity,
        reason: reason,
        userId: userId,
      );

      // Reload inventory to reflect changes
      await loadInventoryItems();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update inventory item details
  Future<bool> updateInventoryItem(InventoryItem item) async {
    try {
      await _repository.updateInventoryItem(item);
      
      // Update local list
      final index = _inventoryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _inventoryItems[index] = item;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete inventory item
  Future<bool> deleteInventoryItem(String inventoryItemId) async {
    try {
      await _repository.deleteInventoryItem(inventoryItemId);
      
      // Remove from local list
      _inventoryItems.removeWhere((item) => item.id == inventoryItemId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get inventory item by product ID
  Future<InventoryItem?> getInventoryByProductId(String productId) async {
    try {
      return await _repository.getInventoryItemByProductId(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get transactions for a specific inventory item
  Future<List<InventoryTransaction>> getTransactionsForItem(String inventoryItemId) async {
    try {
      return await _repository.getTransactionsForItem(inventoryItemId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get low stock items
  Future<List<InventoryItem>> getLowStockItems() async {
    try {
      return await _repository.getLowStockItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems() async {
    try {
      return await _repository.getOutOfStockItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Search inventory items
  Future<List<InventoryItem>> searchInventoryItems(String query) async {
    try {
      return await _repository.searchInventoryItems(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadInventoryItems();
    await loadRecentTransactions();
  }

}