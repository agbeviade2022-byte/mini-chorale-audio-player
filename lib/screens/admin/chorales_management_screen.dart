import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/models/chorale.dart';
import 'package:mini_chorale_audio_player/providers/chorale_provider.dart';
import 'package:mini_chorale_audio_player/services/chorale_service.dart';

class ChoralesManagementScreen extends ConsumerStatefulWidget {
  const ChoralesManagementScreen({super.key});

  @override
  ConsumerState<ChoralesManagementScreen> createState() => _ChoralesManagementScreenState();
}

class _ChoralesManagementScreenState extends ConsumerState<ChoralesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final choralesAsync = ref.watch(choralesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Chorales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateChoraleDialog(context),
            tooltip: 'Créer une chorale',
          ),
        ],
      ),
      body: choralesAsync.when(
        data: (chorales) {
          if (chorales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune chorale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre première chorale',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateChoraleDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une chorale'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chorales.length,
            itemBuilder: (context, index) {
              final chorale = chorales[index];
              return _buildChoraleCard(chorale);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(choralesListProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoraleCard(Chorale chorale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(chorale.couleurTheme),
          child: Text(
            chorale.nom[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          chorale.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chorale.description != null)
              Text(
                chorale.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${chorale.nombreMembres} membres'),
                const SizedBox(width: 16),
                if (chorale.ville != null) ...[
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(chorale.ville!),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditChoraleDialog(context, chorale);
                break;
              case 'delete':
                _showDeleteConfirmation(context, chorale);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showChoraleDetails(context, chorale),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppTheme.primaryBlue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryBlue;
    }
  }

  void _showCreateChoraleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateChoraleDialog(),
    ).then((created) {
      if (created == true) {
        ref.invalidate(choralesListProvider);
      }
    });
  }

  void _showEditChoraleDialog(BuildContext context, Chorale chorale) {
    showDialog(
      context: context,
      builder: (context) => CreateChoraleDialog(chorale: chorale),
    ).then((updated) {
      if (updated == true) {
        ref.invalidate(choralesListProvider);
      }
    });
  }

  void _showChoraleDetails(BuildContext context, Chorale chorale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chorale.nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chorale.description != null) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(chorale.description!),
                const SizedBox(height: 12),
              ],
              _buildDetailRow('Membres', '${chorale.nombreMembres}'),
              if (chorale.ville != null) _buildDetailRow('Ville', chorale.ville!),
              if (chorale.pays != null) _buildDetailRow('Pays', chorale.pays!),
              if (chorale.emailContact != null) _buildDetailRow('Email', chorale.emailContact!),
              if (chorale.telephone != null) _buildDetailRow('Téléphone', chorale.telephone!),
              if (chorale.siteWeb != null) _buildDetailRow('Site web', chorale.siteWeb!),
              _buildDetailRow('Statut', chorale.statut),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Chorale chorale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la chorale'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${chorale.nom}" ?\n\n'
          '⚠️ ATTENTION : Tous les membres de cette chorale seront également supprimés !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final service = ref.read(choraleServiceProvider);
                await service.deleteChorale(chorale.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chorale supprimée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  ref.invalidate(choralesListProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DIALOG DE CRÉATION/MODIFICATION DE CHORALE
// =====================================================

class CreateChoraleDialog extends ConsumerStatefulWidget {
  final Chorale? chorale;

  const CreateChoraleDialog({super.key, this.chorale});

  @override
  ConsumerState<CreateChoraleDialog> createState() => _CreateChoraleDialogState();
}

class _CreateChoraleDialogState extends ConsumerState<CreateChoraleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _slugController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _adresseController;
  late final TextEditingController _villeController;
  late final TextEditingController _paysController;
  late final TextEditingController _siteWebController;
  String _couleurTheme = '#6366F1';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.chorale?.nom);
    _slugController = TextEditingController(text: widget.chorale?.slug);
    _descriptionController = TextEditingController(text: widget.chorale?.description);
    _emailController = TextEditingController(text: widget.chorale?.emailContact);
    _telephoneController = TextEditingController(text: widget.chorale?.telephone);
    _adresseController = TextEditingController(text: widget.chorale?.adresse);
    _villeController = TextEditingController(text: widget.chorale?.ville);
    _paysController = TextEditingController(text: widget.chorale?.pays ?? 'France');
    _siteWebController = TextEditingController(text: widget.chorale?.siteWeb);
    _couleurTheme = widget.chorale?.couleurTheme ?? '#6366F1';

    // Auto-générer le slug quand le nom change
    _nomController.addListener(_generateSlug);
  }

  void _generateSlug() {
    if (widget.chorale == null) {
      // Seulement en mode création
      final slug = _nomController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[àáâãäå]'), 'a')
          .replaceAll(RegExp(r'[èéêë]'), 'e')
          .replaceAll(RegExp(r'[ìíîï]'), 'i')
          .replaceAll(RegExp(r'[òóôõö]'), 'o')
          .replaceAll(RegExp(r'[ùúûü]'), 'u')
          .replaceAll(RegExp(r'[ç]'), 'c')
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      _slugController.text = slug;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    _siteWebController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.chorale != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifier la chorale' : 'Créer une chorale'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la chorale *',
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug (URL) *',
                  prefixIcon: Icon(Icons.link),
                  helperText: 'Ex: ma-chorale (sans espaces ni accents)',
                ),
                enabled: !isEdit, // Ne pas modifier le slug en édition
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un slug';
                  }
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                    return 'Slug invalide (a-z, 0-9, - uniquement)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paysController,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email de contact',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _siteWebController,
                decoration: const InputDecoration(
                  labelText: 'Site web',
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(choraleServiceProvider);

      if (widget.chorale != null) {
        // Mode édition
        await service.updateChorale(
          id: widget.chorale!.id,
          data: {
            'nom': _nomController.text.trim(),
            'description': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            'couleur_theme': _couleurTheme,
            'email_contact': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'telephone': _telephoneController.text.trim().isEmpty
                ? null
                : _telephoneController.text.trim(),
            'adresse': _adresseController.text.trim().isEmpty
                ? null
                : _adresseController.text.trim(),
            'ville': _villeController.text.trim().isEmpty
                ? null
                : _villeController.text.trim(),
            'pays': _paysController.text.trim().isEmpty
                ? null
                : _paysController.text.trim(),
            'site_web': _siteWebController.text.trim().isEmpty
                ? null
                : _siteWebController.text.trim(),
          },
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chorale modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mode création
        await service.createChorale(
          nom: _nomController.text.trim(),
          slug: _slugController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          couleurTheme: _couleurTheme,
          emailContact: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          ville: _villeController.text.trim().isEmpty
              ? null
              : _villeController.text.trim(),
          pays: _paysController.text.trim().isEmpty
              ? null
              : _paysController.text.trim(),
          siteWeb: _siteWebController.text.trim().isEmpty
              ? null
              : _siteWebController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chorale créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
