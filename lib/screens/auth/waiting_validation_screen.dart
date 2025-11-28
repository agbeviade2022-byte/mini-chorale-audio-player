import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/screens/auth/login.dart';

class WaitingValidationScreen extends ConsumerWidget {
  const WaitingValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  // Icône d'attente
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_empty,
                      size: 60,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    'Inscription réussie !',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Message principal
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Votre compte a été créé avec succès',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.white, thickness: 0.5),
                        const SizedBox(height: 24),
                        
                        // Message d'attente
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                size: 32,
                                color: AppTheme.gold,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'En attente de validation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Un administrateur doit valider votre compte et vous attribuer une chorale avant que vous puissiez accéder aux chants.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.white.withOpacity(0.9),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Informations supplémentaires
                        _buildInfoRow(
                          context,
                          Icons.email_outlined,
                          'Vérifiez vos emails',
                          'Confirmez votre adresse email si vous avez reçu un lien de confirmation.',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.timer_outlined,
                          'Délai de validation',
                          'La validation peut prendre de quelques heures à quelques jours.',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.notifications_active_outlined,
                          'Notification',
                          'Vous recevrez un email dès que votre compte sera validé.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Message de sécurité
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.lightBlueAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ce processus garantit la sécurité et l\'authenticité des membres de votre chorale.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.white.withOpacity(0.8),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.white.withOpacity(0.2),
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppTheme.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact support
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Ouvrir un formulaire de contact ou email
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contactez votre administrateur pour plus d\'informations'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline, color: AppTheme.gold),
                    label: Text(
                      'Besoin d\'aide ?',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.gold,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.white.withOpacity(0.8),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
