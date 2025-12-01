import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/services/otp_auth_service.dart';
import 'package:mini_chorale_audio_player/services/admin_api_service.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

/// Écran pour ajouter un nouveau membre
/// Accessible uniquement aux Admin et Super Admin
class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpService = OtpAuthService();
  final _adminApiService = AdminApiService();
  final _supabase = Supabase.instance.client;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'membre';
  String? _selectedChoraleId;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _temporaryPassword;
  bool _sendInvitation = true; // Par défaut, envoyer une invitation

  List<Map<String, dynamic>> _chorales = [];
  bool _isSuperAdmin = false;
  String? _adminChoraleId;
  String? _adminChoraleName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Charger les données (profil admin + chorales)
  Future<void> _loadData() async {
    try {
      // 1. Récupérer le profil de l'utilisateur connecté
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final myProfile = await _supabase
          .from('profiles')
          .select('role, chorale_id, chorales(nom)')
          .eq('user_id', userId)
          .single();
      
      final myRole = myProfile['role'] as String?;
      final myChoraleId = myProfile['chorale_id'] as String?;
      final myChoraleName = myProfile['chorales']?['nom'] as String?;
      
      _isSuperAdmin = myRole == 'super_admin';
      _adminChoraleId = myChoraleId;
      _adminChoraleName = myChoraleName;
      
      print('👤 AddMember - Mon rôle: $myRole, Ma chorale: $myChoraleId');
      
      // 2. Charger les chorales (filtrées si admin)
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
        // Pré-sélectionner la chorale de l'admin
        _selectedChoraleId = myChoraleId;
      } else {
        choralesData = [];
      }

      setState(() {
        _chorales = List<Map<String, dynamic>>.from(choralesData);
      });
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    }
  }

  /// Créer un nouveau membre avec compte Auth complet
  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _temporaryPassword = null;
    });

    try {
      final result = await _adminApiService.createMemberWithAuth(
        email: _emailController.text.trim().toLowerCase(),
        fullName: _fullNameController.text.trim(),
        telephone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedRole,
        choraleId: _selectedChoraleId,
        sendInvitation: _sendInvitation,
      );

      if (result['success'] == true) {
        final tempPassword = result['temporary_password'] as String?;
        
        setState(() {
          _successMessage = result['message'];
          _temporaryPassword = tempPassword;
        });

        // Effacer le formulaire
        _fullNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        setState(() {
          _selectedRole = 'membre';
          if (_isSuperAdmin) {
            _selectedChoraleId = null;
          }
        });

        // Afficher un snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un membre'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte d'information
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Le membre recevra un code OTP par email pour se connecter',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nom complet
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet *',
                    hintText: 'Jean Dupont',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    if (value.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'jean.dupont@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!_otpService.isValidEmail(value.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    hintText: '+33 6 12 34 56 78',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rôle (limité pour les admins)
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Rôle *',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'membre',
                      child: Text('Membre'),
                    ),
                    // Seul super_admin peut créer des admins
                    if (_isSuperAdmin) ...[
                      const DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin (Gestionnaire de chorale)'),
                      ),
                      const DropdownMenuItem(
                        value: 'super_admin',
                        child: Text('Super Admin'),
                      ),
                    ],
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Chorale (verrouillée pour les admins)
                if (_isSuperAdmin)
                  DropdownButtonFormField<String>(
                    value: _selectedChoraleId,
                    decoration: InputDecoration(
                      labelText: 'Chorale (optionnel)',
                      prefixIcon: const Icon(Icons.groups_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Aucune chorale'),
                      ),
                      ..._chorales.map((chorale) {
                        return DropdownMenuItem(
                          value: chorale['id'],
                          child: Text(chorale['nom']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedChoraleId = value;
                      });
                    },
                  )
                else
                  // Admin: chorale verrouillée sur sa propre chorale
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.groups_outlined, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chorale',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _adminChoraleName ?? 'Ma chorale',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.lock, size: 16, color: Colors.grey[500]),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Option d'invitation
                Card(
                  child: SwitchListTile(
                    title: const Text('Envoyer une invitation par email'),
                    subtitle: Text(
                      _sendInvitation 
                          ? 'Le membre recevra un email pour définir son mot de passe'
                          : 'Un mot de passe temporaire sera généré',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: _sendInvitation,
                    onChanged: (value) {
                      setState(() {
                        _sendInvitation = value;
                      });
                    },
                    secondary: Icon(
                      _sendInvitation ? Icons.email : Icons.password,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Messages
                if (_errorMessage != null) ...[
                  _buildErrorMessage(_errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (_successMessage != null) ...[
                  _buildSuccessMessage(_successMessage!),
                  const SizedBox(height: 16),
                ],
                
                // Afficher le mot de passe temporaire si généré
                if (_temporaryPassword != null) ...[
                  _buildPasswordCard(_temporaryPassword!),
                  const SizedBox(height: 16),
                ],

                // Bouton créer
                ElevatedButton(
                  onPressed: _isLoading ? null : _createMember,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Créer le membre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Note
                Text(
                  '* Champs obligatoires',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Message d'erreur
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Message de succès
  Widget _buildSuccessMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte avec le mot de passe temporaire (copiable)
  Widget _buildPasswordCard(String password) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_key, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Mot de passe temporaire',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      password,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mot de passe copié !'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copier',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Communiquez ce mot de passe au membre de façon sécurisée. Il devra le changer à sa première connexion.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
