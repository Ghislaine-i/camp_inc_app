import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Abstract contract for uploading incident images.
abstract class ImageRepository {
  /// Uploads [image] and returns its public URL.
  /// [onProgress] is called with values in [0, 1] as the upload progresses.
  Future<String> upload(
    File image, {
    String? pathHint,
    void Function(double progress)? onProgress,
  });
}

// ---------------------------------------------------------------------------
// Cloudinary implementation (primary)
// ---------------------------------------------------------------------------

class CloudinaryImageRepository implements ImageRepository {
  CloudinaryImageRepository({Dio? dio}) : _dio = dio ?? Dio();

  static const _cloudName = 'fmhemgxt';
  static const _uploadPreset = 'campus_incidents';
  static const _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final Dio _dio;

  @override
  Future<String> upload(
    File image, {
    String? pathHint,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'upload_preset': _uploadPreset,
      'file': await MultipartFile.fromFile(
        image.path,
        filename: pathHint ?? image.path.split(Platform.pathSeparator).last,
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      _uploadUrl,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          onProgress?.call(sent / total);
        }
      },
    );

    final secureUrl = response.data?['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary upload succeeded but returned no URL.');
    }
    return secureUrl;
  }
}

// ---------------------------------------------------------------------------
// Firebase Storage implementation (alternative / kept for reference)
// ---------------------------------------------------------------------------

class FirebaseStorageImageRepository implements ImageRepository {
  FirebaseStorageImageRepository(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> upload(
    File image, {
    String? pathHint,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathHint ?? 'incident_images/${image.path}');
    final task = ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) {
        onProgress?.call(s.bytesTransferred / s.totalBytes);
      }
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return ref.getDownloadURL();
  }
}
