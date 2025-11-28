import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/role_provider.dart';

/// Widget pour afficher le badge de rôle de l'utilisateur
class RoleBadge extends ConsumerWidget {
  final bool showIcon;
  final bool showText;
  final double fontSize;
  
  const RoleBadge({
    super.key,
    this.showIcon = true,
    this.showText = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(role.badgeColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(role.badgeColor).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Text(
                  role.icon,
                  style: TextStyle(fontSize: fontSize + 2),
                ),
                if (showText) const SizedBox(width: 6),
              ],
              if (showText)
                Text(
                  role.displayName,
                  style: TextStyle(
                    color: Color(role.badgeColor),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget pour afficher les permissions de l'utilisateur
class RolePermissionsCard extends ConsumerWidget {
  const RolePermissionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      role.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      role.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(role.badgeColor),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vos permissions :',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPermission(
                  context,
                  'Voir tous les chants',
                  role.canViewAllChants,
                ),
                _buildPermission(
                  context,
                  'Télécharger les chants',
                  role.canDownloadChants,
                ),
                _buildPermission(
                  context,
                  'Créer des playlists',
                  role.canCreatePlaylists,
                ),
                _buildPermission(
                  context,
                  'Ajouter aux favoris',
                  role.canAddFavorites,
                ),
                _buildPermission(
                  context,
                  'Gérer les chants',
                  role.canManageChants,
                ),
                _buildPermission(
                  context,
                  'Gérer les chorales',
                  role.canManageChorales,
                ),
                _buildPermission(
                  context,
                  'Gérer les utilisateurs',
                  role.canManageUsers,
                ),
                _buildPermission(
                  context,
                  'Accès dashboard web',
                  role.hasWebDashboardAccess,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPermission(BuildContext context, String label, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: granted ? Colors.black87 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
