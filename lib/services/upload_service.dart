import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; 

class UploadService {
  final ImagePicker _imagePicker = ImagePicker();

  
  final String cloudName = "dg9whoifo"; 
  final String uploadPreset = "techni";

  
  UploadService();

  // ================= 1. CLOUDINARY UPLOAD LOGIC =================
  
  Future<String?> uploadToCloudinary(PlatformFile file) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      
      var request = http.MultipartRequest('POST', url);
      
      // Web සහ Mobile දෙකටම ගැලපෙන පරිදි bytes හෝ path භාවිතා කිරීම
      if (kIsWeb || file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      }

      request.fields['upload_preset'] = uploadPreset;
      request.fields['resource_type'] = 'auto'; 

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseString);
        return jsonResponse['secure_url']; // Cloudinary URL එක ලබාදෙයි
      } else {
        debugPrint("Cloudinary Error: $responseString");
        return null;
      }
    } catch (e) {
      debugPrint("Upload Exception: $e");
      return null;
    }
  }

  // ================= 2. FILE PICKER LOGIC =================

  
  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, 
      );
      return result?.files.first;
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  
  Future<XFile?> pickImage() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}