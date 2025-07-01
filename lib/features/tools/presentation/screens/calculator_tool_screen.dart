import 'package:flutter/material.dart';
import '../widgets/formula_builder.dart';
import '../widgets/formula_list.dart';
import '../../../../core/models/calculator/custom_formula.dart';
import '../../../../core/services/calculator/formula_service.dart';
import '../../../../core/services/database/calculator_database_service.dart';

class CalculatorToolScreen extends StatefulWidget {
  const CalculatorToolScreen({super.key});

  @override
  State<CalculatorToolScreen> createState() => _CalculatorToolScreenState();
}

class _CalculatorToolScreenState extends State<CalculatorToolScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FormulaService _formulaService = FormulaService.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDatabase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    try {
      await CalculatorDatabaseService.instance.init();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Handle initialization error
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _showCreateFormulaDialog() {
    showDialog(
      context: context,
      builder: (context) => FormulaBuilder(
        onSave: (formula) async {
          try {
            await _formulaService.createFormula(
              name: formula.name,
              expression: formula.expression,
              description: formula.description,
              category: formula.category,
              isGlobal: formula.isGlobal,
              variables: formula.variables,
            );
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Formula "${formula.name}" created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating formula: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator & Formulas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'Formulas',
            ),
            Tab(
              icon: Icon(Icons.add),
              text: 'Create',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showCreateFormulaDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Formula',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  _showExportDialog();
                  break;
                case 'import':
                  _showImportDialog();
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Formulas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Import Formulas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Calculator...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Formulas list tab
                FormulaList(
                  onFormulaSelected: (formula) {
                    _showEditFormulaDialog(formula);
                  },
                  onFormulaDeleted: (formulaId) async {
                    try {
                      await _formulaService.deleteFormula(formulaId);
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Formula deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting formula: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                
                // Create formula tab
                FormulaBuilder(
                  onSave: (formula) async {
                    try {
                      await _formulaService.createFormula(
                        name: formula.name,
                        expression: formula.expression,
                        description: formula.description,
                        category: formula.category,
                        isGlobal: formula.isGlobal,
                        variables: formula.variables,
                      );
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Formula "${formula.name}" created successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Switch to formulas list tab
                        _tabController.animateTo(0);
                      }
                    } catch (e) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating formula: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: _showCreateFormulaDialog,
              tooltip: 'Create Formula',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showEditFormulaDialog(CustomFormula formula) {
    showDialog(
      context: context,
      builder: (context) => FormulaBuilder(
        formula: formula,
        onSave: (updatedFormula) async {
          try {
            await _formulaService.updateFormula(updatedFormula);
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Formula "${updatedFormula.name}" updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating formula: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Formulas'),
        content: const Text(
          'Export functionality will be implemented in a future update. '
          'This will allow you to share formulas with team members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Formulas'),
        content: const Text(
          'Import functionality will be implemented in a future update. '
          'This will allow you to import formulas from team members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculator Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Creating Formulas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use +, -, ×, ÷ for basic operations'),
              Text('• Use parentheses ( ) for grouping'),
              Text('• Variables: {VariableName}'),
              Text('• Example: {Area} / 100 × 1.1'),
              SizedBox(height: 16),
              Text(
                'Variable Names:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Start with letter or underscore'),
              Text('• Can contain letters, numbers, underscore'),
              Text('• Examples: {Area}, {WastePercent}, {Base_Amount}'),
              SizedBox(height: 16),
              Text(
                'Using in Quotes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap calculator icon in amount fields'),
              Text('• Tap fx button to access formulas'),
              Text('• Enter variable values when prompted'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}