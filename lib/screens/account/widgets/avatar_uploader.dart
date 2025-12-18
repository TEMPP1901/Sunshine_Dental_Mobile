import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/api_service.dart';

class AvatarUploader extends StatelessWidget {
  final String? currentAvatarUrl;
  final String? previewPath; // Đường dẫn file ảnh mới chọn (nếu có)
  final VoidCallback onPickImage;
  final VoidCallback onUpload;

  const AvatarUploader({
    super.key,
    required this.currentAvatarUrl,
    this.previewPath,
    required this.onPickImage,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Logic xác định ảnh hiển thị
    ImageProvider? imageProvider;
    if (previewPath != null) {
      imageProvider = FileImage(File(previewPath!));
    } else if (currentAvatarUrl != null && currentAvatarUrl!.isNotEmpty) {
      imageProvider = ApiService.resolveAvatarImage(currentAvatarUrl);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with better styling
              Text(
                'account.myAccount.avatarTitle'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // Avatar Circle with enhanced styling
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: imageProvider,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: imageProvider == null
                            ? Icon(
                                Icons.person,
                                size: 70,
                                color: colorScheme.primary.withOpacity(0.6),
                              )
                            : null,
                      ),
                    ),
                    // Decorative ring
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nút Chọn ảnh với styling cải thiện
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(
                    'account.myAccount.chooseAvatar'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              // Nút Upload (Chỉ hiện khi đã chọn ảnh mới)
              if (previewPath != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: Text(
                      'account.myAccount.uploadAvatar.button'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
