import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/providers/sync_provider.dart';
import 'package:mini_chorale_audio_player/screens/onboarding/onboarding_screen.dart';
import 'package:mini_chorale_audio_player/screens/home/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Attendre 2 secondes pour le splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 🏆 Essayer de restaurer la session depuis Hive
    final authService = ref.read(authServiceProvider);
    final hasSession = await authService.restoreSession();

    // 🔄 Si session valide, démarrer la synchronisation en temps réel
    if (hasSession) {
      try {
        await ref.read(syncStateProvider.notifier).startSync();
        print('✅ Synchronisation temps réel démarrée');
        
        // Vérifier la cohérence des données
        final isConsistent = await ref.read(syncStateProvider.notifier).checkConsistency();
        if (!isConsistent) {
          print('⚠️ Incohérence détectée, synchronisation...');
          await ref.read(syncStateProvider.notifier).syncAll();
        }
      } catch (e) {
        print('❌ Erreur lors du démarrage de la sync: $e');
        // Ne pas bloquer la navigation si la sync échoue
      }
    }

    if (!mounted) return;

    // Si session valide, aller directement à l'écran principal
    // Sinon, afficher l'onboarding
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            hasSession ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou icône
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity( 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 80,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                'Ma Chorale',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),

              // Indicateur de chargement
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
