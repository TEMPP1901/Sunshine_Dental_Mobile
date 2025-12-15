import 'package:flutter/material.dart';
import 'auth_text_field.dart';

class LoginFormEmail extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final bool isLoading;

  const LoginFormEmail({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onForgotPassword,
    required this.isLoading,
  });

  @override
  State<LoginFormEmail> createState() => _LoginFormEmailState();
}

class _LoginFormEmailState extends State<LoginFormEmail> {
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextField(
            label: "Email Address",
            controller: widget.emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress, // Bàn phím email
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: "Password",
            controller: widget.passwordController,
            icon: Icons.lock_outline,
            isPassword: true,
            showPassword: _showPassword,
            onTogglePassword: () =>
                setState(() => _showPassword = !_showPassword),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: const Text(
                "Forgot Password?",
                style: TextStyle(color: Color(0xFF3366FF)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      widget.onLogin();
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF3366FF),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Login",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
