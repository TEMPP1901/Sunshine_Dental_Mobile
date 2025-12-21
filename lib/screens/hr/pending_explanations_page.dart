import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/admin_service.dart';
import '../../services/hr_service.dart';
import 'common/hr_app_bar.dart';
import 'common/empty_error_state.dart';

class PendingExplanationsPage extends StatefulWidget {
  const PendingExplanationsPage({super.key});

  @override
  State<PendingExplanationsPage> createState() => _PendingExplanationsPageState();
}

class _PendingExplanationsPageState extends State<PendingExplanationsPage> {
  final AdminService _adminService = AdminService();
  final HrService _hrService = HrService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int? _selectedClinicId;
  List<Map<String, dynamic>> _clinics = [];

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _load();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await _hrService.fetchClinics();
      setState(() => _clinics = clinics);
    } catch (e) {
      // Ignore clinic loading error
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _adminService.fetchPendingExplanations(
        clinicId: _selectedClinicId,
      );
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _processExplanation(
    Map<String, dynamic> item,
    String action, // APPROVE hoặc REJECT
  ) async {
    final attendanceId = item['attendanceId'] ?? item['id'];
    if (attendanceId == null) {
      Fluttertoast.showToast(msg: 'hr.pendingExplanations.missingId'.tr());
      return;
    }

    String? adminNote;
    if (action == 'REJECT') {
      final controller = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(action == 'APPROVE' ? 'hr.pendingExplanations.approveTitle'.tr() : 'hr.pendingExplanations.rejectTitle'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'hr.pendingExplanations.hrNote'.tr(),
                  hintText: 'hr.pendingExplanations.hrNoteHint'.tr(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('hr.common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: action == 'APPROVE' ? Colors.green : Colors.red,
              ),
              child: Text(action == 'APPROVE' ? 'hr.pendingExplanations.approve'.tr() : 'hr.pendingExplanations.reject'.tr()),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      adminNote = controller.text.trim().isEmpty ? null : controller.text.trim();
    } else {
      // APPROVE - có thể có ghi chú
      final controller = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(action == 'APPROVE' ? 'hr.pendingExplanations.approveTitle'.tr() : 'hr.pendingExplanations.rejectTitle'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'hr.pendingExplanations.hrNote'.tr(),
                  hintText: 'hr.pendingExplanations.hrNoteHint'.tr(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('hr.common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('hr.pendingExplanations.approve'.tr()),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      adminNote = controller.text.trim().isEmpty ? null : controller.text.trim();
    }

    try {
      await _adminService.processExplanation(
        attendanceId: int.parse(attendanceId.toString()),
        action: action,
        adminNote: adminNote,
      );
      Fluttertoast.showToast(
        msg: action == 'APPROVE' ? 'hr.pendingExplanations.approved'.tr() : 'hr.pendingExplanations.rejected'.tr(),
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
    return Scaffold(
      appBar: HrAppBar(
        context: context,
        titleText: 'hr.pendingExplanations.title'.tr(),
        onRefresh: _loading ? null : _load,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
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
        if (_clinics.isNotEmpty) _buildFilterBar(),
        Expanded(
          child: _items.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildExplanationCard(_items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _selectedClinicId,
              decoration: InputDecoration(
                labelText: 'hr.pendingExplanations.filterByClinic'.tr(),
                prefixIcon: const Icon(Icons.business_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('hr.common.all'.tr()),
                ),
                ..._clinics.map((c) {
                  final id = int.tryParse((c['id'] ?? c['clinicId'] ?? '').toString());
                  final name = c['clinicName']?.toString() ?? c['clinicCode']?.toString() ?? 'Clinic';
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedClinicId = value);
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(48),
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 48,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'hr.pendingExplanations.noPendingExplanations'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'hr.pendingExplanations.allProcessed'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // Extract data
    final user = item['user'] as Map<String, dynamic>?;
    final employeeName = user?['fullName']?.toString() ?? 'hr.common.employee'.tr();
    final employeeId = user?['id']?.toString() ?? user?['userId']?.toString() ?? '';
    final clinic = item['clinic'] as Map<String, dynamic>?;
    final clinicName = clinic?['clinicName']?.toString() ?? clinic?['clinicCode']?.toString() ?? '--';
    final workDateRaw = item['workDate'];
    String workDateStr = '--';
    if (workDateRaw != null) {
      if (workDateRaw is List && workDateRaw.length >= 3) {
        final y = workDateRaw[0];
        final m = workDateRaw[1].toString().padLeft(2, '0');
        final d = workDateRaw[2].toString().padLeft(2, '0');
        workDateStr = '$y-$m-$d';
      } else {
        workDateStr = workDateRaw.toString();
      }
    }
    final explanationType = item['explanationType']?.toString() ?? '';
    final reason = item['employeeReason']?.toString() ?? '';
    final status = item['explanationStatus']?.toString() ?? 'PENDING';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(isDark ? 0.3 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Employee info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (employeeId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: $employeeId',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1).withOpacity(isDark ? 0.15 : 0.08),
                    const Color(0xFF6366F1).withOpacity(isDark ? 0.08 : 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.business_rounded,
                    label: 'hr.common.clinic'.tr(),
                    value: clinicName,
                    iconColor: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'hr.pendingExplanations.workDate'.tr(),
                    value: workDateStr,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  if (explanationType.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.category_rounded,
                      label: 'hr.pendingExplanations.type'.tr(),
                      value: explanationType,
                      iconColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ],
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFEC4899).withOpacity(0.15),
                                const Color(0xFFEC4899).withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEC4899).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.note_rounded,
                            size: 18,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'hr.pendingExplanations.reason'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _processExplanation(item, 'REJECT'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('hr.pendingExplanations.reject'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _processExplanation(item, 'APPROVE'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'hr.pendingExplanations.approve'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
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
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconColor.withOpacity(0.15),
                iconColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
