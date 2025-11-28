import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mini_chorale_audio_player/services/audio_compression_service.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'audio_files';
  final AudioCompressionService _compressionService = AudioCompressionService();

  // Upload un fichier audio avec compression automatique
  Future<String> uploadAudioFile({
    File? file,
    Uint8List? bytes,
    required String fileName,
    String? fileExtension,
    bool compress = true, // Compression activée par défaut
    Function(double progress)? onProgress,
  }) async {
    try {
      File? fileToUpload = file;
      String extension = fileExtension ?? '.mp3';

      // Compression audio (uniquement sur mobile/desktop, pas sur web)
      if (compress && !kIsWeb && file != null) {
        print('🎵 Compression audio activée...');
        onProgress?.call(0.1);
        
        try {
          // Compresser le fichier
          final compressedFile = await _compressionService.compressForChorale(
            file,
            onProgress: (p) => onProgress?.call(0.1 + (p * 0.4)), // 10-50%
          );
          
          fileToUpload = compressedFile;
          extension = '.m4a'; // AAC format
          print('✅ Fichier compressé avec succès');
        } catch (e) {
          print('⚠️ Erreur compression, upload du fichier original: $e');
          // En cas d'erreur, continuer avec le fichier original
        }
      }

      onProgress?.call(0.5);

      // Créer un nom de fichier unique et sécurisé
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = _sanitizeFileName(fileName);
      final uniqueFileName = '${timestamp}_$sanitizedFileName$extension';

      onProgress?.call(0.6);

      // Upload le fichier
      if (kIsWeb && bytes != null) {
        // Sur le web, utiliser les bytes avec le content-type approprié
        final fileOptions = FileOptions(
          contentType: _getContentType(extension),
          upsert: false,
        );
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(uniqueFileName, bytes, fileOptions: fileOptions);
      } else if (fileToUpload != null) {
        // Sur mobile/desktop, utiliser le fichier (compressé ou original)
        final fileOptions = FileOptions(
          contentType: _getContentType(extension),
          upsert: false,
        );
        await _supabase.storage
            .from(_bucketName)
            .upload(uniqueFileName, fileToUpload, fileOptions: fileOptions);
        
        // Nettoyer le fichier temporaire compressé
        if (compress && fileToUpload != file) {
          try {
            await fileToUpload.delete();
          } catch (e) {
            print('⚠️ Erreur suppression fichier temporaire: $e');
          }
        }
      } else {
        throw Exception('Aucun fichier ou données à uploader');
      }

      onProgress?.call(0.9);

      // Obtenir l'URL publique
      final url =
          _supabase.storage.from(_bucketName).getPublicUrl(uniqueFileName);

      onProgress?.call(1.0);
      print('✅ Upload terminé: $url');

      return url;
    } catch (e) {
      // Améliorer le message d'erreur
      throw Exception('Erreur upload: ${e.toString()}');
    }
  }

  // Upload sans compression (pour les fichiers déjà optimisés)
  Future<String> uploadAudioFileWithoutCompression({
    File? file,
    Uint8List? bytes,
    required String fileName,
    String? fileExtension,
    Function(double progress)? onProgress,
  }) async {
    return uploadAudioFile(
      file: file,
      bytes: bytes,
      fileName: fileName,
      fileExtension: fileExtension,
      compress: false,
      onProgress: onProgress,
    );
  }

  // Obtenir le content-type approprié selon l'extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.aac':
        return 'audio/aac';
      case '.flac':
        return 'audio/flac';
      default:
        return 'audio/mpeg';
    }
  }

  // Nettoyer le nom de fichier (enlever accents et caractères spéciaux)
  String _sanitizeFileName(String fileName) {
    // Remplacer les caractères accentués
    const withAccents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÇÑ';
    const withoutAccents = 'aaaaaaeeeeiiiioooooouuuuyycnAAAAAEEEEIIIIOOOOOUUUUYYCN';
    
    String sanitized = fileName;
    for (int i = 0; i < withAccents.length; i++) {
      sanitized = sanitized.replaceAll(withAccents[i], withoutAccents[i]);
    }
    
    // Enlever les caractères spéciaux et espaces
    sanitized = sanitized
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toLowerCase();
    
    // Limiter la longueur
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    
    return sanitized;
  }

  // Sélectionner un fichier audio
  Future<PlatformFile?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.single;
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un fichier audio
  Future<void> deleteAudioFile(String fileUrl) async {
    try {
      // Extraire le nom du fichier de l'URL
      final uri = Uri.parse(fileUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage.from(_bucketName).remove([fileName]);
    } catch (e) {
      rethrow;
    }
  }

  // Obtenir la taille d'un fichier en MB
  double getFileSizeInMB(PlatformFile file) {
    final bytes = file.size;
    return bytes / (1024 * 1024);
  }

  // Vérifier si le fichier est valide (taille max 50MB)
  bool isValidAudioFile(PlatformFile file) {
    final sizeInMB = getFileSizeInMB(file);
    return sizeInMB <= 50;
  }

  // Créer le bucket s'il n'existe pas (à appeler une fois au setup)
  Future<void> createBucketIfNotExists() async {
    try {
      await _supabase.storage.createBucket(
        _bucketName,
        const BucketOptions(
          public: true,
          fileSizeLimit: '52428800', // 50MB
        ),
      );
    } catch (e) {
      // Le bucket existe déjà, on ignore l'erreur
    }
  }
}
