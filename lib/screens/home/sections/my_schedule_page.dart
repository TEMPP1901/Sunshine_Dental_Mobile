import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/schedule_service.dart';
import 'package:go_router/go_router.dart';

class MySchedulePage extends StatefulWidget {
  const MySchedulePage({super.key});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();
  late DateTime _currentWeekStart;
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Khởi tạo tuần hiện tại (bắt đầu từ thứ 2)
    _currentWeekStart = _getMondayOfWeek(DateTime.now());
    _fetchSchedule();
  }

  // Lấy ngày thứ 2 của tuần chứa ngày truyền vào
  DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Lấy dữ liệu lịch trực tuyến
  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[MySchedulePage] Fetching schedule for week: $_currentWeekStart');
      final schedules = await _scheduleService.getMySchedule(_currentWeekStart);
      debugPrint('[MySchedulePage] Received ${schedules.length} schedules');
      
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MySchedulePage] Error: $e');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _schedules = [];
      });
    }
  }

  // Di chuyển về tuần trước
  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _fetchSchedule();
  }

  // Di chuyển sang tuần sau
  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weekEnd = _currentWeekStart.add(const Duration(days: 5)); // Saturday
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('My Schedule'),
      ),
      body: Column(
        children: [
          // Thanh chọn tuần
          Container(
            padding: const EdgeInsets.all(16.0),
            color: colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousWeek,
                  icon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
                ),
                Column(
                  children: [
                    Text(
                      'Week',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(_currentWeekStart)} - ${dateFormat.format(weekEnd)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _nextWeek,
                  icon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Hiển thị danh sách lịch làm việc
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load schedule',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchSchedule,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _schedules.isEmpty
                        ? Center(
                            child: Text(
                              'No schedules for this week.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _schedules[index];
                              return _buildScheduleCard(schedule);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // Xây dựng card chi tiết cho một lịch làm việc
  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final workDate = DateTime.parse(schedule['workDate']);
    final startTime = schedule['startTime']?.toString().substring(0, 5) ?? '--:--';
    final endTime = schedule['endTime']?.toString().substring(0, 5) ?? '--:--';
    final clinicName = schedule['clinic']?['clinicName'] ?? 'Unknown Clinic';
    final roomName = schedule['room']?['roomName'] ?? 'No Room';
    final status = schedule['status'] ?? 'UNKNOWN';
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor = colorScheme.onSurfaceVariant;
    if (status == 'ACTIVE') statusColor = Colors.green;
    if (status == 'CANCELLED') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM').format(workDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  clinicName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.meeting_room, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  roomName,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
