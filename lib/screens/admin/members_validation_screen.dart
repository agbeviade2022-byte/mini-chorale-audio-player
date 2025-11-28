import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/models/chorale.dart';
import 'package:mini_chorale_audio_player/providers/chorale_provider.dart';

final supabase = Supabase.instance.client;

// Provider pour les membres en attente
final pendingMembersProvider = FutureProvider.autoDispose((ref) async {
  final response = await supabase
      .from('membres_en_attente')
      .select('user_id, email, full_name, telephone, created_at, statut_validation, jours_attente');

  return response as List<dynamic>;
});

class MembersValidationScreen extends ConsumerStatefulWidget {
  const MembersValidationScreen({super.key});

  @override
  ConsumerState<MembersValidationScreen> createState() => _MembersValidationScreenState();
}

class _MembersValidationScreenState extends ConsumerState<MembersValidationScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pendingMembersAsync = ref.watch(pendingMembersProvider);
    final choralesAsync = ref.watch(choralesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des membres'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Liste des membres en attente
          Expanded(
            child: pendingMembersAsync.when(
              data: (members) {
                final filteredMembers = members.where((member) {
                  final name = (member['full_name'] ?? '').toString().toLowerCase();
                  final email = (member['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filteredMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun membre en attente'
                              : 'Aucun résultat',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tous les membres ont été validés',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return _buildMemberCard(context, member, choralesAsync);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(pendingMembersProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member, AsyncValue<List<Chorale>> choralesAsync) {
    final createdAt = DateTime.parse(member['created_at']);
    final daysWaiting = (member['jours_attente'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et badge
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    (member['full_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['full_name'] ?? 'Sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        member['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '$daysWaiting j',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations supplémentaires
            if (member['telephone'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    member['telephone'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Inscrit le ${_formatDate(createdAt)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showValidationDialog(context, member, choralesAsync),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRefuseDialog(context, member),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showValidationDialog(BuildContext context, Map<String, dynamic> member, AsyncValue<List<Chorale>> choralesAsync) {
    Chorale? selectedChorale;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Valider le membre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valider ${member['full_name']} et l\'assigner à une chorale :'),
              const SizedBox(height: 16),
              choralesAsync.when(
                data: (chorales) {
                  return DropdownButtonFormField<Chorale>(
                    value: selectedChorale,
                    decoration: const InputDecoration(
                      labelText: 'Chorale *',
                      border: OutlineInputBorder(),
                    ),
                    items: chorales.map((chorale) {
                      return DropdownMenuItem(
                        value: chorale,
                        child: Text(chorale.nom),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedChorale = value;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedChorale == null
                  ? null
                  : () async {
                      await _validateMember(member['user_id'], selectedChorale!.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.refresh(pendingMembersProvider);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRefuseDialog(BuildContext context, Map<String, dynamic> member) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le membre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir refuser ${member['full_name']} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ex: Documents incomplets',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _refuseMember(member['user_id'], commentController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ref.refresh(pendingMembersProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateMember(String userId, String choraleId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      
      await supabase.rpc('valider_membre', params: {
        'p_user_id': userId,
        'p_chorale_id': choraleId,
        'p_validateur_id': currentUserId,
        'p_commentaire': 'Validé par l\'administrateur',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Membre validé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refuseMember(String userId, String? comment) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      
      await supabase.rpc('refuser_membre', params: {
        'p_user_id': userId,
        'p_validateur_id': currentUserId,
        'p_commentaire': comment ?? 'Refusé par l\'administrateur',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Membre refusé'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
