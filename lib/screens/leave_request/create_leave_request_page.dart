import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../services/leave_request_service.dart';
import '../../services/api_service.dart';

// Tạo trang yêu cầu nghỉ mới
class CreateLeaveRequestPage extends StatefulWidget {
  const CreateLeaveRequestPage({super.key});

  @override
  State<CreateLeaveRequestPage> createState() => _CreateLeaveRequestPageState();
}

class _CreateLeaveRequestPageState extends State<CreateLeaveRequestPage> {
  final LeaveRequestService _leaveRequestService = LeaveRequestService();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // Kiểm tra xem user có là bác sĩ không
  Future<void> _checkUserRole() async {
    try {
      final response = await _apiService.get('/api/users/me');
      final userData = response.data as Map<String, dynamic>;
      final jobTitle = (userData['jobTitle'] as String? ?? '').toUpperCase();
      final roles = (userData['roles'] as List<dynamic>? ?? [])
          .map((r) => r.toString().toUpperCase())
          .toList();

      final isDoctorRole =
          jobTitle.contains('DOCTOR') ||
          jobTitle.contains('BÁC SĨ') ||
          roles.any((r) => r.contains('DOCTOR'));

      setState(() {
        _isDoctor = isDoctorRole;
      });
    } catch (e) {
      // Nếu lỗi, mặc định không phải bác sĩ
      setState(() {
        _isDoctor = false;
      });
    }
  }

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'VACATION';
  String _selectedShiftType = 'FULL_DAY';
  bool _isLoading = false;
  bool _isDoctor = false;

  final List<String> _leaveTypes = ['VACATION', 'SICK', 'PERSONAL', 'OTHER'];
  final List<String> _shiftTypes = ['FULL_DAY', 'MORNING', 'AFTERNOON'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Chọn ngày bắt đầu hoặc ngày kết thúc
  Future<void> _selectDate(bool isStartDate) async {
    final now = DateTime.now();
    final firstDate = isStartDate ? now : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: isStartDate ? now : (_startDate ?? now),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Gửi yêu cầu nghỉ
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      Fluttertoast.showToast(msg: 'Please select start and end dates');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      Fluttertoast.showToast(msg: 'End date must be after start date');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _leaveRequestService.createLeaveRequest(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        type: _selectedType,
        reason: _reasonController.text.trim(),
        shiftType: _isDoctor ? _selectedShiftType : null,
      );

      Fluttertoast.showToast(msg: 'leaveRequest.createSuccess'.tr());
      if (context.mounted) {
        context.pop(true);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Trả về nhãn hiển thị cho loại nghỉ
  String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'VACATION':
        return 'leaveRequest.types.vacation'.tr();
      case 'SICK':
        return 'leaveRequest.types.sick'.tr();
      case 'PERSONAL':
        return 'leaveRequest.types.personal'.tr();
      case 'OTHER':
        return 'leaveRequest.types.other'.tr();
      default:
        return type;
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/leave-request');
            }
          },
        ),
        title: Text(
          'leaveRequest.createTitle'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1A2332).withOpacity(0.5)
                    : colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vui lòng điền đầy đủ thông tin để gửi yêu cầu nghỉ phép',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chọn ngày bắt đầu
            _buildDateField(
              context,
              label: 'leaveRequest.startDate'.tr(),
              date: _startDate,
              onTap: () => _selectDate(true),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Chọn ngày kết thúc
            _buildDateField(
              context,
              label: 'leaveRequest.endDate'.tr(),
              date: _endDate,
              onTap: () => _selectDate(false),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Chọn loại nghỉ
            _buildDropdownField(
              context,
              label: 'leaveRequest.type'.tr(),
              icon: Icons.category_rounded,
              value: _getTypeLabel(_selectedType),
              items: _leaveTypes.map((type) => _getTypeLabel(type)).toList(),
              onChanged: (index) {
                setState(() {
                  _selectedType = _leaveTypes[index];
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Chọn ca làm việc (chỉ hiển thị nếu là bác sĩ)
            if (_isDoctor) ...[
              _buildDropdownField(
                context,
                label: 'leaveRequest.shiftType'.tr(),
                icon: Icons.access_time_rounded,
                value: _getShiftLabel(_selectedShiftType),
                items: _shiftTypes.map((shift) => _getShiftLabel(shift)).toList(),
                onChanged: (index) {
                  setState(() {
                    _selectedShiftType = _shiftTypes[index];
                  });
                },
                helperText: 'leaveRequest.shiftTypeHint'.tr(),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],

            // Nhập lý do nghỉ
            _buildReasonField(context, isDark),
            const SizedBox(height: 32),

            // Nút gửi yêu cầu
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'common.submit'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getShiftLabel(String shiftType) {
    switch (shiftType) {
      case 'FULL_DAY':
        return 'leaveRequest.shiftTypes.fullDay'.tr();
      case 'MORNING':
        return 'leaveRequest.shiftTypes.morning'.tr();
      case 'AFTERNOON':
        return 'leaveRequest.shiftTypes.afternoon'.tr();
      default:
        return shiftType;
    }
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1A2332).withOpacity(0.6)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date!)
                        : 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                      color: date != null 
                          ? colorScheme.onSurface 
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(int) onChanged,
    String? helperText,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A2332).withOpacity(0.6)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              _showCustomDropdown(context, label, items, onChanged, isDark);
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
          if (helperText != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                helperText,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonField(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A2332).withOpacity(0.6)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _reasonController,
        maxLines: 4,
        style: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'leaveRequest.reason'.tr(),
          hintText: 'leaveRequest.reasonPlaceholder'.tr(),
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontSize: 15,
          ),
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.note_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập lý do nghỉ phép';
          }
          return null;
        },
      ),
    );
  }

  void _showCustomDropdown(
    BuildContext context,
    String title,
    List<String> items,
    Function(int) onChanged,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                title: Text(
                  item,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  onChanged(index);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

