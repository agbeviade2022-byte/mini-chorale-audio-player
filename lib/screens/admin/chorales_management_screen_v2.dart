import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Écran de gestion des chorales (Super Admin uniquement)
/// Version 2 : Charge directement depuis Supabase (mêmes données que le dashboard)
class ChoralesManagementScreenV2 extends ConsumerStatefulWidget {
  const ChoralesManagementScreenV2({super.key});

  @override
  ConsumerState<ChoralesManagementScreenV2> createState() => _ChoralesManagementScreenV2State();
}

class _ChoralesManagementScreenV2State extends ConsumerState<ChoralesManagementScreenV2> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _chorales = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChorales();
  }

  /// Charger les chorales depuis Supabase
  Future<void> _loadChorales() async {
    setState(() => _isLoading = true);

    try {
      // Charger les chorales
      final choralesData = await _supabase
          .from('chorales')
          .select()
          .order('nom');

      // Compter les membres pour chaque chorale
      final choralesWithCount = <Map<String, dynamic>>[];
      
      for (final chorale in choralesData) {
        final choraleId = chorale['id'];
        
        // Compter les membres de cette chorale
        final membersCountResponse = await _supabase
            .from('profiles')
            .select('user_id')
            .eq('chorale_id', choraleId)
            .count();

        choralesWithCount.add({
          ...chorale,
          'membres_count': membersCountResponse.count,
        });
      }

      setState(() {
        _chorales = choralesWithCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Filtrer les chorales par recherche
  List<Map<String, dynamic>> get _filteredChorales {
    if (_searchQuery.isEmpty) return _chorales;
    
    return _chorales.where((chorale) {
      final nom = (chorale['nom'] ?? '').toString().toLowerCase();
      final ville = (chorale['ville'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return nom.contains(query) || ville.contains(query);
    }).toList();
  }

  /// Afficher le dialog de création/modification de chorale
  Future<void> _showChoraleDialog({Map<String, dynamic>? chorale}) async {
    final nomController = TextEditingController(text: chorale?['nom']);
    final descriptionController = TextEditingController(text: chorale?['description']);
    final villeController = TextEditingController(text: chorale?['ville']);
    final paysController = TextEditingController(text: chorale?['pays'] ?? 'France');
    final emailController = TextEditingController(text: chorale?['email_contact']);
    final telephoneController = TextEditingController(text: chorale?['telephone']);
    final siteWebController = TextEditingController(text: chorale?['site_web']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chorale == null ? 'Créer une chorale' : 'Modifier ${chorale['nom']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la chorale *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Ville
              TextField(
                controller: villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 12),

              // Pays
              TextField(
                controller: paysController,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),

              // Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email de contact',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // Téléphone
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Site web
              TextField(
                controller: siteWebController,
                decoration: const InputDecoration(
                  labelText: 'Site web',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire')),
                );
                return;
              }

              try {
                final data = {
                  'nom': nomController.text.trim(),
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'ville': villeController.text.trim().isEmpty
                      ? null
                      : villeController.text.trim(),
                  'pays': paysController.text.trim().isEmpty
                      ? null
                      : paysController.text.trim(),
                  'email_contact': emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  'telephone': telephoneController.text.trim().isEmpty
                      ? null
                      : telephoneController.text.trim(),
                  'site_web': siteWebController.text.trim().isEmpty
                      ? null
                      : siteWebController.text.trim(),
                };

                if (chorale == null) {
                  // Création
                  await _supabase.from('chorales').insert(data);
                } else {
                  // Modification
                  await _supabase
                      .from('chorales')
                      .update(data)
                      .eq('id', chorale['id']);
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: Text(chorale == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadChorales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chorale == null
                ? 'Chorale créée avec succès'
                : 'Chorale modifiée avec succès'),
          ),
        );
      }
    }
  }

  /// Afficher la confirmation de suppression
  Future<void> _showDeleteConfirmation(Map<String, dynamic> chorale) async {
    final membersCount = chorale['membres_count'] ?? 0;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la chorale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer "${chorale['nom']}" ?'),
            const SizedBox(height: 12),
            if (membersCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$membersCount membre(s) seront sans chorale',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('chorales').delete().eq('id', chorale['id']);
        
        await _loadChorales();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chorale supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des chorales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showChoraleDialog(),
            tooltip: 'Créer une chorale',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChorales,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une chorale...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Statistiques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(
                            '${_chorales.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total chorales',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(
                            '${_chorales.fold<int>(0, (sum, c) => sum + (c['membres_count'] as int? ?? 0))}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total membres',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liste des chorales
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChorales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucune chorale'
                                  : 'Aucun résultat',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _showChoraleDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Créer une chorale'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredChorales.length,
                        itemBuilder: (context, index) {
                            final chorale = _filteredChorales[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    (chorale['nom'] ?? 'C')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  chorale['nom'] ?? 'Sans nom',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (chorale['description'] != null)
                                      Text(
                                        chorale['description'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${chorale['membres_count'] ?? 0} membres'),
                                        if (chorale['ville'] != null) ...[
                                          const SizedBox(width: 16),
                                          const Icon(Icons.location_on, size: 16),
                                          const SizedBox(width: 4),
                                          Text(chorale['ville']),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _showChoraleDialog(chorale: chorale);
                                        break;
                                      case 'delete':
                                        _showDeleteConfirmation(chorale);
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
                                          Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Supprimer',
                                              style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                      ),
          ),
        ],
      ),
    );
  }
}
