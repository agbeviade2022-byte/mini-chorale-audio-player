import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

/// AudioHandler simplifié utilisant uniquement just_audio
/// Sans dépendance à audio_service pour éviter les problèmes de compatibilité
class SimpleAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  MediaItem? _currentMediaItem;
  
  // Getters pour accéder au player
  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  MediaItem? get currentMediaItem => _currentMediaItem;
  
  SimpleAudioHandler() {
    print('✅ SimpleAudioHandler créé avec just_audio');
  }

  // Mettre à jour les métadonnées du média (pour compatibilité)
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    _currentMediaItem = mediaItem;
    print('📝 MediaItem mis à jour: ${mediaItem.title}');
  }

  // Charger un audio depuis une URL
  Future<void> setAudioSource(String url) async {
    try {
      await _player.setUrl(url);
      print('✅ Audio chargé: $url');
    } catch (e) {
      print('❌ Erreur chargement audio: $e');
      rethrow;
    }
  }

  // Lecture
  Future<void> play() async {
    try {
      await _player.play();
      print('▶️ Lecture démarrée');
    } catch (e) {
      print('❌ Erreur lecture: $e');
      rethrow;
    }
  }

  // Pause
  Future<void> pause() async {
    try {
      await _player.pause();
      print('⏸️ Lecture en pause');
    } catch (e) {
      print('❌ Erreur pause: $e');
      rethrow;
    }
  }

  // Stop
  Future<void> stop() async {
    try {
      await _player.stop();
      print('⏹️ Lecture arrêtée');
    } catch (e) {
      print('❌ Erreur stop: $e');
      rethrow;
    }
  }

  // Seek (déplacer la position)
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      print('⏩ Position changée: ${position.inSeconds}s');
    } catch (e) {
      print('❌ Erreur seek: $e');
      rethrow;
    }
  }

  // Changer le volume (0.0 à 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
      print('🔊 Volume changé: ${(volume * 100).toInt()}%');
    } catch (e) {
      print('❌ Erreur volume: $e');
      rethrow;
    }
  }

  // Changer la vitesse (0.5 à 2.0)
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed.clamp(0.5, 2.0));
      print('⚡ Vitesse changée: ${speed}x');
    } catch (e) {
      print('❌ Erreur vitesse: $e');
      rethrow;
    }
  }

  // Mode boucle
  Future<void> setLoopMode(LoopMode loopMode) async {
    try {
      await _player.setLoopMode(loopMode);
      print('🔁 Mode boucle: $loopMode');
    } catch (e) {
      print('❌ Erreur loop mode: $e');
      rethrow;
    }
  }

  // Action personnalisée (pour compatibilité avec MyAudioHandler)
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    print('🔧 Custom action: $name');
    
    if (name == 'dispose') {
      await dispose();
      return null;
    }
    
    return null;
  }

  // Nettoyer les ressources
  Future<void> dispose() async {
    await _player.dispose();
    print('🗑️ SimpleAudioHandler disposed');
  }
}
