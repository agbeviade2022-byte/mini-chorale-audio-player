import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/widgets/error_message_card.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/screens/home/home_screen.dart';
import 'package:mini_chorale_audio_player/screens/auth/register.dart';
import 'package:mini_chorale_audio_player/screens/auth/waiting_validation_screen.dart';
import 'package:mini_chorale_audio_player/screens/auth/forgot_password_screen.dart';
import 'package:mini_chorale_audio_player/exceptions/auth_exceptions.dart';
import 'package:mini_chorale_audio_player/screens/auth/otp_verification_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Email pré-rempli (optionnel) - si fourni, le champ email sera grisé
  final String? prefilledEmail;
  
  const LoginScreen({super.key, this.prefilledEmail});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage; // message générique (peu utilisé désormais)
  String? _emailError;   // message d'erreur spécifique au champ email
  String? _passwordError; // message d'erreur spécifique au champ mot de passe
  bool _emailChecked = false;
  bool _emailValidated = false;
  
  /// Indique si l'email est verrouillé (pré-rempli par un admin OU validé)
  bool get _isEmailLocked => 
      (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) || 
      _emailValidated;

  @override
  void initState() {
    super.initState();
    // Si un email est pré-rempli, le définir et valider automatiquement
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
      // Valider l'email automatiquement après le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkEmailAndShowPassword();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailAndShowPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _emailError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final status = await authService.checkEmailStatus(
        _emailController.text.trim(),
      );

      if (status['exists'] != true) {
        setState(() {
          _emailChecked = true;
          _emailValidated = false;
          _emailError = 'Ce mail est inconnu';
        });
      } else if (status['is_validated'] != true) {
        setState(() {
          _emailChecked = true;
          _emailValidated = false;
          _emailError =
              "Ce mail n'est pas confirmé par l'administrateur";
        });
      } else {
        setState(() {
          _emailChecked = true;
          _emailValidated = true;
          _emailError = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _emailError = _errorMessage;
      });
      _formKey.currentState?.validate();
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid_credentials') || 
        errorString.contains('invalid login credentials')) {
      return '❌ Email ou mot de passe incorrect';
    } else if (errorString.contains('email not confirmed')) {
      return '📧 Veuillez confirmer votre email';
    } else if (errorString.contains('too many requests')) {
      return '⏱️ Trop de tentatives. Réessayez plus tard';
    } else if (errorString.contains('network')) {
      return '🌐 Erreur de connexion. Vérifiez votre internet';
    } else if (error is UserNotValidatedException) {
      return '⏳ Votre compte est en attente de validation';
    } else if (error is UserRefusedException) {
      return '🚫 Votre compte a été refusé';
    } else {
      return '❌ Une erreur est survenue. Réessayez';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // On ne permet la connexion que si l'email a été vérifié et validé
    if (!_emailValidated) {
      await _checkEmailAndShowPassword();
      return;
    }

    // Réinitialiser le message d'erreur
    setState(() {
      _errorMessage = null;
      _emailError = null;
      _passwordError = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final authState = ref.read(authNotifierProvider);

      authState.when(
        data: (_) async {
          // Après une connexion réussie, démarrer le flux OTP natif Supabase (2ᵉ facteur)
          try {
            await Supabase.instance.client.auth.signInWithOtp(
              email: _emailController.text.trim(),
              shouldCreateUser: false,
            );

            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  email: _emailController.text.trim(),
                ),
              ),
            );
          } catch (e) {
            setState(() {
              _errorMessage = _getErrorMessage(e);
              _passwordError = _errorMessage;
            });
            _formKey.currentState?.validate();
          }
        },
        error: (error, _) {
          // Gérer les exceptions personnalisées
          if (error is UserNotValidatedException) {
            // Rediriger vers la page d'attente
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WaitingValidationScreen(),
              ),
            );
          } else {
            // Afficher le message d'erreur stylé
            setState(() {
              _errorMessage = _getErrorMessage(error);
              _passwordError = _errorMessage;
            });
            _formKey.currentState?.validate();
          }
        },
        loading: () {},
      );
    } catch (e) {
      // Gérer les exceptions levées directement
      if (e is UserNotValidatedException) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WaitingValidationScreen(),
          ),
        );
      } else {
        // Afficher le message d'erreur stylé
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _passwordError = _errorMessage;
        });
        _formKey.currentState?.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

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
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 60,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bienvenue dans votre chorale',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.white.withOpacity( 0.8),
                        ),
                  ),
                  const SizedBox(height: 48),

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
                            readOnly: _isEmailLocked, // Verrouillé si validé
                            style: _isEmailLocked 
                                ? TextStyle(color: Colors.grey[700])
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              suffixIcon: _isEmailLocked 
                                  ? IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                      tooltip: 'Modifier l\'email',
                                      onPressed: () {
                                        setState(() {
                                          _emailValidated = false;
                                          _emailChecked = false;
                                          _passwordController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              filled: _isEmailLocked,
                              fillColor: _isEmailLocked ? Colors.grey[100] : null,
                            ),
                            validator: (value) {
                              if (_emailError != null) {
                                final message = _emailError;
                                _emailError = null; // éviter la répétition
                                return message;
                              }
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_emailValidated) ...[
                            // Mot de passe (visible uniquement si email validé)
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
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
                                if (!_emailValidated) return null;
                                if (_passwordError != null) {
                                  final message = _passwordError;
                                  _passwordError = null; // consommer le message
                                  return message;
                                }
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Minimum 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Mot de passe oublié (uniquement si email validé)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Bouton principal : "Continuer" (check email) ou "Se connecter"
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: _emailValidated ? 'Se connecter' : 'Continuer',
                              onPressed:
                                  _emailValidated ? _login : _checkEmailAndShowPassword,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Inscription désactivée : les comptes sont créés uniquement par les admins/super admins.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
