import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/upload_service.dart';
import 'backend_test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeBackendFirebase();
  });

  group('UploadService basics', () {
    test('UploadService can be instantiated', () {
      final service = UploadService();
      expect(service, isNotNull);
    });

    test('uploadToCloudinary returns null for empty PlatformFile mock', () async {
      final service = UploadService();
      final file = PlatformFile(name: 'test.png', size: 0, bytes: Uint8List.fromList([]), path: 'test.png');
      final result = await service.uploadToCloudinary(file);
      expect(result, isNull);
    });
  });
}
