import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/screens/chants/chant_details.dart';
import 'package:mini_chorale_audio_player/screens/admin/edit_chant.dart';
import 'package:mini_chorale_audio_player/providers/favorites_provider.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/providers/role_provider.dart';
import 'package:mini_chorale_audio_player/providers/download_provider.dart';
import 'package:mini_chorale_audio_player/providers/connectivity_provider.dart';
import 'package:mini_chorale_audio_player/widgets/chants_filter.dart';
import 'package:mini_chorale_audio_player/models/chant_sort_option.dart';
import 'package:mini_chorale_audio_player/main.dart';
import 'package:flutter/services.dart';
import 'package:mini_chorale_audio_player/utils/snackbar_utils.dart';

class ChantsListScreen extends ConsumerStatefulWidget {
  final String? searchQuery;
  final String? category;
  final bool showFilterButton;

  const ChantsListScreen({
    super.key,
    this.searchQuery,
    this.category,
    this.showFilterButton = false,
  });

  @override
  ConsumerState<ChantsListScreen> createState() => _ChantsListScreenState();
}

class _ChantsListScreenState extends ConsumerState<ChantsListScreen> with WidgetsBindingObserver {
  ChantSortOption _currentSort = ChantSortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(connectivityStreamProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      final favoritesAsync = ref.watch(favoritesStreamProvider);
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

  @override
  Widget build(BuildContext context) {
    // Utiliser le stream pour les mises à jour en temps réel
    final chantsAsync = widget.category != null
        ? ref.watch(chantsByCategoryStreamProvider(widget.category!))
        : widget.searchQuery != null && widget.searchQuery!.isNotEmpty
            ? ref.watch(searchChantsProvider(widget.searchQuery!))
            : ref.watch(chantsNormalsStreamProvider);

    return chantsAsync.when(
      data: (chants) {
        final filteredChants = _applySortAndFilter(chants);

        if (filteredChants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _currentSort == ChantSortOption.favoritesOnly
                      ? Icons.favorite_border
                      : Icons.music_off,
                  size: 64,
                  color: AppTheme.darkGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  _currentSort == ChantSortOption.favoritesOnly
                      ? 'Aucun favori'
                      : 'Aucun chant disponible',
                ),
                if (widget.showFilterButton) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Modifier les filtres'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            // Barre de filtre
            if (widget.showFilterButton)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.primaryBlue.withOpacity( 0.1),
                child: Row(
                  children: [
                    Icon(
                      _getSortIcon(),
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSortLabel(),
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_list, size: 20),
                      label: const Text('Changer'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredChants.length,
                itemBuilder: (context, index) {
                  return _buildChantCard(context, filteredChants[index], filteredChants);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(), // Masquer l'erreur, garder les données en cache
    );
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

  Widget _buildChantCard(BuildContext context, Chant chant, List<Chant> allChants) {
    return _ChantCard(chant: chant, allChants: allChants);
  }
}

class _ChantCard extends ConsumerWidget {
  final Chant chant;
  final List<Chant> allChants;

  const _ChantCard({
    required this.chant,
    required this.allChants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.4,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
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
            
            // Toujours jouer le chant (relancer depuis le début si c'est le même)
            await ref
                .read(audioPlayerNotifierProvider.notifier)
                .playChant(chant, playlist: allChants);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône ou animation
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isCurrentChant
                      ? AppTheme.goldGradient
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: AppTheme.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      chant.titre,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentChant
                                ? AppTheme.gold
                                : AppTheme.darkGrey,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chant.auteur,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            chant.categorie,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.darkGrey.withOpacity( 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chant.dureeFormatee,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicateur de téléchargement
              Consumer(
                builder: (context, ref, child) {
                  final isDownloadedAsync = ref.watch(isChantDownloadedProvider(chant.id));
                  return isDownloadedAsync.maybeWhen(
                    data: (isDownloaded) => isDownloaded
                        ? const Icon(
                            Icons.offline_pin,
                            size: 18,
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
                      color: isFav ? Colors.red : AppTheme.darkGrey.withOpacity( 0.6),
                      size: 28,
                    ),
                    onPressed: () async {
                      try {
                        // Mise à jour optimiste immédiate
                        ref
                            .read(favoritesNotifierProvider.notifier)
                            .toggleFavorite(chant.id);
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

              // Bouton menu (trois points horizontaux)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_horiz,
                  color: AppTheme.darkGrey.withOpacity( 0.6),
                ),
                onPressed: () {
                  _showChantOptions(context, ref, chant);
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _showChantOptions(BuildContext context, WidgetRef ref, Chant chant) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;
    
    showModalBottomSheet(
      context: navContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final isAdminAsync = ref.watch(isAdminProvider);
          final favoritesAsync = ref.watch(favoritesStreamProvider);

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.darkGrey.withOpacity( 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Titre du chant
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
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Options communes à tous
                _buildOption(
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

                if (chant.lyrics != null)
                  _buildOption(
                    context,
                    icon: Icons.lyrics_outlined,
                    title: 'Paroles',
                    onTap: () {
                      Navigator.pop(context);
                      _showLyrics(context, chant);
                    },
                  ),

                if (chant.partitionUrl != null)
                  _buildOption(
                    context,
                    icon: Icons.music_note_outlined,
                    title: 'Partition',
                    onTap: () {
                      Navigator.pop(context);
                      _showPartition(context, chant);
                    },
                  ),

                // Option Favoris
                Builder(
                  builder: (context) {
                    final favorites = favoritesAsync.value ?? [];
                    final isFav = favorites.contains(chant.id);
                    return _buildOption(
                      context,
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      title: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                      color: isFav ? Colors.red : null,
                      onTap: () {
                        Navigator.pop(context);
                        try {
                          // Mise à jour optimiste immédiate
                          ref
                              .read(favoritesNotifierProvider.notifier)
                              .toggleFavorite(chant.id);
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

                // Options admin uniquement (super_admin et admin)
                isAdminAsync.when(
                  data: (isAdmin) {
                    if (!isAdmin) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(height: 1),
                        _buildOption(
                          context,
                          icon: Icons.edit_outlined,
                          title: 'Modifier',
                          onTap: () async {
                            Navigator.pop(context);
                            final updated = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditChantScreen(chant: chant),
                              ),
                            );
                            // Pas besoin d'invalider, le StreamProvider se met à jour automatiquement
                            if (updated == true && context.mounted) {
                              // Le temps réel Supabase mettra à jour automatiquement
                            }
                          },
                        ),
                        _buildOption(
                          context,
                          icon: Icons.delete_outline,
                          title: 'Supprimer',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete(context, ref, chant);
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

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primaryBlue),
      title: Text(
        title,
        style: TextStyle(color: color ?? AppTheme.darkGrey),
      ),
      onTap: onTap,
    );
  }

  void _showLyrics(BuildContext context, Chant chant) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;
    
    showModalBottomSheet(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkGrey.withOpacity( 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Paroles - ${chant.titre}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    chant.lyrics ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartition(BuildContext context, Chant chant) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;
    
    showModalBottomSheet(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkGrey.withOpacity( 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Partition - ${chant.titre}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Center(
                    child: chant.partitionUrl != null
                        ? Image.network(
                            chant.partitionUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: AppTheme.darkGrey,
                                    ),
                                    SizedBox(height: 16),
                                    Text('Impossible de charger la partition'),
                                  ],
                                ),
                              );
                            },
                          )
                        : const Text('Aucune partition disponible'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Chant chant) {
    // Capturer le notifier AVANT d'ouvrir le dialog
    final notifier = ref.read(chantsNotifierProvider.notifier);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le chant'),
        content: Text('Voulez-vous vraiment supprimer "${chant.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Suppression optimiste immédiate
                await notifier.deleteChant(chant.id);
                
                if (context.mounted) {
                  SnackBarUtils.showChantDeleted(context, chant.titre);
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showChantDeleteError(context, e.toString());
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
