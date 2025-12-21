import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'common/hr_app_bar.dart';
import 'common/empty_error_state.dart';
import '../../services/hr_service.dart';
import 'widgets/employee_list_widgets.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final HrService _hr = HrService();
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  int? _clinicId;
  int? _departmentId;
  int? _roleId;
  String _statusFilter = "active"; // "all" | "active" | "inactive" | "resignation"
  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _load();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom (200px before end)
      if (!_loadingMore && _page + 1 < _totalPages) {
        _loadMore();
      }
    }
  }

  Future<void> _loadDropdowns() async {
    final results = await Future.wait([
      _hr.fetchClinics(),
      _hr.fetchDepartments(),
      _hr.fetchRoles(),
    ]);
    if (!mounted) return;
    setState(() {
      _clinics = results[0];
      _departments = results[1];
      _roles = results[2];
    });
  }

  Future<void> _load({int? page}) async {
    final targetPage = page ?? 0;
    
    setState(() {
      _loading = true;
      _error = null;
      _items = []; // Always clear items when loading new data
    });
    try {
      // Không gửi isActive nếu lọc theo nghỉ việc hoặc all
      bool? isActiveParam;
      if (_statusFilter != "resignation" && _statusFilter != "all") {
        isActiveParam = _statusFilter == "active";
      }

      final data = await _hr.fetchEmployees(
        search: _searchCtrl.text.trim(),
        clinicId: _clinicId,
        departmentId: _departmentId,
        roleId: _roleId,
        isActive: isActiveParam,
        page: targetPage,
        size: 50,
      );
      
      List<Map<String, dynamic>> content = (data['content'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      
      // Nếu chọn nghỉ việc thì chỉ giữ lại những ai đã duyệt đơn nghỉ
      if (_statusFilter == "resignation") {
        content = content.where((emp) => (emp['hasApprovedResignation'] == true)).toList();
      }
      
      final number = _coerceInt(data['number'] ?? data['page']);
      final totalPages = _coerceInt(data['totalPages']);
      int? totalElements = _coerceInt(data['totalElements']);

      // Chỉ gọi statistics API nếu backend trả về totalElements = 0/null nhưng vẫn có data
      // (Đây là fallback mechanism giống web để đảm bảo hiển thị đúng tổng số)
      if (content.isNotEmpty && (totalElements == null || totalElements == 0)) {
        try {
          final statsData = await _hr.fetchEmployeeStats(
            clinicId: _clinicId,
            departmentId: _departmentId,
          );
          final totalEmployees = _coerceInt(statsData['totalEmployees']);
          if (totalEmployees != null && totalEmployees > 0) {
            totalElements = totalEmployees;
          }
        } catch (e) {
          // Silent fail for stats - không ảnh hưởng đến việc hiển thị data
        }
      }

      // Tính toán lại totalPages dựa trên totalElements nếu cần
      int calculatedTotalPages = totalPages ?? 0;
      if (totalElements != null && totalElements > 0) {
        // Nếu backend trả về totalPages = 0 hoặc không hợp lý, tính lại
        if (calculatedTotalPages == 0 || (calculatedTotalPages == 1 && totalElements > content.length)) {
          calculatedTotalPages = (totalElements / 50).ceil();
          if (calculatedTotalPages == 0) calculatedTotalPages = 1;
        }
      }
      
      setState(() {
        _items = content; // Always replace for _load
        _page = number ?? targetPage;
        _totalPages = calculatedTotalPages;
        _totalElements = totalElements ?? 0;
      });
      
      // Tự động load thêm nếu còn thiếu items
      if (totalElements != null && 
          totalElements > content.length && 
          !_loadingMore) {
        // Delay một chút để UI render xong và setState hoàn tất
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && 
              _totalElements > _items.length && 
              !_loadingMore) {
            _loadMore();
          }
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    // Cho phép load nếu: không đang load, và (còn page hoặc vẫn thiếu items)
    if (_loadingMore) return;
    if (_page + 1 >= _totalPages && _totalElements <= _items.length) return;
    
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      
      // Không gửi isActive nếu lọc theo nghỉ việc hoặc all
      bool? isActiveParam;
      if (_statusFilter != "resignation" && _statusFilter != "all") {
        isActiveParam = _statusFilter == "active";
      }

      final data = await _hr.fetchEmployees(
        search: _searchCtrl.text.trim(),
        clinicId: _clinicId,
        departmentId: _departmentId,
        roleId: _roleId,
        isActive: isActiveParam,
        page: nextPage,
        size: 50,
      );
      
      var content = (data['content'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      
      // Nếu chọn nghỉ việc thì chỉ giữ lại những ai đã duyệt đơn nghỉ
      if (_statusFilter == "resignation") {
        content = content.where((emp) => (emp['hasApprovedResignation'] == true)).toList();
      }
      
      final number = _coerceInt(data['number'] ?? data['page']);
      final totalPages = _coerceInt(data['totalPages']);
      final totalElements = _coerceInt(data['totalElements']);
      
      // Tính toán lại totalPages nếu cần
      int calculatedTotalPages = totalPages ?? _totalPages;
      if (totalElements != null && totalElements > 0) {
        if (calculatedTotalPages == 0 || (calculatedTotalPages == 1 && totalElements > _items.length + content.length)) {
          calculatedTotalPages = (totalElements / 50).ceil();
          if (calculatedTotalPages == 0) calculatedTotalPages = 1;
        }
      }
      
      setState(() {
        _items.addAll(content);
        _page = number ?? nextPage;
        _totalPages = calculatedTotalPages;
        if (totalElements != null && totalElements > 0) {
          _totalElements = totalElements;
        }
      });
      
      // Tiếp tục load thêm nếu vẫn còn thiếu items
      if (totalElements != null && 
          totalElements > _items.length && 
          calculatedTotalPages > 1 &&
          _page + 1 < calculatedTotalPages && 
          !_loadingMore) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _page + 1 < _totalPages && !_loadingMore) {
            _loadMore();
          }
        });
      }
    } catch (e) {
      // Silent fail for load more
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  int? _coerceInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    if (v is Map && v['pageNumber'] != null) return _coerceInt(v['pageNumber']);
    return null;
  }

  Future<void> _toggleStatus(Map<String, dynamic> item, bool target) async {
    final id = item['id'] ?? item['employeeId'];
    if (id == null) return;
    try {
      await _hr.toggleEmployeeStatus(employeeId: int.parse(id.toString()), isActive: target, reason: 'Mobile toggle');
      Fluttertoast.showToast(msg: 'hr.employees.statusUpdated'.tr());
      _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HrAppBar(
        context: context,
        titleText: 'hr.employees.title'.tr(),
        onRefresh: _loading ? null : () => _load(page: 0),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(page: _page),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'hr.common.loading'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return EmptyErrorState(error: _error, onRetry: () => _load(page: 0));
    }
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildFilters(),
        const SizedBox(height: 24),
        if (_items.isEmpty && !_loading)
          const EmployeeEmptyState()
        else ...[
          if (_items.isNotEmpty) ...[
            // Show total count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF6D28D9).withOpacity(0.15)
                  : const Color(0xFF6D28D9).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_rounded, 
                    size: 18, 
                    color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'hr.employees.totalEmployees'.tr(namedArgs: {'count': _totalElements.toString()}),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._items.map((e) => EmployeeCard(
              employee: e,
              onToggleStatus: () => _toggleStatus(e, (e['active'] ?? e['isActive'] ?? true) != true),
            )),
            if (_loadingMore)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            if (_page + 1 < _totalPages)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _loadMore,
                    icon: Icon(
                      Icons.expand_more_rounded, 
                      size: 20,
                      color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                    ),
                    label: Text(
                      'hr.common.loadMore'.tr(),
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ),
            if (_items.isNotEmpty && _totalPages > 1) ...[
              const SizedBox(height: 16),
              EmployeePager(
                currentPage: _page,
                totalPages: _totalPages,
                onPrevious: () => _load(page: _page - 1),
                onNext: () => _load(page: _page + 1),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surfaceLightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar with enhanced design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF334155).withOpacity(0.9),
                          const Color(0xFF1E293B).withOpacity(0.95),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF8FAFC),
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark 
                    ? const Color(0xFF6366F1).withOpacity(0.5)
                    : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600, 
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: 0.3,
                ),
                decoration: InputDecoration(
                  hintText: 'hr.employees.searchPlaceholder'.tr(),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500], 
                    fontSize: 15, 
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D28D9).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[700]!.withOpacity(0.7) : Colors.grey[200]!.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded, 
                              color: isDark ? Colors.grey[300] : Colors.grey[700], 
                              size: 18,
                            ),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                            _load(page: 0);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _load(page: 0),
              ),
            ),
            const SizedBox(height: 20),
            // Filter Dropdowns in Grid with improved spacing
            Row(
              children: [
                Expanded(
                  child: EmployeeFilterDropdown(
                    label: 'hr.common.clinic'.tr(),
                    value: _clinicId,
                    data: _clinics,
                    onChanged: (v) => setState(() => _clinicId = v),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: EmployeeFilterDropdown(
                    label: 'hr.common.department'.tr(),
                    value: _departmentId,
                    data: _departments,
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: EmployeeFilterDropdown(
                    label: 'hr.common.role'.tr(),
                    value: _roleId,
                    data: _roles,
                    onChanged: (v) {
                      setState(() {
                        _roleId = v;
                        _page = 0;
                      });
                      _load(page: 0);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'hr.common.status'.tr(),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700], 
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 22,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: "all",
                          child: Text('hr.common.all'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        DropdownMenuItem(
                          value: "active",
                          child: Text('hr.common.active'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        DropdownMenuItem(
                          value: "inactive",
                          child: Text('hr.common.inactive'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        DropdownMenuItem(
                          value: "resignation",
                          child: Text('hr.common.resignation'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      selectedItemBuilder: (context) => [
                        Text('hr.common.all'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('hr.common.active'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('hr.common.inactive'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('hr.common.resignation'.tr(), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _statusFilter = v;
                            _page = 0;
                          });
                          _load(page: 0);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action Buttons with improved design
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!, 
                        width: 2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() {
                            _clinicId = null;
                            _departmentId = null;
                            _roleId = null;
                            _statusFilter = "active";
                            _page = 0;
                          });
                          _load(page: 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'hr.common.reset'.tr(),
                                  style: TextStyle(
                                    fontSize: 15, 
                                    fontWeight: FontWeight.w700, 
                                    color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D28D9).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _load(page: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_alt_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'hr.common.filter'.tr(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
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

}


