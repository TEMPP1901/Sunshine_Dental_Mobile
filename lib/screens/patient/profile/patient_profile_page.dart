import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // [MỚI]

import '../../../../services/api_service.dart'; // [MỚI] Để xử lý ảnh
import '../../../../providers/user_provider.dart'; // [MỚI] Để lấy thông tin user đăng nhập
import '../../../../services/patient/patient_service.dart';
import '../../../../models/patient/patient_profile_model.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final PatientService _service = PatientService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  PatientProfileDTO? _profile;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final data = await _service.getPatientProfile();
    if (mounted) {
      setState(() {
        _profile = data;
        _isLoading = false;
        if (data != null) {
          _nameController.text = data.fullName;
          _addressController.text = data.address ?? '';
          _noteController.text = data.note ?? '';
          _selectedGender = data.gender;
          _selectedDate = data.dateOfBirth;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final updateData = PatientProfileDTO(
        patientId: _profile!.patientId,
        fullName: _nameController.text.trim(),
        phone: _profile!.phone,
        email: _profile!.email,
        patientCode: _profile!.patientCode,
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
      );

      await _service.updatePatientProfile(updateData);

      setState(() {
        _profile = updateData;
        _isEditing = false;
      });
      Fluttertoast.showToast(
        msg: "Cập nhật thành công!",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Lỗi cập nhật: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // [MỚI] Lấy avatar từ UserProvider (giống localStorage bên web)
    final user = context.watch<UserProvider>().user;
    final avatarUrl = user?['avatarUrl'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Hồ sơ bệnh nhân",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing ? "Lưu" : "Sửa",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const Center(child: Text("Không tải được hồ sơ"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Truyền avatarUrl vào Header
                  _buildHeaderBanner(avatarUrl),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Thông tin cá nhân"),
                          const SizedBox(height: 16),

                          _buildTextField(
                            "Họ và tên",
                            _nameController,
                            Icons.person,
                            enabled: _isEditing,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _buildReadOnlyField(
                                  "Số điện thoại",
                                  _profile!.phone,
                                  Icons.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReadOnlyField(
                                  "Mã BN",
                                  _profile!.patientCode,
                                  Icons.qr_code,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(child: _buildGenderDropdown()),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDatePicker(context)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            "Địa chỉ liên hệ",
                            _addressController,
                            Icons.location_on,
                            enabled: _isEditing,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle("Thông tin y tế"),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _noteController,
                            enabled: _isEditing,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "Tiền sử bệnh / Dị ứng / Ghi chú",
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: _isEditing
                                  ? Colors.white
                                  : Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS CON ---

  // [CẬP NHẬT] Nhận avatarUrl làm tham số
  Widget _buildHeaderBanner(String? avatarUrl) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Banner nền
        Container(
          height: 140,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 50),
        ),
        // Avatar
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              // [FIX] Sử dụng ApiService để resolve ảnh
              backgroundImage: ApiService.resolveAvatarImage(avatarUrl),
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: (val) => val!.isEmpty ? "Vui lòng nhập $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: InputDecoration(
        labelText: "Giới tính",
        prefixIcon: const Icon(Icons.transgender, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[100],
      ),
      items: [
        "Nam",
        "Nữ",
        "Khác",
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: _isEditing
          ? (val) => setState(() => _selectedGender = val)
          : null,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: _isEditing
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Ngày sinh",
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[100],
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
              : "Chọn ngày",
          style: TextStyle(
            color: _selectedDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
