import 'package:flutter/material.dart';
class QuoteLevelsManagerDialog extends StatefulWidget {
  final List<String> levelNames;
  final Function(List<String>) onSave;

  const QuoteLevelsManagerDialog({super.key,
    required this.levelNames,
    required this.onSave,
  });

  @override
  State<QuoteLevelsManagerDialog> createState() => QuoteLevelsManagerDialogState();
}

class QuoteLevelsManagerDialogState extends State<QuoteLevelsManagerDialog> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.levelNames.map((name) => TextEditingController(text: name)).toList();
    while (_controllers.length < 3) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.layers, color: Colors.purple.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Quote Levels'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Set names for default quote levels used in product pricing.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              labelText: 'Level ${index + 1} Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_controllers.length > 3) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade600),
                            onPressed: () => _removeLevel(index),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addLevel,
              icon: const Icon(Icons.add),
              label: const Text('Add Level'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final levelNames = _controllers
                .map((c) => c.text.trim())
                .where((name) => name.isNotEmpty)
                .toList();
            widget.onSave(levelNames);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addLevel() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeLevel(int index) {
    if (_controllers.length > 3) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
      });
    }
  }
}

