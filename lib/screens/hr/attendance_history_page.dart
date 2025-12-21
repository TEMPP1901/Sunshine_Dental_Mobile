import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'common/hr_app_bar.dart';
import 'common/empty_error_state.dart';
import 'common/stats_chips.dart';
import '../../services/hr_service.dart';
import 'widgets/attendance_history_widgets.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final HrService _hr = HrService();
  final _startCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _departments = [];
  int? _selectedDepartmentId;
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startCtrl.text = _fmt(today);
    _loadDropdowns();
    _load();
  }

  Future<void> _loadDropdowns() async {
    try {
      final depts = await _hr.fetchDepartments();
      if (mounted) {
        setState(() => _departments = depts);
      }
    } catch (e) {
      // Silent fail
    }
  }

  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load({int? page}) async {
    final targetPage = page ?? 0;
    setState(() {
      _loading = true;
      _error = null;
      _items = []; // Always clear items when loading new page
    });
    try {
      final dateStr = _startCtrl.text.trim();
      if (dateStr.isEmpty) {
        setState(() {
          _error = 'hr.attendance.selectDate'.tr();
          _items = [];
        });
        return;
      }
      
      // Try daily-list API first (same as web), fallback to history API
      Map<String, dynamic> data;
      try {
        data = await _hr.fetchDailyAttendanceList(
          workDate: dateStr,
          departmentId: _selectedDepartmentId,
          page: targetPage,
          size: 20,
        );
      } catch (e) {
        // Fallback to history API
        // Fallback to history API
        data = await _hr.fetchAttendanceHistory(
          startDate: dateStr,
          endDate: dateStr,
          page: targetPage,
          size: 20,
        );
      }
      
      final content = _parseList(data['content'] ?? data);
      // Parse page number từ nhiều field khác nhau
      int? number;
      if (data['number'] != null) {
        number = _coerceInt(data['number']);
      } else if (data['currentPage'] != null) {
        number = _coerceInt(data['currentPage']);
      } else if (data['page'] is int) {
        number = data['page'] as int;
      } else if (data['page'] is Map) {
        number = _coerceInt((data['page'] as Map)['number']);
      }
      
      final totalPages = _coerceInt(data['totalPages'] ?? data['totalPage']);
      final totalElements = _coerceInt(data['totalElements'] ?? data['total'] ?? data['totalCount']);
      
      // Nếu API không trả về totalPages/totalElements, tính dựa trên số items
      int calculatedTotalPages = totalPages ?? 0;
      int calculatedTotalElements = totalElements ?? 0;
      
      if (calculatedTotalPages == 0) {
        if (content.length == 20) {
          // Có đúng 20 items, có thể còn trang tiếp theo
          calculatedTotalPages = 2;
        } else if (content.length > 0) {
          // Có items nhưng ít hơn 20, chắc chắn chỉ có 1 trang
          calculatedTotalPages = 1;
        }
      } else if (calculatedTotalPages > 1 && content.length < 20 && targetPage > 0) {
        // Nếu đã có totalPages > 1 nhưng load được ít hơn 20 items ở page > 0
        // Có nghĩa là đây là trang cuối, update totalPages
        calculatedTotalPages = targetPage + 1;
      }
      
      if (calculatedTotalElements == 0 && content.isNotEmpty) {
        calculatedTotalElements = content.length;
        if (calculatedTotalPages > 1) {
          calculatedTotalElements = content.length * calculatedTotalPages;
        }
      }
      
      setState(() {
        _items = content;
        _page = number ?? targetPage;
        _totalPages = calculatedTotalPages;
        _totalElements = calculatedTotalElements;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _items = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // Filter items by search term (department is already filtered by API)
  List<Map<String, dynamic>> get _filteredItems {
    var filtered = _items;
    
    // Filter by search term (client-side)
    final searchTerm = _searchCtrl.text.trim().toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = (item['fullName'] ?? item['employeeName'] ?? item['employeeName'] ?? '').toString().toLowerCase();
        return name.contains(searchTerm);
      }).toList();
    }
    
    // Department filter is handled by API, no need to filter client-side
    
    return filtered;
  }

  int? _coerceInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    if (v is Map && v['pageNumber'] != null) return _coerceInt(v['pageNumber']);
    return null;
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HrAppBar(
        context: context,
        titleText: 'hr.attendance.title'.tr(),
        onRefresh: _loading ? null : () => _load(page: 0),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(page: _page),
        child: _buildBody(),
      ),
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
      return EmptyErrorState(error: _error, onRetry: () => _load(page: 0));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _filters(),
        const SizedBox(height: 16),
        if (_items.isEmpty && !_loading)
          const AttendanceEmptyState()
        else if (_items.isNotEmpty)
          ..._filteredItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AttendanceItemCard(item: item),
              )),
        if (_filteredItems.isEmpty && _items.isNotEmpty)
          const AttendanceNoSearchResults(),
        if (_items.isNotEmpty && _totalPages > 0) ...[
          const SizedBox(height: 8),
          _pager(),
        ],
      ],
    );
  }


  Widget _filters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surfaceLightColor = isDark ? const Color(0xFF334155) : const Color(0xFFFAFBFC);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceColor,
            surfaceLightColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey[200]!.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
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
            // Date Input
            TextField(
              controller: _startCtrl,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                labelText: 'hr.attendance.date'.tr(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: isDark 
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                    size: 16,
                  ),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.date_range_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () => _pickDate(_startCtrl),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF6D28D9).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _load(page: 0),
            ),
            const SizedBox(height: 12),
            // Search Input
            TextField(
              controller: _searchCtrl,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              cursorColor: const Color(0xFF6D28D9),
              decoration: InputDecoration(
                hintText: 'hr.attendance.searchEmployee'.tr(),
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: isDark 
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                    size: 16,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF6D28D9).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Department Filter
            DropdownButtonFormField<int?>(
              value: _selectedDepartmentId,
              dropdownColor: surfaceColor,
              iconEnabledColor: isDark ? Colors.grey[400] : Colors.grey[600],
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'hr.common.department'.tr(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: isDark 
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                    size: 16,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF6D28D9).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('hr.attendance.allDepartments'.tr()),
                  ),
                  ..._departments.map((dept) {
                    final id = _coerceInt(dept['id']);
                    final name = dept['departmentName']?.toString() ?? 'Unknown';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartmentId = value;
                  });
                  // Reload data when department changes
                  _load(page: 0);
                },
              isExpanded: true,
            ),
            const SizedBox(height: 14),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AttendanceActionButton(
                  label: 'hr.common.reset'.tr(),
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    final today = DateTime.now();
                    _startCtrl.text = _fmt(today);
                    _searchCtrl.clear();
                    setState(() {
                      _selectedDepartmentId = null;
                    });
                    _load(page: 0);
                  },
                  isPrimary: false,
                ),
                const SizedBox(width: 12),
                AttendanceActionButton(
                  label: 'hr.common.filter'.tr(),
                  icon: Icons.filter_alt_rounded,
                  onPressed: () => _load(page: 0),
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController c) async {
    final init = c.text.isNotEmpty ? DateTime.tryParse(c.text) ?? DateTime.now() : DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) {
      c.text = _fmt(picked);
      _load(page: 0);
    }
  }

  Widget _pager() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surfaceLightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    
    final canGoPrev = _page > 0;
    final canGoNext = _totalPages > 1 && _page + 1 < _totalPages;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceColor,
            surfaceLightColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trang ${_page + 1}/${_totalPages > 0 ? _totalPages : 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                ),
              ),
              if (_totalElements > 0)
                Text(
                  'hr.attendance.totalRecords'.tr(args: ['$_totalElements']),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          Row(
            children: [
              AttendancePagerButton(
                icon: Icons.chevron_left_rounded,
                onPressed: canGoPrev ? () => _load(page: _page - 1) : null,
              ),
              const SizedBox(width: 8),
              AttendancePagerButton(
                icon: Icons.chevron_right_rounded,
                onPressed: canGoNext ? () => _load(page: _page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}


