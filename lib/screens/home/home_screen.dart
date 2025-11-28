import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/providers/role_provider.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/widgets/champ_recherche.dart';
import 'package:mini_chorale_audio_player/widgets/role_badge.dart';
import 'package:mini_chorale_audio_player/screens/chants/chants_list.dart';
import 'package:mini_chorale_audio_player/screens/chants/chants_pupitre_list.dart';
import 'package:mini_chorale_audio_player/screens/chants/chant_details.dart';
import 'package:mini_chorale_audio_player/widgets/chants_filter.dart';
import 'package:mini_chorale_audio_player/models/chant_sort_option.dart';
import 'package:mini_chorale_audio_player/screens/admin/add_chant.dart';
import 'package:mini_chorale_audio_player/screens/admin/add_chant_pupitre.dart';
import 'package:mini_chorale_audio_player/screens/admin/edit_chant.dart';
import 'package:mini_chorale_audio_player/screens/admin/chorales_management_screen_v2.dart';
import 'package:mini_chorale_audio_player/screens/admin/members_validation_screen.dart';
import 'package:mini_chorale_audio_player/screens/admin/users_management_screen.dart';
import 'package:mini_chorale_audio_player/providers/favorites_provider.dart';
import 'package:mini_chorale_audio_player/providers/theme_provider.dart';
import 'package:mini_chorale_audio_player/providers/listening_history_provider.dart';
import 'package:mini_chorale_audio_player/providers/download_provider.dart';
import 'package:mini_chorale_audio_player/providers/connectivity_provider.dart';
import 'package:mini_chorale_audio_player/providers/storage_providers.dart';
import 'package:mini_chorale_audio_player/main.dart';
import 'package:mini_chorale_audio_player/models/downloaded_chant.dart';
import 'package:mini_chorale_audio_player/utils/snackbar_utils.dart';
import 'package:mini_chorale_audio_player/widgets/permission_guard_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/permissions_provider_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isFabOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _debounce;
  ChantSortOption _currentSort = ChantSortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 🔥 FORCER LE RECHARGEMENT DES DONNÉES AU DÉMARRAGE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan, forcer la mise à jour complète
      print('🔄 App resumée - Rechargement des données...');
      _refreshAllData();
    }
  }
  
  /// 🔄 FORCER LE RECHARGEMENT DE TOUTES LES DONNÉES
  void _refreshAllData() {
    print('🔄 Rechargement forcé de toutes les données...');
    
    // Invalider tous les providers pour forcer le rechargement
    ref.invalidate(chantsNormalsStreamProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(favoritesNotifierProvider);
    ref.invalidate(connectivityStreamProvider);
    
    print('✅ Providers invalidés - Rechargement en cours...');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabOpen) {
      setState(() {
        _isFabOpen = false;
        _animationController.reverse();
      });
    }
  }

  void _showFilterSheet() {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    showModalBottomSheet(
      context: navContext,
      backgroundColor: Colors.transparent,
      builder: (context) => ChantsFilter(
        currentSort: _currentSort,
        onSortChanged: (sort) {
          setState(() {
            _currentSort = sort;
          });
        },
      ),
    );
  }

  List<Chant> _applySortAndFilter(List<Chant> chants) {
    List<Chant> filtered = List.from(chants);

    // Filtre favoris
    if (_currentSort == ChantSortOption.favoritesOnly) {
      final favoritesAsync = ref.watch(favoritesNotifierProvider);
      final favorites = favoritesAsync.value ?? [];
      filtered = filtered.where((c) => favorites.contains(c.id)).toList();
    }

    // Tri
    switch (_currentSort) {
      case ChantSortOption.titleAsc:
        filtered.sort((a, b) => a.titre.compareTo(b.titre));
        break;
      case ChantSortOption.titleDesc:
        filtered.sort((a, b) => b.titre.compareTo(a.titre));
        break;
      case ChantSortOption.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ChantSortOption.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ChantSortOption.durationAsc:
        filtered.sort((a, b) => a.duree.compareTo(b.duree));
        break;
      case ChantSortOption.durationDesc:
        filtered.sort((a, b) => b.duree.compareTo(a.duree));
        break;
      case ChantSortOption.favoritesOnly:
        // Déjà filtré
        break;
    }

    return filtered;
  }

  IconData _getSortIcon() {
    switch (_currentSort) {
      case ChantSortOption.titleAsc:
      case ChantSortOption.titleDesc:
        return Icons.sort_by_alpha;
      case ChantSortOption.dateAsc:
      case ChantSortOption.dateDesc:
        return Icons.calendar_today;
      case ChantSortOption.durationAsc:
      case ChantSortOption.durationDesc:
        return Icons.access_time;
      case ChantSortOption.favoritesOnly:
        return Icons.favorite;
    }
  }

  String _getSortLabel() {
    switch (_currentSort) {
      case ChantSortOption.titleAsc:
        return 'Tri: Titre (A-Z)';
      case ChantSortOption.titleDesc:
        return 'Tri: Titre (Z-A)';
      case ChantSortOption.dateAsc:
        return 'Tri: Plus ancien';
      case ChantSortOption.dateDesc:
        return 'Tri: Plus récent';
      case ChantSortOption.durationAsc:
        return 'Tri: Durée croissante';
      case ChantSortOption.durationDesc:
        return 'Tri: Durée décroissante';
      case ChantSortOption.favoritesOnly:
        return 'Filtre: Favoris uniquement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      drawer: _buildDrawer(context, userProfile),
      body: CustomScrollView(
          slivers: [
          // Header avec nom utilisateur - Se collapse au scroll et reste fixe
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true, // Reste fixe en haut après scroll
            stretch: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onPrimary),
                tooltip: 'Déconnexion',
                onPressed: () async {
                  // Demander confirmation
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );
                  
                  // Si confirmé, déconnecter
                  if (confirm == true && context.mounted) {
                    print('🚪 Déconnexion en cours...');
                    
                    try {
                      // 0. Arrêter le lecteur audio et nettoyer l'état
                      try {
                        await ref.read(audioPlayerNotifierProvider.notifier).stop();
                        ref.invalidate(audioPlayerNotifierProvider);
                        ref.invalidate(currentChantProvider);
                        ref.invalidate(playlistProvider);
                        print('✅ Lecteur audio arrêté et état nettoyé');
                      } catch (e) {
                        print('⚠️ Erreur arrêt lecteur: $e');
                      }
                      
                      // 1. Effacer TOUTES les données Drift (base de données locale)
                      final driftService = ref.read(driftChantsServiceProvider);
                      await driftService.clearAllData();
                      print('✅ Base de données Drift effacée');
                      
                      // 2. Invalider tous les providers pour nettoyer le cache mémoire
                      ref.invalidate(chantsNormalsStreamProvider);
                      ref.invalidate(categoriesProvider);
                      ref.invalidate(userProfileProvider);
                      ref.invalidate(favoritesNotifierProvider);
                      ref.invalidate(connectivityStreamProvider);
                      print('✅ Providers invalidés');
                      
                      // 3. Déconnecter l'utilisateur
                      await ref.read(authNotifierProvider.notifier).signOut();
                      print('✅ Utilisateur déconnecté');
                      
                      print('✅✅✅ Déconnexion complète réussie');
                      
                      // 4. Rediriger vers la page de connexion
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    } catch (e) {
                      print('❌ Erreur lors de la déconnexion: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur de déconnexion: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calculer le pourcentage de collapse (0.0 = étendu, 1.0 = collapsé)
                final expandRatio = (constraints.maxHeight - kToolbarHeight) / 
                                   (200 - kToolbarHeight);
                
                return FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Opacity(
                    opacity: expandRatio < 0.5 ? 1.0 : 0.0, // Visible seulement quand collapsé
                    child: userProfile.when(
                      data: (user) => Text(
                        'Ma Chorale',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        userProfile.when(
                          data: (user) => Text(
                            'Bonjour, ${user?.fullName ?? "Utilisateur"}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          loading: () => const CircularProgressIndicator(color: Colors.white),
                          error: (_, __) => const Text('Erreur', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explorez votre bibliothèque musicale',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ChampRecherche(
                controller: _searchController,
                onChanged: _onSearchChanged, // Debounce appliqué
                hintText: 'Rechercher un chant...',
              ),
            ),
          ),

          // Bouton de tri/filtre
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(top: 8),
              child: Material(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          _getSortIcon(),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getSortLabel(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Catégories (sans texte "Catégories")
          SliverToBoxAdapter(
            child: categories.when(
              data: (cats) => Container(
                height: 60,
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryChip(cats[index]);
                  },
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(), // Masquer l'erreur, garder les données en cache
            ),
          ),

          // Section Récemment écouté
          _buildRecentlyListenedSection(),

          // Liste des chants - Intégrée dans le scroll principal
          _buildChantsList(),
        ],
      ),
      floatingActionButton: userProfile.when(
        data: (user) => user?.isAdmin == true
            ? _buildAnimatedFab()
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildAnimatedFab() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bouton ajouter chant par pupitre
            if (_animation.value > 0)
              ScaleTransition(
                scale: _animation,
                child: Opacity(
                  opacity: _animation.value,
                  child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      if (_isFabOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Chant par pupitre',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Bouton
                      FloatingActionButton(
                        heroTag: 'add_pupitre',
                        onPressed: () {
                          _closeFab();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddChantPupitreScreen(),
                            ),
                          );
                        },
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.mic),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bouton ajouter chant normal
            if (_animation.value > 0)
              ScaleTransition(
                scale: _animation,
                child: Opacity(
                  opacity: _animation.value,
                  child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      if (_isFabOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Chant normal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Bouton
                      FloatingActionButton(
                        heroTag: 'add_normal',
                        onPressed: () {
                          _closeFab();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddChantScreen(),
                            ),
                          );
                        },
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bouton principal
            FloatingActionButton(
              heroTag: 'main_fab',
              onPressed: _toggleFab,
              backgroundColor: _isFabOpen ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Theme.of(context).colorScheme.primary,
              child: AnimatedRotation(
                turns: _isFabOpen ? 0.125 : 0, // 45 degrés = 1/8 de tour
                duration: const Duration(milliseconds: 300),
                child: Icon(_isFabOpen ? Icons.close : Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChantsList() {
    // Utiliser le stream pour les mises à jour en temps réel
    final chantsAsync = _selectedCategory != null
        ? ref.watch(chantsByCategoryStreamProvider(_selectedCategory!))
        : _searchQuery.isNotEmpty
            ? ref.watch(searchChantsProvider(_searchQuery))
            : ref.watch(chantsNormalsStreamProvider);

    return chantsAsync.when(
      data: (chants) {
        // Appliquer le tri et le filtre
        final filteredChants = _applySortAndFilter(chants);
        
        // Vérifier si on a des données (possiblement depuis le cache)
        if (filteredChants.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentSort == ChantSortOption.favoritesOnly
                        ? Icons.favorite_border
                        : Icons.music_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentSort == ChantSortOption.favoritesOnly
                        ? 'Aucun favori'
                        : 'Aucun chant disponible',
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chant = filteredChants[index];
                return _buildChantCardSimple(context, chant, filteredChants);
              },
              childCount: filteredChants.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SliverToBoxAdapter(
        child: SizedBox.shrink(), // Masquer l'erreur, garder les données en cache
      ),
    );
  }

  Widget _buildChantCardSimple(BuildContext context, Chant chant, List<Chant> chants) {
    final currentChant = ref.watch(currentChantProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isCurrentChant = currentChant?.id == chant.id;
    
    // Vérifier si le chant est téléchargé
    final isDownloadedAsync = ref.watch(isChantDownloadedProvider(chant.id));
    final isDownloaded = isDownloadedAsync.value ?? false;
    
    // Vérifier la connexion
    final hasConnectionAsync = ref.watch(connectivityStreamProvider);
    final hasConnection = hasConnectionAsync.value ?? true;
    
    // Le chant est disponible si téléchargé OU si connecté
    final isAvailable = isDownloaded || hasConnection;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.zero,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.4,
        child: Card(
          elevation: isCurrentChant ? 3 : 1,
          color: isAvailable ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              
              // Si pas disponible, afficher un dialog
              if (!isAvailable) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Hors connexion'),
                      ],
                    ),
                    content: const Text(
                      'Vous êtes hors connexion, ce titre n\'a pas été téléchargé.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }
              
              await ref
                  .read(audioPlayerNotifierProvider.notifier)
                  .playChant(chant, playlist: chants);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image/Icône
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: isCurrentChant
                      ? AppTheme.goldGradient
                      : AppTheme.primaryGradient,
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Info chant
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      chant.titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentChant
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chant.auteur,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '• ${_formatDuration(chant.duree)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Indicateur de téléchargement
              Consumer(
                builder: (context, ref, child) {
                  final isDownloadedAsync = ref.watch(isChantDownloadedProvider(chant.id));
                  return isDownloadedAsync.maybeWhen(
                    data: (isDownloaded) => isDownloaded
                        ? const Icon(
                            Icons.offline_pin,
                            size: 16,
                            color: Colors.green,
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Bouton favoris
              Consumer(
                builder: (context, ref, child) {
                  final favoritesNotifier = ref.watch(favoritesNotifierProvider);
                  final favorites = favoritesNotifier.value ?? [];
                  final isFav = favorites.contains(chant.id);
                  
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity( 0.6),
                      size: 24,
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      try {
                        ref
                            .read(favoritesNotifierProvider.notifier)
                            .toggleFavorite(chant.id);
                        
                        // Afficher un feedback
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav ? 'Chant retiré des favoris' : 'Chant ajouté aux favoris',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
              // Bouton menu (trois points)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _showChantOptions(context, chant, chants);
                },
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  void _showChantOptions(BuildContext context, Chant chant, List<Chant> chants) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;
    
    showModalBottomSheet(
      context: navContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final canManageAsync = ref.watch(canManageChantsProvider);
          final favoritesAsync = ref.watch(favoritesNotifierProvider);

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        chant.titre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chant.auteur,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Option Détails
                _buildMenuOption(
                  context,
                  icon: Icons.info_outline,
                  title: 'Détails',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChantDetailsScreen(chant: chant),
                      ),
                    );
                  },
                ),

                // Option Favoris
                Builder(
                  builder: (context) {
                    final favorites = favoritesAsync.value ?? [];
                    final isFav = favorites.contains(chant.id);
                    return _buildMenuOption(
                      context,
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      title: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                      color: isFav ? Colors.red : null,
                      onTap: () {
                        Navigator.pop(context);
                        try {
                          ref
                              .read(favoritesNotifierProvider.notifier)
                              .toggleFavorite(chant.id);
                          
                          // Afficher un feedback
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFav ? 'Chant retiré des favoris' : 'Chant ajouté aux favoris',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),

                // Option Téléchargement
                Builder(
                  builder: (context) {
                    final downloadState = ref.watch(downloadNotifierProvider);
                    final chantDownloadState = downloadState[chant.id];
                    final isDownloading = chantDownloadState?.status == DownloadStatus.downloading;
                    final isDownloaded = chantDownloadState?.status == DownloadStatus.downloaded;
                    
                    // Vérifier aussi via le provider async
                    final isDownloadedAsync = ref.watch(isChantDownloadedProvider(chant.id));
                    
                    return isDownloadedAsync.maybeWhen(
                      data: (downloaded) {
                        final actuallyDownloaded = isDownloaded || downloaded;
                        
                        if (isDownloading) {
                          return _buildMenuOption(
                            context,
                            icon: Icons.downloading,
                            title: 'Téléchargement... ${(chantDownloadState!.progress * 100).toInt()}%',
                            trailing: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: chantDownloadState.progress,
                                strokeWidth: 2,
                              ),
                            ),
                            onTap: null, // Désactiver pendant le téléchargement
                          );
                        }
                        
                        return _buildMenuOption(
                          context,
                          icon: actuallyDownloaded ? Icons.offline_pin : Icons.download,
                          title: actuallyDownloaded ? 'Supprimer le téléchargement' : 'Télécharger',
                          color: actuallyDownloaded ? Colors.green : null,
                          onTap: () async {
                            Navigator.pop(context);
                            HapticFeedback.mediumImpact();
                            
                            if (actuallyDownloaded) {
                              // Supprimer
                              await ref.read(downloadNotifierProvider.notifier).deleteDownload(chant.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Téléchargement supprimé'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              // Télécharger
                              ref.read(downloadNotifierProvider.notifier).downloadChant(chant);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Téléchargement démarré...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                      orElse: () => _buildMenuOption(
                        context,
                        icon: Icons.download,
                        title: 'Télécharger',
                        onTap: () async {
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                          ref.read(downloadNotifierProvider.notifier).downloadChant(chant);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Téléchargement démarré...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),

                // Options admin (super_admin et admin uniquement)
                canManageAsync.when(
                  data: (canManage) {
                    if (!canManage) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(height: 1),
                        _buildMenuOption(
                          context,
                          icon: Icons.edit_outlined,
                          title: 'Modifier',
                          onTap: () async {
                            Navigator.pop(context);
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditChantScreen(chant: chant),
                              ),
                            );
                          },
                        ),
                        _buildMenuOption(
                          context,
                          icon: Icons.delete_outline,
                          title: 'Supprimer',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete(context, chant);
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? color,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(color: color ?? Theme.of(context).colorScheme.onSurface),
      ),
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  void _confirmDelete(BuildContext context, Chant chant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le chant'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${chant.titre}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(chantsNotifierProvider.notifier)
                    .deleteChant(chant.id);
                if (context.mounted) {
                  SnackBarUtils.showChantDeleted(context, chant.titre);
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showChantDeleteError(context, e.toString());
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildRecentlyListenedSection() {
    // Ce provider retourne uniquement les chants normaux (pas les chants pupitre)
    // pour éviter de mélanger les playlists
    final recentChants = ref.watch(recentlyListenedChantsProvider);

    return recentChants.when(
      data: (chants) {
        if (chants.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Récemment écouté',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: chants.length,
                  itemBuilder: (context, index) {
                    return _buildRecentChantCard(chants[index], chants);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildRecentChantCard(Chant chant, List<Chant> chants) {
    final currentChant = ref.watch(currentChantProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isCurrentChant = currentChant?.id == chant.id;

    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: isCurrentChant ? 3 : 1,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            await ref
                .read(audioPlayerNotifierProvider.notifier)
                .playChant(chant, playlist: chants);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Icône
              Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: isCurrentChant
                      ? AppTheme.goldGradient
                      : AppTheme.primaryGradient,
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // Info chant
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        chant.titre,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCurrentChant
                                  ? Theme.of(context).colorScheme.secondary
                                  : null,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        chant.auteur,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AsyncValue<dynamic> userProfile) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header du drawer
          userProfile.when(
            data: (user) => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              accountName: Text(
                user?.fullName ?? 'Utilisateur',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Consumer(
                builder: (context, ref, child) {
                  final permissionsState = ref.watch(permissionsProvider);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          user?.email ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (permissionsState.role != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: permissionsState.isSuperAdmin
                                ? Colors.red
                                : permissionsState.isAdmin
                                    ? Colors.orange
                                    : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            permissionsState.role!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const RoleBadge(
                          showText: false,
                          showIcon: true,
                          fontSize: 14,
                        ),
                    ],
                  );
                },
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.fullName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            loading: () => const DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (_, __) => const DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Text('Erreur'),
            ),
          ),

          // Menu Accueil
          ListTile(
            leading: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Menu Chants par pupitre
          ListTile(
            leading: Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
            title: const Text('Chants par pupitre'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChantsPupitreListScreen(),
                ),
              );
              // Rafraîchir au retour
              ref.invalidate(chantsPupitreProvider);
            },
          ),

          const Divider(),

          // Section Admin avec nouveau système de permissions
          Consumer(
            builder: (context, ref, child) {
              final permissionsState = ref.watch(permissionsProvider);
              final canManageAsync = ref.watch(canManageChantsProvider);
              
              // Afficher la section admin si l'utilisateur a au moins une permission admin
              final showAdminSection = permissionsState.isAdmin || 
                  permissionsState.hasAnyPermission(['add_chants', 'view_members', 'manage_chorales']);
              
              if (!showAdminSection) return const SizedBox.shrink();
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Administration',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  
                  // Ajouter un chant (permission requise)
                  PermissionGuard(
                    permissionCode: 'add_chants',
                    child: ListTile(
                      leading: Icon(Icons.add,
                          color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Ajouter un chant'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddChantScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Ajouter chant par pupitre (permission requise)
                  PermissionGuard(
                    permissionCode: 'add_chants',
                    child: ListTile(
                      leading: Icon(Icons.mic,
                          color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Ajouter chant par pupitre'),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddChantPupitreScreen(),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(chantsPupitreProvider);
                        }
                      },
                    ),
                  ),
                  
                  // Gestion des Chorales (permission requise)
                  PermissionGuard(
                    permissionCode: 'manage_chorales',
                    child: ListTile(
                      leading: Icon(Icons.groups,
                          color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Gestion des Chorales'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChoralesManagementScreenV2(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Validation des Membres (permission requise)
                  PermissionGuard(
                    permissionCode: 'view_members',
                    child: ListTile(
                      leading: Icon(Icons.how_to_reg,
                          color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Validation des Membres'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MembersValidationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Gestion d'utilisateurs (Super Admin only)
                  SuperAdminGuard(
                    child: ListTile(
                      leading: const Icon(Icons.manage_accounts, color: Colors.red),
                      title: const Text('Gestion d\'utilisateurs'),
                      subtitle: const Text('Modifier rôles et chorales', style: TextStyle(fontSize: 12)),
                      tileColor: Colors.red.withOpacity(0.05),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UsersManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Créer Maître de Chœur (Super Admin only)
                  SuperAdminGuard(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                      title: const Text('Créer Maître de Chœur'),
                      tileColor: Colors.red.withOpacity(0.05),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité à implémenter'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const Divider(),
                ],
              );
            },
          ),

          // À propos
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('À propos'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Ma Chorale',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.music_note,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),

          const Divider(),

          // Toggle Mode Sombre
          ListTile(
            leading: Icon(
              ref.watch(isDarkModeProvider) 
                ? Icons.dark_mode 
                : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Thème'),
            subtitle: Text(
              ref.watch(themeModeProvider) == ThemeMode.system
                  ? 'Automatique'
                  : ref.watch(themeModeProvider) == ThemeMode.dark
                      ? 'Sombre'
                      : 'Clair',
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              _showThemeSelector(context);
            },
          ),

          // Déconnexion
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () async {
              Navigator.pop(context);
              
              // Demander confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
              
              // Si confirmé, déconnecter
              if (confirm == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final currentThemeMode = ref.read(themeModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Clair'),
              subtitle: const Text('Toujours en mode clair'),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sombre'),
              subtitle: const Text('Toujours en mode sombre'),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Automatique'),
              subtitle: const Text('Suit les paramètres système'),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
