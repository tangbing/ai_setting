import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';

class MediaSaveService {
  MediaSaveService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<void> saveImageToGallery(String imageUrl) async {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final permitted = await Gal.requestAccess();
      if (!permitted) {
        throw const _MediaSavePermissionException();
      }
    }

    final imageFile = await _downloadToTempFile(imageUrl);

    try {
      await Gal.putImage(imageFile.path);
    } finally {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }
  }

  Future<File> _downloadToTempFile(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    final extension = _resolveExtension(uri);
    final file = File(
      '${Directory.systemTemp.path}/ai_setting_${DateTime.now().millisecondsSinceEpoch}$extension',
    );

    await _dio.download(imageUrl, file.path);
    return file;
  }

  String _resolveExtension(Uri uri) {
    final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (lastSegment.contains('.')) {
      return '.${lastSegment.split('.').last.split('?').first}';
    }
    return '.jpg';
  }
}

class _MediaSavePermissionException implements Exception {
  const _MediaSavePermissionException();
}
