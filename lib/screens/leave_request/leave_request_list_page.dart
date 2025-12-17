import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../services/leave_request_service.dart';

class LeaveRequestListPage extends StatefulWidget {
  const LeaveRequestListPage({super.key});

  @override
  State<LeaveRequestListPage> createState() => _LeaveRequestListPageState();
}

class _LeaveRequestListPageState extends State<LeaveRequestListPage> {
  final LeaveRequestService _leaveRequestService = LeaveRequestService();
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  // Tải danh sách yêu cầu nghỉ của người dùng
  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _leaveRequestService.getMyLeaveRequests();
      setState(() {
        _leaveRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: _error ?? 'Failed to load leave requests');
    }
  }

  // Xử lý hủy yêu cầu nghỉ phép
  Future<void> _handleCancel(int leaveRequestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('leaveRequest.cancelConfirm'.tr()),
        content: Text('leaveRequest.cancelMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _leaveRequestService.cancelLeaveRequest(leaveRequestId);
      Fluttertoast.showToast(msg: 'leaveRequest.cancelSuccess'.tr());
      _loadLeaveRequests();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Màu sắc thể hiện trạng thái
  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      case 'PENDING_ADMIN':
        return Colors.purple; // Màu tím cho trạng thái chờ Admin
      default:
        return Colors.grey;
    }
  }

  // Lấy nhãn trạng thái tiếng Anh
  String _getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return 'leaveRequest.status.approved'.tr();
      case 'REJECTED':
        return 'leaveRequest.status.rejected'.tr();
      case 'PENDING':
        return 'leaveRequest.status.pending'.tr(); // Pending HR
      case 'PENDING_ADMIN':
        return 'Pending Admin'; // Hoặc thêm key vào file ngôn ngữ
      default:
        return status ?? '';
    }
  }

  // Lấy nhãn loại nghỉ phép tiếng Anh
  String _getTypeLabel(String? type) {
    switch (type?.toUpperCase()) {
      case 'VACATION':
        return 'leaveRequest.types.vacation'.tr();
      case 'SICK':
        return 'leaveRequest.types.sick'.tr();
      case 'PERSONAL':
        return 'leaveRequest.types.personal'.tr();
      case 'OTHER':
        return 'leaveRequest.types.other'.tr();
      default:
        return type ?? '';
    }
  }

  // Lấy ca làm việc tiếng Anh
  String _getShiftTypeLabel(String? shiftType) {
    if (shiftType == null ||
        shiftType.isEmpty ||
        shiftType.toUpperCase() == 'FULL_DAY') {
      return 'leaveRequest.shiftTypes.fullDay'.tr();
    }
    switch (shiftType.toUpperCase()) {
      case 'MORNING':
        return 'leaveRequest.shiftTypes.morning'.tr();
      case 'AFTERNOON':
        return 'leaveRequest.shiftTypes.afternoon'.tr();
      default:
        return shiftType;
    }
  }

  // Định dạng ngày tháng năm
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text('Leave requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push('/leave-request/create');
              if (result == true) {
                _loadLeaveRequests();
              }
            },
            tooltip: 'Create new request',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLeaveRequests,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : _leaveRequests.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 80,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No leave requests available yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await context.push(
                          '/leave-request/create',
                        );
                        if (result == true) {
                          _loadLeaveRequests();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text('Create new request'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLeaveRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _leaveRequests.length,
                itemBuilder: (context, index) {
                  final request = _leaveRequests[index];
                  final status = request['status']?.toString();
                  final statusColor = _getStatusColor(status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _getTypeLabel(request['type']?.toString()),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: statusColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  _getStatusLabel(status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatDate(request['startDate']?.toString())} - ${_formatDate(request['endDate']?.toString())}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (request['shiftType'] != null &&
                              request['shiftType'].toString().toUpperCase() !=
                                  'FULL_DAY') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Shift type: ${_getShiftTypeLabel(request['shiftType']?.toString())}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (request['clinicName'] != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    request['clinicName'].toString(),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (request['reason'] != null &&
                              request['reason'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      request['reason'].toString(),
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (request['approvedByName'] != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Approved by: ${request['approvedByName']}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (status == 'PENDING') ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _handleCancel(request['id'] as int),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 18,
                                ),
                                label: Text('Cancel request'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
