import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Configurable bucket name (fallback options)
  static const String primaryBucket = 'publics';
  static const String fallbackBucket = 'uploads';
  static const List<String> bucketOptions = [primaryBucket, fallbackBucket];

  // Image constraints
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int jpegQuality = 80;
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
  ];

  /// Validates if image file meets requirements
  Future<Map<String, dynamic>> _validateImage(File imageFile) async {
    try {
      final fileSizeBytes = await imageFile.length();
      final extension = path.extension(imageFile.path).toLowerCase();

      // Check file size
      if (fileSizeBytes > maxImageSize) {
        return {
          'valid': false,
          'error':
              'Image too large. Maximum size is 5MB. Current: ${(fileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
        };
      }

      // Check file extension
      if (!allowedExtensions.contains(extension)) {
        return {
          'valid': false,
          'error':
              'Invalid image format. Allowed: ${allowedExtensions.join(', ')}',
        };
      }

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        return {'valid': false, 'error': 'Image file not found'};
      }

      return {
        'valid': true,
        'size': fileSizeBytes,
        'extension': extension,
        'sizeInMB': (fileSizeBytes / 1024 / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      return {'valid': false, 'error': 'Validation error: $e'};
    }
  }

  /// Attempts to find an available bucket
  Future<String?> _findAvailableBucket() async {
    print('[StorageService] Attempting to find available bucket...');
    for (final bucketName in bucketOptions) {
      try {
        print('[StorageService] Testing bucket: $bucketName');
        // Try a test operation to verify bucket exists
        await _supabase.storage.from(bucketName).list(path: '/');
        print('[StorageService] ✓ Bucket "$bucketName" is available');
        return bucketName;
      } catch (e) {
        print('[StorageService] ✗ Bucket "$bucketName" not available: $e');
        continue;
      }
    }
    return null;
  }

  /// Uploads a profile picture to Supabase Storage and returns the public URL
  Future<({String? url, String? error})> uploadProfilePicture({
    required File imageFile,
    required String userId,
  }) async {
    try {
      print('[ProfileUpload] Starting profile picture upload...');

      // Validate image
      final validation = await _validateImage(imageFile);
      if (!validation['valid']) {
        final errorMsg = validation['error'] as String;
        print('[ProfileUpload] Validation failed: $errorMsg');
        return (url: null, error: errorMsg);
      }

      print(
        '[ProfileUpload] Image validated - Size: ${validation['sizeInMB']}MB',
      );

      // Find available bucket
      final bucketName = await _findAvailableBucket();
      if (bucketName == null) {
        const errorMsg =
            'No storage bucket available. Please check Supabase configuration.';
        print('[ProfileUpload] ✗ $errorMsg');
        return (url: null, error: errorMsg);
      }

      // Generate unique filename
      final fileName =
          'profile_pictures/${userId}_${DateTime.now().millisecondsSinceEpoch}${validation['extension']}';
      print(
        '[ProfileUpload] Uploading to bucket: "$bucketName", path: $fileName',
      );

      // Upload the file
      try {
        await _supabase.storage.from(bucketName).upload(fileName, imageFile);
        print('[ProfileUpload] ✓ File uploaded successfully to $bucketName');
      } catch (uploadError) {
        // Try to provide helpful error messages
        final errorStr = uploadError.toString();
        late String userFriendlyError;

        if (errorStr.contains('404')) {
          userFriendlyError =
              'Storage bucket not found. Please ask an administrator to create a "public" bucket in Supabase Storage.';
        } else if (errorStr.contains('403')) {
          userFriendlyError = 'Permission denied. Check storage permissions.';
        } else if (errorStr.contains('413')) {
          userFriendlyError = 'File too large. Maximum 5MB allowed.';
        } else {
          userFriendlyError = 'Upload failed: $uploadError';
        }
        print('[ProfileUpload] ✗ Upload error: $userFriendlyError');
        return (url: null, error: userFriendlyError);
      }

      // Get the public URL
      try {
        final publicUrl = _supabase.storage
            .from(bucketName)
            .getPublicUrl(fileName);
        print('[ProfileUpload] ✓ Public URL generated: $publicUrl');
        return (url: publicUrl, error: null);
      } catch (urlError) {
        print('[ProfileUpload] ✗ Failed to generate public URL: $urlError');
        return (url: null, error: 'Failed to generate public URL: $urlError');
      }
    } catch (e, stackTrace) {
      print('[ProfileUpload] ✗ Unexpected error: $e');
      print('[ProfileUpload] Stack trace: $stackTrace');
      return (url: null, error: 'Unexpected error: $e');
    }
  }

  /// Uploads a post image to Supabase Storage and returns the public URL
  Future<({String? url, String? error})> uploadPostImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      print('[PostUpload] Starting post image upload...');

      // Validate image
      final validation = await _validateImage(imageFile);
      if (!validation['valid']) {
        final errorMsg = validation['error'] as String;
        print('[PostUpload] Validation failed: $errorMsg');
        return (url: null, error: errorMsg);
      }

      print('[PostUpload] Image validated - Size: ${validation['sizeInMB']}MB');

      // Find available bucket
      final bucketName = await _findAvailableBucket();
      if (bucketName == null) {
        const errorMsg =
            'No storage bucket available. Please check Supabase configuration.';
        print('[PostUpload] ✗ $errorMsg');
        return (url: null, error: errorMsg);
      }

      // Generate unique filename
      final fileName =
          'post_images/${userId}_${DateTime.now().millisecondsSinceEpoch}${validation['extension']}';
      print('[PostUpload] Uploading to bucket: "$bucketName", path: $fileName');

      // Upload the file
      try {
        await _supabase.storage.from(bucketName).upload(fileName, imageFile);
        print('[PostUpload] ✓ File uploaded successfully to $bucketName');
      } catch (uploadError) {
        final errorStr = uploadError.toString();
        late String userFriendlyError;

        if (errorStr.contains('404')) {
          userFriendlyError =
              'Storage bucket not found. Please ask an administrator to create a "public" bucket in Supabase Storage.';
        } else if (errorStr.contains('403')) {
          userFriendlyError = 'Permission denied. Check storage permissions.';
        } else if (errorStr.contains('413')) {
          userFriendlyError = 'File too large. Maximum 5MB allowed.';
        } else {
          userFriendlyError = 'Upload failed: $uploadError';
        }
        print('[PostUpload] ✗ Upload error: $userFriendlyError');
        return (url: null, error: userFriendlyError);
      }

      // Get the public URL
      try {
        final publicUrl = _supabase.storage
            .from(bucketName)
            .getPublicUrl(fileName);
        print('[PostUpload] ✓ Public URL generated: $publicUrl');
        return (url: publicUrl, error: null);
      } catch (urlError) {
        print('[PostUpload] ✗ Failed to generate public URL: $urlError');
        return (url: null, error: 'Failed to generate public URL: $urlError');
      }
    } catch (e, stackTrace) {
      print('[PostUpload] ✗ Unexpected error: $e');
      print('[PostUpload] Stack trace: $stackTrace');
      return (url: null, error: 'Unexpected error: $e');
    }
  }

  /// Lists all available buckets (for debugging)
  Future<List<String>> listAvailableBuckets() async {
    final available = <String>[];
    for (final bucketName in bucketOptions) {
      try {
        await _supabase.storage.from(bucketName).list(path: '/');
        available.add(bucketName);
      } catch (e) {
        // Bucket not available
      }
    }
    return available;
  }
}
