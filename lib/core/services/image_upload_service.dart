import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageUploadResult {
  const ImageUploadResult({this.url, this.error});

  final String? url;
  final String? error;

  bool get isSuccess => url != null;
}

/// Gorsel secme, kucultme ve Supabase Storage'a yukleme.
class ImageUploadService {
  ImageUploadService(this._client);

  final SupabaseClient _client;
  final _picker = ImagePicker();
  static const _uuid = Uuid();

  static const _bucket = 'images';

  /// Galeriden veya kameradan gorsel secer.
  Future<File?> pick({required bool fromCamera}) async {
    try {
      final picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        // Kaynakta da sinirlandiriyoruz; boylece bellege devasa
        // bir goruntu hic yuklenmiyor.
        maxWidth: 1600,
        imageQuality: 90,
      );

      return picked == null ? null : File(picked.path);
    } catch (e) {
      debugPrint('IMAGE PICK ERROR: $e');
      return null;
    }
  }

  /// Gorseli kucultup yukler, herkese acik URL doner.
  /// [folder] ornegin 'offers' veya 'logos'.
  ///
  /// Dosya yolu deseni: {userId}/{folder}/{uuid}.jpg
  /// Kullanici kimligi yolun ilk segmenti oldugu icin Storage
  /// RLS politikasi sahiplik kontrolunu dogrudan yapabiliyor.
  Future<ImageUploadResult> upload({
    required File file,
    required String folder,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const ImageUploadResult(error: 'Oturum bulunamadı.');
    }

    try {
      final compressed = await _compress(file);
      final path = '$userId/$folder/${_uuid.v4()}.jpg';

      debugPrint('UPLOAD START: $path (${compressed.lengthSync()} bytes)');

      await _client.storage.from(_bucket).upload(
            path,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      debugPrint('UPLOAD OK: $url');

      return ImageUploadResult(url: url);
    } on StorageException catch (e) {
      debugPrint('STORAGE ERROR: ${e.message} | status: ${e.statusCode}');
      return ImageUploadResult(error: _mapStorageError(e));
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      return ImageUploadResult(error: 'Görsel yüklenemedi: $e');
    }
  }

  /// Yuklenen gorseli siler. URL'den yolu cikarir.
  Future<void> delete(String publicUrl) async {
    try {
      // .../storage/v1/object/public/images/<path>
      final marker = '/$_bucket/';
      final index = publicUrl.indexOf(marker);
      if (index == -1) return;

      final path = publicUrl.substring(index + marker.length);
      await _client.storage.from(_bucket).remove([path]);
    } catch (e) {
      // Silme basarisiz olsa da akisi bozmuyoruz.
      debugPrint('DELETE ERROR: $e');
    }
  }

  /// Yaklasik 300-500 KB'a indirir. Kotayi korumak icin sart:
  /// ham kamera goruntusu 5 MB civari olabiliyor.
  Future<File> _compress(File input) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/${_uuid.v4()}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        input.absolute.path,
        target,
        quality: 78,
        minWidth: 1200,
        minHeight: 1200,
        format: CompressFormat.jpeg,
      );

      return result == null ? input : File(result.path);
    } catch (e) {
      // Sikistirma basarisiz olursa orijinali yukle.
      debugPrint('COMPRESS ERROR: $e');
      return input;
    }
  }

  String _mapStorageError(StorageException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('exceeded') || msg.contains('quota')) {
      return 'Depolama alanı dolu.';
    }
    if (msg.contains('too large') || e.statusCode == '413') {
      return 'Görsel çok büyük.';
    }
    if (msg.contains('bucket not found')) {
      return 'Depolama alanı bulunamadı. Yönetici ile iletişime geçin.';
    }
    if (msg.contains('unauthorized') ||
        msg.contains('policy') ||
        msg.contains('violates') ||
        e.statusCode == '403') {
      return 'Yükleme izni yok. Depolama kuralları eksik olabilir.';
    }
    if (msg.contains('duplicate')) {
      return 'Bu dosya zaten yüklenmiş.';
    }

    return 'Görsel yüklenemedi: ${e.message}';
  }
}