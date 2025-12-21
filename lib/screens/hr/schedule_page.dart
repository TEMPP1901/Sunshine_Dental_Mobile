import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'common/hr_app_bar.dart';
import 'common/empty_error_state.dart';
import '../../services/hr_service.dart';
import 'widgets/schedule_widgets.dart';

class HrSchedulePage extends StatefulWidget {
  const HrSchedulePage({super.key});

  @override
  State<HrSchedulePage> createState() => _HrSchedulePageState();
}

class _HrSchedulePageState extends State<HrSchedulePage> {
  final HrService _hr = HrService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _current = [];
  DateTime? _selectedDate;
  bool _isCustomDate = false; // false = tuần hiện tại, true = chọn ngày

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> schedules;
      if (_isCustomDate && _selectedDate != null) {
        // Load theo ngày đã chọn
        schedules = await _hr.fetchScheduleByDate(_fmt(_selectedDate!));
      } else {
        // Load tuần hiện tại
        schedules = await _hr.fetchCurrentWeekSchedule();
      }
      if (!mounted) return;
      setState(() {
        _current = schedules;
      });
    } catch (e) {
      // Parse error message để hiển thị thân thiện hơn
      String errorMessage = 'hr.schedules.error.loadFailed'.tr();
      final errorStr = e.toString();

      if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
        errorMessage = 'hr.schedules.error.unauthorized'.tr();
      } else if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
        errorMessage = 'hr.schedules.error.forbidden'.tr();
      } else if (errorStr.contains('404') || errorStr.contains('Not Found')) {
        errorMessage = 'hr.schedules.error.notFound'.tr();
      } else if (errorStr.contains('500') ||
          errorStr.contains('Internal Server Error')) {
        errorMessage = 'hr.schedules.error.serverError'.tr();
      } else if (errorStr.contains('Network') ||
          errorStr.contains('Connection')) {
        errorMessage = 'hr.schedules.error.networkError'.tr();
      }
      // Nếu không match với các lỗi đã biết, giữ nguyên message mặc định

      if (mounted) {
        setState(() => _error = errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HrAppBar(
        context: context,
        titleText: 'hr.schedules.title'.tr(),
        onRefresh: _loading ? null : _load,
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6D28D9)),
        ),
      );
    }
    if (_error != null) {
      return EmptyErrorState(error: _error, onRetry: _load);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildDateFilter(),
        const SizedBox(height: 12),
        ScheduleSection(
          title: _isCustomDate && _selectedDate != null
              ? 'hr.schedules.scheduleForDate'.tr(args: [_fmt(_selectedDate!)])
              : 'hr.schedules.currentWeek'.tr(),
          data: _current,
          icon: Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey[200]!.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF6D28D9,
                  ).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_alt_rounded,
                  color: isDark
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF6D28D9),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'hr.schedules.selectDateToView'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isCustomDate = false;
                        _selectedDate = null;
                      });
                      _load();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: !_isCustomDate
                            ? const Color(
                                0xFF6D28D9,
                              ).withOpacity(isDark ? 0.15 : 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isCustomDate
                              ? const Color(0xFF6D28D9).withOpacity(0.4)
                              : (isDark
                                    ? Colors.grey[700]!.withOpacity(0.3)
                                    : Colors.grey[300]!.withOpacity(0.5)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: !_isCustomDate
                                ? const Color(0xFF6D28D9)
                                : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[700]),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'hr.schedules.currentWeek'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isCustomDate
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: !_isCustomDate
                                  ? const Color(0xFF6D28D9)
                                  : (isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _pickDate(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _isCustomDate
                            ? const Color(
                                0xFF6D28D9,
                              ).withOpacity(isDark ? 0.15 : 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCustomDate
                              ? const Color(0xFF6D28D9).withOpacity(0.4)
                              : (isDark
                                    ? Colors.grey[700]!.withOpacity(0.3)
                                    : Colors.grey[300]!.withOpacity(0.5)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            size: 15,
                            color: _isCustomDate
                                ? const Color(0xFF6D28D9)
                                : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[700]),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? _fmt(_selectedDate!)
                                  : 'hr.schedules.selectDate'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isCustomDate
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _isCustomDate
                                    ? const Color(0xFF6D28D9)
                                    : (isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isCustomDate = true;
      });
      _load();
    }
  }
}
