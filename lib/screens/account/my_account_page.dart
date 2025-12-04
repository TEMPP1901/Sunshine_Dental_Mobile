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
  static const String defaultAvatar =
      'https://res.cloudinary.com/dchzko3lj/image/upload/v1762616672/default-avatar_brvdfn.png';

  @override
  void initState() {
    super.initState();
    // Hàm load user và dữ liệu user từ API, đồng thời kiểm tra đăng nhập
    _loadUser();
  }

  // Lấy dữ liệu user từ API và kiểm tra token đăng nhập.
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      if (mounted) {
        context.go('/login');
      }
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
      if (mounted) {
        context.go('/login');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  // Hàm cho phép chọn hình đại diện mới từ thư viện ảnh
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

      Fluttertoast.showToast(msg: 'account.myAccount.uploadAvatar.success'.tr());
    } catch (e) {
      Fluttertoast.showToast(msg: 'account.myAccount.uploadAvatar.failed'.tr());
    }
  }

  // Hàm lưu thay đổi thông tin user
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      Fluttertoast.showToast(msg: 'common.signInRequired'.tr());
      return;
    }

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

      await prefs.setString('user', jsonEncode(updatedUser));
      if (mounted) {
        context.read<UserProvider>().setUser(updatedUser);
      }

      Fluttertoast.showToast(msg: 'account.myAccount.success'.tr());
    } catch (e) {
      Fluttertoast.showToast(msg: 'account.myAccount.failed'.tr());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingUser) {
      return PopScope(
        canPop: context.canPop(),
        child: Scaffold(
          backgroundColor: colorScheme.background,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final avatarSrc = _previewUrl != null
        ? File(_previewUrl!)
        : (_user?['avatarUrl'] != null &&
                _user!['avatarUrl'].toString().trim().isNotEmpty
            ? _user!['avatarUrl']
            : defaultAvatar);

    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text('account.myAccount.title'.tr()),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 960;

            Widget formSection = _buildFormCard(context);
            Widget avatarSection = _buildAvatarCard(context, avatarSrc);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Render thông tin form tài khoản
  Widget _buildFormCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'account.myAccount.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                context,
                controller: _fullNameController,
                label: 'account.myAccount.fullName'.tr(),
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'account.myAccount.validation.fullName'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: _emailController,
                label: 'account.myAccount.email'.tr(),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'account.myAccount.validation.email'.tr();
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'account.myAccount.validation.emailFormat'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: _phoneController,
                label: 'account.myAccount.phone'.tr(),
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${'account.myAccount.username'.tr()}: ${_user?['username'] ?? '-'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('account.myAccount.saveChanges'.tr()),
                    ),
                  ),
                  if (_user?['hasPassword'] == true) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/change-password'),
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: Text('account.changePassword.title'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
            FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text('account.myAccount.chooseAvatar'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      ),
    );
  }
}
