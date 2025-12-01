import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour appeler l'API Admin (Next.js Dashboard)
/// Permet de créer des utilisateurs avec compte Auth complet
class AdminApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // URL de l'API Dashboard (à configurer selon l'environnement)
  // En production, utiliser l'URL de votre dashboard déployé
  static const String _apiBaseUrl = String.fromEnvironment(
    'ADMIN_API_URL',
    defaultValue: 'https://votre-dashboard.vercel.app', // Remplacer par votre URL
  );

  /// Créer un nouveau membre avec compte Auth complet
  /// 
  /// Paramètres:
  /// - email: Email du nouveau membre
  /// - fullName: Nom complet
  /// - telephone: Numéro de téléphone (optionnel)
  /// - role: Rôle (membre, admin, super_admin)
  /// - choraleId: ID de la chorale (optionnel)
  /// - sendInvitation: Si true, envoie une invitation par email
  ///                   Si false, génère un mot de passe temporaire
  /// 
  /// Retourne:
  /// - success: true si le membre a été créé
  /// - temporary_password: Mot de passe temporaire (si sendInvitation=false)
  /// - message: Message d'information
  Future<Map<String, dynamic>> createMemberWithAuth({
    required String email,
    required String fullName,
    String? telephone,
    String role = 'membre',
    String? choraleId,
    bool sendInvitation = false,
  }) async {
    try {
      print('🔐 Création membre avec Auth: $email');
      
      // Récupérer le token de l'utilisateur connecté
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'Vous devez être connecté pour créer un membre',
        };
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/admin/create-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'full_name': fullName.trim(),
          'telephone': telephone?.trim(),
          'role': role,
          'chorale_id': choraleId,
          'send_invitation': sendInvitation,
        }),
      );

      print('📡 Réponse API: ${response.statusCode}');
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'user_id': data['user_id'],
          'email': data['email'],
          'temporary_password': data['temporary_password'],
          'send_invitation': data['send_invitation'],
          'message': data['message'] ?? 'Membre créé avec succès',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'api_error',
          'message': data['error'] ?? 'Erreur lors de la création du membre',
        };
      }
    } catch (e) {
      print('❌ Erreur createMemberWithAuth: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': 'Erreur de connexion au serveur: ${e.toString()}',
      };
    }
  }

  /// Vérifier si l'API est accessible
  Future<bool> isApiAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
