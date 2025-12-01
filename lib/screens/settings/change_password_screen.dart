import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Vérification de la complexité du mot de passe
  bool _hasMinLength(String password) => password.length >= 8;
  bool _hasUppercase(String password) => password.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String password) => password.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String password) => password.contains(RegExp(r'[0-9]'));

  bool _isPasswordValid(String password) {
    return _hasMinLength(password) &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasDigit(password);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null || user.email == null) {
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      // 1. Vérifier le mot de passe actuel en se reconnectant
      final signInResponse = await supabase.auth.signInWithPassword(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      if (signInResponse.user == null) {
        setState(() {
          _errorMessage = 'Mot de passe actuel incorrect';
          _isLoading = false;
        });
        return;
      }

      // 2. Mettre à jour le mot de passe
      final updateResponse = await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (updateResponse.user != null) {
        setState(() {
          _successMessage = 'Mot de passe modifié avec succès !';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        // Afficher un snackbar et retourner
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe modifié avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Retourner après 2 secondes
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la modification du mot de passe';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('Invalid login credentials')) {
          _errorMessage = 'Mot de passe actuel incorrect';
        } else {
          _errorMessage = 'Erreur: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur inattendue: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final newPassword = _newPasswordController.text;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon mot de passe'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              
              // Titre
              Text(
                'Changez votre mot de passe',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre mot de passe actuel et choisissez un nouveau mot de passe sécurisé.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Message d'erreur
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Message de succès
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mot de passe actuel
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez votre mot de passe actuel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nouveau mot de passe
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez un nouveau mot de passe';
                  }
                  if (!_isPasswordValid(value)) {
                    return 'Le mot de passe ne respecte pas les critères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Indicateurs de complexité
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Le mot de passe doit contenir :',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildCriteriaRow(
                      'Au moins 8 caractères',
                      _hasMinLength(newPassword),
                    ),
                    _buildCriteriaRow(
                      'Une lettre majuscule',
                      _hasUppercase(newPassword),
                    ),
                    _buildCriteriaRow(
                      'Une lettre minuscule',
                      _hasLowercase(newPassword),
                    ),
                    _buildCriteriaRow(
                      'Un chiffre',
                      _hasDigit(newPassword),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirmer le mot de passe
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmez le mot de passe';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton de validation
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
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
                        'Modifier le mot de passe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
