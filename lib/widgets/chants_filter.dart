import 'package:flutter/material.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/models/chant_sort_option.dart';

class ChantsFilter extends StatelessWidget {
  final ChantSortOption currentSort;
  final ValueChanged<ChantSortOption> onSortChanged;

  const ChantsFilter({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.darkGrey.withOpacity( 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Trier par',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          _buildSortOption(
            context,
            icon: Icons.favorite,
            title: 'Favoris uniquement',
            value: ChantSortOption.favoritesOnly,
            color: Colors.red,
          ),
          _buildSortOption(
            context,
            icon: Icons.sort_by_alpha,
            title: 'Titre (A-Z)',
            value: ChantSortOption.titleAsc,
          ),
          _buildSortOption(
            context,
            icon: Icons.sort_by_alpha,
            title: 'Titre (Z-A)',
            value: ChantSortOption.titleDesc,
          ),
          _buildSortOption(
            context,
            icon: Icons.calendar_today,
            title: 'Date (Plus récent)',
            value: ChantSortOption.dateDesc,
          ),
          _buildSortOption(
            context,
            icon: Icons.calendar_today,
            title: 'Date (Plus ancien)',
            value: ChantSortOption.dateAsc,
          ),
          _buildSortOption(
            context,
            icon: Icons.access_time,
            title: 'Durée (Croissant)',
            value: ChantSortOption.durationAsc,
          ),
          _buildSortOption(
            context,
            icon: Icons.access_time,
            title: 'Durée (Décroissant)',
            value: ChantSortOption.durationDesc,
          ),

          const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ChantSortOption value,
    Color? color,
  }) {
    final isSelected = currentSort == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (color ?? AppTheme.primaryBlue)
            : AppTheme.darkGrey.withOpacity( 0.5),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? (color ?? AppTheme.primaryBlue) : AppTheme.darkGrey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: color ?? AppTheme.primaryBlue)
          : null,
      onTap: () {
        onSortChanged(value);
        Navigator.pop(context);
      },
    );
  }
}
