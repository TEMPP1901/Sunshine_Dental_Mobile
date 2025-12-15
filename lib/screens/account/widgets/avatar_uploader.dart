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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'account.myAccount.avatarTitle'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Avatar Circle
            CircleAvatar(
              radius: 70,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: CircleAvatar(
                radius: 66,
                backgroundImage: imageProvider,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: imageProvider == null
                    ? Icon(Icons.person, size: 64, color: colorScheme.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Nút Chọn ảnh
            FilledButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text('account.myAccount.chooseAvatar'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            // Nút Upload (Chỉ hiện khi đã chọn ảnh mới)
            if (previewPath != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text('account.myAccount.uploadAvatar.button'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
