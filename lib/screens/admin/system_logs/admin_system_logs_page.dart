import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../services/admin_service.dart';

class AdminSystemLogsPage extends StatefulWidget {
  const AdminSystemLogsPage({super.key});

  @override
  State<AdminSystemLogsPage> createState() => _AdminSystemLogsPageState();
}

class _AdminSystemLogsPageState extends State<AdminSystemLogsPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allLogs = [];
  Map<String, List<Map<String, dynamic>>> _groupedLogs = {};
  bool _isLoading = false;
  DateTime? _selectedDate;
  final int _pageSize = 100; // Load nhiều hơn để có đủ dữ liệu

  @override
  void initState() {
    super.initState();
    _loadAllLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLogs() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> allLogs = [];
      int currentPage = 0;
      int totalPages = 1;
      const maxPages = 20; // Giới hạn tối đa 20 pages (2000 logs)
      
      // Load tất cả pages (có giới hạn)
      while (currentPage < totalPages && currentPage < maxPages) {
        final data = await _adminService.fetchAuditLogs(
          fromDate: _selectedDate != null 
              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
              : null,
          toDate: _selectedDate != null
              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
              : null,
          page: currentPage,
          size: _pageSize,
        );
        
        final content = data['content'] as List<Map<String, dynamic>>? ?? [];
        allLogs.addAll(content);
        totalPages = data['totalPages'] ?? 1;
        currentPage++;
        
        // Nếu không còn dữ liệu, dừng lại
        if (content.isEmpty || currentPage >= totalPages) break;
      }
      
      // Nếu đã load đến giới hạn, thông báo
      if (currentPage >= maxPages && totalPages > maxPages) {
        Fluttertoast.showToast(
          msg: 'Đã tải ${allLogs.length} logs gần nhất. Có thêm ${(totalPages - maxPages) * _pageSize} logs cũ hơn.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
      
      // Group logs theo ngày
      _groupLogsByDate(allLogs);
      
      setState(() {
        _allLogs = allLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Không thể tải dữ liệu: $e');
    }
  }

  void _groupLogsByDate(List<Map<String, dynamic>> logs) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final log in logs) {
      final createdAt = log['createdAt']?.toString();
      if (createdAt == null) continue;
      
      try {
        final dt = DateTime.parse(createdAt);
        final dateKey = DateFormat('yyyy-MM-dd').format(dt);
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(log);
      } catch (e) {
        // Skip invalid dates
        continue;
      }
    }
    
    // Sort dates descending (newest first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    final sortedGrouped = <String, List<Map<String, dynamic>>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    
    _groupedLogs = sortedGrouped;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAllLogs();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadAllLogs();
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '--';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('HH:mm:ss').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : colorScheme.surface,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF151B24) : colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: const Text(
          'Nhật ký hệ thống',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadAllLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar with date picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1A2332).withOpacity(0.4)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Date filter button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: _selectedDate != null
                              ? (isDark 
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.primaryContainer.withOpacity(0.4))
                              : (isDark 
                                  ? const Color(0xFF1A2332).withOpacity(0.7)
                                  : colorScheme.surface),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedDate != null
                                ? colorScheme.primary.withOpacity(0.4)
                                : colorScheme.outlineVariant.withOpacity(0.25),
                            width: _selectedDate != null ? 1.5 : 1,
                          ),
                          boxShadow: _selectedDate != null
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _selectedDate != null
                                    ? colorScheme.primary.withOpacity(0.2)
                                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: _selectedDate != null
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                    : 'Chọn ngày',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedDate != null 
                                      ? FontWeight.w700 
                                      : FontWeight.w500,
                                  color: _selectedDate != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _clearDateFilter();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Search field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? const Color(0xFF1A2332).withOpacity(0.7)
                          : colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading && _allLogs.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
                      ),
                    ),
                  )
                : _groupedLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có nhật ký',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedDate != null
                                  ? 'Không có hoạt động nào vào ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'
                                  : 'Chưa có hoạt động nào được ghi lại',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadAllLogs(),
                        color: isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
                        child: _buildGroupedLogsList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedLogsList() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = _searchController.text.toLowerCase();
    
    // Filter logs by search query
    final filteredGroupedLogs = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in _groupedLogs.entries) {
      final filteredLogs = entry.value.where((log) {
        if (searchQuery.isEmpty) return true;
        
        final title = log['title']?.toString().toLowerCase() ?? '';
        final message = log['message']?.toString().toLowerCase() ?? '';
        final action = log['action']?.toString().toLowerCase() ?? '';
        final tableName = log['tableName']?.toString().toLowerCase() ?? '';
        final username = log['user']?['username']?.toString().toLowerCase() ?? '';
        final fullName = log['user']?['fullName']?.toString().toLowerCase() ?? '';
        
        return title.contains(searchQuery) ||
               message.contains(searchQuery) ||
               action.contains(searchQuery) ||
               tableName.contains(searchQuery) ||
               username.contains(searchQuery) ||
               fullName.contains(searchQuery);
      }).toList();
      
      if (filteredLogs.isNotEmpty) {
        filteredGroupedLogs[entry.key] = filteredLogs;
      }
    }
    
    if (filteredGroupedLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredGroupedLogs.length * 2, // Date header + logs
      itemBuilder: (context, index) {
        // Date header
        if (index.isEven) {
          final dateIndex = index ~/ 2;
          final dateKey = filteredGroupedLogs.keys.elementAt(dateIndex);
          final date = DateTime.parse(dateKey);
          
          return _DateHeader(
            date: date,
            logCount: filteredGroupedLogs[dateKey]!.length,
            isDark: isDark,
          );
        }
        // Logs for this date
        else {
          final dateIndex = (index - 1) ~/ 2;
          final dateKey = filteredGroupedLogs.keys.elementAt(dateIndex);
          final logs = filteredGroupedLogs[dateKey]!;
          
          return Column(
            children: logs.map((log) => _LogCard(
              log: log,
              formatDateTime: _formatDateTime,
              isDark: isDark,
            )).toList(),
          );
        }
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final int logCount;
  final bool isDark;

  const _DateHeader({
    required this.date,
    required this.logCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (dateOnly == today) {
      dateText = 'Hôm nay';
    } else if (dateOnly == yesterday) {
      dateText = 'Hôm qua';
    } else {
      dateText = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date);
      // Capitalize first letter
      if (dateText.isNotEmpty) {
        dateText = dateText[0].toUpperCase() + dateText.substring(1);
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.primary.withOpacity(0.08),
                ]
              : [
                  colorScheme.primaryContainer.withOpacity(0.4),
                  colorScheme.primaryContainer.withOpacity(0.2),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.list_rounded,
                  size: 12,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$logCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final String Function(String?) formatDateTime;
  final bool isDark;

  const _LogCard({
    required this.log,
    required this.formatDateTime,
    required this.isDark,
  });

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'ERROR':
        return const Color(0xFFEF4444);
      case 'WARNING':
        return const Color(0xFFF59E0B);
      case 'INFO':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priority = log['priority']?.toString() ?? 'INFO';
    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A2332).withOpacity(0.7)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(isDark ? 0.3 : 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: priorityColor.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDateTime(log['createdAt']?.toString()),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (log['title'] != null)
              Text(
                log['title'].toString(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
            if (log['message'] != null) ...[
              const SizedBox(height: 8),
              Text(
                log['message'].toString(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (log['user'] != null)
                  _InfoChip(
                    icon: Icons.person_outline_rounded,
                    label: log['user']['username']?.toString() ?? 
                           log['user']['fullName']?.toString() ?? 'User',
                    isDark: isDark,
                  ),
                if (log['action'] != null)
                  _InfoChip(
                    icon: Icons.flash_on_rounded,
                    label: log['action'].toString(),
                    isDark: isDark,
                  ),
                if (log['tableName'] != null)
                  _InfoChip(
                    icon: Icons.table_chart_rounded,
                    label: log['tableName'].toString(),
                    isDark: isDark,
                  ),
                if (log['recordId'] != null)
                  _InfoChip(
                    icon: Icons.tag_rounded,
                    label: 'ID: ${log['recordId']}',
                    isDark: isDark,
                  ),
              ],
            ),
            if (log['ipAddr'] != null || log['userAgent'] != null) ...[
              const SizedBox(height: 14),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      colorScheme.outlineVariant.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (log['ipAddr'] != null)
                _InfoRow(
                  icon: Icons.language_rounded,
                  label: 'IP: ${log['ipAddr']}',
                  isDark: isDark,
                ),
              if (log['userAgent'] != null)
                _InfoRow(
                  icon: Icons.devices_rounded,
                  label: log['userAgent'].toString(),
                  isDark: isDark,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon, 
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2A3441).withOpacity(0.6)
            : colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 13,
              color: colorScheme.primary.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoRow({
    required this.icon, 
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2A3441).withOpacity(0.5)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              size: 13,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}


