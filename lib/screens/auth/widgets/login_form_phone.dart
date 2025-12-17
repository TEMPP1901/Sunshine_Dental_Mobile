import 'package:flutter/material.dart';
import 'auth_text_field.dart';

class LoginFormPhone extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController otpController;
  final Function(bool isOtpMode) onLogin;
  final Function(String phone) onSendOtp;
  final bool isLoading;
  final bool otpSent;
  final int countdown;
  final VoidCallback onResetOtp;

  const LoginFormPhone({
    super.key,
    required this.phoneController,
    required this.passwordController,
    required this.otpController,
    required this.onLogin,
    required this.onSendOtp,
    required this.isLoading,
    required this.otpSent,
    required this.countdown,
    required this.onResetOtp,
  });

  @override
  State<LoginFormPhone> createState() => _LoginFormPhoneState();
}

class _LoginFormPhoneState extends State<LoginFormPhone> {
  bool _isOtpMode = false;
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Toggle Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab(
                  "Password",
                  !_isOtpMode,
                  () => setState(() => _isOtpMode = false),
                ),
                _buildTab(
                  "OTP Code",
                  _isOtpMode,
                  () => setState(() => _isOtpMode = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Phone Input
          AuthTextField(
            label: "Phone Number",
            controller: widget.phoneController,
            icon: Icons.phone_android,
            isNumber: true,
            enabled: !widget.otpSent, // Khóa khi đã gửi OTP
          ),
          const SizedBox(height: 16),

          // Conditional Input (Pass or OTP)
          if (!_isOtpMode)
            AuthTextField(
              label: "Password",
              controller: widget.passwordController,
              icon: Icons.lock_outline,
              isPassword: true,
              showPassword: _showPassword,
              onTogglePassword: () =>
                  setState(() => _showPassword = !_showPassword),
            )
          else if (widget.otpSent)
            Column(
              children: [
                AuthTextField(
                  label: "OTP Code",
                  controller: widget.otpController,
                  icon: Icons.message,
                  isNumber: true,
                  keyboardType: TextInputType.number,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onResetOtp,
                    child: const Text(
                      "Change Phone Number?",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Action Button
          FilledButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      if (_isOtpMode && !widget.otpSent) {
                        widget.onSendOtp(widget.phoneController.text);
                      } else {
                        widget.onLogin(_isOtpMode);
                      }
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _isOtpMode && !widget.otpSent
                  ? Colors
                        .black87 // Màu đen cho nút gửi OTP
                  : const Color(0xFF3366FF),
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
                : Text(
                    _isOtpMode
                        ? (widget.otpSent ? "Verify & Login" : "Get OTP Code")
                        : "Login",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          // Resend Link
          if (widget.otpSent && _isOtpMode)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: widget.countdown > 0
                    ? null
                    : () => widget.onSendOtp(widget.phoneController.text),
                child: Text(
                  widget.countdown > 0
                      ? "Resend OTP in ${widget.countdown}s"
                      : "Resend OTP",
                  style: TextStyle(
                    color: widget.countdown > 0
                        ? Colors.grey
                        : const Color(0xFF3366FF),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
