import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/models/downloaded_chant.dart';

class DownloadService {
  static const String _downloadsKey = 'downloaded_chants';

  // Télécharger un chant
  Future<DownloadedChant?> downloadChant(
    Chant chant,
    Function(double)? onProgress,
  ) async {
    try {
      // Créer le dossier de téléchargement
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Nom du fichier
      final fileName = '${chant.id}.mp3';
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      // Vérifier si déjà téléchargé
      if (await file.exists()) {
        return DownloadedChant(
          chantId: chant.id,
          localPath: filePath,
          downloadedAt: DateTime.now(),
          fileSize: await file.length(),
          status: DownloadStatus.downloaded,
        );
      }

      // Télécharger le fichier
      final request = http.Request('GET', Uri.parse(chant.urlAudio));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Erreur de téléchargement: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;

      // Écrire le fichier avec suivi de progression
      final sink = file.openWrite();
      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0 && onProgress != null) {
          final progress = downloadedBytes / contentLength;
          onProgress(progress);
        }
      }
      await sink.close();

      // Créer l'objet DownloadedChant
      final downloadedChant = DownloadedChant(
        chantId: chant.id,
        localPath: filePath,
        downloadedAt: DateTime.now(),
        fileSize: await file.length(),
        status: DownloadStatus.downloaded,
      );

      // Sauvegarder dans les préférences
      await _saveDownloadInfo(downloadedChant);

      return downloadedChant;
    } catch (e) {
      print('Erreur lors du téléchargement: $e');
      return null;
    }
  }

  // Sauvegarder les infos de téléchargement
  Future<void> _saveDownloadInfo(DownloadedChant downloadedChant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_downloadsKey);

      Map<String, dynamic> downloads = {};
      if (downloadsJson != null) {
        downloads = Map<String, dynamic>.from(jsonDecode(downloadsJson));
      }

      downloads[downloadedChant.chantId] = downloadedChant.toMap();
      await prefs.setString(_downloadsKey, jsonEncode(downloads));
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  // Obtenir tous les téléchargements
  Future<Map<String, DownloadedChant>> getAllDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_downloadsKey);

      if (downloadsJson == null) return {};

      final Map<String, dynamic> downloadsMap = jsonDecode(downloadsJson);
      return downloadsMap.map(
        (key, value) => MapEntry(key, DownloadedChant.fromMap(value)),
      );
    } catch (e) {
      print('Erreur lors de la lecture des téléchargements: $e');
      return {};
    }
  }

  // Vérifier si un chant est téléchargé
  Future<bool> isDownloaded(String chantId) async {
    final downloads = await getAllDownloads();
    if (!downloads.containsKey(chantId)) return false;

    // Vérifier que le fichier existe toujours
    final downloadedChant = downloads[chantId]!;
    final file = File(downloadedChant.localPath);
    return await file.exists();
  }

  // Obtenir le chemin local d'un chant
  Future<String?> getLocalPath(String chantId) async {
    final downloads = await getAllDownloads();
    if (!downloads.containsKey(chantId)) return null;

    final downloadedChant = downloads[chantId]!;
    final file = File(downloadedChant.localPath);

    if (await file.exists()) {
      return downloadedChant.localPath;
    }

    return null;
  }

  // Supprimer un téléchargement
  Future<bool> deleteDownload(String chantId) async {
    try {
      final downloads = await getAllDownloads();
      if (!downloads.containsKey(chantId)) return false;

      final downloadedChant = downloads[chantId]!;
      final file = File(downloadedChant.localPath);

      // Supprimer le fichier
      if (await file.exists()) {
        await file.delete();
      }

      // Supprimer des préférences
      downloads.remove(chantId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _downloadsKey,
        jsonEncode(downloads.map((key, value) => MapEntry(key, value.toMap()))),
      );

      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Supprimer tous les téléchargements
  Future<void> clearAllDownloads() async {
    try {
      final downloads = await getAllDownloads();

      // Supprimer tous les fichiers
      for (var download in downloads.values) {
        final file = File(download.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Vider les préférences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadsKey);
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }

  // Obtenir la taille totale des téléchargements
  Future<int> getTotalSize() async {
    final downloads = await getAllDownloads();
    return downloads.values.fold<int>(0, (sum, d) => sum + d.fileSize);
  }

  // Formater la taille en MB
  String formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
