import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class FaceEmbeddingService {
  FaceEmbeddingService._();

  static final FaceEmbeddingService _instance = FaceEmbeddingService._();

  factory FaceEmbeddingService() => _instance;

  final ImagePicker _picker = ImagePicker();

  // Chụp ảnh khuôn mặt từ camera trước với overlay hướng dẫn
  // Sử dụng custom camera screen để người dùng đưa mặt vào đúng vùng
  Future<XFile?> captureFaceImage(BuildContext context) async {
    try {
      // Mở custom camera screen với overlay hướng dẫn
      final result = await context.push<XFile>('/face-camera');

      if (result == null) {
        // User cancelled
        return null;
      }

      return result;
    } catch (e) {
      // Fallback về image_picker nếu có lỗi
      try {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        return image;
      } catch (fallbackError) {
        throw Exception(
          'Không thể mở camera. Vui lòng kiểm tra quyền truy cập camera.',
        );
      }
    }
  }

  // Trích xuất embedding từ ảnh khuôn mặt đã chọn
  Future<String> extractEmbedding(XFile imageFile) async {
    final file = File(imageFile.path);
    final fileName = imageFile.name;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await ApiService().postFormData(
        '/api/hr/attendance/embedding',
        formData,
      );

      final embedding = response.data?['embedding']?.toString();
      if (embedding == null || embedding.isEmpty) {
        throw const FormatException('Embedding value is empty');
      }

      // Validate embedding format: phải là JSON array
      final trimmed = embedding.trim();
      if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
        throw const FormatException(
          'Invalid embedding format: must be JSON array',
        );
      }

      // Validate embedding không phải là mảng rỗng hoặc chỉ có whitespace
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is! List || parsed.isEmpty) {
          throw const FormatException('Invalid embedding: array is empty');
        }
        if (parsed.length != 512) {
          throw FormatException(
            'Invalid embedding: expected 512 dimensions, got ${parsed.length}',
          );
        }
        // Kiểm tra không phải toàn số 0
        final allZeros = parsed.every(
          (value) => value is num && (value == 0 || value.abs() < 1e-6),
        );
        if (allZeros) {
          throw const FormatException(
            'Invalid embedding: array contains only zeros. No face detected.',
          );
        }
      } catch (e) {
        if (e is FormatException) {
          rethrow;
        }
        throw FormatException('Invalid embedding format: $e');
      }

      return embedding;
    } on DioException catch (dioError) {
      // Xử lý lỗi 401 (Unauthorized) - token hết hạn hoặc không hợp lệ
      if (dioError.response?.statusCode == 401) {
        final serverMessage = dioError.response?.data?['message']?.toString();
        throw Exception(
          serverMessage?.isNotEmpty == true
              ? serverMessage
              : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      // Xử lý các lỗi khác
      final serverMessage =
          dioError.response?.data?['message']?.toString() ??
          dioError.response?.data?['error']?.toString();
      throw Exception(
        serverMessage?.isNotEmpty == true
            ? serverMessage
            : 'Không thể xử lý ảnh khuôn mặt. Vui lòng thử lại.',
      );
    } catch (e) {
      // Re-throw FormatException và các exception khác
      rethrow;
    }
  }
}
