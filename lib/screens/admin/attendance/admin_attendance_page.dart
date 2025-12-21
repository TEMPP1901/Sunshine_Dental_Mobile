import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../services/admin_service.dart';
import 'widgets/attendance_filter_chip.dart';
import 'widgets/attendance_card.dart';

class AdminAttendancePage extends StatefulWidget {
  const AdminAttendancePage({super.key});

  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _dateController = TextEditingController();

  List<Map<String, dynamic>> _attendanceList = [];
  List<Map<String, dynamic>> _clinicsList = [];
  bool _isLoading = false;
  bool _isLoadingClinics = false;
  String? _selectedStatus;
  int? _selectedClinicId;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadClinics();
    _loadAttendance();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoadingClinics = true);
    try {
      final clinics = await _adminService.fetchClinics();
      debugPrint('Loaded ${clinics.length} clinics');
      if (clinics.isNotEmpty) {
        debugPrint('First clinic: ${clinics.first}');
      }
      setState(() {
        _clinicsList = clinics;
        _isLoadingClinics = false;
      });
    } catch (e) {
      setState(() => _isLoadingClinics = false);
      debugPrint('Error loading clinics: $e');
      debugPrint('Error stack: ${e.toString()}');
      Fluttertoast.showToast(
        msg: 'admin.attendance.error.loadClinicsFailed'.tr(
          args: [e.toString()],
        ),
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = _dateController.text.isNotEmpty
        ? DateTime.tryParse(_dateController.text) ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark
                  ? const Color(0xFF5C6BC0)
                  : const Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1A2332) : Colors.white,
              onSurface: isDark
                  ? const Color(0xFFE8EAED)
                  : const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    // Validate date format if provided
    if (_dateController.text.isNotEmpty) {
      try {
        DateFormat('yyyy-MM-dd').parseStrict(_dateController.text);
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'admin.attendance.error.invalidDateFormat'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      // Prepare parameters
      final String? dateParam = _dateController.text.trim().isNotEmpty
          ? _dateController.text.trim()
          : null;

      final int? clinicIdParam = _selectedClinicId;

      final String? statusParam = _selectedStatus;

      // Debug log (remove in production)
      debugPrint(
        'Loading attendance with filters: date=$dateParam, clinicId=$clinicIdParam, status=$statusParam',
      );

      final data = await _adminService.fetchAdminAttendance(
        date: dateParam,
        clinicId: clinicIdParam,
        status: statusParam,
      );

      // Debug: Log dữ liệu để kiểm tra
      if (data.isNotEmpty) {
        debugPrint('Sample attendance data: ${data.first}');
        debugPrint(
          'Status field: attendanceStatus=${data.first['attendanceStatus']}, status=${data.first['status']}',
        );
      }

      setState(() {
        _attendanceList = data;
        _isLoading = false;
      });

      // Show success message if filters are applied
      if (dateParam != null || clinicIdParam != null || statusParam != null) {
        debugPrint('Loaded ${data.length} attendance records');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading attendance: $errorMsg');
      Fluttertoast.showToast(
        msg: 'admin.attendance.error.loadFailed'.tr(args: [errorMsg]),
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return const Color(0xFF10B981);
      case 'LATE':
        return const Color(0xFFF59E0B);
      case 'ABSENT':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return Icons.check_circle_rounded;
      case 'LATE':
        return Icons.schedule_rounded;
      case 'ABSENT':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _updateStatus(int attendanceId, String newStatus) async {
    final noteController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(newStatus);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    colors: [Colors.white, const Color(0xFFF8FAFC)],
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
                      color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getStatusIcon(newStatus),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'admin.attendance.updateStatus'.tr(),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'admin.attendance.newStatus'.tr(),
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      newStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'admin.attendance.note'.tr(),
                  hintText: 'admin.attendance.noteHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey[900]!.withOpacity(0.3)
                      : Colors.grey[50],
                ),
                maxLines: 3,
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
                        'admin.common.cancel'.tr(),
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
                          colors: [statusColor, statusColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
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
                                  _getStatusIcon(newStatus),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'admin.attendance.update'.tr(),
                                  style: TextStyle(
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

    if (result != true) return;

    try {
      await _adminService.updateAttendanceStatus(
        attendanceId: attendanceId,
        newStatus: newStatus,
        adminNote: noteController.text,
      );
      Fluttertoast.showToast(msg: 'admin.attendance.statusUpdated'.tr());
      _loadAttendance();
    } catch (e) {
      Fluttertoast.showToast(msg: '${'admin.common.error'.tr()}: $e');
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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Text(
          'admin.attendance.title'.tr(),
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAttendance,
          ),
        ],
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
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2332).withOpacity(0.5)
                  : Colors.grey[50]!.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[200]!.withOpacity(0.5),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input fields
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'admin.attendance.date'.tr(),
                            hintText: 'admin.attendance.selectDate'.tr(),
                            prefixIcon: Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF5C6BC0)
                                    : const Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey[900]!.withOpacity(0.3)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                          ),
                          child: Text(
                            _dateController.text.isNotEmpty
                                ? _dateController.text
                                : 'admin.attendance.selectDate'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: _dateController.text.isNotEmpty
                                  ? (isDark
                                        ? const Color(0xFFE8EAED)
                                        : const Color(0xFF0F172A))
                                  : (isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedClinicId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'admin.common.clinic'.tr(),
                          hintText: 'admin.attendance.selectClinic'.tr(),
                          prefixIcon: Icon(
                            Icons.business_rounded,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF5C6BC0)
                                  : const Color(0xFF1A237E),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[900]!.withOpacity(0.3)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFE8EAED)
                              : const Color(0xFF0F172A),
                        ),
                        items: _isLoadingClinics
                            ? [
                                DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(
                                    'admin.common.loading'.tr(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ]
                            : [
                                DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(
                                    'admin.attendance.allClinics'.tr(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ..._clinicsList.map((clinic) {
                                  final clinicId = clinic['id'];
                                  // Thử nhiều cách để lấy tên phòng khám
                                  final clinicName =
                                      clinic['clinicName']?.toString() ??
                                      clinic['name']?.toString() ??
                                      clinic['clinicCode']?.toString() ??
                                      'admin.attendance.clinicName'.tr(
                                        namedArgs: {'id': '${clinicId ?? ''}'},
                                      );
                                  debugPrint(
                                    'Clinic item: id=$clinicId, name=$clinicName, fullData=$clinic',
                                  );
                                  // Xử lý clinicId có thể là int hoặc dynamic
                                  final int? clinicIdInt = clinicId is int
                                      ? clinicId
                                      : (clinicId != null
                                            ? int.tryParse(clinicId.toString())
                                            : null);
                                  return DropdownMenuItem<int>(
                                    value: clinicIdInt,
                                    child: Text(
                                      clinicName,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFFE8EAED)
                                            : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                        onChanged: _isLoadingClinics
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedClinicId = value;
                                });
                                Future.microtask(() => _loadAttendance());
                              },
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Status filter
                Text(
                  'admin.attendance.status'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AttendanceFilterChip(
                      label: 'admin.common.all'.tr(),
                      selected: _selectedStatus == null,
                      disabled: _isLoading,
                      onTap: () {
                        if (_isLoading) return;
                        setState(() {
                          _selectedStatus = null;
                        });
                        Future.microtask(() => _loadAttendance());
                      },
                    ),
                    AttendanceFilterChip(
                      label: 'admin.attendance.statusOptions.present'.tr(),
                      selected: _selectedStatus == 'PRESENT',
                      disabled: _isLoading,
                      onTap: () {
                        if (_isLoading) return;
                        setState(() {
                          _selectedStatus = 'PRESENT';
                        });
                        Future.microtask(() => _loadAttendance());
                      },
                    ),
                    AttendanceFilterChip(
                      label: 'admin.attendance.statusOptions.late'.tr(),
                      selected: _selectedStatus == 'LATE',
                      disabled: _isLoading,
                      onTap: () {
                        if (_isLoading) return;
                        setState(() {
                          _selectedStatus = 'LATE';
                        });
                        Future.microtask(() => _loadAttendance());
                      },
                    ),
                    AttendanceFilterChip(
                      label: 'admin.attendance.statusOptions.absent'.tr(),
                      selected: _selectedStatus == 'ABSENT',
                      disabled: _isLoading,
                      onTap: () {
                        if (_isLoading) return;
                        setState(() {
                          _selectedStatus = 'ABSENT';
                        });
                        Future.microtask(() => _loadAttendance());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results count
          if (!_isLoading && _attendanceList.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF5C6BC0).withOpacity(0.1)
                    : const Color(0xFF1A237E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF5C6BC0).withOpacity(0.2)
                      : const Color(0xFF1A237E).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF1A237E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'admin.attendance.foundResults'.tr(
                      namedArgs: {'count': '${_attendanceList.length}'},
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE8EAED)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFF5C6BC0)
                            : const Color(0xFF1A237E),
                      ),
                    ),
                  )
                : _attendanceList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF5C6BC0)
                                        : const Color(0xFF1A237E))
                                    .withOpacity(isDark ? 0.15 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            size: 56,
                            color: isDark
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'admin.attendance.noData'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE8EAED)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'admin.attendance.tryChangeFilters'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAttendance,
                    color: isDark
                        ? const Color(0xFF5C6BC0)
                        : const Color(0xFF1A237E),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _attendanceList.length,
                      itemBuilder: (context, index) {
                        final item = _attendanceList[index];
                        return AttendanceCard(
                          item: item,
                          isDark: isDark,
                          onUpdateStatus: (newStatus) => _updateStatus(
                            item['id'] ?? item['attendanceId'],
                            newStatus,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
