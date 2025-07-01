import 'package:flutter/material.dart';
class UnitsManagerDialog extends StatefulWidget {
  final List<String> units;
  final String defaultUnit;
  final Function(List<String>, String) onSave;

  const UnitsManagerDialog({super.key,
    required this.units,
    required this.defaultUnit,
    required this.onSave,
  });

  @override
  State<UnitsManagerDialog> createState() => UnitsManagerDialogState();
}

class UnitsManagerDialogState extends State<UnitsManagerDialog> {
  late List<String> _units;
  late String _defaultUnit;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _units = List.from(widget.units);
    _defaultUnit = widget.defaultUnit;
  }

  @override
  void dispose() {
    _addController.dispose();
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
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.straighten, color: Colors.green.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Units'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: InputDecoration(
                            labelText: 'New Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _addUnit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addUnit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _defaultUnit,
                    decoration: InputDecoration(
                      labelText: 'Default Unit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _units.map((unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _defaultUnit = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _units.length,
                itemBuilder: (context, index) {
                  final unit = _units[index];
                  final isDefault = unit == _defaultUnit;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: isDefault ? Colors.green.shade50 : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(
                          isDefault ? Icons.star : Icons.straighten,
                          color: isDefault ? Colors.green.shade700 : Colors.grey[600],
                        ),
                        title: Text(
                          unit,
                          style: TextStyle(
                            fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: isDefault ? const Text('Default unit') : null,
                        trailing: _units.length > 1 && !isDefault
                            ? IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                          onPressed: () => _removeUnit(index),
                        )
                            : null,
                      ),
                    ),
                  );
                },
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
            widget.onSave(_units, _defaultUnit);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addUnit() {
    final newUnit = _addController.text.trim();
    if (newUnit.isNotEmpty && !_units.contains(newUnit)) {
      setState(() {
        _units.add(newUnit);
        _addController.clear();
      });
    }
  }

  void _removeUnit(int index) {
    if (_units.length > 1 && _units[index] != _defaultUnit) {
      setState(() {
        _units.removeAt(index);
      });
    }
  }
}

