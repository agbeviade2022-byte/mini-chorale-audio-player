import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/widgets/error_message_card.dart';
import 'package:mini_chorale_audio_player/screens/auth/reset_password_screen.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lastAttemptTime;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      setState(() {
        _errorMessage = '❌ Veuillez entrer le code à 6 chiffres';
      });
      return;
    }

    // Protection contre les attaques par force brute
    if (_failedAttempts >= 5) {
      setState(() {
        _errorMessage = '🚫 Trop de tentatives échouées. Demandez un nouveau code';
      });
      return;
    }

    // Délai entre les tentatives (après 3 échecs)
    if (_failedAttempts >= 3 && _lastAttemptTime != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastAttemptTime!);
      if (timeSinceLastAttempt.inSeconds < 5) {
        setState(() {
          _errorMessage = '⏱️ Attendez ${5 - timeSinceLastAttempt.inSeconds} secondes avant de réessayer';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utiliser le système OTP custom via EnhancedAuthService
      final authService = ref.read(authServiceProvider);
      final result = await authService.verifyOtp(
        email: widget.email,
        code: _otpCode,
      );

      // Si la vérification réussit, la RPC renvoie success = true
      final success = result['success'] == true;

      if (success) {
        // Réinitialiser les tentatives échouées
        _failedAttempts = 0;

        setState(() {
          _isLoading = false;
        });

        // Naviguer vers l'écran de réinitialisation du mot de passe
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            ),
          );
        }
      } else {
        // Incrémenter les tentatives échouées
        _failedAttempts++;
        _lastAttemptTime = DateTime.now();

        final message = result['message'] as String? ?? 'Code invalide ou expiré';

        setState(() {
          _errorMessage = '❌ $message (${_failedAttempts}/5 tentatives)';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Incrémenter les tentatives échouées
      _failedAttempts++;
      _lastAttemptTime = DateTime.now();
      
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _failedAttempts = 0; // Réinitialiser les tentatives
    });

    try {
      // Renvoyer un OTP via le système custom (RPC generate_otp)
      final authService = ref.read(authServiceProvider);
      await authService.generateOtp(email: widget.email);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nouveau code envoyé !'),
            backgroundColor: Colors.green,
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

    if (errorString.contains('invalid') || errorString.contains('expired')) {
      return '❌ Code invalide ou expiré';
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
                      Icons.mail_lock,
                      size: 60,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    'Vérification',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez le code à 6 chiffres envoyé à',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),

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

                  // Champs OTP
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // 6 champs pour le code OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 45,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue, // Couleur visible
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Bouton vérifier
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Vérifier',
                            onPressed: _verifyOtp,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Renvoyer le code
                        TextButton(
                          onPressed: _isLoading ? null : _resendOtp,
                          child: const Text(
                            'Renvoyer le code',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
                            'Le code expire dans 10 minutes',
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
