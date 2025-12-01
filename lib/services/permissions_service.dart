import 'package:supabase_flutter/supabase_flutter.dart';

class PermissionsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupérer toutes les permissions de l'utilisateur connecté
  Future<List<String>> getUserPermissions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Récupérer le rôle depuis profiles
      final profileResponse = await _supabase
          .from('profiles')
          .select('user_id, role')
          .eq('user_id', userId)
          .single();

      final userIdFromProfile = profileResponse['user_id'];
      final role = profileResponse['role'];

      print('🔑 Chargement permissions pour user_id: $userIdFromProfile, role: $role');

      // Super admin a toutes les permissions
      if (role == 'super_admin') {
        final allPermissions = await _supabase
            .from('modules_permissions')
            .select('code');
        return (allPermissions as List)
            .map((p) => p['code'] as String)
            .toList();
      }

      // Récupérer directement depuis user_permissions
      final response = await _supabase
          .from('user_permissions')
          .select('module_code')
          .eq('user_id', userIdFromProfile);

      if (response == null) return [];

      final permissions = (response as List)
          .map((p) => p['module_code'] as String)
          .toList();
      
      print('✅ Permissions trouvées: $permissions');
      return permissions;
    } catch (e) {
      print('❌ Erreur lors de la récupération des permissions: $e');
      return [];
    }
  }

  /// Vérifier si l'utilisateur a une permission spécifique
  Future<bool> hasPermission(String permissionCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final profileResponse = await _supabase
          .from('profiles')
          .select('user_id, role')
          .eq('user_id', userId)
          .single();

      final userIdFromProfile = profileResponse['user_id'];
      final role = profileResponse['role'];

      // Super admin a toutes les permissions
      if (role == 'super_admin') return true;

      // Vérifier directement dans user_permissions
      final response = await _supabase
          .from('user_permissions')
          .select('id')
          .eq('user_id', userIdFromProfile)
          .eq('module_code', permissionCode)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erreur lors de la vérification de permission: $e');
      return false;
    }
  }

  /// Récupérer le rôle de l'utilisateur
  Future<String?> getUserRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      print('Erreur lors de la récupération du rôle: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est Super Admin
  Future<bool> isSuperAdmin() async {
    final role = await getUserRole();
    return role == 'super_admin';
  }

  /// Vérifier si l'utilisateur est Maître de Chœur
  Future<bool> isMaitreChoeur() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('est_maitre_choeur')
          .eq('user_id', userId)
          .single();

      return response['est_maitre_choeur'] == true;
    } catch (e) {
      print('Erreur lors de la vérification MC: $e');
      return false;
    }
  }

  /// Récupérer tous les modules de permissions disponibles
  Future<List<Map<String, dynamic>>> getAllModules() async {
    try {
      final response = await _supabase
          .from('modules_permissions')
          .select('*')
          .order('ordre');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur lors de la récupération des modules: $e');
      return [];
    }
  }

  /// Attribuer une permission à un utilisateur
  Future<bool> assignPermission({
    required String targetUserId,
    required String permissionCode,
    DateTime? expiresAt,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Récupérer les profile IDs
      final currentProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final targetProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', targetUserId)
          .single();

      // Appeler la fonction SQL
      await _supabase.rpc('attribuer_permission', params: {
        'p_user_id': targetProfile['id'],
        'p_module_code': permissionCode,
        'p_attribue_par': currentProfile['id'],
        'p_expire_le': expiresAt?.toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'attribution de permission: $e');
      return false;
    }
  }

  /// Révoquer une permission
  Future<bool> revokePermission({
    required String targetUserId,
    required String permissionCode,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final currentProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final targetProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', targetUserId)
          .single();

      await _supabase.rpc('revoquer_permission', params: {
        'p_user_id': targetProfile['id'],
        'p_module_code': permissionCode,
        'p_revoque_par': currentProfile['id'],
      });

      return true;
    } catch (e) {
      print('Erreur lors de la révocation de permission: $e');
      return false;
    }
  }
}
