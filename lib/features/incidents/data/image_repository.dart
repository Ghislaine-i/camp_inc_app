import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstraction over "where photos are stored".
/// The rest of the app depends only on this interface.
abstract class ImageRepository {
  /// Uploads [file] and returns a public URL to save in Firestore.
  Future<String> upload(
    File file, {
    required String folder,
    required String name,
    void Function(double progress)? onProgress,
  });
}

/// Active implementation: no billing account required.
class CloudinaryImageRepository implements ImageRepository {
  CloudinaryImageRepository({
    required this.cloudName,
    required this.uploadPreset,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String cloudName;
  final String uploadPreset;
  final Dio _dio;

  @override
  Future<String> upload(
    File file, {
    required String folder,
    required String name,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: '$name.jpg'),
      'upload_preset': uploadPreset,
      'folder': folder,
    });

    try {
      final res = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: form,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return res.data['secure_url'] as String;
    } on DioException catch (e) {
      throw Exception('Photo upload failed: ${e.message}');
    }
  }
}

/// Ready for when a Blaze billing account is available.
class FirebaseStorageImageRepository implements ImageRepository {
  FirebaseStorageImageRepository(this._storage);
  final FirebaseStorage _storage;

  @override
  Future<String> upload(
    File file, {
    required String folder,
    required String name,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('$folder/$name.jpg');
    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return ref.getDownloadURL();
  }
}

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  // To switch to Firebase Storage once billing is enabled, return:
  // FirebaseStorageImageRepository(FirebaseStorage.instance)
  return CloudinaryImageRepository(
    cloudName: 'fmhemgxt', // from the Cloudinary dashboard
    uploadPreset: 'campus_incidents', // your unsigned preset
  );
});
