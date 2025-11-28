import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer la connectivité réseau
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  static const String _cacheKey = 'last_connection_state';

  /// Stream qui émet true si connecté, false sinon
  Stream<bool> get connectionStream async* {
    // Émettre d'abord l'état en cache
    final cachedState = await _getCachedConnectionState();
    yield cachedState;
    print('💾 État en cache: $cachedState');
    
    // Puis écouter les changements réels
    await for (final result in _connectivity.onConnectivityChanged) {
      final isConnected = result != ConnectivityResult.none;
      print('🌐 Changement de connexion détecté: $result → $isConnected');
      
      // Sauvegarder le nouvel état
      await _saveConnectionState(isConnected);
      
      yield isConnected;
    }
  }

  /// Vérifier si l'appareil a une connexion internet
  Future<bool> hasConnection() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      final isConnected = result != ConnectivityResult.none;
      print('🌐 Vérification connexion: $result → $isConnected');
      
      // Sauvegarder l'état
      await _saveConnectionState(isConnected);
      
      return isConnected;
    } catch (e) {
      print('❌ Erreur lors de la vérification de la connexion: $e');
      // En cas d'erreur, retourner l'état en cache
      return await _getCachedConnectionState();
    }
  }

  /// Obtenir le type de connexion actuel
  Future<String> getConnectionType() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      
      if (result == ConnectivityResult.wifi) {
        return 'WiFi';
      } else if (result == ConnectivityResult.mobile) {
        return 'Données mobiles';
      } else if (result == ConnectivityResult.ethernet) {
        return 'Ethernet';
      } else if (result == ConnectivityResult.none) {
        return 'Aucune connexion';
      }
      return 'Autre';
    } catch (e) {
      return 'Erreur';
    }
  }

  /// Sauvegarder l'état de connexion dans le cache
  Future<void> _saveConnectionState(bool isConnected) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, isConnected);
      print('💾 État de connexion sauvegardé: $isConnected');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de l\'état: $e');
    }
  }

  /// Récupérer l'état de connexion depuis le cache
  Future<bool> _getCachedConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Par défaut, on suppose qu'on est en ligne
      final cachedState = prefs.getBool(_cacheKey) ?? true;
      return cachedState;
    } catch (e) {
      print('❌ Erreur lors de la récupération du cache: $e');
      return true; // Par défaut, on suppose qu'on est en ligne
    }
  }
}
