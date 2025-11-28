import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hive/user_session.dart';
import 'hive_session_service.dart';
import '../exceptions/auth_exceptions.dart';
import 'package:mini_chorale_audio_player/services/encrypted_hive_service.dart';
import 'package:mini_chorale_audio_player/services/session_tracking_service.dart';
import 'package:mini_chorale_audio_player/services/secure_storage_service.dart';
import 'package:mini_chorale_audio_player/models/hive/user_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:mini_chorale_audio_player/services/permissions_service.dart';
/// Service d'authentification amélioré avec sécurité niveau Spotify
/// 🔐 Utilise EncryptedHiveService + SecureStorage + SessionTracking
class EnhancedAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final HiveSessionService _hiveSession; // Legacy - pour compatibilité
  final EncryptedHiveService? _encryptedHive; // Nouveau système sécurisé
  final SessionTrackingService? _sessionTracking; // Tracking des connexions
  final SecureStorageService? _secureStorage; // Stockage sécurisé

  EnhancedAuthService(
    this._hiveSession, {
    EncryptedHiveService? encryptedHive,
    SessionTrackingService? sessionTracking,
    SecureStorageService? secureStorage,
  })  : _encryptedHive = encryptedHive,
        _sessionTracking = sessionTracking,
        _secureStorage = secureStorage;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;

  // Stream de l'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== CONNEXION ====================

  /// Connexion avec email et mot de passe + sécurité niveau Spotify
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Vérifier si l'utilisateur est bloqué (rate limiting)
      if (_sessionTracking != null) {
        try {
          final isBlocked = await _supabase.rpc('is_login_blocked', params: {
            'p_identifier': email,
            'p_identifier_type': 'email',
          });

          if (isBlocked == true) {
            throw Exception('Compte temporairement bloqué. Trop de tentatives de connexion. Réessayez dans 15 minutes.');
          }
        } catch (e) {
          print('⚠️ Impossible de vérifier le blocage: $e');
        }
      }

      // 2. Authentifier avec Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 3. Réinitialiser le compteur de tentatives après succès
      if (_sessionTracking != null && response.user != null) {
        try {
          await _supabase.rpc('reset_login_attempts', params: {
            'p_email': email,
          });
        } catch (e) {
          print('⚠️ Impossible de réinitialiser le compteur: $e');
        }
      }

      // 4. Vérifier le statut de validation
      if (response.user != null) {
        final profile = await getUserProfile();
        final statutValidation = profile?['statut_validation'] as String?;
        
        // 🚨 SÉCURITÉ CRITIQUE: Vérifier le statut de validation
        if (statutValidation == 'refuse') {
          // Compte refusé
          await _supabase.auth.signOut();
          throw UserRefusedException();
        } else if (statutValidation != 'valide') {
          // Compte en attente - NE PAS déconnecter pour permettre la redirection
          throw UserNotValidatedException(statutValidation: statutValidation ?? 'en_attente');
        }
        
        await _saveSessionToHive(response.user!, response.session);
        
        // 5. Tracker la connexion
        if (_sessionTracking != null) {
          try {
            await _sessionTracking!.trackLogin(userId: response.user!.id);
            print('📊 Connexion trackée');
            
            // 6. Vérifier activité suspecte
            final suspiciousCheck = await _sessionTracking!.checkSuspiciousActivity(
              response.user!.id,
            );
            
            if (suspiciousCheck['is_suspicious'] == true) {
              print('⚠️ Activité suspecte détectée:');
              final reasons = suspiciousCheck['reasons'] as List?;
              if (reasons != null) {
                for (final reason in reasons) {
                  print('  - $reason');
                }
              }
            }
          } catch (e) {
            print('⚠️ Erreur tracking: $e');
          }
        }
      }

      try {
        final permissionsService = PermissionsService();
        final permissions = await permissionsService.getUserPermissions();
        final role = await permissionsService.getUserRole();
        print('✅ Permissions chargées: ${permissions.length} permissions, rôle: $role');
      } catch (e) {
        print('⚠️ Erreur chargement permissions: $e');
        // Ne pas bloquer la connexion si les permissions échouent
      }

      print('✅ Connexion réussie et session sauvegardée de manière sécurisée');
      return response;
    } catch (e) {
      // Enregistrer la tentative échouée
      if (_sessionTracking != null) {
        try {
          await _supabase.rpc('record_failed_login', params: {
            'p_email': email,
            'p_error_message': e.toString(),
          });
        } catch (recordError) {
          print('⚠️ Impossible d\'enregistrer la tentative échouée: $recordError');
        }
      }
      
      print('❌ Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Inscription avec email, mot de passe et nom complet (sans chorale)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // 🚨 SÉCURITÉ: Nettoyer TOUTES les données avant inscription
      print('🧹 Nettoyage complet des données locales avant inscription...');
      await _clearAllLocalData();
      
      // 1. Créer le compte Supabase
      print('📝 Création du compte utilisateur...');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw Exception('Erreur: Utilisateur non créé');
      }

      print('✅ Utilisateur créé avec ID: ${response.user!.id}');

      // 2. Créer le profil manuellement dans la table profiles
      print('📝 Création du profil utilisateur...');
      try {
        await _supabase.from('profiles').insert({
          'user_id': response.user!.id,
          'full_name': fullName,
          'role': 'membre',
          'statut_validation': 'en_attente',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ Profil créé avec succès');
      } catch (profileError) {
        print('⚠️ Erreur création profil: $profileError');
        // Si le profil existe déjà (trigger a fonctionné), on continue
        if (!profileError.toString().contains('duplicate') && 
            !profileError.toString().contains('unique')) {
          // Si ce n'est pas une erreur de duplication, on la relance
          rethrow;
        }
        print('ℹ️ Profil existe déjà (trigger a fonctionné)');
      }

      // 3. Sauvegarder la session dans Hive
      await _saveSessionToHive(response.user!, response.session);

      print('✅ Inscription réussie - En attente de validation admin');
      print('✅ Session sauvegardée dans Hive');
      print('📊 User ID: ${response.user?.id}');
      print('📊 Email: ${response.user?.email}');
      return response;
    } catch (e, stackTrace) {
      print('❌ Erreur lors de l\'inscription: $e');
      print('📊 Type d\'erreur: ${e.runtimeType}');
      print('📊 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== DÉCONNEXION ====================

  /// Déconnexion sécurisée avec tracking
  Future<void> signOut() async {
    try {
      final userId = currentUser?.id;
      
      // 1. Tracker la déconnexion
      if (_sessionTracking != null && userId != null) {
        try {
          await _sessionTracking!.trackLogout(userId: userId);
          print('📊 Déconnexion trackée');
        } catch (e) {
          print('⚠️ Erreur tracking déconnexion: $e');
        }
      }

      // 2. Nettoyer TOUTES les données locales
      print('🧹 Nettoyage complet des données locales...');
      await _clearAllLocalData();

      // 3. Déconnecter de Supabase
      await _supabase.auth.signOut();
      print('✅ Déconnexion réussie et données nettoyées de manière sécurisée');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  // ==================== RESTAURATION DE SESSION ====================

  /// Vérifier et restaurer la session depuis Hive au démarrage
  Future<bool> restoreSession() async {
    try {
      // 1. Vérifier d'abord si Supabase a une session (persistée automatiquement)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        print('✅ Session Supabase active: ${currentUser.email}');
        
        // 🚨 SÉCURITÉ CRITIQUE: Vérifier le statut de validation
        final profile = await getUserProfile();
        final statutValidation = profile?['statut_validation'] as String?;
        
        if (statutValidation == 'refuse') {
          print('🚨 Utilisateur refusé détecté - Déconnexion forcée');
          await _supabase.auth.signOut();
          await _hiveSession.clearSession();
          return false;
        } else if (statutValidation != 'valide') {
          print('⚠️ Utilisateur non validé détecté');
          // Ne pas déconnecter, laisser l'UI gérer la redirection
          return false;
        }
        
        // Synchroniser avec Hive si nécessaire
        if (!_hiveSession.hasSession()) {
          print('🔄 Synchronisation Hive depuis Supabase...');
          final session = _supabase.auth.currentSession;
          if (session != null) {
            await _saveSessionToHive(currentUser, session);
          }
        }
        
        return true;
      }

      // 2. Sinon, vérifier si une session existe dans Hive
      if (!_hiveSession.hasSession()) {
        print('! Aucune session trouvée dans Hive');
        return false;
      }

      // 3. Récupérer la session Hive
      final session = _hiveSession.getSession();
      if (session == null || !session.isValid) {
        print('⚠️ Session Hive invalide ou expirée');
        await _hiveSession.clearSession();
        return false;
      }

      // 4. Essayer de restaurer la session Supabase avec le refresh token
      if (session.refreshToken != null) {
        try {
          print('🔄 Tentative de restauration avec refresh token...');
          final response = await _supabase.auth.refreshSession();
          if (response.session != null) {
            await _updateSessionTokens(response.session!);
            print('✅ Session Supabase restaurée avec refresh token');
            print('👤 Utilisateur: ${session.email}');
            return true;
          }
        } catch (e) {
          print('❌ Impossible de restaurer la session Supabase: $e');
          await _hiveSession.clearSession();
          return false;
        }
      }
      
      print('⚠️ Impossible de restaurer la session');
      await _hiveSession.clearSession();
      return false;
    } catch (e) {
      print('❌ Erreur lors de la restauration de session: $e');
      return false;
    }
  }

  // ==================== GESTION DU PROFIL ====================

  /// Obtenir le profil utilisateur depuis Supabase
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      print('🔍 Récupération du profil pour user_id: ${currentUser!.id}');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', currentUser!.id)  // ✅ CORRECTION: user_id au lieu de id
          .maybeSingle();

      if (response == null) {
        print('⚠️ Profil non trouvé pour ${currentUser!.email}, création automatique...');
        // Créer le profil automatiquement
        await _createMissingProfile();
        // Réessayer
        return await getUserProfile();
      }

      print('✅ Profil récupéré: statut_validation = ${response['statut_validation']}');
      return response;
    } catch (e) {
      print('❌ Erreur lors de la récupération du profil: $e');
      return null; // Ne pas rethrow pour ne pas bloquer
    }
  }

  /// Créer un profil manquant
  Future<void> _createMissingProfile() async {
    try {
      if (currentUser == null) return;

      await _supabase.from('profiles').insert({
        'id': currentUser!.id,
        'full_name': currentUser!.userMetadata?['full_name'] ?? 'Utilisateur',
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Profil créé automatiquement pour ${currentUser!.email}');
    } catch (e) {
      print('❌ Erreur lors de la création du profil: $e');
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. Mettre à jour dans Supabase
      await _supabase.from('profiles').update(data).eq('user_id', userId);

      // 2. Mettre à jour dans Hive
      await _hiveSession.updateProfile(
        fullName: data['full_name'] as String?,
        photoUrl: data['photo_url'] as String?,
        choraleName: data['chorale_name'] as String?,
        pupitre: data['pupitre'] as String?,
        role: data['role'] as String?,
      );

      print('✅ Profil mis à jour dans Supabase et Hive');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur est admin
  Future<bool> isAdmin() async {
    try {
      // Vérifier d'abord dans Hive (plus rapide)
      final session = _hiveSession.getSession();
      if (session != null) {
        return session.isAdmin;
      }

      // Sinon, vérifier dans Supabase
      final profile = await getUserProfile();
      if (profile == null) return false;
      
      final role = profile['role'] as String?;
      return role == 'admin' || role == 'super_admin';
    } catch (e) {
      print('❌ Erreur lors de la vérification admin: $e');
      return false;
    }
  }

  // ==================== MOT DE PASSE ====================

  /// Réinitialisation du mot de passe
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }

  /// Mettre à jour le mot de passe
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du mot de passe: $e');
      rethrow;
    }
  }

  /// Vérifier le statut d'un email (existe, validé ou non) via la fonction SQL check_email_status
  Future<Map<String, dynamic>> checkEmailStatus(String email) async {
    try {
      final result = await _supabase.rpc(
        'check_email_status',
        params: {'p_email': email},
      ) as Map<String, dynamic>;
      return result;
    } catch (e) {
      print('❌ Erreur checkEmailStatus: $e');
      rethrow;
    }
  }

  // ==================== OTP (2ᵉ facteur DEV) ====================

  /// Générer un code OTP pour un email (mode développement, ne fait qu'appeler la RPC)
  Future<Map<String, dynamic>> generateOtp({required String email}) async {
    try {
      final result = await _supabase.rpc(
        'generate_otp',
        params: {'p_email': email},
      ) as Map<String, dynamic>;

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Erreur lors de la génération du code');
      }

      return result;
    } catch (e) {
      print('❌ Erreur generateOtp: $e');
      rethrow;
    }
  }

  /// Vérifier un code OTP pour un email (2ᵉ facteur)
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final result = await _supabase.rpc(
        'verify_otp',
        params: {
          'p_email': email,
          'p_code': code,
        },
      ) as Map<String, dynamic>;

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Code invalide ou expiré');
      }

      return result;
    } catch (e) {
      print('❌ Erreur verifyOtp: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Sauvegarder la session de manière sécurisée
  Future<void> _saveSessionToHive(User user, Session? session) async {
    try {
      // Récupérer le profil complet
      final profile = await getUserProfile();

      // Créer l'objet UserSession
      final userSession = UserSession(
        userId: user.id,
        email: user.email ?? '',
        accessToken: session?.accessToken,
        refreshToken: session?.refreshToken,
        tokenExpiresAt: session?.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000)
            : null,
        fullName: profile?['full_name'] ?? user.userMetadata?['full_name'] ?? '',
        role: profile?['role'] ?? 'user',
        photoUrl: profile?['photo_url'],
        choraleName: profile?['chorale_name'],
        pupitre: profile?['pupitre'],
        createdAt: DateTime.parse(user.createdAt),
        lastLoginAt: DateTime.now(),
      );

      // Sauvegarder dans le système sécurisé si disponible
      if (_encryptedHive != null) {
        await _encryptedHive!.saveSession(userSession);
        print('🔐 Session sauvegardée dans EncryptedHive (AES-256) pour ${user.email}');
      } else {
        // Fallback sur l'ancien système
        await _hiveSession.saveSession(userSession);
        print('💾 Session sauvegardée dans Hive (legacy) pour ${user.email}');
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la session: $e');
      // Ne pas rethrow pour ne pas bloquer la connexion
    }
  }

  /// Mettre à jour les tokens dans Hive
  Future<void> _updateSessionTokens(Session session) async {
    try {
      await _hiveSession.updateToken(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '', // Gérer le cas null
        expiresAt: session.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            : null,
      );
      print('🔄 Tokens mis à jour dans Hive');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des tokens: $e');
    }
  }

  // ==================== GETTERS UTILITAIRES ====================

  /// Obtenir la session depuis Hive
  UserSession? get sessionFromHive => _hiveSession.getSession();

  /// Vérifier si une session existe dans Hive
  bool get hasSessionInHive => _hiveSession.hasSession();

  /// Vérifier si la session Hive est valide
  bool get isSessionValidInHive => _hiveSession.isSessionValid();

  // ==================== NETTOYAGE SÉCURISÉ ====================

  /// 🔐 SÉCURITÉ: Nettoyer TOUTES les données locales de manière sécurisée
  /// Utilisé lors de la déconnexion et avant l'inscription
  /// pour éviter qu'un nouvel utilisateur hérite des données de l'ancien
  Future<void> _clearAllLocalData() async {
    try {
      print('🧹 Début du nettoyage complet des données locales...');
      
      // 1. Nettoyer le système sécurisé si disponible
      if (_encryptedHive != null) {
        await _encryptedHive!.clearAll();
        print('✅ EncryptedHive nettoyé');
      }
      
      // 2. Nettoyer le stockage sécurisé
      if (_secureStorage != null) {
        await _secureStorage!.clearAll();
        print('✅ SecureStorage nettoyé');
      }
      
      // 3. Nettoyer la session Hive legacy
      await _hiveSession.clearSession();
      print('✅ Session Hive (legacy) nettoyée');
      
      // 4. Fermer et supprimer toutes les boxes Hive
      try {
        // Fermer toutes les boxes ouvertes
        await Hive.close();
        print('✅ Boxes Hive fermées');
        
        // Supprimer tous les fichiers Hive
        await Hive.deleteFromDisk();
        print('✅ Données Hive supprimées du disque');
        
        // Réinitialiser Hive
        await Hive.initFlutter();
        
        // Réenregistrer les adapters
        HiveSessionService.registerAdapters();
        print('✅ Hive réinitialisé et adapters réenregistrés');
        
        // Réinitialiser le service de session
        await _hiveSession.initialize();
        print('✅ Service de session réinitialisé');
      } catch (e) {
        print('⚠️ Erreur lors du nettoyage Hive: $e');
      }
      
      // 5. TODO: Nettoyer Drift (base de données SQLite)
      // Note: Drift sera nettoyé automatiquement car lié à l'utilisateur
      // Mais on pourrait ajouter une suppression explicite ici
      
      print('✅ Nettoyage complet sécurisé terminé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage des données: $e');
      // Ne pas rethrow pour ne pas bloquer la déconnexion/inscription
    }
  }
}
