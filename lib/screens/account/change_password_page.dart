import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Biểu thức kiểm tra quy tắc password
  final _passwordRule = RegExp(
    r'^(?=\S+$)(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,100}$',
  );

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hàm xử lý đổi mật khẩu
  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra mật khẩu cũ và mới không được giống nhau
    if (_oldPasswordController.text == _newPasswordController.text) {
      Fluttertoast.showToast(
        msg: 'Current and new password must be different.',
      );
      return;
    }

    // Kiểm tra mật khẩu mới có hợp lệ không
    if (!_passwordRule.hasMatch(_newPasswordController.text)) {
      Fluttertoast.showToast(
        msg:
            'Password must be at least 8 characters and include upper, lower case, number, and special character.',
      );
      return;
    }

    // Kiểm tra xác nhận mật khẩu mới
    if (_newPasswordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(msg: 'Password confirmation does not match.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    // Kiểm tra đăng nhập
    if (token == null) {
      Fluttertoast.showToast(msg: 'Sign in is required.');
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().post(
        '/api/auth/change-password',
        data: {
          'currentPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmNewPassword': _confirmPasswordController.text,
        },
      );

      Fluttertoast.showToast(msg: 'Password changed successfully.');
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Chuyển hướng sang trang tài khoản sau khi đổi mật khẩu thành công
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go('/my-account');
          }
        });
      }
    } catch (e) {
      String errorMsg = 'Error changing password';
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data != null) {
          if (data is List) {
            errorMsg = data.join(', ');
          } else if (data['errors'] is List) {
            errorMsg = (data['errors'] as List).join(', ');
          } else {
            errorMsg = data['message'] ?? data['error'] ?? errorMsg;
          }
        }
      }
      Fluttertoast.showToast(msg: errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
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
                context.go('/my-account');
              }
            },
          ),
          title: Text('Change Password'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lock_reset_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change Password',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Update your password to secure your account.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPasswordField(
                                  context,
                                  controller: _oldPasswordController,
                                  label: 'Current Password',
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  context,
                                  controller: _newPasswordController,
                                  label: 'New Password',
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  context,
                                  controller: _confirmPasswordController,
                                  label: 'Confirm New Password',
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleChangePassword,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text('Update Password'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng trường nhập mật khẩu
  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please fill in this field!';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
