import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ExplanationDialog extends StatefulWidget {
  const ExplanationDialog({super.key});

  @override
  State<ExplanationDialog> createState() => _ExplanationDialogState();
}

class _ExplanationDialogState extends State<ExplanationDialog> {
  final TextEditingController _reasonController = TextEditingController();

  // Hủy bộ nhớ của controller khi không dùng nữa
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Giao diện dialog cung cấp ô nhập lý do giải thích, gồm nút Cancel và Submit
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Explanation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                hintText: 'Please enter your explanation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              maxLines: 4,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    // Kiểm tra lý do không rỗng trước khi gửi về
                    if (_reasonController.text.trim().isNotEmpty) {
                      Navigator.pop(context, _reasonController.text.trim());
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Submit',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
