import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../services/admin_service.dart';
import 'package:intl/intl.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _inventoryStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [statsData, inventoryData] = await Future.wait([
        _adminService.fetchDashboardStats(),
        _adminService.fetchInventoryStatistics(),
      ]);
      
      // Debug log để kiểm tra dữ liệu
      debugPrint('Dashboard Stats Response: $statsData');
      debugPrint('Inventory Stats Response: $inventoryData');
      
      setState(() {
        _stats = statsData;
        _inventoryStats = inventoryData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading data: $e');
      Fluttertoast.showToast(msg: 'Không thể tải dữ liệu: $e');
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 ₫';
    // Xử lý cả int, double, String (BigDecimal từ Java có thể là String)
    final numValue = value is num 
        ? value.toDouble() 
        : double.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(numValue);
  }

  // Helper để parse số từ API (có thể là int, long, String)
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // Helper để parse số thực từ API (có thể là BigDecimal, double, String)
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: const Text(
          'Báo cáo & Thống kê',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Section
                    _buildSectionTitle('Doanh thu', Icons.trending_up_rounded, const Color(0xFF10B981), isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            'Tháng này',
                            _formatCurrency(_stats['monthRevenue']),
                            Icons.calendar_month_rounded,
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            'Lợi nhuận',
                            _formatCurrency(_stats['netProfit']),
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF14B8A6),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Appointments Section
                    _buildSectionTitle('Lịch hẹn', Icons.calendar_today_rounded, const Color(0xFF3B82F6), isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            'Tháng này',
                            '${_parseInt(_stats['monthAppointments'])}',
                            Icons.calendar_month_rounded,
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            'Đã hủy',
                            '${_parseInt(_stats['todayCancelledAppointments'])}',
                            Icons.cancel_rounded,
                            const Color(0xFFEF4444),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Staff & Patients Section
                    _buildSectionTitle('Nhân sự & Bệnh nhân', Icons.people_rounded, const Color(0xFF6366F1), isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            'Tổng nhân viên',
                            '${_parseInt(_stats['totalStaff'])}',
                            Icons.people_alt_rounded,
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            'Tổng bệnh nhân',
                            '${_parseInt(_stats['totalPatients'])}',
                            Icons.person_outline_rounded,
                            const Color(0xFF06B6D4),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Clinics Section
                    _buildSectionTitle('Phòng khám', Icons.local_hospital_rounded, const Color(0xFFEF4444), isDark),
                    const SizedBox(height: 12),
                    _StatCard(
                      'Tổng phòng khám',
                      '${_parseInt(_stats['totalClinics'])}',
                      Icons.business_rounded,
                      const Color(0xFF3B82F6),
                      isDark,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 20),

                    // Inventory Section
                    if (_inventoryStats.isNotEmpty) ...[
                      _buildSectionTitle('Cảnh báo kho hàng', Icons.warning_rounded, const Color(0xFFF59E0B), isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              'Sắp hết',
                              '${_parseInt(_inventoryStats['lowStockProductsCount'])}',
                              Icons.warning_rounded,
                              const Color(0xFFF59E0B),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              'Hết hàng',
                              '${_parseInt(_inventoryStats['outOfStockProductsCount'])}',
                              Icons.error_rounded,
                              const Color(0xFFEF4444),
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Pending Actions
                    if ((_stats['pendingLeaveRequests'] ?? 0) > 0) ...[
                      _buildSectionTitle('Cần xử lý', Icons.notifications_active_rounded, const Color(0xFFF59E0B), isDark),
                      const SizedBox(height: 12),
                      _StatCard(
                        'Đơn nghỉ chờ',
                        '${_parseInt(_stats['pendingLeaveRequests'])}',
                        Icons.description_rounded,
                        const Color(0xFFF59E0B),
                        isDark,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<_StatCard> cards) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isFullWidth;

  const _StatCard(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.isDark, {
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = isDark 
        ? color.withOpacity(0.15)
        : color.withOpacity(0.08);
    final borderColor = color.withOpacity(isDark ? 0.2 : 0.15);
    final textColor = colorScheme.onSurface;
    final textSecondaryColor = colorScheme.onSurfaceVariant;

    return Container(
      constraints: isFullWidth ? null : const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDark ? 0.3 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDark ? 0.3 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}

