import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../camera/face_camera_screen.dart';
import 'package:image_picker/image_picker.dart';

/// Màn hình đăng ký face profile bắt buộc cho nhân viên mới
class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({super.key});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  bool _isUploading = false;
  XFile? _capturedImage;

  Future<void> _captureAndRegister() async {
    try {
      // Mở camera với overlay hướng dẫn
      final XFile? image = await context.push<XFile>('/face-camera');
      if (image == null) {
        // User cancelled
        return;
      }

      setState(() {
        _capturedImage = image;
      });

      // Tự động upload để đăng ký
      await _uploadFaceProfile(image);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Không thể mở camera. Vui lòng thử lại.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _uploadFaceProfile(XFile imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(imageFile.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: imageFile.name),
      });

      final response = await ApiService().dio.post(
        '/api/hr/face-profile/register',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: ApiService.authHeaders(),
        ),
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Đăng ký khuôn mặt thành công! Bạn có thể sử dụng hệ thống.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );

        // Chuyển về home sau khi đăng ký thành công
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Lỗi khi đăng ký khuôn mặt. Vui lòng thử lại.';
        if (e is DioException && e.response != null) {
          final message = e.response?.data?['message'];
          if (message != null) {
            errorMsg = message.toString();
          }
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // Không cho phép quay lại
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon và tiêu đề
                Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Đăng ký khuôn mặt chấm công',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Để sử dụng hệ thống chấm công, bạn cần đăng ký khuôn mặt của mình.\nVui lòng chụp ảnh khuôn mặt theo hướng dẫn.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Preview ảnh đã chụp (nếu có)
                if (_capturedImage != null) ...[
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.file(
                        File(_capturedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Button chụp ảnh
                FilledButton.icon(
                  onPressed: _isUploading ? null : _captureAndRegister,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                  label: Text(_isUploading ? 'Đang xử lý...' : 'Chụp ảnh đăng ký'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lưu ý: Đảm bảo khuôn mặt rõ ràng, nhìn thẳng vào camera',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

