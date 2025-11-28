import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

/// Enum pour les rôles utilisateurs
enum UserRole {
  superAdmin('super_admin'),
  admin('admin'),
  membre('membre'),
  user('user');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'membre':
        return UserRole.membre;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

/// Provider du rôle de l'utilisateur actuel
final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final authService = ref.watch(authServiceProvider);
  
  try {
    final profile = await authService.getUserProfile();
    if (profile == null) return UserRole.user;
    
    final roleString = profile['role'] as String? ?? 'user';
    return UserRole.fromString(roleString);
  } catch (e) {
    print('❌ Erreur lors de la récupération du rôle: $e');
    return UserRole.user;
  }
});

/// Provider pour vérifier si l'utilisateur est super admin
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role == UserRole.superAdmin;
});

/// Provider pour vérifier si l'utilisateur est admin (admin ou super_admin)
final isAdminOrSuperAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role == UserRole.admin || role == UserRole.superAdmin;
});

/// Provider pour vérifier si l'utilisateur est membre
final isMembreProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role == UserRole.membre;
});

/// Provider pour vérifier si l'utilisateur peut gérer les chants (admin ou super_admin)
final canManageChantsProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role == UserRole.admin || role == UserRole.superAdmin;
});

/// Provider pour vérifier si l'utilisateur peut voir tous les chants
final canViewAllChantsProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  // Super admin, admin et membre peuvent voir tous les chants
  return role == UserRole.superAdmin || 
         role == UserRole.admin || 
         role == UserRole.membre;
});

/// Provider pour vérifier si l'utilisateur peut télécharger les chants
final canDownloadChantsProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  // Tous sauf user basique peuvent télécharger
  return role != UserRole.user;
});

/// Extension pour faciliter les vérifications de permissions
extension UserRolePermissions on UserRole {
  /// Peut gérer les utilisateurs
  bool get canManageUsers => this == UserRole.superAdmin || this == UserRole.admin;
  
  /// Peut gérer les chorales
  bool get canManageChorales => this == UserRole.superAdmin || this == UserRole.admin;
  
  /// Peut créer/modifier/supprimer des chants
  bool get canManageChants => this == UserRole.superAdmin || this == UserRole.admin;
  
  /// Peut voir tous les chants (y compris privés)
  bool get canViewAllChants => this == UserRole.superAdmin || 
                                this == UserRole.admin || 
                                this == UserRole.membre;
  
  /// Peut télécharger les chants pour écoute hors ligne
  bool get canDownloadChants => this != UserRole.user;
  
  /// Peut créer des playlists
  bool get canCreatePlaylists => true; // Tous les utilisateurs
  
  /// Peut ajouter aux favoris
  bool get canAddFavorites => true; // Tous les utilisateurs
  
  /// A accès au dashboard web
  bool get hasWebDashboardAccess => this == UserRole.superAdmin || this == UserRole.admin;
  
  /// Nom d'affichage du rôle
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrateur';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.membre:
        return 'Membre';
      case UserRole.user:
        return 'Utilisateur';
    }
  }
  
  /// Icône du rôle
  String get icon {
    switch (this) {
      case UserRole.superAdmin:
        return '👑';
      case UserRole.admin:
        return '🔧';
      case UserRole.membre:
        return '🎵';
      case UserRole.user:
        return '👤';
    }
  }
  
  /// Couleur du badge de rôle
  int get badgeColor {
    switch (this) {
      case UserRole.superAdmin:
        return 0xFFE53935; // Rouge
      case UserRole.admin:
        return 0xFFFB8C00; // Orange
      case UserRole.membre:
        return 0xFF43A047; // Vert
      case UserRole.user:
        return 0xFF1E88E5; // Bleu
    }
  }
}
