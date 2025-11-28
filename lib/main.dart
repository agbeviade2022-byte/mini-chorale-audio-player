import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/theme_provider.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/providers/storage_providers.dart';
import 'package:mini_chorale_audio_player/screens/splash/splash_screen.dart';
import 'package:mini_chorale_audio_player/widgets/main_layout.dart';
import 'package:mini_chorale_audio_player/services/app_lifecycle_observer.dart';
import 'package:mini_chorale_audio_player/services/audio_handler.dart';
import 'package:mini_chorale_audio_player/services/simple_audio_handler.dart';
import 'package:mini_chorale_audio_player/services/notification_service.dart';
import 'package:mini_chorale_audio_player/services/hive_session_service.dart';
import 'package:mini_chorale_audio_player/services/encrypted_hive_service.dart';
import 'package:mini_chorale_audio_player/services/secure_storage_service.dart';
import 'package:mini_chorale_audio_player/widgets/download_listener.dart';

// GlobalKey pour accéder au Navigator depuis n'importe où
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ValueNotifier pour tracker si le full player modal est ouvert
final ValueNotifier<bool> isFullPlayerOpen = ValueNotifier<bool>(false);

// ValueNotifier pour tracker si un bottom sheet overlay est ouvert
final ValueNotifier<bool> isBottomSheetOpen = ValueNotifier<bool>(false);

void main() async {
  // Capturer les erreurs Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('❌ Flutter Error: ${details.exception}');
    print('📍 Stack: ${details.stack}');
  };

  // Exécuter l'app dans une zone protégée pour capturer les erreurs Dart
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 🔐 Initialisation du stockage sécurisé (Spotify-level security)
      late SecureStorageService secureStorage;
      late EncryptedHiveService encryptedHive;
      late HiveSessionService hiveSessionService; // Gardé pour compatibilité
      
      try {
        print('🔐 Initialisation du système de sécurité...');
        
        // 1. Initialiser le stockage sécurisé (Keychain/Keystore)
        secureStorage = SecureStorageService();
        print('✅ SecureStorageService initialisé');
        
        // 2. Initialiser Hive avec chiffrement AES-256
        encryptedHive = EncryptedHiveService();
        await encryptedHive.initialize();
        print('✅ EncryptedHiveService initialisé avec chiffrement AES-256');
        
        // 3. Migrer les anciennes données (une seule fois)
        await encryptedHive.migrateFromUnencryptedHive();
        print('✅ Migration des anciennes données terminée');
        
        // 4. Initialiser l'ancien service pour compatibilité
        hiveSessionService = HiveSessionService();
        await hiveSessionService.initialize();
        print('✅ HiveSessionService (legacy) initialisé');
        
        // Afficher les stats de sécurité
        final stats = encryptedHive.getStorageStats();
        print('📊 Stats stockage sécurisé: $stats');
        print('🔐 Système de sécurité niveau Spotify activé ✅');
      } catch (e) {
        print('❌ Erreur lors de l\'initialisation du stockage sécurisé: $e');
        print('⚠️ Fallback sur l\'ancien système Hive');
        
        // Fallback sur l'ancien système
        hiveSessionService = HiveSessionService();
        await hiveSessionService.initialize();
      }

      // Initialisation Supabase avec persistance de session
      try {
        await Supabase.initialize(
          url: 'https://milzcdtfblwhblstwuzh.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pbHpjZHRmYmx3aGJsc3R3dXpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxMTIwNjQsImV4cCI6MjA3ODY4ODA2NH0.HRYmU5hWySL51sD45d16bIRusknirhrdlYNoccxIEKc',
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.implicit, // ✅ CHANGÉ: implicit au lieu de pkce
            autoRefreshToken: true, // Rafraîchir automatiquement le token
          ),
          // La persistance locale est activée par défaut via SharedPreferences
          // Pas besoin de configuration supplémentaire
        );
        print('✅ Supabase initialisé avec persistance de session');
      } catch (e) {
        print('❌ Erreur lors de l\'initialisation de Supabase: $e');
      }

      // Initialiser SimpleAudioHandler (just_audio uniquement)
      // Pas de dépendance à AudioService pour éviter les problèmes de compatibilité
      late dynamic audioHandler;
      audioHandler = SimpleAudioHandler();
      print('✅ SimpleAudioHandler initialisé avec just_audio');

      // Initialiser les notifications
      try {
        await NotificationService().initialize();
        print('✅ Service de notifications initialisé');
      } catch (e) {
        print('❌ Erreur lors de l\'initialisation des notifications: $e');
      }

      runApp(
        ProviderScope(
          overrides: [
            audioHandlerProvider.overrideWithValue(audioHandler),
            hiveSessionServiceProvider.overrideWithValue(hiveSessionService),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      print('❌ Erreur non capturée: $error');
      print('📍 Stack: $stack');
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    print('✅ Lifecycle observer ajouté');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    print('✅ Lifecycle observer retiré');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ma Chorale',
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showPerformanceOverlay: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        // Envelopper toutes les pages avec le MainLayout pour afficher le MiniPlayer partout
        if (child == null) return const SizedBox.shrink();
        
        // Ne pas afficher le MiniPlayer sur le SplashScreen et OnboardingScreen
        final route = ModalRoute.of(context);
        final routeName = route?.settings.name;
        final isSplashOrOnboarding = child is SplashScreen || 
            routeName == '/splash' || 
            routeName == '/onboarding';
        
        if (isSplashOrOnboarding) {
          return child;
        }
        
        // Wrapper avec DownloadListener pour afficher les pop-ups de téléchargement
        return DownloadListener(
          child: MainLayout(child: child),
        );
      },
    );
  }
}
