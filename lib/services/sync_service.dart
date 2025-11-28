import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/services/hive_session_service.dart';

/// Service de synchronisation en temps réel avec le Dashboard Web
/// 🔄 Assure la cohérence des données entre Flutter et Next.js
class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final HiveSessionService _hiveSession;
  
  // Subscriptions pour les changements en temps réel
  RealtimeChannel? _profileChannel;
  RealtimeChannel? _choralesChannel;
  RealtimeChannel? _chantsChannel;
  
  // Controllers pour notifier les changements
  final _profileChangesController = StreamController<Map<String, dynamic>>.broadcast();
  final _choralesChangesController = StreamController<Map<String, dynamic>>.broadcast();
  final _chantsChangesController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Streams publics
  Stream<Map<String, dynamic>> get profileChanges => _profileChangesController.stream;
  Stream<Map<String, dynamic>> get choralesChanges => _choralesChangesController.stream;
  Stream<Map<String, dynamic>> get chantsChanges => _chantsChangesController.stream;

  SyncService(this._hiveSession);

  // ==================== INITIALISATION ====================

  /// Démarrer la synchronisation en temps réel
  Future<void> startSync() async {
    try {
      final session = _hiveSession.getSession();
      if (session == null) {
        print('⚠️ Pas de session, synchronisation non démarrée');
        return;
      }

      print('🔄 Démarrage de la synchronisation en temps réel...');

      // Écouter les changements de profil
      await _listenToProfileChanges(session.userId);
      
      // Écouter les changements de chorales
      await _listenToChoralesChanges();
      
      // Écouter les changements de chants
      await _listenToChantsChanges();

      print('✅ Synchronisation en temps réel activée');
    } catch (e) {
      print('❌ Erreur lors du démarrage de la sync: $e');
    }
  }

  /// Arrêter la synchronisation
  Future<void> stopSync() async {
    try {
      await _profileChannel?.unsubscribe();
      await _choralesChannel?.unsubscribe();
      await _chantsChannel?.unsubscribe();
      
      _profileChannel = null;
      _choralesChannel = null;
      _chantsChannel = null;

      print('🛑 Synchronisation arrêtée');
    } catch (e) {
      print('❌ Erreur lors de l\'arrêt de la sync: $e');
    }
  }

  // ==================== ÉCOUTE DES CHANGEMENTS ====================

  /// Écouter les changements de profil utilisateur
  Future<void> _listenToProfileChanges(String userId) async {
    _profileChannel = _supabase.channel('profile-changes-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) async {
          print('📥 Changement de profil détecté: ${payload.eventType}');
          
          // Mettre à jour Hive avec les nouvelles données
          if (payload.newRecord != null) {
            await _updateProfileInHive(payload.newRecord);
          }
          
          // Notifier les listeners
          _profileChangesController.add(payload.newRecord ?? {});
        },
      )
      .subscribe();
  }

  /// Écouter les changements de chorales
  Future<void> _listenToChoralesChanges() async {
    _choralesChannel = _supabase.channel('chorales-changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chorales',
        callback: (payload) {
          print('📥 Changement de chorale détecté: ${payload.eventType}');
          
          // Notifier les listeners
          _choralesChangesController.add({
            'event': payload.eventType.toString(),
            'data': payload.newRecord ?? payload.oldRecord,
          });
        },
      )
      .subscribe();
  }

  /// Écouter les changements de chants
  Future<void> _listenToChantsChanges() async {
    _chantsChannel = _supabase.channel('chants-changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chants',
        callback: (payload) {
          print('📥 Changement de chant détecté: ${payload.eventType}');
          
          // Notifier les listeners
          _chantsChangesController.add({
            'event': payload.eventType.toString(),
            'data': payload.newRecord ?? payload.oldRecord,
          });
        },
      )
      .subscribe();
  }

  // ==================== MISE À JOUR LOCALE ====================

  /// Mettre à jour le profil dans Hive
  Future<void> _updateProfileInHive(Map<String, dynamic> profileData) async {
    try {
      await _hiveSession.updateProfile(
        fullName: profileData['full_name'] as String?,
        photoUrl: profileData['photo_url'] as String?,
        choraleName: profileData['chorale_name'] as String?,
        pupitre: profileData['pupitre'] as String?,
        role: profileData['role'] as String?,
      );
      
      print('💾 Profil mis à jour dans Hive depuis le serveur');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du profil local: $e');
    }
  }

  // ==================== LOGGING DES ACTIONS ====================

  /// Logger une action utilisateur (visible sur le dashboard)
  Future<void> logAction({
    required String action,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final session = _hiveSession.getSession();
      if (session == null) return;

      // Récupérer l'ID de l'admin système
      final adminData = await _supabase
          .from('system_admins')
          .select('id')
          .eq('user_id', session.userId)
          .maybeSingle();

      if (adminData == null) {
        print('⚠️ Utilisateur non admin, log non enregistré');
        return;
      }

      await _supabase.from('admin_logs').insert({
        'admin_id': adminData['id'],
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'details': details,
        'platform': 'flutter_mobile',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('📝 Action loggée: $action');
    } catch (e) {
      print('❌ Erreur lors du logging: $e');
      // Ne pas bloquer l'action si le log échoue
    }
  }

  // ==================== SYNCHRONISATION MANUELLE ====================

  /// Forcer la synchronisation du profil
  Future<Map<String, dynamic>?> syncProfile() async {
    try {
      final session = _hiveSession.getSession();
      if (session == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', session.userId)  // ✅ CORRECTION: user_id au lieu de id
          .single();

      await _updateProfileInHive(profile);
      
      print('✅ Profil synchronisé manuellement');
      return profile;
    } catch (e) {
      print('❌ Erreur lors de la sync manuelle du profil: $e');
      return null;
    }
  }

  /// Forcer la synchronisation des chorales
  Future<List<Map<String, dynamic>>> syncChorales() async {
    try {
      final chorales = await _supabase
          .from('chorales')
          .select()
          .order('created_at', ascending: false);

      print('✅ ${chorales.length} chorales synchronisées');
      return chorales;
    } catch (e) {
      print('❌ Erreur lors de la sync des chorales: $e');
      return [];
    }
  }

  /// Forcer la synchronisation des chants
  Future<List<Map<String, dynamic>>> syncChants() async {
    try {
      final chants = await _supabase
          .from('chants')
          .select()
          .order('created_at', ascending: false);

      print('✅ ${chants.length} chants synchronisés');
      return chants;
    } catch (e) {
      print('❌ Erreur lors de la sync des chants: $e');
      return [];
    }
  }

  // ==================== VÉRIFICATION DE COHÉRENCE ====================

  /// Vérifier la cohérence entre Hive et Supabase
  Future<bool> checkConsistency() async {
    try {
      final session = _hiveSession.getSession();
      if (session == null) return false;

      // Vérifier le profil
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', session.userId)  // ✅ CORRECTION: user_id au lieu de id
          .maybeSingle();

      if (profile == null) {
        print('⚠️ Profil non trouvé sur Supabase');
        return false;
      }

      // Comparer les données
      final isConsistent = 
          profile['full_name'] == session.fullName &&
          profile['role'] == session.role;

      if (!isConsistent) {
        print('⚠️ Incohérence détectée, synchronisation...');
        await _updateProfileInHive(profile);
      } else {
        print('✅ Données cohérentes');
      }

      return isConsistent;
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
      return false;
    }
  }

  // ==================== NETTOYAGE ====================

  /// Nettoyer les ressources
  void dispose() {
    _profileChangesController.close();
    _choralesChangesController.close();
    _chantsChangesController.close();
    stopSync();
  }
}
