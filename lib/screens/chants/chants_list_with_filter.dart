import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/providers/favorites_provider.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/widgets/chants_filter.dart';
import 'package:mini_chorale_audio_player/models/chant_sort_option.dart';
import 'package:mini_chorale_audio_player/screens/chants/chants_list.dart';
import 'package:mini_chorale_audio_player/main.dart';

class ChantsListWithFilterScreen extends ConsumerStatefulWidget {
  final String? category;

  const ChantsListWithFilterScreen({
    super.key,
    this.category,
  });

  @override
  ConsumerState<ChantsListWithFilterScreen> createState() =>
      _ChantsListWithFilterScreenState();
}

class _ChantsListWithFilterScreenState
    extends ConsumerState<ChantsListWithFilterScreen> {
  ChantSortOption _currentSort = ChantSortOption.dateDesc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? 'Tous les chants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer',
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: _buildFilteredList(),
    );
  }

  Widget _buildFilteredList() {
    final chantsAsync = widget.category != null
        ? ref.watch(chantsByCategoryStreamProvider(widget.category!))
        : ref.watch(chantsNormalsStreamProvider);

    final favoritesAsync = ref.watch(favoritesStreamProvider);

    return chantsAsync.when(
      data: (chants) {
        if (chants.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off, size: 64, color: AppTheme.darkGrey),
                SizedBox(height: 16),
                Text('Aucun chant disponible'),
              ],
            ),
          );
        }

        // Appliquer le filtre
        List<Chant> filteredChants = List.from(chants);

        // Filtre favoris
        if (_currentSort == ChantSortOption.favoritesOnly) {
          final favorites = favoritesAsync.value ?? [];
          filteredChants =
              filteredChants.where((c) => favorites.contains(c.id)).toList();
        }

        // Tri
        switch (_currentSort) {
          case ChantSortOption.titleAsc:
            filteredChants.sort((a, b) => a.titre.compareTo(b.titre));
            break;
          case ChantSortOption.titleDesc:
            filteredChants.sort((a, b) => b.titre.compareTo(a.titre));
            break;
          case ChantSortOption.dateAsc:
            filteredChants.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case ChantSortOption.dateDesc:
            filteredChants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case ChantSortOption.durationAsc:
            filteredChants.sort((a, b) => a.duree.compareTo(b.duree));
            break;
          case ChantSortOption.durationDesc:
            filteredChants.sort((a, b) => b.duree.compareTo(a.duree));
            break;
          case ChantSortOption.favoritesOnly:
            // Déjà filtré ci-dessus
            break;
        }

        if (filteredChants.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: AppTheme.darkGrey),
                SizedBox(height: 16),
                Text('Aucun favori'),
              ],
            ),
          );
        }

        return ChantsListScreen(category: widget.category);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }
}
