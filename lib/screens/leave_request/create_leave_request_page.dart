import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

      final isDoctorRole = jobTitle.contains('DOCTOR') ||
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
      initialDate: isStartDate ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
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
      Fluttertoast.showToast(
        msg: e.toString().replaceFirst('Exception: ', ''),
      );
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

    return Scaffold(
      appBar: AppBar(
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
        title: Text('leaveRequest.createTitle'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chọn ngày bắt đầu
            InkWell(
              onTap: () => _selectDate(true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'leaveRequest.startDate'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _startDate != null
                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                      : 'Select start date',
                  style: TextStyle(
                    color: _startDate != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chọn ngày kết thúc
            InkWell(
              onTap: () => _selectDate(false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'leaveRequest.endDate'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Select end date',
                  style: TextStyle(
                    color: _endDate != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chọn loại nghỉ
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'leaveRequest.type'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _leaveTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Chọn ca làm việc (chỉ hiển thị nếu là bác sĩ)
            if (_isDoctor)
              DropdownButtonFormField<String>(
                value: _selectedShiftType,
                decoration: InputDecoration(
                  labelText: 'leaveRequest.shiftType'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  helperText: 'leaveRequest.shiftTypeHint'.tr(),
                ),
                items: _shiftTypes.map((shiftType) {
                  String label;
                  switch (shiftType) {
                    case 'FULL_DAY':
                      label = 'leaveRequest.shiftTypes.fullDay'.tr();
                      break;
                    case 'MORNING':
                      label = 'leaveRequest.shiftTypes.morning'.tr();
                      break;
                    case 'AFTERNOON':
                      label = 'leaveRequest.shiftTypes.afternoon'.tr();
                      break;
                    default:
                      label = shiftType;
                  }
                  return DropdownMenuItem<String>(
                    value: shiftType,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedShiftType = value!;
                  });
                },
              ),
            if (_isDoctor) const SizedBox(height: 16),

            // Nhập lý do nghỉ
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'leaveRequest.reason'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
                hintText: 'leaveRequest.reasonPlaceholder'.tr(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Nút gửi yêu cầu
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.submit'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
