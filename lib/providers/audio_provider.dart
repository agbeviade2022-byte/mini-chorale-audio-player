import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mini_chorale_audio_player/services/audio_player_service.dart';
import 'package:mini_chorale_audio_player/services/download_service.dart';
import 'package:mini_chorale_audio_player/services/connectivity_service.dart';
import 'package:mini_chorale_audio_player/services/audio_handler.dart';
import 'package:mini_chorale_audio_player/services/simple_audio_handler.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/providers/download_provider.dart';
import 'package:mini_chorale_audio_player/providers/listening_history_provider.dart';
import 'package:mini_chorale_audio_player/providers/notification_provider.dart';

// Provider de l'AudioHandler (sera initialisé dans main.dart)
// Utilise dynamic pour supporter à la fois MyAudioHandler et SimpleAudioHandler
final audioHandlerProvider = Provider<dynamic>((ref) {
  throw UnimplementedError('AudioHandler must be initialized in main.dart');
});

// Provider du service audio
final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  final service = AudioPlayerService(audioHandler);
  ref.onDispose(() => service.dispose());
  return service;
});

// Provider du chant actuel
final currentChantProvider = StateProvider<Chant?>((ref) => null);

// Provider de la playlist
final playlistProvider = StateProvider<List<Chant>>((ref) => []);

// Provider de l'index actuel
final currentIndexProvider = StateProvider<int>((ref) => 0);

// Provider du mode shuffle
final shuffleModeProvider = StateProvider<bool>((ref) => false);

// Provider du mode loop
final loopModeProvider = StateProvider<LoopMode>((ref) => LoopMode.off);

// Provider de l'état de lecture (immédiat)
final isPlayingProvider = StateProvider<bool>((ref) => false);

// Provider de l'état de lecture (stream)
final playingStateProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playingStream;
});

// Provider de la position
final positionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.positionStream;
});

// Provider de la durée
final durationProvider = StreamProvider<Duration?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.durationStream;
});

// Provider de l'état du player
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playerStateStream;
});

// Notifier pour le lecteur audio
class AudioPlayerNotifier extends StateNotifier<AsyncValue<void>> {
  final AudioPlayerService _audioService;
  final Ref _ref;
  Duration _lastRecordedPosition = Duration.zero;
  String? _currentPlayingChantId;

  AudioPlayerNotifier(this._audioService, this._ref)
      : super(const AsyncValue.data(null)) {
    // Synchroniser les états shuffle et loop au démarrage
    _ref.read(shuffleModeProvider.notifier).state = _audioService.isShuffleMode;
    _ref.read(loopModeProvider.notifier).state = _audioService.loopMode;
    
    // Écouter les changements de chant pour synchroniser automatiquement
    _audioService.currentChantStream.listen((chant) {
      if (chant != null) {
        _ref.read(currentChantProvider.notifier).state = chant;
        _ref.read(currentIndexProvider.notifier).state = _audioService.currentIndex;
        _ref.read(isPlayingProvider.notifier).state = true;
        
        // Réinitialiser pour le nouveau chant
        _currentPlayingChantId = chant.id;
        _lastRecordedPosition = Duration.zero;
      }
    });

    // Écouter la position pour enregistrer l'écoute
    _audioService.positionStream.listen((position) {
      _checkAndRecordListening(position);
    });
  }

  // Vérifier et enregistrer l'écoute si nécessaire
  void _checkAndRecordListening(Duration position) {
    final chant = _ref.read(currentChantProvider);
    if (chant == null || _currentPlayingChantId != chant.id) return;

    // Enregistrer tous les 30 secondes d'écoute
    if (position.inSeconds > 0 && 
        position.inSeconds - _lastRecordedPosition.inSeconds >= 30) {
      
      _lastRecordedPosition = position;
      
      // Déterminer si le chant est complété (écouté à 90% ou plus)
      final totalDuration = chant.duree;
      final completed = position.inSeconds >= (totalDuration * 0.9).toInt();

      // Enregistrer dans l'historique
      _ref.read(listeningHistoryNotifierProvider.notifier).recordListen(
        chantId: chant.id,
        durationListened: position.inSeconds,
        completed: completed,
      );
    }
  }

