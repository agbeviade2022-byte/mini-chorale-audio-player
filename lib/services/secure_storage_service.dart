import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

/// 🔐 Service de stockage sécurisé pour les données sensibles
/// Utilise Keychain (iOS) et Keystore (Android)
/// Inspiré des standards de sécurité Spotify
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Configuration pour Android et iOS
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Utilise EncryptedSharedPreferences sur Android
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      // Accessible après le premier déverrouillage
    ),
  );

  // ==================== CLÉS DE STOCKAGE ====================
  
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyHiveEncryptionKey = 'hive_encryption_key';
  static const String _keyUserId = 'user_id';
  static const String _keyDeviceId = 'device_id';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  // ==================== TOKENS ====================

  /// Sauvegarder l'access token de manière sécurisée
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _keyAccessToken, value: token);
      print('🔐 Access token sauvegardé de manière sécurisée');
    } catch (e) {
      print('❌ Erreur sauvegarde access token: $e');
      rethrow;
    }
  }

  /// Récupérer l'access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      print('❌ Erreur lecture access token: $e');
      return null;
    }
  }

  /// Sauvegarder le refresh token de manière sécurisée
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
      print('🔐 Refresh token sauvegardé de manière sécurisée');
    } catch (e) {
      print('❌ Erreur sauvegarde refresh token: $e');
      rethrow;
    }
  }

  /// Récupérer le refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      print('❌ Erreur lecture refresh token: $e');
      return null;
    }
  }

  /// Sauvegarder la date d'expiration du token
  Future<void> saveTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(
        key: _keyTokenExpiry,
        value: expiry.toIso8601String(),
      );
    } catch (e) {
      print('❌ Erreur sauvegarde expiry: $e');
    }
  }

  /// Récupérer la date d'expiration du token
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: _keyTokenExpiry);
      if (expiryString == null) return null;
      return DateTime.parse(expiryString);
    } catch (e) {
      print('❌ Erreur lecture expiry: $e');
      return null;
    }
  }

  /// Vérifier si le token est expiré
  Future<bool> isTokenExpired() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }

  /// Supprimer tous les tokens
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyTokenExpiry);
      print('🗑️ Tokens supprimés du stockage sécurisé');
    } catch (e) {
      print('❌ Erreur suppression tokens: $e');
    }
  }

  // ==================== CLÉS DE CHIFFREMENT ====================

  /// Générer ou récupérer la clé de chiffrement Hive
  /// Cette clé est utilisée pour chiffrer la base de données Hive
  Future<String> getOrCreateHiveEncryptionKey() async {
    try {
      // Vérifier si une clé existe déjà
      String? existingKey = await _storage.read(key: _keyHiveEncryptionKey);
      
      if (existingKey != null && existingKey.isNotEmpty) {
        print('🔑 Clé de chiffrement Hive récupérée');
        return existingKey;
      }

      // Générer une nouvelle clé de 256 bits (32 bytes)
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final key = base64Encode(keyBytes);

      // Sauvegarder la clé de manière sécurisée
      await _storage.write(key: _keyHiveEncryptionKey, value: key);
      print('🔑 Nouvelle clé de chiffrement Hive générée et sauvegardée');

      return key;
    } catch (e) {
      print('❌ Erreur génération clé Hive: $e');
      rethrow;
    }
  }

  /// Supprimer la clé de chiffrement Hive (déconnexion complète)
  Future<void> clearHiveEncryptionKey() async {
    try {
      await _storage.delete(key: _keyHiveEncryptionKey);
      print('🗑️ Clé de chiffrement Hive supprimée');
    } catch (e) {
      print('❌ Erreur suppression clé Hive: $e');
    }
  }

  // ==================== USER ID ====================

  /// Sauvegarder l'ID utilisateur
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _keyUserId, value: userId);
    } catch (e) {
      print('❌ Erreur sauvegarde userId: $e');
    }
  }

  /// Récupérer l'ID utilisateur
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _keyUserId);
    } catch (e) {
      print('❌ Erreur lecture userId: $e');
      return null;
    }
  }

  // ==================== DEVICE ID ====================

  /// Générer ou récupérer un ID unique pour cet appareil
  /// Utilisé pour le tracking des sessions et la détection de connexions suspectes
  Future<String> getOrCreateDeviceId() async {
    try {
      String? existingId = await _storage.read(key: _keyDeviceId);
      
      if (existingId != null && existingId.isNotEmpty) {
        return existingId;
      }

      // Générer un nouvel ID unique
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      final deviceId = sha256.convert(bytes).toString();

      await _storage.write(key: _keyDeviceId, value: deviceId);
      print('📱 Nouvel ID d\'appareil généré: ${deviceId.substring(0, 8)}...');

      return deviceId;
    } catch (e) {
      print('❌ Erreur génération device ID: $e');
      rethrow;
    }
  }

  // ==================== BIOMÉTRIE ====================

  /// Activer/désactiver l'authentification biométrique
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _keyBiometricEnabled,
        value: enabled.toString(),
      );
    } catch (e) {
      print('❌ Erreur sauvegarde biometric: $e');
    }
  }

  /// Vérifier si la biométrie est activée
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  // ==================== NETTOYAGE COMPLET ====================

  /// Supprimer TOUTES les données sécurisées
  /// Utilisé lors de la déconnexion complète
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      print('🗑️ Toutes les données sécurisées supprimées');
    } catch (e) {
      print('❌ Erreur suppression complète: $e');
    }
  }

  // ==================== UTILITAIRES ====================

  /// Vérifier si des données existent dans le stockage sécurisé
  Future<bool> hasSecureData() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir toutes les clés stockées (pour debug uniquement)
  Future<Map<String, String>> getAllKeys() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      print('❌ Erreur lecture toutes les clés: $e');
      return {};
    }
  }

  /// Sauvegarder une valeur personnalisée de manière sécurisée
  Future<void> saveCustomValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('❌ Erreur sauvegarde valeur custom: $e');
    }
  }

  /// Récupérer une valeur personnalisée
  Future<String?> getCustomValue(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('❌ Erreur lecture valeur custom: $e');
      return null;
    }
  }
}
