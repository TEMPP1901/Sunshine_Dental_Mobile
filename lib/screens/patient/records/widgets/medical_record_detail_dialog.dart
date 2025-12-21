import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Import i18n
import '../../../../models/patient/patient_models.dart';
import '../../../../services/api_service.dart';

class MedicalRecordDetailDialog extends StatelessWidget {
  final MedicalRecord record;

  const MedicalRecordDetailDialog({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Xanh
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3366FF), Color(0xFF0099FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "records.detail.title".tr(), // "Chi tiết hồ sơ"
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "#${record.id} • ${record.visitDate}",
                          style: TextStyle(
                            color: Colors.blue.shade100,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body (Cuộn được)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid: Chẩn đoán & Điều trị
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            "records.detail.diagnosis".tr(), // "CHẨN ĐOÁN"
                            record.diagnosis,
                            Colors.grey.shade100,
                            Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoBox(
                            "records.detail.treatment".tr(), // "ĐIỀU TRỊ"
                            record.treatment,
                            Colors.blue.shade50,
                            Colors.blue.shade800,
                            footer: "records.card.doctor".tr(
                              namedArgs: {'name': record.doctorName},
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Lời dặn (Note)
                    if (record.note != null && record.note!.isNotEmpty) ...[
                      Text(
                        "💬 ${"records.detail.note".tr()}", // "LỜI DẶN"
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.yellow.shade100),
                        ),
                        child: Text(
                          '"${record.note}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.orange.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Đơn thuốc
                    if (record.prescriptionNote != null &&
                        record.prescriptionNote!.isNotEmpty) ...[
                      Text(
                        "💊 ${"records.detail.prescription".tr()}", // "ĐƠN THUỐC"
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          record.prescriptionNote!,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade900,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Hình ảnh
                    if (record.imageUrl != null &&
                        record.imageUrl!.isNotEmpty) ...[
                      Text(
                        "records.detail.image".tr(), // "HÌNH ẢNH"
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: (record.imageUrl != null && 
                                  record.imageUrl!.isNotEmpty &&
                                  ApiService.resolveUrl(record.imageUrl!).isNotEmpty)
                              ? Image.network(
                                  ApiService.resolveUrl(record.imageUrl!),
                                  headers: ApiService.authHeaders(),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 150,
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                )
                              : Container(
                                  height: 150,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: Text("records.detail.close".tr()), // "Đóng lại"
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(
    String label,
    String content,
    Color bgColor,
    Color textColor, {
    String? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Divider(color: textColor.withOpacity(0.2), height: 1),
            const SizedBox(height: 4),
            Text(
              footer,
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.8)),
            ),
          ],
        ],
      ),
    );
  }
}
