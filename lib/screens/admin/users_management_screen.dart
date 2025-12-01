import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/screens/admin/add_member_screen.dart';

/// Écran de gestion des utilisateurs (Super Admin uniquement)
class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _chorales = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSuperAdmin = false;
  String? _adminChoraleId;
  bool _canAddMembers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Charger les utilisateurs et les chorales
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Récupérer le profil de l'utilisateur connecté
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final myProfile = await _supabase
          .from('profiles')
          .select('role, chorale_id')
          .eq('user_id', userId)
          .single();
      
      final myRole = myProfile['role'] as String?;
      final myChoraleId = myProfile['chorale_id'] as String?;
      
      _isSuperAdmin = myRole == 'super_admin';
      _adminChoraleId = myChoraleId;

      var canAddMembers = _isSuperAdmin;
      if (!canAddMembers) {
        final addPermission = await _supabase
            .from('user_permissions')
            .select('module_code')
            .eq('user_id', userId)
            .eq('module_code', 'add_members')
            .maybeSingle();
        canAddMembers = addPermission != null;
      }
      
      print('👤 Mon rôle: $myRole, Ma chorale: $myChoraleId');
      
      // 2. Charger les utilisateurs (filtrés si admin)
      List<dynamic> usersData;
      if (_isSuperAdmin) {
        // Super admin voit tout
        usersData = await _supabase.rpc('get_all_users_with_emails_debug');
      } else if (myChoraleId != null) {
        // Admin voit uniquement les membres de sa chorale
        usersData = await _supabase
            .from('profiles')
            .select('*, chorales(nom)')
            .eq('chorale_id', myChoraleId)
            .order('full_name');
      } else {
        usersData = [];
      }
      
      // 3. Charger les chorales (filtrées si admin)
      List<dynamic> choralesData;
      if (_isSuperAdmin) {
        choralesData = await _supabase
            .from('chorales')
            .select('id, nom')
            .order('nom');
      } else if (myChoraleId != null) {
        // Admin voit uniquement sa chorale
        choralesData = await _supabase
            .from('chorales')
            .select('id, nom')
            .eq('id', myChoraleId);
      } else {
        choralesData = [];
      }

      setState(() {
        _users = List<Map<String, dynamic>>.from(usersData);
        _chorales = List<Map<String, dynamic>>.from(choralesData);
        _canAddMembers = canAddMembers;
        _isLoading = false;
      });
      
      print('✅ ${_users.length} utilisateurs chargés, ${_chorales.length} chorales');
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Filtrer les utilisateurs par recherche
  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      final fullName = (user['full_name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return fullName.contains(query) || 
             email.contains(query) || 
             role.contains(query);
    }).toList();
  }

  /// Afficher le dialog de modification d'utilisateur
  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final fullNameController = TextEditingController(text: user['full_name']);
    String selectedRole = user['role'] ?? 'membre';
    String? selectedChoraleId = user['chorale_id'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier ${user['full_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email (non modifiable)
                Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Nom complet
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Rôle
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                    DropdownMenuItem(value: 'membre', child: Text('Membre')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedRole = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Chorale
                DropdownButtonFormField<String?>(
                  value: selectedChoraleId,
                  decoration: const InputDecoration(
                    labelText: 'Chorale',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Aucune chorale'),
                    ),
                    ..._chorales.map((chorale) => DropdownMenuItem(
                      value: chorale['id'],
                      child: Text(chorale['nom']),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedChoraleId = value);
                  },
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
                try {
                  // Mettre à jour l'utilisateur
                  await _supabase
                      .from('profiles')
                      .update({
                        'full_name': fullNameController.text.trim(),
                        'role': selectedRole,
                        'chorale_id': selectedChoraleId,
                      })
                      .eq('user_id', user['user_id']);

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
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur modifié avec succès')),
        );
      }
    }
  }

  /// Obtenir la couleur du badge de rôle
  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'membre':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir le texte du badge de rôle
  String _getRoleText(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'membre':
        return 'Membre';
      default:
        return 'Utilisateur';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: _canAddMembers
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddMemberScreen(),
                  ),
                );
                if (mounted) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter'),
            )
          : null,
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
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
                            '${_users.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total utilisateurs',
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
                            '${_users.where((u) => u['chorale_id'] != null).length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Avec chorale',
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

          // Liste des utilisateurs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text('Aucun utilisateur trouvé'),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(user['role'] ?? 'user'),
                                  child: Text(
                                    (user['full_name'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user['full_name'] ?? 'Sans nom',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email'] ?? ''),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(user['role'] ?? 'user'),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getRoleText(user['role'] ?? 'user'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (user['chorale_nom'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user['chorale_nom'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Sans chorale',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditUserDialog(user),
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
