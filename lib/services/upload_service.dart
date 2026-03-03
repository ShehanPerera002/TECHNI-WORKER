import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class UploadService {
  final ImagePicker _imagePicker = ImagePicker();
  late final Dio _dio;

  String get _baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/workers';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/workers';
    }

    return 'http://localhost:5000/api/workers';
  }

  UploadService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  // Pick a document (PDF, DOC, image, etc)
  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      rethrow;
    }
  }

  // Upload a document file
  Future<String?> uploadDocument(PlatformFile file, String token) async {
    try {
      FormData formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/document',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['fileUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      rethrow;
    }
  }

  Future<XFile?> pickImage() async {
    try {
      debugPrint('Starting image picker...');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (pickedFile == null) {
        debugPrint('No image selected');
        return null;
      }

      debugPrint('Image picked: ${pickedFile.name}');
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(XFile imageFile, String token) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/profile-image',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['imageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<String?> uploadNIC(
    XFile imageFile,
    String token, {
    String side = 'front',
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'side': side,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/nic-image',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['fileUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading NIC: $e');
      rethrow;
    }
  }
}
