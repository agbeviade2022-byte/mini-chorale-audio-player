import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/widgets/error_message_card.dart';
import 'package:mini_chorale_audio_player/screens/auth/verify_otp_screen.dart';

/// Alternative utilisant l'API REST directement pour forcer l'envoi d'OTP
class ForgotPasswordScreenAlternative extends ConsumerStatefulWidget {
  const ForgotPasswordScreenAlternative({super.key});

  @override
  ConsumerState<ForgotPasswordScreenAlternative> createState() => _ForgotPasswordScreenAlternativeState();
}

class _ForgotPasswordScreenAlternativeState extends ConsumerState<ForgotPasswordScreenAlternative> {
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
      // Méthode 1 : Utiliser l'API REST directement
      final response = await Supabase.instance.client.functions.invoke(
        'send-otp',
        body: {
          'email': _emailController.text.trim(),
          'type': 'recovery',
        },
      );

      // Méthode 2 : Utiliser signInWithOtp avec options spécifiques
      // await Supabase.instance.client.auth.signInWithOtp(
      //   email: _emailController.text.trim(),
      //   shouldCreateUser: false,
      // );

      setState(() {
        _isLoading = false;
      });

      // Naviguer vers l'écran de vérification OTP
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
      // Si la fonction Edge n'existe pas, utiliser la méthode standard
      try {
        await Supabase.instance.client.auth.signInWithOtp(
          email: _emailController.text.trim(),
          shouldCreateUser: false,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } catch (e2) {
        setState(() {
          _errorMessage = _getErrorMessage(e2);
          _isLoading = false;
        });
      }
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
    // ... même UI que forgot_password_screen.dart
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
                  // Même contenu que l'écran original
                  Text('Alternative avec API REST directe'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
