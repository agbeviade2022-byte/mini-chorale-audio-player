import 'package:hive_flutter/hive_flutter.dart';
import 'package:mini_chorale_audio_player/models/hive/user_session.dart';
import 'package:mini_chorale_audio_player/models/hive/app_settings.dart';

/// Service Hive pour gérer la session utilisateur et les paramètres
/// 🏆 Remplace SharedPreferences pour une persistance ultra-rapide
class HiveSessionService {
  static const String _sessionBoxName = 'user_session';
  static const String _settingsBoxName = 'app_settings';
  static const String _sessionKey = 'current_session';
  static const String _settingsKey = 'current_settings';

  Box<UserSession>? _sessionBox;
  Box<AppSettings>? _settingsBox;

  /// Réenregistrer les adapters Hive (utilisé après deleteFromDisk)
  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
  }

  /// Initialiser Hive et ouvrir les boxes
  Future<void> initialize() async {
    try {
      // Initialiser Hive
      await Hive.initFlutter();

      // Enregistrer les adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserSessionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AppSettingsAdapter());
      }

      // Ouvrir les boxes
      _sessionBox = await Hive.openBox<UserSession>(_sessionBoxName);
      _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

      print('✅ Hive initialisé avec succès');
      print('📦 Session box: ${_sessionBox!.length} entrées');
      print('⚙️ Settings box: ${_settingsBox!.length} entrées');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de Hive: $e');
      rethrow;
    }
  }

  // ==================== SESSION UTILISATEUR ====================

  /// Sauvegarder la session utilisateur
  Future<void> saveSession(UserSession session) async {
    try {
      await _sessionBox?.put(_sessionKey, session);
      print('💾 Session sauvegardée pour ${session.email}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la session: $e');
      rethrow;
    }
  }

  /// Récupérer la session utilisateur
  UserSession? getSession() {
    try {
      final session = _sessionBox?.get(_sessionKey);
      if (session != null) {
        print('✅ Session récupérée pour ${session.email}');
        print('🔑 Token valide: ${session.isValid}');
      } else {
        print('⚠️ Aucune session trouvée');
      }
      return session;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la session: $e');
      return null;
    }
  }

  /// Vérifier si une session existe
  bool hasSession() {
    return _sessionBox?.containsKey(_sessionKey) ?? false;
  }

  /// Vérifier si la session est valide
  bool isSessionValid() {
    final session = getSession();
    return session?.isValid ?? false;
  }

  /// Mettre à jour le token de la session
  Future<void> updateToken({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    try {
      final session = getSession();
      if (session != null) {
        final updatedSession = session.copyWith(
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenExpiresAt: expiresAt,
          lastLoginAt: DateTime.now(),
        );
        await saveSession(updatedSession);
        print('🔄 Token mis à jour');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du token: $e');
      rethrow;
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<void> updateProfile({
    String? fullName,
    String? photoUrl,
    String? choraleName,
    String? pupitre,
    String? role,
  }) async {
    try {
      final session = getSession();
      if (session != null) {
        final updatedSession = session.copyWith(
          fullName: fullName,
          photoUrl: photoUrl,
          choraleName: choraleName,
          pupitre: pupitre,
          role: role,
        );
        await saveSession(updatedSession);
        print('👤 Profil mis à jour');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  /// Supprimer la session (déconnexion)
  Future<void> clearSession() async {
    try {
      await _sessionBox?.delete(_sessionKey);
      print('🗑️ Session supprimée');
    } catch (e) {
      print('❌ Erreur lors de la suppression de la session: $e');
      rethrow;
    }
  }

  // ==================== PARAMÈTRES APPLICATION ====================

  /// Sauvegarder les paramètres
  Future<void> saveSettings(AppSettings settings) async {
    try {
      await _settingsBox?.put(_settingsKey, settings);
      print('⚙️ Paramètres sauvegardés');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des paramètres: $e');
      rethrow;
    }
  }

  /// Récupérer les paramètres
  AppSettings getSettings() {
    try {
      final settings = _settingsBox?.get(_settingsKey);
      if (settings != null) {
        print('✅ Paramètres récupérés');
        return settings;
      } else {
        print('⚠️ Aucun paramètre trouvé, utilisation des valeurs par défaut');
        return AppSettings.defaults();
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des paramètres: $e');
      return AppSettings.defaults();
    }
  }

  /// Mettre à jour un paramètre spécifique
  Future<void> updateSetting({
    String? theme,
    String? defaultPupitre,
    double? volume,
    bool? offlineMode,
    bool? autoDownloadFavorites,
    String? audioQuality,
    bool? notificationsEnabled,
    String? language,
  }) async {
    try {
      final settings = getSettings();
      final updatedSettings = settings.copyWith(
        theme: theme,
        defaultPupitre: defaultPupitre,
        volume: volume,
        offlineMode: offlineMode,
        autoDownloadFavorites: autoDownloadFavorites,
        audioQuality: audioQuality,
        notificationsEnabled: notificationsEnabled,
        language: language,
        lastUpdated: DateTime.now(),
      );
      await saveSettings(updatedSettings);
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du paramètre: $e');
      rethrow;
    }
  }

  /// Réinitialiser les paramètres
  Future<void> resetSettings() async {
    try {
      await saveSettings(AppSettings.defaults());
      print('🔄 Paramètres réinitialisés');
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation des paramètres: $e');
      rethrow;
    }
  }

  // ==================== UTILITAIRES ====================

  /// Obtenir des statistiques sur le stockage
  Map<String, dynamic> getStorageStats() {
    return {
      'sessionExists': hasSession(),
      'sessionValid': isSessionValid(),
      'sessionBoxSize': _sessionBox?.length ?? 0,
      'settingsBoxSize': _settingsBox?.length ?? 0,
      'totalBoxes': 2,
    };
  }

  /// Vider toutes les données Hive (DANGER)
  Future<void> clearAllData() async {
    try {
      await _sessionBox?.clear();
      await _settingsBox?.clear();
      print('🗑️ Toutes les données Hive supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression des données: $e');
      rethrow;
    }
  }

  /// Fermer les boxes Hive
  Future<void> close() async {
    try {
      await _sessionBox?.close();
      await _settingsBox?.close();
      print('🔒 Boxes Hive fermées');
    } catch (e) {
      print('❌ Erreur lors de la fermeture des boxes: $e');
    }
  }

  /// Compacter les boxes pour optimiser l'espace
  Future<void> compact() async {
    try {
      await _sessionBox?.compact();
      await _settingsBox?.compact();
      print('🗜️ Boxes Hive compactées');
    } catch (e) {
      print('❌ Erreur lors de la compaction: $e');
    }
  }
}
