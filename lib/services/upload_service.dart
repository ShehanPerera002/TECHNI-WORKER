import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; 

class UploadService {
  final ImagePicker _imagePicker = ImagePicker();
  late final Dio _dio;

  // --- CLOUDINARY CONFIG (ඔයාගේ විස්තර මෙතන Update කළා) ---
  final String cloudName = "dg9whoifo"; 
  final String uploadPreset = "techni";

  String get _baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:5000/api/workers';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000/api/workers';
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

  // ================= CLOUDINARY UPLOAD LOGIC =================
  // මේකෙන් තමයි දැන් ඔයාගේ images කෙලින්ම Cloudinary එකට යන්නේ
  Future<String?> uploadToCloudinary(PlatformFile file) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      
      var request = http.MultipartRequest('POST', url);
      
      // Web සහ Mobile දෙකටම ගැලපෙන විදියට file එක සකස් කිරීම
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else {
        debugPrint("Upload Error: File data is missing");
        return null;
      }

      request.fields['upload_preset'] = uploadPreset;
      request.fields['resource_type'] = 'auto'; 

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseString);
        return jsonResponse['secure_url']; // සාර්ථක නම් URL එක ලැබෙනවා
      } else {
        debugPrint("Cloudinary Error Response: $responseString");
        return null;
      }
    } catch (e) {
      debugPrint("Upload exception details: $e");
      return null;
    }
  }

  // ================= YOUR EXISTING LOGIC (LOCAL API) =================

  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true, // Web support එක සඳහා මේක වැදගත්
      );
      if (result != null && result.files.isNotEmpty) return result.files.first;
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      rethrow;
    }
  }

  // මෙතනින් පල්ලෙහා තියෙන ඒව ඔයාගේ පරණ API එකට (localhost) සම්බන්ධ ඒවා
  Future<String?> uploadDocument(PlatformFile file, String token) async {
    try {
      FormData formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(file.path!, filename: file.name),
      });
      final response = await _dio.post('$_baseUrl/document', data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 ? response.data['fileUrl'] : null;
    } catch (e) {
      debugPrint('Local API Upload Error: $e');
      return null;
    }
  }

  Future<XFile?> pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}