  // Jouer un chant
  Future<void> playChant(Chant chant, {List<Chant>? playlist}) async {
    state = const AsyncValue.loading();
    try {
      // Vérifier si le chant est téléchargé localement
      final localPath = await _ref.read(downloadServiceProvider).getLocalPath(chant.id);
      
      // Si pas de fichier local, vérifier la connexion internet
      if (localPath == null) {
        final connectivityService = ConnectivityService();
        final hasConnection = await connectivityService.hasConnection();
        
        if (!hasConnection) {
          _ref.read(isPlayingProvider.notifier).state = false;
          throw Exception(
            'Pas de connexion internet et le chant n\'est pas téléchargé. '
            'Veuillez télécharger le chant ou vous connecter à internet.'
          );
        }
      }
      
      // Mettre à jour l'état AVANT de jouer
      _ref.read(currentChantProvider.notifier).state = chant;
      
      if (playlist != null) {
        _ref.read(playlistProvider.notifier).state = playlist;
        _ref.read(currentIndexProvider.notifier).state =
            playlist.indexWhere((c) => c.id == chant.id);
      }
      
      _ref.read(isPlayingProvider.notifier).state = true;
      
      // Créer une copie du chant avec le chemin local si disponible
      final chantToPlay = localPath != null
          ? chant.copyWith(urlAudio: localPath)
          : chant;
      
      // Jouer le chant (local ou online)
      await _audioService.playChant(chantToPlay, playlist: playlist);

      // Afficher la notification de lecture
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.showNowPlaying(chant.titre, chant.auteur);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      _ref.read(isPlayingProvider.notifier).state = false;
      state = AsyncValue.error(e, stack);
      print('❌ Erreur lors de la lecture: $e');
    }
  }

  // Toggle Play/Pause
  Future<void> togglePlayPause() async {
    try {
      final currentState = _ref.read(isPlayingProvider);
      _ref.read(isPlayingProvider.notifier).state = !currentState;
      await _audioService.togglePlayPause();
    } catch (e, stack) {
      _ref.read(isPlayingProvider.notifier).state =
          _audioService.audioPlayer.playing;
      state = AsyncValue.error(e, stack);
    }
  }

  // Play
  Future<void> play() async {
    try {
      _ref.read(isPlayingProvider.notifier).state = true;
      await _audioService.play();
    } catch (e, stack) {
      _ref.read(isPlayingProvider.notifier).state = false;
      state = AsyncValue.error(e, stack);
    }
  }

  // Pause
  Future<void> pause() async {
    try {
      _ref.read(isPlayingProvider.notifier).state = false;
      await _audioService.pause();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Stop
  Future<void> stop() async {
    try {
      _ref.read(isPlayingProvider.notifier).state = false;
      await _audioService.stop();
      _ref.read(currentChantProvider.notifier).state = null;
      
      // Masquer la notification de lecture
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.hideNowPlaying();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Seek
  Future<void> seek(Duration position) async {
    try {
      await _audioService.seek(position);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Avancer
  Future<void> seekForward() async {
    try {
      await _audioService.seekForward();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Reculer
  Future<void> seekBackward() async {
    try {
      await _audioService.seekBackward();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Chant suivant
  Future<void> playNext() async {
    try {
      await _audioService.playNext();
      _ref.read(currentChantProvider.notifier).state =
          _audioService.currentChant;
      _ref.read(currentIndexProvider.notifier).state =
          _audioService.currentIndex;
      _ref.read(isPlayingProvider.notifier).state = true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // Chant précédent
  Future<void> playPrevious() async {
    try {
      await _audioService.playPrevious();
      _ref.read(currentChantProvider.notifier).state =
          _audioService.currentChant;
      _ref.read(currentIndexProvider.notifier).state =
          _audioService.currentIndex;
      _ref.read(isPlayingProvider.notifier).state = true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // Toggle shuffle
  void toggleShuffle() {
    _audioService.toggleShuffle();
    _ref.read(shuffleModeProvider.notifier).state = _audioService.isShuffleMode;
    _ref.read(playlistProvider.notifier).state = _audioService.playlist;
  }

  // Toggle loop
  void toggleLoop() {
    _audioService.toggleLoopMode();
    _ref.read(loopModeProvider.notifier).state = _audioService.loopMode;
  }

  // Définir la playlist
  void setPlaylist(List<Chant> playlist) {
    _audioService.setPlaylist(playlist);
    _ref.read(playlistProvider.notifier).state = playlist;
  }
}

// Provider du notifier audio
final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AsyncValue<void>>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return AudioPlayerNotifier(audioService, ref);
});
