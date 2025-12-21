import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../services/admin_service.dart';
import '../hr/common/empty_error_state.dart';
import '../hr/widgets/approved_leave_widgets.dart';

/// Dashboard dành riêng cho Admin: duyệt đơn nghỉ ở pha Admin.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();

  // Leave (Admin phase)
  List<Map<String, dynamic>> _pendingLeaveAdmin = [];
  bool _loadingLeave = false;
  String? _errorLeave;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final result = await showDialog<bool>(
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
                      action == 'APPROVE' 
                          ? 'admin.dashboard.approveLeaveRequest'.tr()
                          : 'admin.dashboard.rejectLeaveRequest'.tr(),
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
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'admin.dashboard.noteOptional'.tr(),
                  hintText: 'admin.dashboard.enterNoteIfAny'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900]!.withOpacity(0.3) : Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'admin.dashboard.cancel'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (action == 'APPROVE' ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                .withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, true),
                          borderRadius: BorderRadius.circular(12),
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
                                  action == 'APPROVE' 
                                      ? 'admin.dashboard.approve'.tr()
                                      : 'admin.dashboard.reject'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
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
    if (result != true) {
      return;
    }

    final leaveId = item['id'] ?? item['leaveRequestId'];
    if (leaveId == null) {
      Fluttertoast.showToast(msg: 'admin.dashboard.missingLeaveRequestId'.tr());
      return;
    }

    try {
      await _adminService.processLeaveRequest(
        leaveRequestId: int.parse(leaveId.toString()),
        action: action,
        comment: noteController.text,
      );
      Fluttertoast.showToast(msg: 'admin.dashboard.leaveRequestProcessed'.tr());
      _loadLeaveRequests();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  bool _hasBack(BuildContext context) => context.canPop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => _hasBack(context) ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'admin.dashboard.title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.grey[800]!.withOpacity(0.3)
                : Colors.grey[200]!.withOpacity(0.5),
          ),
        ),
      ),
      body: _LeaveTab(
        title: 'admin.dashboard.pendingLeaveRequests'.tr(),
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
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
        ),
      );
    }
    if (error != null) {
      return EmptyErrorState(error: error, onRetry: onRefresh);
    }
    if (items.isEmpty) {
      return const LeaveEmptyState();
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFDC2626),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return LeaveRequestCard(
            item: items[index],
            onApprove: () => onApprove(items[index]),
            onReject: () => onReject(items[index]),
          );
        },
      ),
    );
  }
}


