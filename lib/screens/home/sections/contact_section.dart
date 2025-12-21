import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ContactSection extends StatefulWidget {
  const ContactSection({super.key});

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  // Controllers để quản lý text nhập vào
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // Giả lập gửi form
    if (_emailController.text.isEmpty || _messageController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Vui lòng điền đầy đủ thông tin");
      return;
    }

    // Clear form
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();

    // Show success (Giống hành vi web)
    Fluttertoast.showToast(
      msg: "Đã gửi tin nhắn thành công!",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Màu chữ đậm: #0D1B3E
    const textColor = Color(0xFF0D1B3E);

    return Column(
      children: [
        // 1. Tiêu đề & Ảnh (Giống phần Left side của Web)
        Text(
          'contact.title'.tr(), // "Liên hệ với chúng tôi"
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/images/contact-tooth.png', // Đảm bảo bạn có ảnh này
          height: 120,
          fit: BoxFit.contain,
          // Fallback nếu chưa có ảnh
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.mail_outline, size: 60, color: Colors.blue),
        ),
        const SizedBox(height: 24),

        // 2. Form (Giống phần Right side của Web)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Gradient: from-[#E6F0FF] to-[#F6FAFF]
            gradient: const LinearGradient(
              colors: [Color(0xFFE6F0FF), Color(0xFFF6FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24), // rounded-3xl
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Hàng 1: Tên & Email (Trên mobile sẽ stack dọc cho dễ nhập)
              _buildTextField(
                controller: _nameController,
                hint: 'contact.form.name'.tr(), // "Họ và tên"
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                hint: 'contact.form.email'.tr(), // "Email"
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // Hàng 2: Tiêu đề
              _buildTextField(
                controller: _subjectController,
                hint: 'contact.form.subject'.tr(), // "Tiêu đề"
              ),
              const SizedBox(height: 12),

              // Hàng 3: Nội dung (Textarea)
              _buildTextField(
                controller: _messageController,
                hint: 'contact.form.message'.tr(), // "Nội dung"
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Nút Gửi
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF3366FF).withOpacity(0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      // Gradient Button: from-[#66CCFF] to-[#3366FF]
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66CCFF), Color(0xFF3366FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Send', // 'contact.form.send'.tr() // "Gửi tin nhắn"
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          maxLines > 1 ? 16 : 30,
        ), // rounded-2xl hoặc rounded-full
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
