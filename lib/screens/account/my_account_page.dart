import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../../providers/user_provider.dart';

// Import các Widget con
import 'widgets/account_form.dart';
import 'widgets/avatar_uploader.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingUser = true;
  XFile? _newAvatar;
  String? _previewUrl;
  Map<String, dynamic>? _user;

  // Kiểm tra xem user có phải là nhân viên cần chấm công không
  // Nhân viên chấm công: DOCTOR, HR, RECEPTION, ACCOUNTANT
  bool _isEmployeeForAttendance() {
    if (_user == null) return false;
    final roles = _user!['roles'];
    if (roles == null) return false;
    
    List<String> normalizedRoles = [];
    if (roles is List) {
      normalizedRoles = roles.map((role) => role.toString().toUpperCase()).toList();
    } else if (roles is String) {
      normalizedRoles = roles.split(',').map((role) => role.trim().toUpperCase()).toList();
    }
    
    // Các role cần chấm công: DOCTOR, HR, RECEPTION, ACCOUNTANT
    final attendanceRoles = ['DOCTOR', 'HR', 'RECEPTION', 'ACCOUNTANT'];
    return normalizedRoles.any((role) => attendanceRoles.contains(role));
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final response = await ApiService().get('/api/users/me');
      final userData = response.data;

      setState(() {
        _user = userData;
        _fullNameController.text = userData['fullName'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      });

      await prefs.setString('user', jsonEncode(userData));
      if (mounted) {
        context.read<UserProvider>().setUser(userData);
      }
    } catch (e) {
      if (mounted) context.go('/login');
    } finally {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  // Hàm cho phép chọn hình đại diện mới từ thư viện ảnh hoặc camera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newAvatar = image;
        _previewUrl = image.path;
      });
    }
  }

  // Hàm chụp ảnh khuôn mặt bằng camera mới (để đăng ký face profile chuẩn)
  Future<void> _captureFaceForRegistration() async {
    try {
      // Mở màn hình camera với overlay hướng dẫn
      final XFile? image = await context.push<XFile>('/face-camera');
      if (image != null) {
        setState(() {
          _newAvatar = image;
          _previewUrl = image.path;
        });
        // Chỉ preview, không tự động upload - người dùng sẽ tự quyết định upload
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Không thể mở camera. Vui lòng thử lại.',
        backgroundColor: Colors.red,
      );
    }
  }

  // Upload hình đại diện mới lên server
  Future<void> _uploadAvatar() async {
    if (_newAvatar == null || _user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      Fluttertoast.showToast(msg: 'common.signInRequired'.tr());
      return;
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_newAvatar!.path),
      });

      final response = await ApiService().dio.patch(
        '/api/users/${_user!['userId']}/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final updatedUser = {..._user!, 'avatarUrl': response.data['avatarUrl']};
      setState(() {
        _user = updatedUser;
        _newAvatar = null;
        _previewUrl = null;
      });

      await prefs.setString('user', jsonEncode(updatedUser));
      if (mounted) {
        context.read<UserProvider>().updateUser(updatedUser);
      }

      Fluttertoast.showToast(
        msg: 'account.myAccount.uploadAvatar.success'.tr(),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'account.myAccount.uploadAvatar.failed'.tr());
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().patch(
        '/api/users/${_user!['userId']}',
        data: {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      final updatedUser = response.data;
      setState(() => _user = updatedUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser));
      if (mounted) {
        context.read<UserProvider>().setUser(updatedUser);
      }

      Fluttertoast.showToast(msg: 'account.myAccount.success'.tr());
    } catch (e) {
      Fluttertoast.showToast(msg: 'account.myAccount.failed'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingUser) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text('account.myAccount.title'.tr()),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 960;

          // Khởi tạo các widget con
          final avatarSection = AvatarUploader(
            currentAvatarUrl: _user?['avatarUrl'],
            previewPath: _previewUrl,
            onPickImage: _pickImage,
            onUpload: _uploadAvatar,
          );

          final formSection = AccountForm(
            formKey: _formKey,
            fullNameController: _fullNameController,
            emailController: _emailController,
            phoneController: _phoneController,
            username: _user?['username'] ?? '-',
            hasPassword: _user?['hasPassword'] == true,
            isLoading: _isLoading,
            onSave: _saveChanges,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: formSection),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: avatarSection),
                            ],
                          )
                        : Column(
                            children: [
                              avatarSection,
                              const SizedBox(height: 24),
                              formSection,
                            ],
                          ),
                    const SizedBox(height: 28),
                    // Action buttons section with improved styling
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.surface,
                              colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _saveChanges,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'account.myAccount.saveChanges'.tr(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                  ),
                                ),
                                if (_user?['hasPassword'] == true) ...[
                                  const SizedBox(width: 16),
                                  OutlinedButton.icon(
                                    onPressed: () => context.go('/change-password'),
                                    icon: const Icon(Icons.lock_reset_rounded, size: 20),
                                    label: Text(
                                      'account.changePassword.title'.tr(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                        horizontal: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      side: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Button cập nhật khuôn mặt chấm công (chỉ cho nhân viên)
                            if (_buildUpdateFaceProfileButton(context) != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: _buildUpdateFaceProfileButton(context)!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Render card hình đại diện và chức năng upload ảnh mới
  Widget _buildAvatarCard(BuildContext context, dynamic avatarSrc) {
    final colorScheme = Theme.of(context).colorScheme;

    ImageProvider? avatarImage;
    if (_previewUrl != null) {
      avatarImage = FileImage(File(_previewUrl!));
    } else if (avatarSrc is String) {
      avatarImage = ApiService.resolveAvatarImage(avatarSrc);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'account.myAccount.avatarTitle'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 70,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: CircleAvatar(
                radius: 66,
                backgroundImage: avatarImage,
                backgroundColor: colorScheme.surfaceVariant,
                child: avatarImage == null
                    ? Icon(Icons.person, size: 64, color: colorScheme.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // Button chụp ảnh khuôn mặt để đăng ký (ưu tiên)
            FilledButton.icon(
              onPressed: _captureFaceForRegistration,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Chụp ảnh đăng ký khuôn mặt'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            // Button chọn từ thư viện
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text('account.myAccount.chooseAvatar'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: colorScheme.primary),
              ),
            ),
            if (_newAvatar != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploadAvatar,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text('account.myAccount.uploadAvatar.button'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Button để navigate đến màn hình cập nhật khuôn mặt chấm công (chỉ cho nhân viên)
  Widget? _buildUpdateFaceProfileButton(BuildContext context) {
    if (!_isEmployeeForAttendance()) return null;
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return OutlinedButton.icon(
      onPressed: () => context.push('/update-face-profile'),
      icon: const Icon(Icons.face_retouching_natural_rounded, size: 20),
      label: const Text(
        'Cập nhật khuôn mặt chấm công',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // Render một trường form có gắn icon
  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
