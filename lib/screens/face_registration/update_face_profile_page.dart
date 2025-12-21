import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../camera/face_camera_screen.dart';

/// Màn hình cập nhật khuôn mặt chấm công (chờ HR duyệt)
class UpdateFaceProfilePage extends StatefulWidget {
  const UpdateFaceProfilePage({super.key});

  @override
  State<UpdateFaceProfilePage> createState() => _UpdateFaceProfilePageState();
}

class _UpdateFaceProfilePageState extends State<UpdateFaceProfilePage> {
  bool _isUploading = false;
  XFile? _capturedImage;
  String? _previewUrl;

  Future<void> _captureFaceImage() async {
    try {
      // Mở camera với overlay hướng dẫn
      final XFile? image = await context.push<XFile>('/face-camera');
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _previewUrl = image.path;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'profile.updateFaceProfile.toast.cameraError'.tr(),
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _submitUpdateRequest() async {
    if (_capturedImage == null) {
      Fluttertoast.showToast(
        msg: 'profile.updateFaceProfile.toast.noImage'.tr(),
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(_capturedImage!.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: _capturedImage!.name),
      });

      // Gửi yêu cầu cập nhật face profile (cần HR duyệt)
      await ApiService().dio.post(
        '/api/hr/face-profile/update-request',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: ApiService.authHeaders(),
        ),
      );

      setState(() {
        _capturedImage = null;
        _previewUrl = null;
      });

      Fluttertoast.showToast(
        msg: 'profile.updateFaceProfile.toast.success'.tr(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Quay lại màn hình trước sau 1.5 giây
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      String errorMsg = 'profile.updateFaceProfile.toast.error'.tr();
      
      if (e is DioException) {
        if (e.response != null) {
          final statusCode = e.response?.statusCode;
          final data = e.response?.data;
          
          // Parse error message từ response
          if (data is Map<String, dynamic>) {
            final message = data['message']?.toString();
            final error = data['error']?.toString();
            
            if (message != null && message.isNotEmpty) {
              errorMsg = message;
            } else if (error != null && error.isNotEmpty) {
              errorMsg = error;
            } else if (statusCode == 500) {
              errorMsg = 'profile.updateFaceProfile.toast.serverError'.tr();
            }
          }
          
          // Xử lý các lỗi cụ thể
          if (statusCode == 400) {
            if (errorMsg.contains('does not have a face profile') || 
                errorMsg.contains('register first')) {
              errorMsg = 'profile.updateFaceProfile.toast.notRegistered'.tr();
            } else if (errorMsg.contains('pending')) {
              errorMsg = 'profile.updateFaceProfile.toast.pendingRequest'.tr();
            } else if (errorMsg.contains('embedding') || errorMsg.contains('face')) {
              errorMsg = 'profile.updateFaceProfile.toast.faceRecognitionFailed'.tr();
            }
          } else if (statusCode == 500) {
            if (errorMsg.contains('extract') || errorMsg.contains('embedding')) {
              errorMsg = 'profile.updateFaceProfile.toast.faceProcessingFailed'.tr();
            }
          }
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'profile.updateFaceProfile.toast.timeout'.tr();
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'profile.updateFaceProfile.toast.connectionError'.tr();
        }
      }
      
      Fluttertoast.showToast(
        msg: errorMsg,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('profile.updateFaceProfile.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thông báo về quy trình
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.updateFaceProfile.importantNote'.tr(),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'profile.updateFaceProfile.importantNoteMessage'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Preview ảnh đã chụp
            if (_previewUrl != null) ...[
              Text(
                'profile.updateFaceProfile.capturedImage'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.file(
                      File(_previewUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Hướng dẫn
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt_rounded, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'profile.updateFaceProfile.instructions.title'.tr(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      context,
                      Icons.light_mode_outlined,
                      'profile.updateFaceProfile.instructions.lighting.title'.tr(),
                      'profile.updateFaceProfile.instructions.lighting.description'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      context,
                      Icons.face_outlined,
                      'profile.updateFaceProfile.instructions.faceStraight.title'.tr(),
                      'profile.updateFaceProfile.instructions.faceStraight.description'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      context,
                      Icons.visibility_outlined,
                      'profile.updateFaceProfile.instructions.faceClear.title'.tr(),
                      'profile.updateFaceProfile.instructions.faceClear.description'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      context,
                      Icons.straighten_outlined,
                      'profile.updateFaceProfile.instructions.distance.title'.tr(),
                      'profile.updateFaceProfile.instructions.distance.description'.tr(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Button chụp ảnh
            FilledButton.icon(
              onPressed: _isUploading ? null : _captureFaceImage,
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
              label: Text(_capturedImage == null 
                  ? 'profile.updateFaceProfile.buttons.capture'.tr() 
                  : 'profile.updateFaceProfile.buttons.captureAgain'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: colorScheme.primary,
              ),
            ),

            // Button gửi yêu cầu (chỉ hiển thị khi đã chụp ảnh)
            if (_capturedImage != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _submitUpdateRequest,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isUploading 
                    ? 'profile.updateFaceProfile.buttons.submitting'.tr() 
                    : 'profile.updateFaceProfile.buttons.submit'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

