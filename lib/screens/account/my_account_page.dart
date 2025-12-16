import 'dart:convert';
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
    );
  }
}
