import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _selectedAvatarUrl;
  XFile? _customAvatar;
  String? _previewUrl;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildAvatarSection(List<String> defaultAvatars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your avatar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: defaultAvatars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final avatarUrl = defaultAvatars[index];
              final isSelected = _selectedAvatarUrl == avatarUrl;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatarUrl = avatarUrl;
                    _customAvatar = null;
                    _previewUrl = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF52B8FF), Color(0xFF3366FF)],
                          )
                        : null,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage(avatarUrl),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ),
              );
            },
          ),
        ),
        if (_previewUrl != null) ...[
          const SizedBox(height: 16),
          Text(
            'Preview custom avatar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 44,
            backgroundImage: FileImage(File(_previewUrl!)),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_rounded),
          label: Text('Choose file'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF3366FF)) : null,
      filled: true,
      fillColor: isDark
          ? theme.inputDecorationTheme.fillColor
          : const Color(0xFFF5F7FB),
      labelStyle: TextStyle(
        color: isDark
            ? theme.colorScheme.onSurface.withOpacity(0.7)
            : null,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: isDark
              ? Colors.grey.shade700
              : Colors.transparent,
          width: isDark ? 1 : 0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: isDark
              ? Colors.grey.shade700
              : Colors.transparent,
          width: isDark ? 1 : 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF3366FF), width: 1.5),
      ),
    );
  }

  Widget _buildFormSection(List<String> defaultAvatars) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create a new account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Please fill out the form below to register',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _fullNameController,
            decoration: _inputDecoration(
              'Full name',
              Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: _inputDecoration(
              'Username',
              Icons.badge_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              'Email',
              Icons.alternate_email_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (!value.contains('@')) {
                return 'Invalid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              'Phone number',
              Icons.phone_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: _inputDecoration(
              'Password',
              Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: _inputDecoration(
              'Confirm password',
              Icons.lock_open_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildAvatarSection(defaultAvatars),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Sign Up',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(text: "Already have an account? "),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        "Login",
                        style: const TextStyle(
                          color: Color(0xFF0D6EFD),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Phương thức chọn ảnh đại diện tuỳ chỉnh bằng thư viện image_picker
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _customAvatar = image;
        _previewUrl = image.path;
        _selectedAvatarUrl = null;
      });
    }
  }

  // Xử lý logic đăng ký tài khoản mới và upload avatar nếu có
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(
        msg: 'Passwords do not match',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Chuẩn bị đường dẫn avatar
      String? initialAvatarUrl;
      if (_selectedAvatarUrl != null) {
        initialAvatarUrl = _selectedAvatarUrl;
        if (!initialAvatarUrl!.startsWith('/')) {
          initialAvatarUrl = '/$initialAvatarUrl';
        }
      }

      // Gửi dữ liệu đăng ký lên server
      final response = await ApiService().post(
        '/api/auth/sign-up',
        data: {
          'fullName': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'avatarUrl': initialAvatarUrl,
          'locale': 'en',
        },
      );

      final data = response.data;
      final userId = data['userId'];
      final patientCode = data['patientCode'];

      if (userId == null) {
        throw Exception('Account ID is missing!');
      }

      // Nếu người dùng chọn avatar tuỳ chỉnh thì upload avatar đó lên
      if (_customAvatar != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_customAvatar!.path),
        });
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) {
          await ApiService().dio.patch(
            '/api/users/$userId/avatar',
            data: formData,
            options: Options(
              contentType: 'multipart/form-data',
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
        }
      }

      // Hiển thị thông báo đăng ký thành công
      String successMsg = 'Registration successful';
      if (patientCode != null) {
        successMsg = '$successMsg — Your patient code: $patientCode';
      }
      Fluttertoast.showToast(
        msg: successMsg,
        toastLength: Toast.LENGTH_SHORT,
      );

      // Sau 2s chuyển sang trang đăng nhập
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      // Xử lý các trường hợp lỗi khi đăng ký
      String errorMsg = 'Registration failed. Please try again!';
      if (e is DioException && e.response != null) {
        final message = e.response?.data?['message'];
        if (message != null) {
          errorMsg = message is List ? message.join(', ') : message.toString();
        }
      }
      Fluttertoast.showToast(
        msg: errorMsg,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultAvatars = [
      'assets/avatars/avatar1.png',
      'assets/avatars/avatar2.png',
      'assets/avatars/avatar3.png',
      'assets/avatars/avatar4.png',
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: context.canPop(),
      onPopInvoked: (didPop) {
        if (!didPop && !context.canPop()) {
          // Nếu ở trang root thì quay lại màn hình login
          context.go('/login');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A0A),
                      const Color(0xFF1A1A2E),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF05152E), Color(0xFF030A1A)],
                  ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? theme.cardColor : const Color(0xFFE8F4F8),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 220,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                ),
                                image: DecorationImage(
                                  image: AssetImage('assets/images/doctor.png'),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(40),
                                    topRight: Radius.circular(40),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF05152E).withOpacity(0.55),
                                      const Color(0xFF05152E).withOpacity(0.1),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                alignment: Alignment.bottomLeft,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: _buildFormSection(defaultAvatars),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
