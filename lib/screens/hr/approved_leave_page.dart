import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'common/hr_app_bar.dart';
import 'common/empty_error_state.dart';
import '../../services/hr_service.dart';
import '../../services/admin_service.dart';
import 'widgets/approved_leave_widgets.dart';

class ApprovedLeavePage extends StatefulWidget {
  const ApprovedLeavePage({super.key});

  @override
  State<ApprovedLeavePage> createState() => _ApprovedLeavePageState();
}

class _ApprovedLeavePageState extends State<ApprovedLeavePage> {
  final AdminService _adminService = AdminService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _statusFilter = 'PENDING'; // 'PENDING' hoặc 'PENDING_ADMIN' hoặc 'ALL'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> data = [];
      
      if (_statusFilter == 'PENDING') {
        data = await _adminService.fetchPendingLeaveRequests();
      } else if (_statusFilter == 'PENDING_ADMIN') {
        data = await _adminService.fetchPendingAdminLeaveRequests();
      } else {
        // ALL - lấy cả hai
        final pending = await _adminService.fetchPendingLeaveRequests();
        final pendingAdmin = await _adminService.fetchPendingAdminLeaveRequests();
        data = [...pending, ...pendingAdmin];
      }
      
      setState(() => _items = data);
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = errorMsg);
      Fluttertoast.showToast(
        msg: 'Lỗi: $errorMsg',
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _processLeaveRequest(
    Map<String, dynamic> item,
    String action, // APPROVE hoặc REJECT
  ) async {
    final leaveRequestId = item['id'] ?? item['leaveRequestId'];
    if (leaveRequestId == null) {
      Fluttertoast.showToast(msg: 'Không tìm thấy ID đơn xin nghỉ');
      return;
    }

    String? comment;
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isDark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: action == 'APPROVE'
                            ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                            : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (action == 'APPROVE' ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      action == 'APPROVE' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      action == 'APPROVE' ? 'Duyệt đơn xin nghỉ' : 'Từ chối đơn xin nghỉ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                maxLines: 4,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'Nhập ghi chú nếu cần...',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: action == 'APPROVE' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: action == 'APPROVE'
                              ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                              : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (action == 'APPROVE' ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, true),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  action == 'APPROVE' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  action == 'APPROVE' ? 'Duyệt' : 'Từ chối',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    comment = controller.text.trim().isEmpty ? null : controller.text.trim();

    try {
      await _adminService.processLeaveRequest(
        leaveRequestId: int.parse(leaveRequestId.toString()),
        action: action,
        comment: comment,
      );
      Fluttertoast.showToast(
        msg: action == 'APPROVE' ? 'Đã duyệt đơn xin nghỉ' : 'Đã từ chối đơn xin nghỉ',
      );
      _load();
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: HrAppBar(
        context: context,
        titleText: 'Đơn xin nghỉ cần xử lý',
        onRefresh: _loading ? null : _load,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF6366F1),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      );
    }
    if (_error != null) {
      return EmptyErrorState(error: _error, onRetry: _load);
    }
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _items.isEmpty
              ? const LeaveEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return LeaveRequestCard(
                      item: _items[index],
                      onApprove: () => _processLeaveRequest(_items[index], 'APPROVE'),
                      onReject: () => _processLeaveRequest(_items[index], 'REJECT'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: LeaveFilterChip(
              label: 'PENDING',
              icon: Icons.pending_actions_rounded,
              isSelected: _statusFilter == 'PENDING',
              onTap: () {
                setState(() => _statusFilter = 'PENDING');
                _load();
              },
              isDark: isDark,
              color: const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LeaveFilterChip(
              label: 'PENDING_ADMIN',
              icon: Icons.admin_panel_settings_rounded,
              isSelected: _statusFilter == 'PENDING_ADMIN',
              onTap: () {
                setState(() => _statusFilter = 'PENDING_ADMIN');
                _load();
              },
              isDark: isDark,
              color: const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LeaveFilterChip(
              label: 'Tất cả',
              icon: Icons.list_rounded,
              isSelected: _statusFilter == 'ALL',
              onTap: () {
                setState(() => _statusFilter = 'ALL');
                _load();
              },
              isDark: isDark,
              color: const Color(0xFF6D28D9),
            ),
          ),
        ],
      ),
    );
  }

}
