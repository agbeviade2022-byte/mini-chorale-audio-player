import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/sync_provider.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';

/// Widget pour afficher le statut de synchronisation
/// 🔄 Affiche si l'app est synchronisée avec le dashboard
class SyncStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  final double iconSize;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: syncState.isActive 
            ? Colors.green.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: syncState.isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            syncState.isActive ? Icons.sync : Icons.sync_disabled,
            size: iconSize,
            color: syncState.isActive ? Colors.green : Colors.grey,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              syncState.isActive ? 'Synchronisé' : 'Hors ligne',
              style: TextStyle(
                fontSize: 12,
                color: syncState.isActive ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (syncState.lastSyncAt != null && showLabel) ...[
            const SizedBox(width: 8),
            Text(
              _formatTime(syncState.lastSyncAt!),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

/// Bouton pour forcer la synchronisation manuelle
class SyncButton extends ConsumerWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    return IconButton(
      icon: Icon(
        Icons.refresh,
        color: syncState.isActive ? AppTheme.primary : Colors.grey,
      ),
      onPressed: () async {
        try {
          await ref.read(syncStateProvider.notifier).syncAll();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('✅ Synchronisation terminée'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('❌ Erreur: $e'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      tooltip: 'Synchroniser',
    );
  }
}

/// Widget détaillé du statut de synchronisation
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  syncState.isActive ? Icons.cloud_done : Icons.cloud_off,
                  color: syncState.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  'Synchronisation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SyncButton(),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow(
              'Profil',
              syncState.isProfileSynced,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Chorales',
              syncState.isChoralesSynced,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Chants',
              syncState.isChantsSynced,
            ),
            
            if (syncState.lastSyncAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Dernière synchronisation: ${_formatFullTime(syncState.lastSyncAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            if (syncState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncState.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool synced) {
    return Row(
      children: [
        Icon(
          synced ? Icons.check_circle : Icons.pending,
          size: 16,
          color: synced ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          synced ? 'Synchronisé' : 'En attente',
          style: TextStyle(
            fontSize: 12,
            color: synced ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  String _formatFullTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} à ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
