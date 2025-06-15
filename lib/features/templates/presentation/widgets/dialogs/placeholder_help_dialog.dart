import 'package:flutter/material.dart';
import '../../controllers/placeholder_help_controller.dart';
import '../../../../../data/models/templates/email_template.dart';

/// Dialog for showing placeholder help and selection
/// Extracted from EmailTemplateEditorScreen for reusability
class PlaceholderHelpDialog extends StatefulWidget {
  final Function(String) onPlaceholderSelected;
  final PlaceholderHelpController controller;

  const PlaceholderHelpDialog({
    super.key,
    required this.onPlaceholderSelected,
    required this.controller,
  });

  @override
  State<PlaceholderHelpDialog> createState() => _PlaceholderHelpDialogState();
}

class _PlaceholderHelpDialogState extends State<PlaceholderHelpDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      widget.controller.searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            Expanded(child: _buildFieldsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.data_object, color: Colors.orange),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Insert Fields',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search fields...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: widget.controller.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    widget.controller.searchQuery = '';
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsList() {
    final filteredCategories = widget.controller.filteredCategories;
    final customFields = widget.controller.customFields;

    if (filteredCategories.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final categoryName = filteredCategories.keys.elementAt(index);
        final fields = filteredCategories[categoryName]!;
        
        return _buildCategorySection(categoryName, fields, customFields);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No fields found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String categoryName, List<String> fields, List<dynamic> customFields) {
    return ExpansionTile(
      leading: _getCategoryIcon(categoryName),
      title: Text(
        categoryName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        '${fields.length} fields',
        style: const TextStyle(fontSize: 13),
      ),
      children: fields.map((field) => _buildFieldItem(field, customFields)).toList(),
    );
  }

  Widget _buildFieldItem(String appDataType, List<dynamic> customFields) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.data_object,
          size: 18,
          color: Colors.orange,
        ),
      ),
      title: Text(
        EmailTemplate.getFieldDisplayName(appDataType, customFields),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        _getFieldHint(appDataType),
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Icon(Icons.add, color: Colors.orange, size: 16),
      ),
      onTap: () => widget.onPlaceholderSelected(appDataType),
    );
  }

  Widget _getCategoryIcon(String categoryName) {
    IconData iconData;
    Color iconColor;

    if (categoryName.contains('Customer')) {
      iconData = Icons.person;
      iconColor = Colors.blue.shade600;
    } else if (categoryName.contains('Company')) {
      iconData = Icons.business;
      iconColor = Colors.indigo.shade600;
    } else if (categoryName.contains('Quote')) {
      iconData = Icons.description;
      iconColor = Colors.purple.shade600;
    } else if (categoryName.contains('Products')) {
      iconData = Icons.inventory;
      iconColor = Colors.green.shade600;
    } else if (categoryName.contains('Calculations')) {
      iconData = Icons.calculate;
      iconColor = Colors.orange.shade600;
    } else {
      iconData = Icons.settings;
      iconColor = Colors.grey.shade600;
    }
    return Icon(iconData, size: 18, color: iconColor);
  }

  String _getFieldHint(String appDataType) {
    if (appDataType.contains('Name')) return 'Name field';
    if (appDataType.contains('Phone')) return 'Phone number';
    if (appDataType.contains('Email')) return 'Email address';
    if (appDataType.contains('Address')) return 'Address info';
    if (appDataType.contains('company')) return 'Business info';
    if (appDataType.contains('customer')) return 'Customer info';
    if (appDataType.contains('quote')) return 'Quote data';
    return 'Insert field';
  }
}