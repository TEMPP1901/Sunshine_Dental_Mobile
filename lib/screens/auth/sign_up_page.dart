import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/user_provider.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/avatar_picker.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  XFile? _pickedFile;
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      Fluttertoast.showToast(
        msg: "Passwords do not match",
        backgroundColor: Colors.red,
      );
      return;
    }

    final provider = context.read<UserProvider>();
    final userId = await provider.signUp(
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (userId != null) {
      if (_pickedFile != null) {
        await provider.uploadAvatar(userId, _pickedFile!.path);
      }
      Fluttertoast.showToast(
        msg: "Registration successful! Please Login.",
        backgroundColor: Colors.green,
      );
      if (mounted) context.go('/login');
    } else {
      Fluttertoast.showToast(
        msg: provider.errorMessage ?? "Registration failed",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AvatarPicker(onImagePicked: (file) => _pickedFile = file),
              const SizedBox(height: 30),

              AuthTextField(
                label: "Full Name",
                controller: _nameCtrl,
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: "Username",
                controller: _usernameCtrl,
                icon: Icons.account_circle,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: "Email",
                controller: _emailCtrl,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: "Phone",
                controller: _phoneCtrl,
                icon: Icons.phone,
                isNumber: true,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: "Password",
                controller: _passCtrl,
                icon: Icons.lock,
                isPassword: true,
                showPassword: _showPass,
                onTogglePassword: () => setState(() => _showPass = !_showPass),
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: "Confirm Password",
                controller: _confirmCtrl,
                icon: Icons.lock_clock,
                isPassword: true,
                showPassword: _showConfirm,
                onTogglePassword: () =>
                    setState(() => _showConfirm = !_showConfirm),
              ),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: isLoading ? null : _handleSignUp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF3366FF),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
