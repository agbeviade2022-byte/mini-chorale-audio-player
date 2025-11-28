import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';

/// Observateur du cycle de vie de l'application
/// Gère les états : paused, resumed, inactive, detached
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 App lifecycle: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
        // L'app passe en arrière-plan
        // Le son continue de jouer grâce à audio_service
        print('📱 App en arrière-plan - la musique continue');
        break;
        
      case AppLifecycleState.resumed:
        // L'app revient au premier plan
        print('📱 App au premier plan');
        // Rafraîchir l'état si nécessaire
        break;
        
      case AppLifecycleState.inactive:
        // Transition temporaire (ex: appel entrant, centre de contrôle)
        print('📱 App inactive');
        break;
        
      case AppLifecycleState.detached:
        // L'app est sur le point d'être fermée
        print('📱 App fermée - nettoyage');
        _cleanup();
        break;
        
      case AppLifecycleState.hidden:
        // L'app est cachée mais pas détruite
        print('📱 App cachée');
        break;
    }
  }

  /// Nettoyer les ressources avant la fermeture
  void _cleanup() {
    try {
      final audioService = ref.read(audioServiceProvider);
      audioService.dispose();
      print('✅ Ressources audio nettoyées');
    } catch (e) {
      print('⚠️ Erreur lors du nettoyage: $e');
    }
  }
}
