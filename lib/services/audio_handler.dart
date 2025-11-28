import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// AudioHandler personnalisé pour gérer les contrôles média système
/// (notification, écran de verrouillage, Bluetooth, etc.)
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  MyAudioHandler() {
    // Initialiser l'état de lecture
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
      ],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));
    
    // Écouter les changements d'état du player
    _player.playbackEventStream.listen((event) {
      // Ne broadcaster que si le player est vraiment en train de jouer ou en pause
      // Évite les broadcasts intempestifs pendant le chargement
      if (event.processingState == ProcessingState.ready || 
          event.processingState == ProcessingState.completed) {
        _broadcastState();
      }
    });
    
    // Écouter les changements de position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  // Diffuser l'état actuel du lecteur
  void _broadcastState() {
    final playing = _player.playing;
    final processingState = _player.processingState;
    
    print('📡 Broadcast State: playing=$playing, processingState=$processingState');
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  // Mettre à jour les métadonnées (titre, artiste, pochette)
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
    _broadcastState();
  }

  // Charger une URL audio
  Future<void> setAudioSource(String url) async {
    try {
      print('🎵 Chargement audio: $url');
      print('🔍 Type d\'URL: ${url.startsWith('http') ? 'HTTP/HTTPS' : 'Fichier local'}');
      
      // Vérifier si c'est un fichier local ou une URL
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // URL réseau
        await _player.setUrl(url);
      } else if (url.startsWith('file://') || url.startsWith('/')) {
        // Fichier local
        await _player.setFilePath(url.replaceFirst('file://', ''));
      } else {
        // Essayer comme URL par défaut
        await _player.setUrl(url);
      }
      
      print('✅ Audio chargé avec succès');
      _broadcastState();
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement de l\'audio: $e');
      print('🔍 URL: $url');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    try {
      print('▶️ Démarrage lecture');
      print('📱 MediaItem actuel: ${mediaItem.value?.title}');
      print('🔍 État avant play: ${_player.processingState}');
      
      await _player.play();
      
      // Attendre un court instant que le player démarre vraiment
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Maintenant broadcaster l'état (playing devrait être true)
      _broadcastState();
      
      print('✅ Commande play envoyée');
      print('🔊 Playing: ${_player.playing}');
      print('🔍 État après play: ${_player.processingState}');
    } catch (e) {
      print('❌ Erreur lors du démarrage de la lecture: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    print('⏸️ Mise en pause');
    await _player.pause();
    _broadcastState();
    print('✅ Lecture en pause');
  }

  @override
  Future<void> stop() async {
    print('⏹️ Arrêt de la lecture');
    await _player.stop();
    _broadcastState();
    await super.stop();
    print('✅ Lecture arrêtée');
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    // Sera géré par le AudioPlayerService
    // On envoie juste l'événement
  }

  @override
  Future<void> skipToPrevious() async {
    // Sera géré par le AudioPlayerService
    // On envoie juste l'événement
  }

  @override
  Future<void> fastForward() async {
    final position = _player.position + const Duration(seconds: 10);
    await _player.seek(position);
  }

  @override
  Future<void> rewind() async {
    var position = _player.position - const Duration(seconds: 10);
    if (position < Duration.zero) position = Duration.zero;
    await _player.seek(position);
  }

  // Getters
  AudioPlayer get player => _player;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;

  // Nettoyer les ressources
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
    }
  }
}
