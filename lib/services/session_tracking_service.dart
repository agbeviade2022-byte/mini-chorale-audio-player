import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mini_chorale_audio_player/services/secure_storage_service.dart';
import 'dart:io';

/// 🔍 Service de tracking des sessions pour la sécurité
/// Détecte les connexions suspectes et enregistre l'historique
/// Inspiré des systèmes de sécurité Spotify
class SessionTrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SecureStorageService _secureStorage = SecureStorageService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ==================== TRACKING DE CONNEXION ====================

  /// Enregistrer une nouvelle connexion
  Future<void> trackLogin({
    required String userId,
    String? ipAddress,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final deviceId = await _secureStorage.getOrCreateDeviceId();

      await _supabase.from('user_sessions_log').insert({
        'user_id': userId,
        'device_id': deviceId,
        'device_info': deviceInfo,
        'platform': Platform.operatingSystem,
        'ip_address': ipAddress,
        'connected_at': DateTime.now().toIso8601String(),
      });

      print('📊 Connexion enregistrée: ${deviceInfo['model']} - $deviceId');
    } catch (e) {
      print('⚠️ Erreur tracking login: $e');
      // Ne pas bloquer la connexion si le tracking échoue
    }
  }

  /// Enregistrer une déconnexion
  Future<void> trackLogout({
    required String userId,
  }) async {
    try {
      final deviceId = await _secureStorage.getOrCreateDeviceId();

      // Mettre à jour la dernière session active
      await _supabase
          .from('user_sessions_log')
          .update({
            'disconnected_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .isFilter('disconnected_at', null);

      print('📊 Déconnexion enregistrée');
    } catch (e) {
      print('⚠️ Erreur tracking logout: $e');
    }
  }

  /// Obtenir les sessions actives d'un utilisateur
  Future<List<Map<String, dynamic>>> getActiveSessions(String userId) async {
    try {
      final response = await _supabase
          .from('user_sessions_log')
          .select()
          .eq('user_id', userId)
          .isFilter('disconnected_at', null)
          .order('connected_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération sessions actives: $e');
      return [];
    }
  }

  /// Obtenir l'historique des connexions
  Future<List<Map<String, dynamic>>> getLoginHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('user_sessions_log')
          .select()
          .eq('user_id', userId)
          .order('connected_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// Déconnecter une session spécifique
  Future<void> disconnectSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      await _supabase
          .from('user_sessions_log')
          .update({
            'disconnected_at': DateTime.now().toIso8601String(),
            'disconnected_reason': 'user_revoked',
          })
          .eq('id', sessionId)
          .eq('user_id', userId);

      print('✅ Session déconnectée: $sessionId');
    } catch (e) {
      print('❌ Erreur déconnexion session: $e');
      rethrow;
    }
  }

  /// Déconnecter toutes les autres sessions
  Future<void> disconnectAllOtherSessions(String userId) async {
    try {
      final currentDeviceId = await _secureStorage.getOrCreateDeviceId();

      await _supabase
          .from('user_sessions_log')
          .update({
            'disconnected_at': DateTime.now().toIso8601String(),
            'disconnected_reason': 'user_revoked_all',
          })
          .eq('user_id', userId)
          .neq('device_id', currentDeviceId)
          .isFilter('disconnected_at', null);

      print('✅ Toutes les autres sessions déconnectées');
    } catch (e) {
      print('❌ Erreur déconnexion autres sessions: $e');
      rethrow;
    }
  }

  // ==================== DÉTECTION DE CONNEXIONS SUSPECTES ====================

  /// Vérifier si une connexion est suspecte
  Future<Map<String, dynamic>> checkSuspiciousActivity(String userId) async {
    try {
      final activeSessions = await getActiveSessions(userId);
      final currentDeviceId = await _secureStorage.getOrCreateDeviceId();

      // Vérifier le nombre de sessions actives
      final activeSessionCount = activeSessions.length;
      final isMultipleSessions = activeSessionCount > 3;

      // Vérifier si c'est un nouvel appareil
      final isNewDevice = !activeSessions.any(
        (session) => session['device_id'] == currentDeviceId,
      );

      // Vérifier les connexions récentes (dernières 24h)
      final recentLogins = activeSessions.where((session) {
        final connectedAt = DateTime.parse(session['connected_at']);
        final difference = DateTime.now().difference(connectedAt);
        return difference.inHours < 24;
      }).length;

      final isSuspicious = isMultipleSessions || (isNewDevice && recentLogins > 5);

      return {
        'is_suspicious': isSuspicious,
        'active_sessions': activeSessionCount,
        'is_new_device': isNewDevice,
        'recent_logins_24h': recentLogins,
        'reasons': [
          if (isMultipleSessions) 'Trop de sessions actives ($activeSessionCount)',
          if (isNewDevice) 'Nouvel appareil détecté',
          if (recentLogins > 5) 'Trop de connexions récentes ($recentLogins)',
        ],
      };
    } catch (e) {
      print('❌ Erreur vérification activité suspecte: $e');
      return {
        'is_suspicious': false,
        'error': e.toString(),
      };
    }
  }

  /// Envoyer une alerte de sécurité
  Future<void> sendSecurityAlert({
    required String userId,
    required String alertType,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _supabase.from('security_alerts').insert({
        'user_id': userId,
        'alert_type': alertType,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
        'resolved': false,
      });

      print('🚨 Alerte de sécurité envoyée: $alertType');
    } catch (e) {
      print('❌ Erreur envoi alerte: $e');
    }
  }

  // ==================== INFORMATIONS APPAREIL ====================

  /// Obtenir les informations de l'appareil
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
        };
      } else {
        return {
          'platform': Platform.operatingSystem,
          'unknown': true,
        };
      }
    } catch (e) {
      print('❌ Erreur récupération device info: $e');
      return {
        'platform': Platform.operatingSystem,
        'error': e.toString(),
      };
    }
  }

  /// Obtenir un résumé des informations de l'appareil actuel
  Future<String> getDeviceSummary() async {
    final info = await _getDeviceInfo();
    if (Platform.isAndroid) {
      return '${info['manufacturer']} ${info['model']} (Android ${info['version']})';
    } else if (Platform.isIOS) {
      return '${info['model']} (iOS ${info['system_version']})';
    }
    return 'Appareil inconnu';
  }

  // ==================== STATISTIQUES ====================

  /// Obtenir les statistiques de connexion
  Future<Map<String, dynamic>> getConnectionStats(String userId) async {
    try {
      final history = await getLoginHistory(userId: userId, limit: 100);
      final activeSessions = await getActiveSessions(userId);

      final uniqueDevices = <String>{};
      final platforms = <String, int>{};

      for (final session in history) {
        uniqueDevices.add(session['device_id']);
        final platform = session['platform'] ?? 'unknown';
        platforms[platform] = (platforms[platform] ?? 0) + 1;
      }

      return {
        'total_logins': history.length,
        'active_sessions': activeSessions.length,
        'unique_devices': uniqueDevices.length,
        'platforms': platforms,
        'last_login': history.isNotEmpty
            ? history.first['connected_at']
            : null,
      };
    } catch (e) {
      print('❌ Erreur récupération stats: $e');
      return {};
    }
  }
}
