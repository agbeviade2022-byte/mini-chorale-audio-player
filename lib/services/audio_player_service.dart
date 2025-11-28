import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/services/audio_handler.dart';
import 'package:mini_chorale_audio_player/services/simple_audio_handler.dart';

class AudioPlayerService {
  final dynamic _audioHandler; // Peut être MyAudioHandler ou SimpleAudioHandler
  final AudioPlayer _preloadPlayer = AudioPlayer(); // Pour précharger le prochain chant
  final StreamController<Chant?> _currentChantController = StreamController<Chant?>.broadcast();
  
  AudioPlayer get _audioPlayer {
    if (_audioHandler is SimpleAudioHandler) {
      return (_audioHandler as SimpleAudioHandler).player;
    } else if (_audioHandler is MyAudioHandler) {
      return (_audioHandler as MyAudioHandler).player;
    }
    throw Exception('AudioHandler type not supported');
  }

  Chant? _currentChant;
  List<Chant> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffleMode = false;
  LoopMode _loopMode = LoopMode.off;
  String? _preloadedChantId;

  AudioPlayerService(this._audioHandler) {
    // Écouter la fin de la lecture pour passer au chant suivant
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        print('🎵 Chant terminé - Passage au suivant');
        _handleSongCompletion();
      }
    });
    
    // Écouter les commandes système (notification) - seulement pour MyAudioHandler
    if (_audioHandler is MyAudioHandler) {
      (_audioHandler as MyAudioHandler).playbackState.listen((state) {
        // Les actions sont déjà gérées par l'AudioHandler
      });
    }
  }

  // Gérer la fin d'un chant
  Future<void> _handleSongCompletion() async {
    try {
      // Si le mode loop one est activé, rejouer le même chant
      if (_loopMode == LoopMode.one) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
        return;
      }

      // Sinon, passer au chant suivant si la playlist n'est pas vide
      if (_playlist.isNotEmpty) {
        await playNext();
      }
    } catch (e) {
      // Laisser l'erreur remonter silencieusement pour ne pas bloquer
      // L'utilisateur peut toujours changer de chant manuellement
    }
  }

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  Chant? get currentChant => _currentChant;
  List<Chant> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isShuffleMode => _isShuffleMode;
  LoopMode get loopMode => _loopMode;

  // Stream des états
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  // Stream de position optimisé pour économiser la batterie
  // N'émet que quand la seconde change (au lieu de plusieurs fois par seconde)
  Stream<Duration> get positionStream => _audioPlayer.positionStream
      .distinct((prev, next) => prev.inSeconds == next.inSeconds);
      
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<Chant?> get currentChantStream => _currentChantController.stream;

  // Charger et jouer un chant
  Future<void> playChant(Chant chant, {List<Chant>? playlist}) async {
    try {
      print('🎵 playChant appelé: ${chant.titre}');
      print('🔍 URL Audio: ${chant.urlAudio}');
      
      _currentChant = chant;
      _currentChantController.add(_currentChant);

      if (playlist != null) {
        _playlist = playlist;
        _currentIndex = playlist.indexWhere((c) => c.id == chant.id);
      }

      // Mettre à jour les métadonnées de la notification
      await _audioHandler.updateMediaItem(
        MediaItem(
          id: chant.id,
          title: chant.titre,
          artist: chant.auteur,
          album: chant.categorie,
          duration: Duration(seconds: chant.duree),
          artUri: Uri.parse('https://via.placeholder.com/300x300.png?text=${Uri.encodeComponent(chant.titre)}'),
          displayTitle: chant.titre,
          displaySubtitle: '${chant.auteur} • ${chant.categorie}',
        ),
      );

      // Vérifier si ce chant était préchargé
      if (_preloadedChantId == chant.id) {
        // Swap: utiliser le player préchargé comme player principal
        // Note: Just Audio ne permet pas de swap directement les players
        // donc on charge normalement mais ça sera très rapide (en cache)
        await _audioHandler.setAudioSource(chant.urlAudio);
      } else {
        await _audioHandler.setAudioSource(chant.urlAudio);
      }
      
      await _audioHandler.play();

      // Précharger le prochain chant
      _preloadNextChant();
    } catch (e) {
      rethrow;
    }
  }

  // Précharger le prochain chant de la playlist
  Future<void> _preloadNextChant() async {
    try {
      if (_playlist.isEmpty || _loopMode == LoopMode.one) {
        return;
      }

      // Déterminer le prochain index
      int nextIndex;
      if (_currentIndex < _playlist.length - 1) {
        nextIndex = _currentIndex + 1;
      } else if (_loopMode == LoopMode.all) {
        nextIndex = 0; // Revenir au début
      } else {
        return; // Fin de la playlist
      }

      final nextChant = _playlist[nextIndex];
      
      // Ne précharger que si différent
      if (_preloadedChantId != nextChant.id) {
        _preloadedChantId = nextChant.id;
        // Précharger en arrière-plan (ne pas attendre)
        _preloadPlayer.setUrl(nextChant.urlAudio).catchError((e) {
          print('Erreur préchargement: $e');
        });
        print('⚡ Préchargement: ${nextChant.titre}');
      }
    } catch (e) {
      print('Erreur lors du préchargement: $e');
    }
  }

  // Play / Pause
  Future<void> togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioHandler.pause();
      } else {
        await _audioHandler.play();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Pause
  Future<void> pause() async {
    try {
      await _audioHandler.pause();
    } catch (e) {
      rethrow;
    }
  }

  // Play
  Future<void> play() async {
    try {
      await _audioHandler.play();
    } catch (e) {
      rethrow;
    }
  }

  // Stop
  Future<void> stop() async {
    try {
      await _audioHandler.stop();
      _currentChant = null;
    } catch (e) {
      rethrow;
    }
  }

  // Seek vers une position
  Future<void> seek(Duration position) async {
    try {
      await _audioHandler.seek(position);
    } catch (e) {
      rethrow;
    }
  }

  // Avancer de 10 secondes
  Future<void> seekForward() async {
    try {
      final currentPosition = _audioPlayer.position;
      final duration = _audioPlayer.duration;

      if (duration != null) {
        final newPosition = currentPosition + const Duration(seconds: 10);
        await seek(newPosition > duration ? duration : newPosition);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reculer de 10 secondes
  Future<void> seekBackward() async {
    try {
      final currentPosition = _audioPlayer.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      await seek(newPosition.isNegative ? Duration.zero : newPosition);
    } catch (e) {
      rethrow;
    }
  }

  // Chant suivant
  Future<void> playNext() async {
    try {
      if (_playlist.isEmpty) return;

      if (_isShuffleMode) {
        _currentIndex = (_currentIndex + 1) % _playlist.length;
      } else {
        if (_currentIndex < _playlist.length - 1) {
          _currentIndex++;
        } else {
          // Navigation circulaire : retour au début
          _currentIndex = 0;
        }
      }

      _currentChant = _playlist[_currentIndex];
      _currentChantController.add(_currentChant);
      
      // Mettre à jour les métadonnées de la notification
      await _audioHandler.updateMediaItem(
        MediaItem(
          id: _currentChant!.id,
          title: _currentChant!.titre,
          artist: _currentChant!.auteur,
          album: _currentChant!.categorie,
          duration: Duration(seconds: _currentChant!.duree),
          artUri: Uri.parse('https://via.placeholder.com/300x300.png?text=${Uri.encodeComponent(_currentChant!.titre)}'),
          displayTitle: _currentChant!.titre,
          displaySubtitle: '${_currentChant!.auteur} • ${_currentChant!.categorie}',
        ),
      );
      
      await _audioHandler.setAudioSource(_currentChant!.urlAudio);
      await _audioHandler.play();
    } catch (e) {
      rethrow;
    }
  }

  // Chant précédent
  Future<void> playPrevious() async {
    try {
      if (_playlist.isEmpty) return;

      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        // Navigation circulaire : aller à la fin
        _currentIndex = _playlist.length - 1;
      }

      _currentChant = _playlist[_currentIndex];
      _currentChantController.add(_currentChant);
      
      // Mettre à jour les métadonnées de la notification
      await _audioHandler.updateMediaItem(
        MediaItem(
          id: _currentChant!.id,
          title: _currentChant!.titre,
          artist: _currentChant!.auteur,
          album: _currentChant!.categorie,
          duration: Duration(seconds: _currentChant!.duree),
          artUri: Uri.parse('https://via.placeholder.com/300x300.png?text=${Uri.encodeComponent(_currentChant!.titre)}'),
          displayTitle: _currentChant!.titre,
          displaySubtitle: '${_currentChant!.auteur} • ${_currentChant!.categorie}',
        ),
      );
      
      await _audioHandler.setAudioSource(_currentChant!.urlAudio);
      await _audioHandler.play();
    } catch (e) {
      rethrow;
    }
  }

  // Toggle shuffle mode
  void toggleShuffle() {
    _isShuffleMode = !_isShuffleMode;
    if (_isShuffleMode) {
      _playlist.shuffle();
    }
  }

  // Toggle loop mode
  void toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        _loopMode = LoopMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        _loopMode = LoopMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
  }

  // Définir la playlist
  void setPlaylist(List<Chant> playlist) {
    _playlist = playlist;
  }

  // Nettoyer les ressources
  Future<void> dispose() async {
    await _currentChantController.close();
    await _audioHandler.customAction('dispose');
    await _preloadPlayer.dispose();
  }
}
