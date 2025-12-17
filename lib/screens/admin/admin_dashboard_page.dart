import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../services/admin_service.dart';

/// Dashboard dành riêng cho Admin: duyệt đơn nghỉ ở pha Admin.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AdminService _adminService = AdminService();

  // Leave (Admin phase)
  List<Map<String, dynamic>> _pendingLeaveAdmin = [];
  bool _loadingLeave = false;
  String? _errorLeave;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_pendingLeaveAdmin.isEmpty) _loadLeaveRequests();
    });
    _loadLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _loadingLeave = true;
      _errorLeave = null;
    });
    try {
      final data = await _adminService.fetchPendingAdminLeaveRequests();
      setState(() {
        _pendingLeaveAdmin = data;
      });
    } catch (e) {
      setState(() => _errorLeave = e.toString());
    } finally {
      setState(() => _loadingLeave = false);
    }
  }

  Future<void> _handleLeaveAction(
    Map<String, dynamic> item,
    String action,
  ) async {
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'APPROVE' ? 'Duyệt' : 'Từ chối'} đơn nghỉ'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'APPROVE' ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final leaveId = item['id'] ?? item['leaveRequestId'];
    if (leaveId == null) {
      Fluttertoast.showToast(msg: 'Thiếu leaveRequestId');
      return;
    }

    try {
      await _adminService.processLeaveRequest(
        leaveRequestId: int.parse(leaveId.toString()),
        action: action,
        comment: noteController.text,
      );
      Fluttertoast.showToast(msg: 'Đã xử lý đơn nghỉ');
      _loadLeaveRequests();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  bool _hasBack(BuildContext context) => context.canPop();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => _hasBack(context) ? context.pop() : context.go('/home'),
          ),
          title: const Text('Admin Dashboard'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.verified_user_outlined), text: 'Leave (Admin)'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _LeaveTab(
              title: 'Đơn nghỉ chờ Admin',
              loading: _loadingLeave,
              error: _errorLeave,
              items: _pendingLeaveAdmin,
              counts: const {},
              page: 0,
              totalPages: 0,
              onNext: null,
              onPrev: null,
              onStatusFilter: null,
              onRefresh: _loadLeaveRequests,
              onApprove: (item) => _handleLeaveAction(item, 'APPROVE'),
              onReject: (item) => _handleLeaveAction(item, 'REJECT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveTab extends StatelessWidget {
  final String title;
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> counts;
  final int page;
  final int totalPages;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final void Function(String status)? onStatusFilter;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReject;

  const _LeaveTab({
    required this.title,
    required this.loading,
    required this.error,
    required this.items,
    required this.counts,
    required this.page,
    required this.totalPages,
    required this.onNext,
    required this.onPrev,
    required this.onStatusFilter,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRefresh, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text('Không có $title', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 2, // header (counts + filters) + list + pager
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (counts.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: counts.entries
                        .map((e) => Chip(
                              label: Text('${e.key}: ${e.value}'),
                              backgroundColor: colorScheme.surfaceVariant,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (onStatusFilter != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      _StatusFilterChip(label: 'ALL', onTap: () => onStatusFilter!.call('')),
                      _StatusFilterChip(label: 'PENDING', onTap: () => onStatusFilter!.call('PENDING')),
                      _StatusFilterChip(label: 'APPROVED', onTap: () => onStatusFilter!.call('APPROVED')),
                      _StatusFilterChip(label: 'REJECTED', onTap: () => onStatusFilter!.call('REJECTED')),
                      _StatusFilterChip(label: 'PENDING_ADMIN', onTap: () => onStatusFilter!.call('PENDING_ADMIN')),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            );
          }
          if (index == items.length + 1) {
            if (onNext == null || onPrev == null) return const SizedBox.shrink();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trang ${page + 1}/${totalPages == 0 ? 1 : totalPages}'),
                Row(
                  children: [
                    IconButton(
                      onPressed: page > 0 ? onPrev : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: (page + 1 < totalPages) ? onNext : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            );
          }
          final item = items[index - 1];
          final employee = item['fullName'] ?? item['employeeName'] ?? 'Nhân viên';
          final status = item['status']?.toString() ?? '';
          final type = item['type']?.toString() ?? '';
          final range = '${item['startDate'] ?? '--'} - ${item['endDate'] ?? '--'}';
          final reason = item['reason']?.toString() ?? '';
          final shiftType = item['shiftType']?.toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(employee, style: Theme.of(context).textTheme.titleMedium),
                      Chip(label: Text(status)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Loại: $type'),
                  Text('Thời gian: $range'),
                  if (shiftType != null && shiftType.isNotEmpty) Text('Ca: $shiftType'),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Lý do: $reason'),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onReject(item),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => onApprove(item),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Duyệt'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StatusFilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> stats;
  final int page;
  final int totalPages;
  final TextEditingController dateController;
  final TextEditingController clinicController;
  final Future<void> Function() onRefresh;
  final VoidCallback onFilter;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _AttendanceTab({
    required this.loading,
    required this.error,
    required this.items,
    required this.stats,
    required this.page,
    required this.totalPages,
    required this.dateController,
    required this.clinicController,
    required this.onRefresh,
    required this.onFilter,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRefresh, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Ngày (yyyy-MM-dd)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: clinicController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Clinic ID',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onFilter,
                icon: const Icon(Icons.search),
                label: const Text('Lọc'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: stats.entries
                      .map((e) => Chip(
                            label: Text('${e.key}: ${e.value}'),
                            backgroundColor: colorScheme.surfaceVariant,
                          ))
                      .toList(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Không có dữ liệu attendance', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            )
          else
            ...items.map((item) {
              final employee = item['fullName'] ?? item['employeeName'] ?? 'Nhân viên';
              final status = item['status']?.toString() ?? '';
              final checkIn = item['checkInTime']?.toString() ?? item['checkIn']?.toString() ?? '--';
              final checkOut = item['checkOutTime']?.toString() ?? item['checkOut']?.toString() ?? '--';
              final clinic = item['clinicName'] ?? item['clinic'] ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(employee, style: Theme.of(context).textTheme.titleMedium),
                          if (status.isNotEmpty) Chip(label: Text(status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Check-in: $checkIn'),
                      Text('Check-out: $checkOut'),
                      if (clinic.toString().isNotEmpty) Text('Phòng khám: $clinic'),
                    ],
                  ),
                ),
              );
            }),
          if (items.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trang ${page + 1}/${totalPages == 0 ? 1 : totalPages}'),
                Row(
                  children: [
                    IconButton(
                      onPressed: page > 0 ? onPrev : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: (page + 1 < totalPages) ? onNext : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

