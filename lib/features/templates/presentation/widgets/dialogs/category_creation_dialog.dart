import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

/// Reusable dialog for creating new template categories
/// Extracted from EmailTemplateEditorScreen for reusability
class CategoryCreationDialog extends StatefulWidget {
  final String title;
  final String description;
  final String hintText;
  final Function(String) onCategoryCreated;

  const CategoryCreationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.hintText,
    required this.onCategoryCreated,
  });

  @override
  State<CategoryCreationDialog> createState() => _CategoryCreationDialogState();
}

class _CategoryCreationDialogState extends State<CategoryCreationDialog> {
  final TextEditingController _categoryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: widget.hintText,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 14),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (_) => _handleCreate(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RufkoSecondaryButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          RufkoPrimaryButton(
            onPressed: _isLoading ? null : _handleCreate,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onCategoryCreated(categoryName);
      if (mounted) {
        Navigator.of(context).pop(categoryName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Helper function to show category creation dialog
Future<String?> showCategoryCreationDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String hintText,
  required Function(String) onCategoryCreated,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => CategoryCreationDialog(
      title: title,
      description: description,
      hintText: hintText,
      onCategoryCreated: onCategoryCreated,
    ),
  );
}
