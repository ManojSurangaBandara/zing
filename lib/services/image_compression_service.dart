import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera with optional preferredCameraDevice
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (source == ImageSource.camera) {
        // Fallback to gallery if camera is unavailable on device/emulator
        try {
          return await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
        } catch (_) {}
      }
      return null;
    }
  }

  /// Convenient helper to capture verification documents (Live Selfie, NIC front/back)
  /// directly with camera (or gallery) and automatically compress the result.
  static Future<File?> captureVerificationPhoto({
    bool isFrontCamera = false,
    ImageSource source = ImageSource.camera,
  }) async {
    final xfile = await pickImage(
      source: source,
      preferredCameraDevice: isFrontCamera ? CameraDevice.front : CameraDevice.rear,
    );
    if (xfile == null) return null;
    final file = File(xfile.path);
    final compressed = await compressImageFile(file);
    return compressed ?? file;
  }

  /// Pick multiple images for profile (up to maxAllowed)
  static Future<List<XFile>> pickMultiImages({int maxAllowed = 10}) async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (files.length > maxAllowed) {
        return files.sublist(0, maxAllowed);
      }
      return files;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Compress an image file before uploading to Firebase
  /// Reduces size typically by 70-85% while keeping high visual clarity
  static Future<File?> compressImageFile(File file, {int quality = 70, int minWidth = 1024, int minHeight = 1024}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        final compressedFile = File(compressedXFile.path);
        debugPrint('Original size: ${await file.length()} bytes, Compressed size: ${await compressedFile.length()} bytes');
        return compressedFile;
      }
      return file;
    } catch (e) {
      debugPrint('Compression error (fallback to original): $e');
      return file;
    }
  }

  /// Compress raw bytes (useful for web or direct data transfers)
  static Future<Uint8List> compressBytes(Uint8List list, {int quality = 70, int minWidth = 1024, int minHeight = 1024}) async {
    try {
      final Uint8List result = await FlutterImageCompress.compressWithList(
        list,
        minHeight: minHeight,
        minWidth: minWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint('Bytes compression error: $e');
      return list;
    }
  }
}
