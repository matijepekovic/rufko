import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/email_template.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/email_template_editor_screen.dart';

class EmailTemplatesTab extends StatefulWidget {
  const EmailTemplatesTab({super.key});

  @override
  State<EmailTemplatesTab> createState() => _EmailTemplatesTabState();
}

class _EmailTemplatesTabState extends State<EmailTemplatesTab> {
  String _searchQuery = '';
  String _selectedCategoryKey = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final templates = _filterTemplates(appState.emailTemplates);
        final grouped = <String, List<EmailTemplate>>{};
        for (final t in templates) {
          final key = t.userCategoryKey ?? 'uncategorized';
          grouped.putIfAbsent(key, () => []).add(t);
        }

        return Column(
          children: [
            _buildSearchAndFilter(appState),
            const SizedBox(height: 16),
            Expanded(
              child: templates.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final key = grouped.keys.elementAt(index);
                        final items = grouped[key]!;
                        return _buildCategorySection(key, items);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search email templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                    future: appState.getAllTemplateCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 40);
                      }
                      final cats = snapshot.data!['email_templates'] ?? [];
                      return Row(
                        children: [
                          _buildFilterChip('All Categories', Icons.view_list, 'all'),
                          ...cats.map((c) => _buildFilterChip(
                              c['name'] as String, Icons.email, c['key'] as String)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, String key) {
    final selected = _selectedCategoryKey == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: selected,
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
        onSelected: (_) {
          setState(() => _selectedCategoryKey = key);
        },
      ),
    );
  }

  Widget _buildCategorySection(String key, List<EmailTemplate> templates) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getCategoryDisplayName(key),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const Spacer(),
                Text('${templates.length} template${templates.length == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          ...templates.map(_buildTemplateCard),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(EmailTemplate template) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.templateName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(dateFormat.format(template.updatedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  List<EmailTemplate> _filterTemplates(List<EmailTemplate> templates) {
    var filtered = templates;
    if (_selectedCategoryKey != 'all') {
      filtered = filtered
          .where((t) => t.userCategoryKey == _selectedCategoryKey)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.templateName.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.subject.toLowerCase().contains(q) ||
              t.emailContent.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  String _getCategoryDisplayName(String key) {
    if (key == 'uncategorized') return 'Uncategorized Templates';
    return '$key Templates';
  }

  void _editTemplate(EmailTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailTemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Email Templates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first email template to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}
