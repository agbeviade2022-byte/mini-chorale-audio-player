import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/widgets/error_message_card.dart';
import 'package:mini_chorale_audio_player/screens/auth/verify_otp_screen.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Envoyer un code OTP à 6 chiffres via le système custom (RPC generate_otp)
      final authService = ref.read(authServiceProvider);
      await authService.generateOtp(email: _emailController.text.trim());

      setState(() {
        _isLoading = false;
      });

      // Naviguer vers l'écran de vérification du code
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('email not found') || 
        errorString.contains('user not found')) {
      return '❌ Aucun compte associé à cet email';
    } else if (errorString.contains('too many requests')) {
      return '⏱️ Trop de tentatives. Réessayez plus tard';
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
                  // Bouton retour
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                    'Mot de passe oublié ?',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez votre email pour recevoir un code à 6 chiffres',
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
                      onDismiss: () {
                        setState(() {
                          _successMessage = null;
                        });
                      },
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
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              hintText: 'votre.email@example.com',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Bouton envoyer
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Envoyer le code',
                              onPressed: _sendOTP,
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
                            'Vous recevrez un code à 6 chiffres par email pour réinitialiser votre mot de passe',
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
