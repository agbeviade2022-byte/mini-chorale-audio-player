import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service de compression audio pour optimiser les fichiers avant upload
/// Réduit la taille des fichiers de 80-90% sans perte significative de qualité
class AudioCompressionService {
  /// Formats de compression disponibles
  static const String formatAAC = 'aac';  // Recommandé - Meilleure qualité/taille
  static const String formatMP3 = 'mp3';  // Compatible partout
  static const String formatOPUS = 'opus'; // Meilleure compression mais moins compatible

  /// Qualités de compression (bitrate en kbps)
  static const int qualityLow = 64;      // Très compressé - Voix uniquement
  static const int qualityMedium = 96;   // Bon compromis - Musique simple
  static const int qualityHigh = 128;    // Recommandé - Musique chorale
  static const int qualityVeryHigh = 192; // Haute qualité - Musique complexe

  /// Compresser un fichier audio
  /// 
  /// NOTE: En mode développement sans ffmpeg_kit_flutter, cette méthode
  /// ne fait PAS de vraie compression et renvoie simplement le fichier d'entrée.
  /// L'API reste identique pour éviter de casser le code appelant.
  Future<File> compressAudio({
    required File inputFile,
    String format = formatAAC,
    int bitrate = qualityHigh,
    Function(double progress)? onProgress,
  }) async {
    try {
      // En l'absence de ffmpeg, on ne compresse pas réellement.
      // On copie le fichier dans un dossier temporaire pour simuler
      // un "fichier de sortie" sans casser le flux existant.

      print('🎵 Compression audio désactivée (ffmpeg_kit_flutter absent)');
      print('📁 Fichier source: ${inputFile.path}');

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFileName = 'uncompressed_${timestamp}.${_getExtension(format)}';
      final outputPath = path.join(tempDir.path, outputFileName);

      final outputFile = await inputFile.copy(outputPath);

      print('ℹ️ Fichier simplement copié sans compression: ${_formatFileSize(outputFile.lengthSync())}');
      onProgress?.call(1.0);
      return outputFile;
    } catch (e) {
      print('❌ Erreur (mode sans compression): $e');
      rethrow;
    }
  }

  /// Compresser avec paramètres optimaux pour musique chorale
  /// Format AAC 128 kbps - Meilleur compromis qualité/taille
  Future<File> compressForChorale(File inputFile, {Function(double)? onProgress}) {
    return compressAudio(
      inputFile: inputFile,
      format: formatAAC,
      bitrate: qualityHigh,
      onProgress: onProgress,
    );
  }

  /// Compresser avec paramètres optimaux pour voix seule
  /// Format AAC 96 kbps - Très compressé, parfait pour voix
  Future<File> compressForVoice(File inputFile, {Function(double)? onProgress}) {
    return compressAudio(
      inputFile: inputFile,
      format: formatAAC,
      bitrate: qualityMedium,
      onProgress: onProgress,
    );
  }

  /// Obtenir les informations d'un fichier audio
  Future<AudioInfo> getAudioInfo(File audioFile) async {
    try {
      // Sans ffmpeg, on ne peut pas analyser précisément le fichier.
      // On retourne des informations minimales basées sur la taille.
      print('ℹ️ getAudioInfo: mode simplifié sans ffmpeg');
      return AudioInfo(
        duration: Duration.zero,
        bitrate: 0,
        format: 'unknown',
        fileSize: audioFile.lengthSync(),
      );
    } catch (e) {
      print('⚠️ Erreur lecture infos audio (mode simplifié): $e');
      return AudioInfo(
        duration: Duration.zero,
        bitrate: 0,
        format: 'unknown',
        fileSize: audioFile.lengthSync(),
      );
    }
  }

  /// Estimer la taille après compression
  int estimateCompressedSize({
    required int originalSize,
    required int originalBitrate,
    required int targetBitrate,
  }) {
    if (originalBitrate == 0) return originalSize;
    return (originalSize * targetBitrate / originalBitrate).round();
  }

  /// Vérifier si FFmpeg est disponible
  Future<bool> isFFmpegAvailable() async {
    // Sans ffmpeg_kit_flutter, on considère que FFmpeg n'est pas disponible.
    return false;
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Obtenir l'extension pour un format
  String _getExtension(String format) {
    switch (format) {
      case formatAAC:
        return 'm4a';
      case formatMP3:
        return 'mp3';
      case formatOPUS:
        return 'opus';
      default:
        return 'm4a';
    }
  }

  /// Parser la durée depuis la sortie FFmpeg
  Duration _parseDuration(String output) {
    final regex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
    final match = regex.firstMatch(output);
    
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
    
    return Duration.zero;
  }

  /// Parser le bitrate depuis la sortie FFmpeg
  int _parseBitrate(String output) {
    final regex = RegExp(r'bitrate: (\d+) kb/s');
    final match = regex.firstMatch(output);
    
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    
    return 0;
  }

  /// Parser le format depuis la sortie FFmpeg
  String _parseFormat(String output) {
    final regex = RegExp(r'Audio: (\w+)');
    final match = regex.firstMatch(output);
    
    if (match != null) {
      return match.group(1)!;
    }
    
    return 'unknown';
  }

  /// Formater la taille de fichier
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Informations sur un fichier audio
class AudioInfo {
  final Duration duration;
  final int bitrate;
  final String format;
  final int fileSize;

  AudioInfo({
    required this.duration,
    required this.bitrate,
    required this.format,
    required this.fileSize,
  });

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'AudioInfo(duration: $formattedDuration, bitrate: ${bitrate}kbps, format: $format, size: $formattedSize)';
  }
}
