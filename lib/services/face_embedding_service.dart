import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class FaceEmbeddingService {
  FaceEmbeddingService._();

  static final FaceEmbeddingService _instance = FaceEmbeddingService._();

  factory FaceEmbeddingService() => _instance;

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> captureFaceImage() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
  }

  Future<String> extractEmbedding(XFile imageFile) async {
    final file = File(imageFile.path);
    final fileName = imageFile.name;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response =
        await ApiService().postFormData('/api/hr/attendance/embedding', formData);

    final embedding = response.data?['embedding']?.toString();
    if (embedding == null || embedding.isEmpty) {
      throw const FormatException('Embedding value is empty');
    }

    return embedding;
  }
}


