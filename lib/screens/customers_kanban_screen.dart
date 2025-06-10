import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/app_state_provider.dart';
import '../widgets/customer_card.dart';
import 'customer_detail_screen.dart';

class CustomersKanbanScreen extends StatefulWidget {
  const CustomersKanbanScreen({super.key});

  @override
  State<CustomersKanbanScreen> createState() => _CustomersKanbanScreenState();
}

class _CustomersKanbanScreenState extends State<CustomersKanbanScreen> {
  String? _selectedBoardId;
  final Map<String, String> _sortBy = {}; // stageId -> sort mode

  @override
  void initState() {
    super.initState();
    final boards =
        Provider.of<AppStateProvider>(context, listen: false).appSettings?.kanbanBoards;
    if (boards != null && boards.isNotEmpty) {
      _selectedBoardId = boards.first.id;
      for (final stage in boards.first.stages) {
        _sortBy[stage.id] = 'priority';
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              final boards = appState.appSettings?.kanbanBoards ?? [];
              if (boards.isEmpty) return const SizedBox.shrink();
              return DropdownButton<String>(
                value: _selectedBoardId ?? boards.first.id,
                underline: const SizedBox(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBoardId = value;
                    });
                  }
                },
                items: boards
                    .map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          final boards = appState.appSettings?.kanbanBoards ?? [];
          if (boards.isEmpty) return const SizedBox();
          final board = boards.firstWhere(
            (b) => b.id == (_selectedBoardId ?? boards.first.id),
            orElse: () => boards.first,
          );
          final stages = board.stages;
          for (final stage in stages) {
            _sortBy.putIfAbsent(stage.id, () => 'priority');
          }
          final Map<String, List<Customer>> grouped = {
            for (final stage in stages) stage.id: [],
          };
          for (final customer in appState.customers
              .where((c) => c.boardId == board.id)) {
            grouped.putIfAbsent(customer.stage, () => []).add(customer);
          }
          for (final stage in stages) {
            final customers = grouped[stage.id];
            if (customers == null) continue;
            customers.sort((a, b) => _compareCustomers(
                a, b, _sortBy[stage.id] ?? 'priority', appState));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stages.map((stage) {
                final customers = grouped[stage.id] ?? [];
                return DragTarget<Customer>(
                  onWillAccept: (data) => data != null && data.stage != stage.id,
                  onAccept: (customer) {
                    customer
                      ..stage = stage.id
                      ..updatedAt = DateTime.now();
                    appState.updateCustomer(customer);
                  },
                  builder: (context, candidate, rejected) {
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Color(stage.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stage.name.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Color(stage.color)),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) => setState(() {
                                    _sortBy[stage.id] = value;
                                  }),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'priority', child: Text('Priority')),
                                    const PopupMenuItem(value: 'next', child: Text('Next Action')),
                                    const PopupMenuItem(value: 'deal', child: Text('Deal Value')),
                                    const PopupMenuItem(value: 'days', child: Text('Days Stuck')),
                                  ],
                                  icon: const Icon(Icons.sort, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: candidate.isNotEmpty
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: customers.isEmpty
                                  ? const Center(child: Text('No customers'))
                                  : ListView.builder(
                                      itemCount: customers.length,
                                      itemBuilder: (context, index) {
                                        final customer = customers[index];
                                        final stageName = stage.name;
                                        return LongPressDraggable<Customer>(
                                          data: customer,
                                          feedback: Material(
                                            color: Colors.transparent,
                                            child: SizedBox(
                                              width: 280,
                                              child: CustomerCard(
                                                customer: customer,
                                                quoteCount: appState.getSimplifiedQuotesForCustomer(customer.id).length,
                                                stageLabel: stageName,
                                                stageColor: Color(stage.color),
                                                urgencyColor: _getUrgencyColor(appState, customer),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.5,
                                            child: CustomerCard(
                                              customer: customer,
                                              quoteCount: appState.getSimplifiedQuotesForCustomer(customer.id).length,
                                              stageLabel: stageName,
                                              stageColor: Color(stage.color),
                                              urgencyColor: _getUrgencyColor(appState, customer),
                                            ),
                                          ),
                                          child: CustomerCard(
                                            customer: customer,
                                            quoteCount: appState.getSimplifiedQuotesForCustomer(customer.id).length,
                                            stageLabel: stageName,
                                            stageColor: Color(stage.color),
                                            urgencyColor: _getUrgencyColor(appState, customer),
                                            onTap: () => _showCustomerDetailDrawer(customer),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getUrgencyColor(AppStateProvider appState, Customer customer) {
    final settings = appState.appSettings;
    if (settings == null) return Colors.white;
    final daysIdle = DateTime.now().difference(customer.updatedAt).inDays;
    if (daysIdle >= settings.redThresholdDays) return Colors.red.shade100;
    if (daysIdle >= settings.orangeThresholdDays) return Colors.orange.shade100;
    if (daysIdle >= settings.yellowThresholdDays) return Colors.yellow.shade100;
    return Colors.white;
  }

  int _urgencyLevel(AppStateProvider appState, Customer customer) {
    final settings = appState.appSettings;
    if (settings == null) return 0;
    final daysIdle = DateTime.now().difference(customer.updatedAt).inDays;
    if (daysIdle >= settings.redThresholdDays) return 3;
    if (daysIdle >= settings.orangeThresholdDays) return 2;
    if (daysIdle >= settings.yellowThresholdDays) return 1;
    return 0;
  }

  DateTime? _getNextActionDate(Customer customer) {
    final regex = RegExp(r'FOLLOW-UP \(([0-9-]+)\)');
    DateTime? next;
    final now = DateTime.now();
    for (final entry in customer.communicationHistory) {
      final match = regex.firstMatch(entry);
      if (match != null) {
        final date = DateTime.tryParse(match.group(1)!);
        if (date != null && date.isAfter(now)) {
          if (next == null || date.isBefore(next)) next = date;
        }
      }
    }
    return next;
  }

  double _getDealValue(AppStateProvider appState, Customer customer) {
    final quotes = appState.getSimplifiedQuotesForCustomer(customer.id);
    double maxValue = 0.0;
    for (final q in quotes) {
      if (q.levels.isEmpty) continue;
      final total = q.calculateFinalTotal(
        selectedLevelId: q.levels.first.id,
        selectedAddons: q.addons,
      );
      if (total > maxValue) maxValue = total;
    }
    return maxValue;
  }

  int _compareCustomers(Customer a, Customer b, String mode, AppStateProvider appState) {
    switch (mode) {
      case 'next':
        final aDate = _getNextActionDate(a) ?? DateTime(9999);
        final bDate = _getNextActionDate(b) ?? DateTime(9999);
        return aDate.compareTo(bDate);
      case 'deal':
        final aVal = _getDealValue(appState, a);
        final bVal = _getDealValue(appState, b);
        return bVal.compareTo(aVal);
      case 'days':
        final aDays = DateTime.now().difference(a.updatedAt).inDays;
        final bDays = DateTime.now().difference(b.updatedAt).inDays;
        return bDays.compareTo(aDays);
      default:
        final aUrg = _urgencyLevel(appState, a);
        final bUrg = _urgencyLevel(appState, b);
        if (aUrg != bUrg) return bUrg - aUrg;
        final aDays2 = DateTime.now().difference(a.updatedAt).inDays;
        final bDays2 = DateTime.now().difference(b.updatedAt).inDays;
        return bDays2.compareTo(aDays2);
    }
  }

  void _showCustomerDetailDrawer(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.95,
          child: CustomerDetailScreen(customer: customer),
        ),
      ),
    );
  }
}
