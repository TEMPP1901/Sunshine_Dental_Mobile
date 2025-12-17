import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final bool isNumber;
  final bool? enabled;
  final String? Function(String?)? validator;
  final VoidCallback? onTogglePassword;
  final bool showPassword;
  final TextInputType? keyboardType; // Thêm tham số này để linh hoạt hơn

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.isNumber = false,
    this.enabled,
    this.validator,
    this.onTogglePassword,
    this.showPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !showPassword,
          // Ưu tiên keyboardType truyền vào, nếu không thì check isNumber
          keyboardType:
              keyboardType ??
              (isNumber ? TextInputType.phone : TextInputType.text),
          enabled: enabled,
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3366FF), width: 2),
            ),
            filled: true,
            fillColor: enabled == false ? Colors.grey[100] : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
