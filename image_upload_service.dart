import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

/// ImageUploadService - FIXED version
/// Handles all image picking, cropping and uploading reliably
class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─────────────────────────────────────────────────────────────
  // PICK IMAGE - FIXED: handles permissions and errors properly
  // ─────────────────────────────────────────────────────────────
  static Future<File?> pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    bool crop = true,
  }) async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
        // Note: requestFullMetadata removed — not available in image_picker ^1.0.7
      );

      if (xFile == null) return null;

      final File imageFile = File(xFile.path);

      // Verify file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file not found after picking');
      }

      if (crop) {
        return await _cropImage(imageFile);
      }

      return imageFile;
    } on Exception catch (e) {
      debugPrint('Image pick error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CROP IMAGE
  // ─────────────────────────────────────────────────────────────
  static Future<File?> _cropImage(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF0C0F0C),
            toolbarWidgetColor: const Color(0xFF00C875),
            activeControlsWidgetColor: const Color(0xFF00C875),
            backgroundColor: const Color(0xFF0C0F0C),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile == null) return imageFile; // Return original if crop cancelled
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('Crop error: $e');
      return imageFile; // Return original on crop error
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD IMAGE TO FIREBASE STORAGE - FIXED with retry logic
  // ─────────────────────────────────────────────────────────────
  static Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? customFileName,
    void Function(double progress)? onProgress,
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        // Validate file
        if (!await imageFile.exists()) {
          throw Exception('File does not exist: ${imageFile.path}');
        }

        final int fileSize = await imageFile.length();
        if (fileSize == 0) {
          throw Exception('File is empty: ${imageFile.path}');
        }

        if (fileSize > 10 * 1024 * 1024) {
          // 10MB limit
          throw Exception('File too large: ${fileSize ~/ 1024}KB (max 10MB)');
        }

        // Generate unique filename
        final String fileName = customFileName ??
            '${const Uuid().v4()}.${_getExtension(imageFile.path)}';
        final String storagePath = '$folder/$fileName';

        // Upload with progress tracking
        final UploadTask uploadTask =
            _storage.ref(storagePath).putFile(
          imageFile,
          SettableMetadata(
            contentType: 'image/${_getExtension(imageFile.path)}',
            customMetadata: {
              'uploaded_at': DateTime.now().toIso8601String(),
              'original_size': fileSize.toString(),
            },
          ),
        );

        // Listen to progress
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final double progress =
                snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          });
        }

        // Wait for completion
        final TaskSnapshot snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final String downloadUrl =
              await snapshot.ref.getDownloadURL();
          debugPrint('Upload success: $downloadUrl');
          return downloadUrl;
        } else {
          throw Exception('Upload failed with state: ${snapshot.state}');
        }
      } on FirebaseException catch (e) {
        debugPrint('Firebase upload error (attempt $attempt): ${e.code} - ${e.message}');

        if (e.code == 'storage/unauthorized') {
          throw Exception('Storage permission denied. Check Firebase rules.');
        }
        if (e.code == 'storage/quota-exceeded') {
          throw Exception('Storage quota exceeded.');
        }

        if (attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
      } catch (e) {
        debugPrint('Upload error (attempt $attempt): $e');
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // PICK MULTIPLE IMAGES
  // ─────────────────────────────────────────────────────────────
  static Future<List<File>> pickMultipleImages({int limit = 5}) async {
    try {
      final List<XFile> xFiles = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
      );

      if (xFiles.isEmpty) return [];

      final List<File> files = [];
      for (final xFile in xFiles.take(limit)) {
        final file = File(xFile.path);
        if (await file.exists()) {
          files.add(file);
        }
      }
      return files;
    } catch (e) {
      debugPrint('Multiple image pick error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE IMAGE FROM STORAGE
  // ─────────────────────────────────────────────────────────────
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      return true;
    } catch (e) {
      debugPrint('Delete image error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW IMAGE SOURCE PICKER DIALOG
  // ─────────────────────────────────────────────────────────────
  static Future<ImageSource?> showSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A2419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  color: Color(0xFFEEF4EE),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFF00C875),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF00D4FF),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static String _getExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase().replaceAll('.', '');
    return ext.isEmpty ? 'jpg' : ext;
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
