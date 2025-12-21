import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // Import i18n

import '../../../../services/api_service.dart';
import '../../../../providers/user_provider.dart';
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

  // [AN TOÀN] Hàm chuẩn hóa giới tính từ API
  String? _normalizeGender(String? rawGender) {
    if (rawGender == null || rawGender.isEmpty) return null;
    final g = rawGender.trim().toLowerCase();

    if (g == 'nam' || g == 'male' || g == 'm') return 'Male';
    if (g == 'nữ' || g == 'nu' || g == 'female' || g == 'f') return 'Female';

    return 'Other';
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _service.getPatientProfile();
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
          if (data != null) {
            _nameController.text = data.fullName;
            _addressController.text = data.address ?? '';
            _noteController.text = data.note ?? '';
            _selectedGender = _normalizeGender(data.gender);
            _selectedDate = data.dateOfBirth;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "patientProfile.toast.loadFailed".tr());
      }
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
        msg: "patientProfile.toast.updateSuccess".tr(),
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "patientProfile.toast.updateError".tr(),
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final avatarUrl = user?['avatarUrl'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "patientProfile.title".tr(), // KEY MỚI
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                      _isEditing ? "common.save".tr() : "common.edit".tr(),
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
          ? Center(child: Text("patientProfile.toast.loadFailed".tr()))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderBanner(avatarUrl),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            "patientProfile.personalInfo".tr(),
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            "patientProfile.fullName".tr(),
                            _nameController,
                            Icons.person,
                            enabled: _isEditing,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _buildReadOnlyField(
                                  "patientProfile.phone".tr(),
                                  _profile!.phone,
                                  Icons.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReadOnlyField(
                                  "patientProfile.code".tr(),
                                  _profile!.patientCode,
                                  Icons.qr_code,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildGenderDropdown()),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDatePicker(context)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            "patientProfile.address".tr(),
                            _addressController,
                            Icons.location_on,
                            enabled: _isEditing,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle("patientProfile.medicalInfo".tr()),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _noteController,
                            enabled: _isEditing,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "patientProfile.noteHint".tr(),
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

  Widget _buildHeaderBanner(String? avatarUrl) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
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
        validator: (val) =>
            val!.isEmpty ? "common.required".tr(args: [label]) : null,
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
    const validValues = ["Male", "Female", "Other"];

    // Kiểm tra an toàn
    String? safeValue = _selectedGender;
    if (safeValue != null && !validValues.contains(safeValue)) {
      safeValue = null;
    }

    return DropdownButtonFormField<String>(
      isExpanded: true, // Fix lỗi RenderFlex overflowed
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: "patientProfile.genderLabel".tr(), // KEY MỚI
        prefixIcon: const Icon(Icons.transgender, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
      ),
      items: validValues
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                "patientProfile.gender.$e".tr(), // KEY MỚI
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
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
          labelText: "patientProfile.dob".tr(), // KEY MỚI
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 15,
          ),
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
              : "common.selectDate".tr(),
          style: TextStyle(
            color: _selectedDate != null ? Colors.black : Colors.grey,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
