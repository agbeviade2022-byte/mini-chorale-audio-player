import 'package:hive_flutter/hive_flutter.dart';
import 'package:mini_chorale_audio_player/services/secure_storage_service.dart';
import 'package:mini_chorale_audio_player/models/hive/user_session.dart';
import 'package:mini_chorale_audio_player/models/hive/app_settings.dart';
import 'dart:convert';

/// 🔐 Service Hive avec chiffrement AES
/// Utilise une clé stockée dans Flutter Secure Storage
/// Niveau de sécurité: Spotify-grade
class EncryptedHiveService {
  static final EncryptedHiveService _instance = EncryptedHiveService._internal();
  factory EncryptedHiveService() => _instance;
  EncryptedHiveService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  
  Box<UserSession>? _sessionBox;
  Box<AppSettings>? _settingsBox;
  
  HiveAesCipher? _encryptionCipher;
  bool _isInitialized = false;

  static const String _sessionBoxName = 'user_session_encrypted';
  static const String _settingsBoxName = 'app_settings_encrypted';
  static const String _sessionKey = 'current_session';
  static const String _settingsKey = 'app_settings';

  // ==================== INITIALISATION ====================

  /// Initialiser Hive avec chiffrement
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ EncryptedHiveService déjà initialisé');
      return;
    }

    try {
      print('🔐 Initialisation de Hive avec chiffrement...');

      // 1. Initialiser Hive
      await Hive.initFlutter();

      // 2. Enregistrer les adapters
      _registerAdapters();

      // 3. Obtenir ou créer la clé de chiffrement
      final encryptionKeyBase64 = await _secureStorage.getOrCreateHiveEncryptionKey();
      final encryptionKey = base64Decode(encryptionKeyBase64);

      // 4. Créer le cipher AES
      _encryptionCipher = HiveAesCipher(encryptionKey);
      print('🔑 Cipher AES-256 créé avec succès');

      // 5. Ouvrir les boxes chiffrées
      await _openEncryptedBoxes();

      _isInitialized = true;
      print('✅ EncryptedHiveService initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de EncryptedHiveService: $e');
      rethrow;
    }
  }

  /// Enregistrer les adapters Hive
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserSessionAdapter());
      print('✅ UserSessionAdapter enregistré');
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
      print('✅ AppSettingsAdapter enregistré');
    }
  }

  /// Ouvrir les boxes avec chiffrement
  Future<void> _openEncryptedBoxes() async {
    try {
      // Ouvrir la box de session avec chiffrement
      if (!Hive.isBoxOpen(_sessionBoxName)) {
        _sessionBox = await Hive.openBox<UserSession>(
          _sessionBoxName,
          encryptionCipher: _encryptionCipher,
        );
        print('🔐 Box session ouverte avec chiffrement AES-256');
      } else {
        _sessionBox = Hive.box<UserSession>(_sessionBoxName);
      }

      // Ouvrir la box de paramètres avec chiffrement
      if (!Hive.isBoxOpen(_settingsBoxName)) {
        _settingsBox = await Hive.openBox<AppSettings>(
          _settingsBoxName,
          encryptionCipher: _encryptionCipher,
        );
        print('🔐 Box settings ouverte avec chiffrement AES-256');
      } else {
        _settingsBox = Hive.box<AppSettings>(_settingsBoxName);
      }
    } catch (e) {
      print('❌ Erreur ouverture boxes chiffrées: $e');
      rethrow;
    }
  }

  // ==================== SESSION UTILISATEUR ====================

  /// Sauvegarder la session utilisateur (SANS les tokens sensibles)
  /// Les tokens sont stockés dans Flutter Secure Storage
  Future<void> saveSession(UserSession session) async {
    try {
      _ensureInitialized();

      // Créer une copie de la session SANS les tokens
      // Les tokens seront stockés dans Secure Storage
      final sessionWithoutTokens = session.copyWith(
        accessToken: null, // ❌ Ne pas stocker dans Hive
        refreshToken: null, // ❌ Ne pas stocker dans Hive
      );

      await _sessionBox?.put(_sessionKey, sessionWithoutTokens);
      print('💾 Session sauvegardée dans Hive chiffré (sans tokens)');

      // Sauvegarder les tokens dans Secure Storage
      if (session.accessToken != null) {
        await _secureStorage.saveAccessToken(session.accessToken!);
      }
      if (session.refreshToken != null) {
        await _secureStorage.saveRefreshToken(session.refreshToken!);
      }
      if (session.tokenExpiresAt != null) {
        await _secureStorage.saveTokenExpiry(session.tokenExpiresAt!);
      }
      await _secureStorage.saveUserId(session.userId);

      print('🔐 Tokens sauvegardés dans Secure Storage');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la session: $e');
      rethrow;
    }
  }

  /// Récupérer la session utilisateur
  /// Reconstruit la session complète avec les tokens depuis Secure Storage
  Future<UserSession?> getSession() async {
    try {
      _ensureInitialized();

      final session = _sessionBox?.get(_sessionKey);
      if (session == null) {
        print('⚠️ Aucune session trouvée dans Hive');
        return null;
      }

      // Récupérer les tokens depuis Secure Storage
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();
      final tokenExpiry = await _secureStorage.getTokenExpiry();

      // Reconstruire la session complète
      final completeSession = session.copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenExpiresAt: tokenExpiry,
      );

      print('✅ Session récupérée (Hive + Secure Storage)');
      print('🔑 Token valide: ${completeSession.isValid}');

      return completeSession;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la session: $e');
      return null;
    }
  }

  /// Vérifier si une session existe
  bool hasSession() {
    _ensureInitialized();
    return _sessionBox?.containsKey(_sessionKey) ?? false;
  }

  /// Vérifier si la session est valide
  Future<bool> isSessionValid() async {
    final session = await getSession();
    return session?.isValid ?? false;
  }

  /// Mettre à jour les tokens de la session
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    try {
      _ensureInitialized();

      // Sauvegarder les nouveaux tokens dans Secure Storage
      await _secureStorage.saveAccessToken(accessToken);
      await _secureStorage.saveRefreshToken(refreshToken);
      if (expiresAt != null) {
        await _secureStorage.saveTokenExpiry(expiresAt);
      }

      print('🔄 Tokens mis à jour dans Secure Storage');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des tokens: $e');
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
      _ensureInitialized();

      final session = await getSession();
      if (session != null) {
        final updatedSession = session.copyWith(
          fullName: fullName,
          photoUrl: photoUrl,
          choraleName: choraleName,
          pupitre: pupitre,
          role: role,
        );
        await saveSession(updatedSession);
        print('👤 Profil mis à jour dans Hive chiffré');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  /// Supprimer la session (déconnexion)
  Future<void> clearSession() async {
    try {
      _ensureInitialized();

      // Supprimer de Hive
      await _sessionBox?.delete(_sessionKey);
      print('🗑️ Session supprimée de Hive');

      // Supprimer les tokens de Secure Storage
      await _secureStorage.clearTokens();
      print('🗑️ Tokens supprimés de Secure Storage');
    } catch (e) {
      print('❌ Erreur lors de la suppression de la session: $e');
      rethrow;
    }
  }

  // ==================== PARAMÈTRES APPLICATION ====================

  /// Sauvegarder les paramètres
  Future<void> saveSettings(AppSettings settings) async {
    try {
      _ensureInitialized();
      await _settingsBox?.put(_settingsKey, settings);
      print('⚙️ Paramètres sauvegardés dans Hive chiffré');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des paramètres: $e');
      rethrow;
    }
  }

  /// Récupérer les paramètres
  AppSettings? getSettings() {
    _ensureInitialized();
    return _settingsBox?.get(_settingsKey);
  }

  /// Supprimer les paramètres
  Future<void> clearSettings() async {
    try {
      _ensureInitialized();
      await _settingsBox?.delete(_settingsKey);
      print('🗑️ Paramètres supprimés');
    } catch (e) {
      print('❌ Erreur lors de la suppression des paramètres: $e');
    }
  }

  // ==================== NETTOYAGE COMPLET ====================

  /// Supprimer TOUTES les données chiffrées
  Future<void> clearAll() async {
    try {
      print('🧹 Nettoyage complet des données chiffrées...');

      // Supprimer les données Hive
      await _sessionBox?.clear();
      await _settingsBox?.clear();
      print('✅ Données Hive supprimées');

      // Supprimer les données Secure Storage
      await _secureStorage.clearAll();
      print('✅ Données Secure Storage supprimées');

      print('✅ Nettoyage complet terminé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage complet: $e');
    }
  }

  /// Fermer les boxes
  Future<void> close() async {
    try {
      await _sessionBox?.close();
      await _settingsBox?.close();
      _isInitialized = false;
      print('✅ Boxes Hive fermées');
    } catch (e) {
      print('❌ Erreur lors de la fermeture des boxes: $e');
    }
  }

  // ==================== MIGRATION ====================

  /// Migrer depuis l'ancien Hive non chiffré
  Future<void> migrateFromUnencryptedHive() async {
    try {
      print('🔄 Migration depuis Hive non chiffré...');

      // Ouvrir l'ancienne box non chiffrée
      final oldSessionBox = await Hive.openBox<UserSession>('user_session');
      final oldSession = oldSessionBox.get('current_session');

      if (oldSession != null) {
        // Sauvegarder dans la nouvelle box chiffrée
        await saveSession(oldSession);
        print('✅ Session migrée vers Hive chiffré');

        // Supprimer l'ancienne box
        await oldSessionBox.clear();
        await oldSessionBox.close();
        await Hive.deleteBoxFromDisk('user_session');
        print('✅ Ancienne box non chiffrée supprimée');
      } else {
        print('⚠️ Aucune session à migrer');
      }
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      // Ne pas rethrow pour ne pas bloquer l'app
    }
  }

  // ==================== UTILITAIRES ====================

  /// Vérifier que le service est initialisé
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('EncryptedHiveService n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
  }

  /// Obtenir des statistiques sur le stockage
  Map<String, dynamic> getStorageStats() {
    return {
      'initialized': _isInitialized,
      'session_box_open': _sessionBox?.isOpen ?? false,
      'settings_box_open': _settingsBox?.isOpen ?? false,
      'has_session': hasSession(),
      'session_count': _sessionBox?.length ?? 0,
      'settings_count': _settingsBox?.length ?? 0,
    };
  }
}
