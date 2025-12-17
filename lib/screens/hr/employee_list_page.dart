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
      Fluttertoast.showToast(msg: 'Đã cập nhật trạng thái');
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
        titleText: 'Nhân viên (HR)',
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
              'Đang tải...',
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
                    'Tổng: $_totalElements nhân viên',
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
                      'Tải thêm',
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
          color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.2 : 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar with modern design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF334155),
                          const Color(0xFF1E293B),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF1F5F9),
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark 
                    ? const Color(0xFF6366F1).withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w500, 
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tên/mã',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500], 
                    fontSize: 15, 
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[700] : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded, 
                              color: isDark ? Colors.grey[300] : Colors.grey[700], 
                              size: 16,
                            ),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            _load(page: 0);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _load(page: 0),
              ),
            ),
            const SizedBox(height: 16),
            // Filter Dropdowns in Grid
            Row(
              children: [
                Expanded(
                  child: EmployeeFilterDropdown(
                    label: 'Clinic',
                    value: _clinicId,
                    data: _clinics,
                    onChanged: (v) => setState(() => _clinicId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EmployeeFilterDropdown(
                    label: 'Dept',
                    value: _departmentId,
                    data: _departments,
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: EmployeeFilterDropdown(
                    label: 'Role',
                    value: _roleId,
                    data: _roles,
                    onChanged: (v) {
                  setState(() {
                    _roleId = v;
                    _page = 0; // Reset page when filter changes
                  });
                  _load(page: 0);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Trạng thái',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700], 
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: TextStyle(
                      fontSize: 13, 
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: const [
                      DropdownMenuItem(
                        value: "all",
                        child: Text('Tất cả', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: "active",
                        child: Text('Hoạt động', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: "inactive",
                        child: Text('Đã khóa', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: "resignation",
                        child: Text('Nghỉ việc', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    selectedItemBuilder: (context) => const [
                      Text('Tất cả', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      Text('Hoạt động', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      Text('Đã khóa', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                      Text('Nghỉ việc', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 13)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _statusFilter = v;
                          _page = 0; // Reset page when filter changes
                        });
                        _load(page: 0);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!, 
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() {
                            _clinicId = null;
                            _departmentId = null;
                            _roleId = null;
                            _statusFilter = "active"; // Reset về active như web
                            _page = 0;
                          });
                          _load(page: 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.w700, 
                              color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                            ),
                          ),
                        ),
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
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D28D9).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _load(page: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.filter_alt_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Lọc',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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


