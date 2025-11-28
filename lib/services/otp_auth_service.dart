import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification par OTP (Email Magic Link)
/// Inspiré de Clerk, Notion, Slack
/// Aucun mot de passe stocké - Sécurité maximale
class OtpAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Étape 1: Générer et envoyer un code OTP à l'email
  /// 
  /// Retourne:
  /// - success: true si l'OTP a été envoyé
  /// - error: 'email_not_found' si l'email n'existe pas
  /// - message: Message d'information pour l'utilisateur
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      print('📧 Envoi OTP à: $email');

      // Appeler la fonction SQL generate_otp
      final response = await _supabase.rpc('generate_otp', params: {
        'p_email': email.trim().toLowerCase(),
      });

      print('✅ Réponse OTP: $response');

      if (response == null) {
        return {
          'success': false,
          'error': 'server_error',
          'message': 'Erreur serveur. Réessayez plus tard.',
        };
      }

      // Convertir la réponse en Map
      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Code OTP envoyé à votre email',
          'code': result['code'], // ⚠️ Pour debug uniquement - À retirer en prod
        };
      } else {
        // Email non trouvé ou compte non validé
        return {
          'success': false,
          'error': result['error'] ?? 'unknown_error',
          'message': result['message'] ?? 'Aucun compte trouvé. Contactez votre chorale.',
        };
      }
    } catch (e) {
      print('❌ Erreur sendOtp: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Étape 2: Vérifier le code OTP et connecter l'utilisateur
  /// 
  /// Retourne:
  /// - success: true si l'OTP est valide
  /// - user_id: ID de l'utilisateur connecté
  /// - profile: Profil de l'utilisateur
  /// - error: 'invalid_code' si le code est invalide ou expiré
  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    try {
      print('🔐 Vérification OTP pour: $email');

      // Appeler la fonction SQL verify_otp
      final response = await _supabase.rpc('verify_otp', params: {
        'p_email': email.trim().toLowerCase(),
        'p_code': code.trim(),
      });

      print('✅ Réponse vérification: $response');

      if (response == null) {
        return {
          'success': false,
          'error': 'server_error',
          'message': 'Erreur serveur. Réessayez plus tard.',
        };
      }

      // Convertir la réponse en Map
      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        // OTP valide - Créer une session Supabase
        final userId = result['user_id'] as String;
        final profile = result['profile'] as Map<String, dynamic>;

        // Créer une session personnalisée
        // Note: Supabase Auth ne supporte pas directement l'OTP custom
        // On utilise signInWithPassword avec un token temporaire
        
        print('✅ OTP valide - Connexion utilisateur: $userId');

        return {
          'success': true,
          'user_id': userId,
          'profile': profile,
          'message': result['message'] ?? 'Connexion réussie',
        };
      } else {
        // Code invalide ou expiré
        return {
          'success': false,
          'error': result['error'] ?? 'invalid_code',
          'message': result['message'] ?? 'Code OTP invalide ou expiré',
        };
      }
    } catch (e) {
      print('❌ Erreur verifyOtp: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Créer une session Supabase après vérification OTP
  /// 
  /// Note: Supabase Auth ne supporte pas directement l'OTP custom
  /// Cette méthode utilise signInWithOtp de Supabase (Magic Link)
  Future<Map<String, dynamic>> createSession(String email) async {
    try {
      print('🔑 Création session pour: $email');

      // Utiliser le Magic Link natif de Supabase
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // Pas de redirection
      );

      // Attendre que la session soit créée
      await Future.delayed(const Duration(seconds: 1));

      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session != null && user != null) {
        print('✅ Session créée: ${user.id}');
        return {
          'success': true,
          'user_id': user.id,
          'session': session,
        };
      } else {
        return {
          'success': false,
          'error': 'session_failed',
          'message': 'Impossible de créer la session',
        };
      }
    } catch (e) {
      print('❌ Erreur createSession: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur signOut: $e');
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur est connecté
  bool isSignedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Obtenir l'utilisateur actuel
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Obtenir le profil de l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erreur getCurrentProfile: $e');
      return null;
    }
  }

  /// Créer un nouveau membre (Admin/Super Admin uniquement)
  /// 
  /// Paramètres:
  /// - fullName: Nom complet
  /// - email: Email (unique)
  /// - phone: Numéro de téléphone (optionnel)
  /// - role: Rôle (membre, admin, super_admin)
  /// - choraleId: ID de la chorale (optionnel)
  /// - adminId: ID de l'admin qui crée le membre
  Future<Map<String, dynamic>> createMember({
    required String fullName,
    required String email,
    String? phone,
    required String role,
    String? choraleId,
    required String adminId,
  }) async {
    try {
      print('👤 Création membre: $email par admin: $adminId');

      // Appeler la fonction SQL create_member
      final response = await _supabase.rpc('create_member', params: {
        'p_full_name': fullName.trim(),
        'p_email': email.trim().toLowerCase(),
        'p_phone': phone?.trim(),
        'p_role': role,
        'p_chorale_id': choraleId,
        'p_admin_id': adminId,
      });

      print('✅ Réponse création membre: $response');

      if (response == null) {
        return {
          'success': false,
          'error': 'server_error',
          'message': 'Erreur serveur. Réessayez plus tard.',
        };
      }

      // Convertir la réponse en Map
      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        return {
          'success': true,
          'member_id': result['member_id'],
          'message': result['message'] ?? 'Membre créé avec succès',
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'unknown_error',
          'message': result['message'] ?? 'Erreur lors de la création du membre',
        };
      }
    } catch (e) {
      print('❌ Erreur createMember: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les logs d'audit (Super Admin uniquement)
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select('''
            *,
            admin:admin_id(full_name, email),
            target:target_user_id(full_name, email)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur getAuditLogs: $e');
      return [];
    }
  }

  /// Valider le format d'un email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valider le format d'un code OTP (6 chiffres)
  bool isValidOtpCode(String code) {
    final codeRegex = RegExp(r'^\d{6}$');
    return codeRegex.hasMatch(code);
  }
}
