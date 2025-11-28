import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/widgets/error_message_card.dart';
import 'package:mini_chorale_audio_player/widgets/password_strength_indicator.dart';
import 'package:mini_chorale_audio_player/screens/auth/login.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '❌ Les mots de passe ne correspondent pas';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Mettre à jour le mot de passe
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
        ),
      );

      setState(() {
        _successMessage = '✅ Mot de passe modifié avec succès !';
        _isLoading = false;
      });

      // Déconnecter l'utilisateur
      await Supabase.instance.client.auth.signOut();

      // Rediriger vers la page de connexion après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('weak password') || 
        errorString.contains('password is too short')) {
      return '❌ Mot de passe trop faible (minimum 6 caractères)';
    } else if (errorString.contains('same password')) {
      return '❌ Le nouveau mot de passe doit être différent';
    } else if (errorString.contains('network')) {
      return '🌐 Erreur de connexion. Vérifiez votre internet';
    } else {
      return '❌ Une erreur est survenue. Réessayez';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    'Nouveau mot de passe',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez un nouveau mot de passe sécurisé',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Message de succès
                  if (_successMessage != null)
                    SuccessMessageCard(
                      message: _successMessage!,
                    ),

                  if (_successMessage != null) const SizedBox(height: 16),

                  // Message d'erreur
                  if (_errorMessage != null)
                    ErrorMessageCard(
                      message: _errorMessage!,
                      onDismiss: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),

                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Formulaire
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nouveau mot de passe
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (value) {
                              setState(() {}); // Mettre à jour l'indicateur
                            },
                            decoration: InputDecoration(
                              labelText: 'Nouveau mot de passe',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un mot de passe';
                              }
                              if (value.length < 8) {
                                return 'Minimum 8 caractères';
                              }
                              // Vérifier la complexité du mot de passe
                              if (!value.contains(RegExp(r'[A-Z]'))) {
                                return 'Au moins une majuscule requise';
                              }
                              if (!value.contains(RegExp(r'[a-z]'))) {
                                return 'Au moins une minuscule requise';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return 'Au moins un chiffre requis';
                              }
                              return null;
                            },
                          ),
                          
                          // Indicateur de force du mot de passe
                          PasswordStrengthIndicator(
                            password: _passwordController.text,
                          ),
                          
                          const SizedBox(height: 16),

                          // Confirmer le mot de passe
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer le mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Bouton réinitialiser
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Réinitialiser',
                              onPressed: _resetPassword,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Après la réinitialisation, vous devrez vous reconnecter avec votre nouveau mot de passe',
                            style: TextStyle(
                              color: AppTheme.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
