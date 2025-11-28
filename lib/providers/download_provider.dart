import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/models/downloaded_chant.dart';
import 'package:mini_chorale_audio_player/services/download_service.dart';
import 'package:mini_chorale_audio_player/providers/notification_provider.dart';

// Provider du service de téléchargement
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

// Provider de tous les téléchargements
final downloadsProvider = FutureProvider<Map<String, DownloadedChant>>((ref) async {
  final service = ref.watch(downloadServiceProvider);
  return await service.getAllDownloads();
});

// Provider pour vérifier si un chant est téléchargé
final isChantDownloadedProvider = FutureProvider.family<bool, String>((ref, chantId) async {
  final service = ref.watch(downloadServiceProvider);
  return await service.isDownloaded(chantId);
});

// Provider pour obtenir le chemin local d'un chant
final chantLocalPathProvider = FutureProvider.family<String?, String>((ref, chantId) async {
  final service = ref.watch(downloadServiceProvider);
  return await service.getLocalPath(chantId);
});

// Provider de la taille totale des téléchargements
final totalDownloadSizeProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(downloadServiceProvider);
  final totalBytes = await service.getTotalSize();
  return service.formatSize(totalBytes);
});

// État de téléchargement pour un chant
class DownloadState {
  final DownloadStatus status;
  final double progress;
  final String? error;

  DownloadState({
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? error,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

// Notifier pour gérer les téléchargements
class DownloadNotifier extends StateNotifier<Map<String, DownloadState>> {
  final DownloadService _service;
  final Ref _ref;

  DownloadNotifier(this._service, this._ref) : super({});

  // Télécharger un chant
  Future<void> downloadChant(Chant chant) async {
    // Initialiser l'état
    state = {
      ...state,
      chant.id: DownloadState(
        status: DownloadStatus.downloading,
        progress: 0.0,
      ),
    };

    // Afficher la notification de progression
    final notificationService = _ref.read(notificationServiceProvider);
    await notificationService.showDownloadProgress(chant.titre, 0, chant.id);

    try {
      final result = await _service.downloadChant(
        chant,
        (progress) {
          // Mettre à jour la progression
          state = {
            ...state,
            chant.id: DownloadState(
              status: DownloadStatus.downloading,
              progress: progress,
            ),
          };
          
          // Mettre à jour la notification de progression
          final progressPercent = (progress * 100).toInt();
          notificationService.showDownloadProgress(chant.titre, progressPercent, chant.id);
        },
      );

      if (result != null) {
        // Téléchargement réussi
        state = {
          ...state,
          chant.id: DownloadState(
            status: DownloadStatus.downloaded,
            progress: 1.0,
          ),
        };

        // Afficher une notification de progression (masquer)
        final notificationService = _ref.read(notificationServiceProvider);
        await notificationService.hideDownloadProgress(chant.id);

        // Rafraîchir les providers
        _ref.invalidate(downloadsProvider);
        _ref.invalidate(isChantDownloadedProvider(chant.id));
        _ref.invalidate(chantLocalPathProvider(chant.id));
        _ref.invalidate(totalDownloadSizeProvider);
      } else {
        // Échec du téléchargement
        state = {
          ...state,
          chant.id: DownloadState(
            status: DownloadStatus.failed,
            progress: 0.0,
            error: 'Échec du téléchargement',
          ),
        };

        // Masquer la notification de progression
        final notificationService = _ref.read(notificationServiceProvider);
        await notificationService.hideDownloadProgress(chant.id);
      }
    } catch (e) {
      // Erreur
      state = {
        ...state,
        chant.id: DownloadState(
          status: DownloadStatus.failed,
          progress: 0.0,
          error: e.toString(),
        ),
      };
    }
  }

  // Supprimer un téléchargement
  Future<void> deleteDownload(String chantId) async {
    try {
      final success = await _service.deleteDownload(chantId);
      
      if (success) {
        // Retirer de l'état
        final newState = Map<String, DownloadState>.from(state);
        newState.remove(chantId);
        state = newState;

        // Rafraîchir les providers
        _ref.invalidate(downloadsProvider);
        _ref.invalidate(isChantDownloadedProvider(chantId));
        _ref.invalidate(chantLocalPathProvider(chantId));
        _ref.invalidate(totalDownloadSizeProvider);
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
    }
  }

  // Supprimer tous les téléchargements
  Future<void> clearAll() async {
    try {
      await _service.clearAllDownloads();
      state = {};

      // Rafraîchir les providers
      _ref.invalidate(downloadsProvider);
      _ref.invalidate(totalDownloadSizeProvider);
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }

  // Obtenir l'état d'un chant
  DownloadState getState(String chantId) {
    return state[chantId] ?? DownloadState();
  }
}

// Provider du notifier de téléchargement
final downloadNotifierProvider =
    StateNotifierProvider<DownloadNotifier, Map<String, DownloadState>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return DownloadNotifier(service, ref);
});
