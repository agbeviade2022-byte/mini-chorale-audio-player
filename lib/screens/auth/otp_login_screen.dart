import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mini_chorale_audio_player/services/otp_auth_service.dart';

/// Écran de connexion par OTP (Email Magic Link)
/// Inspiré de Clerk, Notion, Slack
/// 
/// Flow:
/// 1. Utilisateur entre son email
/// 2. Système envoie un code OTP à 6 chiffres
/// 3. Utilisateur entre le code OTP
/// 4. Connexion automatique
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _otpService = OtpAuthService();
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  // Pour debug uniquement - À retirer en production
  String? _debugOtpCode;

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Étape 1: Envoyer l'OTP
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    // Validation
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
      });
      return;
    }

    if (!_otpService.isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Email invalide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _otpService.sendOtp(email);

      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
          _successMessage = result['message'];
          _debugOtpCode = result['code']; // Pour debug uniquement
          _resendCountdown = 120; // 2 minutes
        });

        // Démarrer le compte à rebours
        _startCountdown();

        // Focus sur le premier champ OTP
        _otpFocusNodes[0].requestFocus();
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

  /// Étape 2: Vérifier l'OTP
  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final code = _otpControllers.map((c) => c.text).join();

    // Validation
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer les 6 chiffres';
      });
      return;
    }

    if (!_otpService.isValidOtpCode(code)) {
      setState(() {
        _errorMessage = 'Code invalide (6 chiffres uniquement)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _otpService.verifyOtp(email, code);

      if (result['success'] == true) {
        // Connexion réussie
        setState(() {
          _successMessage = result['message'];
        });

        // Créer la session Supabase
        await _otpService.createSession(email);

        // Rediriger vers l'écran principal
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
          // Effacer les champs OTP
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _otpFocusNodes[0].requestFocus();
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

  /// Renvoyer l'OTP
  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    // Effacer les champs OTP
    for (var controller in _otpControllers) {
      controller.clear();
    }

    await _sendOtp();
  }

  /// Démarrer le compte à rebours
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Retour à l'écran email
  void _backToEmail() {
    setState(() {
      _otpSent = false;
      _errorMessage = null;
      _successMessage = null;
      _debugOtpCode = null;
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });
    _countdownTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Titre
                Text(
                  'Mini-Chorale',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Sous-titre
                Text(
                  _otpSent ? 'Entrez le code OTP' : 'Connexion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 48),

                // Carte principale
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _otpSent ? _buildOtpForm() : _buildEmailForm(),
                ),

                // Message d'aide
                if (!_otpSent) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Vous n\'avez pas de compte ?\nContactez votre chorale.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formulaire email
  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Champ email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'votre.email@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _sendOtp(),
        ),
        const SizedBox(height: 24),

        // Messages
        if (_errorMessage != null) ...[
          _buildErrorMessage(_errorMessage!),
          const SizedBox(height: 16),
        ],

        // Bouton continuer
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
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
                  'Continuer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  /// Formulaire OTP
  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bouton retour
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _backToEmail,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(height: 8),

        // Email
        Text(
          _emailController.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // Message succès
        if (_successMessage != null) ...[
          _buildSuccessMessage(_successMessage!),
          const SizedBox(height: 16),
        ],

        // Code OTP pour debug
        if (_debugOtpCode != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  '🔧 DEBUG MODE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code OTP: $_debugOtpCode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Champs OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 50,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Passer au champ suivant
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      // Dernier champ - vérifier automatiquement
                      _verifyOtp();
                    }
                  } else {
                    // Retour au champ précédent
                    if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Messages
        if (_errorMessage != null) ...[
          _buildErrorMessage(_errorMessage!),
          const SizedBox(height: 16),
        ],

        // Bouton vérifier
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
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
                  'Vérifier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 16),

        // Bouton renvoyer
        TextButton(
          onPressed: _resendCountdown > 0 ? null : _resendOtp,
          child: Text(
            _resendCountdown > 0
                ? 'Renvoyer le code (${_resendCountdown}s)'
                : 'Renvoyer le code',
          ),
        ),
      ],
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
}
