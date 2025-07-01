import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/business/job.dart';
import '../../../../../data/repositories/job_repository.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../screens/job_detail_screen.dart';
import '../../screens/job_form_screen.dart';

/// Job Calendar Tab with interactive calendar view
/// Allows filtering by: active, scheduled, type
class JobCalendarTab extends StatefulWidget {
  const JobCalendarTab({super.key});

  @override
  State<JobCalendarTab> createState() => _JobCalendarTabState();
}

class _JobCalendarTabState extends State<JobCalendarTab> {
  final JobRepository _jobRepository = JobRepository();
  
  late final ValueNotifier<List<Job>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Job>> _events = {};
  List<Job> _allJobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final _dateFormat = DateFormat('MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadJobs();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    
    try {
      final jobs = await _jobRepository.getAllJobs();
      setState(() {
        _allJobs = jobs;
        _buildEventMap();
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  void _buildEventMap() {
    // Always use ALL jobs for calendar markers, not filtered jobs
    // This ensures calendar shows all job markers regardless of active filter
    // Filtering is applied later in _getEventsForDay() for the events list
    final Map<DateTime, List<Job>> newEvents = {};
    
    for (final job in _allJobs) {
      if (job.scheduledStartDate != null) {
        final date = DateTime(
          job.scheduledStartDate!.year,
          job.scheduledStartDate!.month,
          job.scheduledStartDate!.day,
        );
        
        if (newEvents[date] == null) {
          newEvents[date] = [];
        }
        newEvents[date]!.add(job);
      }
    }
    
    setState(() {
      _events = newEvents;
    });
  }


  List<Job> _getEventsForDay(DateTime day) {
    final dayJobs = _events[day] ?? [];
    
    // Apply current filter to the day's jobs
    switch (_selectedFilter) {
      case 'active':
        return dayJobs.where((job) => job.status == JobStatus.active).toList();
      case 'scheduled':
        return dayJobs.where((job) => job.status == JobStatus.scheduled).toList();
      case 'all':
        return dayJobs.where((job) => 
          job.status != JobStatus.cancelled && 
          job.status != JobStatus.complete).toList();
      default:
        // If it's a job type filter, filter by that specific job type
        return dayJobs.where((job) => 
          job.type == _selectedFilter &&
          job.status != JobStatus.cancelled && 
          job.status != JobStatus.complete).toList();
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // No need to rebuild event map - just update the selected day events with new filter
    _selectedEvents.value = _getEventsForDay(_selectedDay!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        _buildCalendar(),
        const SizedBox(height: 8),
        Expanded(child: _buildEventsList()),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final jobTypes = appState.appSettings?.jobTypes ?? JobTypeHelper.defaultJobTypes;
        
        // Build base filters
        final filters = <Map<String, dynamic>>[
          {'key': 'all', 'label': 'All', 'icon': Icons.work_outline},
          {'key': 'active', 'label': 'Active', 'icon': Icons.play_circle_filled},
          {'key': 'scheduled', 'label': 'Scheduled', 'icon': Icons.schedule},
        ];
        
        // Add job type filters
        for (final jobType in jobTypes) {
          IconData icon;
          switch (jobType.toLowerCase()) {
            case 'roof replacement':
              icon = Icons.roofing;
              break;
            case 'roof repair':
              icon = Icons.build;
              break;
            case 'gutter installation':
            case 'gutter repair':
              icon = Icons.water_drop;
              break;
            case 'emergency repair':
              icon = Icons.warning;
              break;
            default:
              icon = Icons.category;
          }
          
          filters.add({
            'key': jobType,
            'label': jobType.length > 12 ? '${jobType.substring(0, 9)}...' : jobType,
            'icon': icon,
          });
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter['key'];
              
              return FilterChip(
                avatar: Icon(
                  filter['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                ),
                label: Text(filter['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(filter['key'] as String);
                  }
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    if (_isLoading) {
      return const SizedBox(
        height: 330,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: TableCalendar<Job>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.grey[600]),
          holidayTextStyle: TextStyle(color: Colors.red[600]),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          formatButtonTextStyle: TextStyle(
            color: Colors.white,
          ),
        ),
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return _buildEventMarkers(events.cast<Job>());
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildEventMarkers(List<Job> jobs) {
    final markers = <Widget>[];
    
    // Group jobs by status
    final activeJobs = jobs.where((j) => j.status == JobStatus.active).length;
    final scheduledJobs = jobs.where((j) => j.status == JobStatus.scheduled).length;
    final overdueJobs = jobs.where((j) => j.isOverdue).length;

    // Add colored dots for different job types
    if (overdueJobs > 0) {
      markers.add(
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    
    if (activeJobs > 0) {
      markers.add(
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    
    if (scheduledJobs > 0) {
      markers.add(
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: markers,
      ),
    );
  }

  Widget _buildEventsList() {
    return ValueListenableBuilder<List<Job>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: const Border(
                  top: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDay != null 
                        ? 'Jobs for ${_dateFormat.format(_selectedDay!)}'
                        : 'Select a date',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (value.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${value.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: value.isEmpty
                  ? _buildEmptyEventsList()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(value[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyEventsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs scheduled',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${_selectedDay != null ? _dateFormat.format(_selectedDay!) : 'this date'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createJobForDate(_selectedDay ?? DateTime.now()),
              icon: const Icon(Icons.add),
              label: const Text('Schedule Job'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getJobStatusColor(job),
          child: Icon(
            _getJobStatusIcon(job),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.customerName),
            if (job.scheduledStartDate != null)
              Text(
                _timeFormat.format(job.scheduledStartDate!),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(job.status),
            if (job.isOverdue)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'OVERDUE',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _viewJobDetails(job),
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case JobStatus.active:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case JobStatus.scheduled:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case JobStatus.complete:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      case JobStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case JobStatus.onHold:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getJobStatusColor(Job job) {
    if (job.isOverdue) return Colors.red;
    
    switch (job.status) {
      case JobStatus.active:
        return Colors.green;
      case JobStatus.scheduled:
        return Colors.blue;
      case JobStatus.complete:
        return Colors.grey;
      case JobStatus.cancelled:
        return Colors.red;
      case JobStatus.onHold:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getJobStatusIcon(Job job) {
    switch (job.status) {
      case JobStatus.active:
        return Icons.play_circle_filled;
      case JobStatus.scheduled:
        return Icons.schedule;
      case JobStatus.complete:
        return Icons.check_circle;
      case JobStatus.cancelled:
        return Icons.cancel;
      case JobStatus.onHold:
        return Icons.pause_circle_filled;
      default:
        return Icons.work;
    }
  }

  void _viewJobDetails(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job),
      ),
    );
  }

  Future<void> _createJobForDate(DateTime date) async {
    // Create a new job with the selected date pre-filled
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JobFormScreen(initialScheduledDate: date),
        fullscreenDialog: true,
      ),
    );
    
    if (result == true) {
      // Job was created, reload the calendar
      _loadJobs();
    }
  }
}