import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../services/admin_service.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize =
      100; // Tăng lên 100 để load tất cả staff trong một lần (backend max = 100)

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadStaff();
    _loadTotalStaffCount(); // Load tổng số từ dashboard stats
  }

  // Load tổng số nhân viên từ dashboard stats (tất cả users trong hệ thống)
  // Dashboard stats có totalStaff = userRepo.count() - tổng số TẤT CẢ users
  // Staff API chỉ trả về active staff với roles (RECEPTION, ACCOUNTANT, DOCTOR, HR, RECEPTIONIST)
  // Nên dùng totalStaff từ dashboard để hiển thị tổng số đúng
  Future<void> _loadTotalStaffCount() async {
    try {
      final stats = await _adminService.fetchDashboardStats();
      final totalStaff = stats['totalStaff'];
      debugPrint(
        'Dashboard stats totalStaff: $totalStaff (type: ${totalStaff?.runtimeType})',
      );

      if (totalStaff != null) {
        int count = 0;
        if (totalStaff is int) {
          count = totalStaff;
        } else if (totalStaff is num) {
          count = totalStaff.toInt();
        } else if (totalStaff is String) {
          count = int.tryParse(totalStaff) ?? 0;
        }

        // Luôn update totalElements từ dashboard stats (tổng số tất cả users)
        // Vì đây là số chính xác hơn so với totalElements từ staff API
        if (count > 0) {
          setState(() {
            _totalElements = count;
          });
          debugPrint('Updated totalElements from dashboard stats: $count');
        }
      } else {
        debugPrint('Dashboard stats totalStaff is null');
      }
    } catch (e) {
      debugPrint('Error loading total staff count from dashboard: $e');
      // Không hiển thị error vì đây chỉ là fallback
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // Update UI để hiển thị clear button
  }

  Future<void> _loadStaff({bool resetPage = false}) async {
    if (resetPage) _currentPage = 0;
    setState(() => _isLoading = true);
    try {
      // Load tất cả staff trong một lần với size lớn
      final data = await _adminService.fetchStaff(
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        page: 0, // Luôn load từ page 0
        size: _pageSize, // 100 items
      );

      // Debug log để kiểm tra dữ liệu
      debugPrint('Staff API Response: $data');
      debugPrint('totalElements type: ${data['totalElements']?.runtimeType}');
      debugPrint('totalElements value: ${data['totalElements']}');

      // Parse totalElements an toàn hơn
      int totalElements = 0;
      final totalElementsValue = data['totalElements'];
      if (totalElementsValue != null) {
        if (totalElementsValue is int) {
          totalElements = totalElementsValue;
        } else if (totalElementsValue is num) {
          totalElements = totalElementsValue.toInt();
        } else if (totalElementsValue is String) {
          totalElements = int.tryParse(totalElementsValue) ?? 0;
        }
      }

      // Parse totalPages an toàn hơn
      int totalPages = 0;
      final totalPagesValue = data['totalPages'];
      if (totalPagesValue != null) {
        if (totalPagesValue is int) {
          totalPages = totalPagesValue;
        } else if (totalPagesValue is num) {
          totalPages = totalPagesValue.toInt();
        } else if (totalPagesValue is String) {
          totalPages = int.tryParse(totalPagesValue) ?? 0;
        }
      }

      // Nếu không có totalPages trong response, tính từ totalElements
      if (totalPages == 0 && totalElements > 0) {
        totalPages = ((totalElements - 1) ~/ _pageSize) + 1;
        debugPrint('Calculated totalPages from totalElements: $totalPages');
      }

      List<Map<String, dynamic>> allStaff =
          data['content'] as List<Map<String, dynamic>>? ?? [];
      debugPrint(
        'Initial load: ${allStaff.length} items, totalElements=$totalElements, totalPages=$totalPages',
      );

      // Nếu API không trả về đúng totalElements/totalPages (bằng 0) nhưng có content,
      // cần load tiếp các pages cho đến khi không còn data
      if (totalElements == 0 && totalPages == 0 && allStaff.isNotEmpty) {
        // API không trả về pagination info, cần load tiếp từ page 1
        debugPrint(
          'API returned totalElements=0 but has content, will load more pages until empty',
        );

        // Load tất cả các pages tiếp theo cho đến khi gặp empty page
        int currentPage = 1;
        while (currentPage < 100) {
          // Giới hạn 100 pages để tránh vòng lặp vô hạn
          try {
            debugPrint('Loading page $currentPage...');
            final pageData = await _adminService.fetchStaff(
              search: _searchController.text.trim().isNotEmpty
                  ? _searchController.text.trim()
                  : null,
              page: currentPage,
              size: _pageSize,
            );
            final pageContent =
                pageData['content'] as List<Map<String, dynamic>>? ?? [];
            if (pageContent.isNotEmpty) {
              allStaff.addAll(pageContent);
              debugPrint(
                'Loaded page $currentPage: ${pageContent.length} items, total so far: ${allStaff.length}',
              );

              // Nếu page không đầy (ít hơn pageSize), có thể đã hết data
              if (pageContent.length < _pageSize) {
                debugPrint(
                  'Page $currentPage is not full (${pageContent.length} < $_pageSize), likely last page',
                );
                break;
              }

              currentPage++;
            } else {
              debugPrint('Page $currentPage returned empty content, stopping');
              break;
            }
          } catch (e) {
            debugPrint('Error loading page $currentPage: $e');
            // Dừng lại nếu có lỗi
            break;
          }
        }
      } else if (totalPages > 1 && allStaff.length < totalElements) {
        // API trả về đúng pagination info, load các pages còn lại
        debugPrint(
          'Need to load more: current=${allStaff.length}, total=$totalElements, pages=$totalPages',
        );

        // Load tất cả các pages còn lại
        for (int page = 1; page < totalPages; page++) {
          try {
            debugPrint('Loading page $page/$totalPages...');
            final pageData = await _adminService.fetchStaff(
              search: _searchController.text.trim().isNotEmpty
                  ? _searchController.text.trim()
                  : null,
              page: page,
              size: _pageSize,
            );
            final pageContent =
                pageData['content'] as List<Map<String, dynamic>>? ?? [];
            if (pageContent.isNotEmpty) {
              allStaff.addAll(pageContent);
              debugPrint(
                'Loaded page $page: ${pageContent.length} items, total so far: ${allStaff.length}',
              );

              // Nếu đã đủ số lượng, dừng lại
              if (allStaff.length >= totalElements) {
                debugPrint('Reached totalElements, stopping pagination');
                break;
              }
            } else {
              debugPrint('Page $page returned empty content, stopping');
              break;
            }
          } catch (e) {
            debugPrint('Error loading page $page: $e');
            // Tiếp tục load các pages khác
          }
        }
      }

      debugPrint(
        'Final staff list length: ${allStaff.length}, expected: $totalElements',
      );

      setState(() {
        _staffList = allStaff;
        _totalPages = totalPages;
        // Tạm thời dùng totalElements từ API (sẽ được update từ dashboard stats nếu lớn hơn)
        _totalElements = totalElements;
        _isLoading = false;
      });

      debugPrint(
        'Final - totalElements from API: $totalElements, totalPages: $_totalPages, staffCount: ${_staffList.length}',
      );

      // Kiểm tra nếu số items < totalElements từ API
      if (_staffList.length < totalElements && totalElements > 0) {
        debugPrint(
          'WARNING: Staff list (${_staffList.length}) < totalElements from API ($totalElements)',
        );
        debugPrint('This might indicate pagination issue or API filter');
      }

      // Luôn load totalStaff từ dashboard stats để có tổng số TẤT CẢ users
      // (Dashboard có userRepo.count(), staff API chỉ có active staff với roles)
      _loadTotalStaffCount();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading staff: $e');
      Fluttertoast.showToast(
        msg: 'admin.staff.error.loadFailed'.tr(
          namedArgs: {'error': e.toString()},
        ),
        toastLength: Toast.LENGTH_LONG,
      );
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
          'admin.staff.title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : () => _loadStaff(resetPage: true),
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
          // Search bar
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
            child: TextField(
              controller: _searchController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'admin.staff.searchPlaceholder'.tr(),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _loadStaff(resetPage: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
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
              onSubmitted: (_) => _loadStaff(resetPage: true),
            ),
          ),
          // Stats - luôn hiển thị để người dùng biết tổng số
          if (!_isLoading)
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
                    'admin.staff.totalStaff'.tr(
                      namedArgs: {'count': '$_totalElements'},
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
            child: _isLoading && _staffList.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFF5C6BC0)
                            : const Color(0xFF1A237E),
                      ),
                    ),
                  )
                : _staffList.isEmpty
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
                            Icons.people_outline_rounded,
                            size: 56,
                            color: isDark
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'admin.staff.notFound'.tr(),
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
                          _searchController.text.isNotEmpty
                              ? 'admin.staff.tryChangeSearch'.tr()
                              : 'admin.staff.emptyList'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadStaff(resetPage: true),
                    color: isDark
                        ? const Color(0xFF5C6BC0)
                        : const Color(0xFF1A237E),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _staffList.length + 1, // +1 for pagination
                      itemBuilder: (context, index) {
                        if (index == _staffList.length) {
                          // Pagination
                          return _buildPagination(isDark);
                        }
                        final staff = _staffList[index];
                        return StaffCard(staff: staff, isDark: isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 && !_isLoading
                ? () {
                    setState(() => _currentPage--);
                    _loadStaff();
                  }
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF5C6BC0).withOpacity(0.1)
                  : const Color(0xFF1A237E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Trang ${_currentPage + 1}/$_totalPages',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFE8EAED)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages - 1 && !_isLoading
                ? () {
                    setState(() => _currentPage++);
                    _loadStaff();
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
          ),
        ],
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final bool isDark;

  const StaffCard({super.key, required this.staff, required this.isDark});

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'N';
    final parts = fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'N';
    if (parts.length == 1) {
      final first = parts[0];
      if (first.isEmpty) return 'N';
      return first
          .substring(0, first.length > 1 ? 1 : first.length)
          .toUpperCase();
    }
    // Lấy chữ cái đầu của từ đầu và từ cuối
    final first = parts.first;
    final last = parts.last;
    final firstChar = first.isNotEmpty ? first.substring(0, 1) : '';
    final lastChar = last.isNotEmpty ? last.substring(0, 1) : '';
    if (firstChar.isEmpty && lastChar.isEmpty) return 'N';
    return (firstChar + lastChar).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = staff['active'] == true || staff['isActive'] == true;
    final fullName = staff['fullName']?.toString() ?? 'N/A';
    final surfaceColor = isDark ? const Color(0xFF1A2332) : Colors.white;
    final borderColor = isDark
        ? Colors.grey[800]!.withOpacity(0.5)
        : Colors.grey[200]!.withOpacity(0.8);
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
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
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6D28D9),
                        const Color(0xFF7C3AED),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(staff['fullName']?.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (staff['code'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.badge_rounded,
                              size: 14,
                              color: textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'admin.staff.code'.tr(
                                namedArgs: {'code': '${staff['code']}'},
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(
                            0xFF10B981,
                          ).withOpacity(isDark ? 0.2 : 0.12)
                        : Colors.red.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : Colors.red.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 14,
                        color: isActive ? const Color(0xFF10B981) : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive
                            ? 'admin.staff.active'.tr()
                            : 'admin.staff.inactive'.tr(),
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF10B981)
                              : Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[900]!.withOpacity(0.3)
                    : Colors.grey[50]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[200]!.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  if (staff['email'] != null)
                    StaffInfoRow(
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'admin.staff.email'.tr(),
                      value: staff['email'].toString(),
                      isDark: isDark,
                    ),
                  if (staff['phone'] != null) ...[
                    if (staff['email'] != null) const SizedBox(height: 12),
                    StaffInfoRow(
                      icon: Icons.phone_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      label: 'admin.staff.phone'.tr(),
                      value: staff['phone'].toString(),
                      isDark: isDark,
                    ),
                  ],
                  if (staff['roles'] != null &&
                      staff['roles'] is List &&
                      (staff['roles'] as List).isNotEmpty) ...[
                    if (staff['email'] != null || staff['phone'] != null)
                      const SizedBox(height: 12),
                    StaffInfoRow(
                      icon: Icons.badge_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'admin.staff.role'.tr(),
                      value: (staff['roles'] as List)
                          .map((r) {
                            try {
                              if (r is Map<String, dynamic>) {
                                return r['roleName']?.toString() ??
                                    r['name']?.toString() ??
                                    r.toString();
                              }
                              return r.toString();
                            } catch (e) {
                              return r.toString();
                            }
                          })
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      isDark: isDark,
                    ),
                  ],
                  if (staff['departmentName'] != null) ...[
                    if (staff['email'] != null ||
                        staff['phone'] != null ||
                        (staff['roles'] != null && staff['roles'] is List))
                      const SizedBox(height: 12),
                    StaffInfoRow(
                      icon: Icons.business_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'admin.staff.department'.tr(),
                      value: staff['departmentName'].toString(),
                      isDark: isDark,
                    ),
                  ],
                  if (staff['clinics'] != null &&
                      staff['clinics'] is List &&
                      (staff['clinics'] as List).isNotEmpty) ...[
                    if (staff['email'] != null ||
                        staff['phone'] != null ||
                        staff['roles'] != null ||
                        staff['departmentName'] != null)
                      const SizedBox(height: 12),
                    StaffInfoRow(
                      icon: Icons.local_hospital_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'admin.common.clinic'.tr(),
                      value: (staff['clinics'] as List)
                          .map((c) {
                            try {
                              if (c is Map<String, dynamic>) {
                                return c['clinicName']?.toString() ??
                                    c['name']?.toString() ??
                                    c.toString();
                              }
                              return c.toString();
                            } catch (e) {
                              return c.toString();
                            }
                          })
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const StaffInfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDark ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
