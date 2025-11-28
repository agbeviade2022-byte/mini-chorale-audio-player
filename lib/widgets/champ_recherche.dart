import 'package:flutter/material.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';

class ChampRecherche extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String hintText;
  final VoidCallback? onClear;

  const ChampRecherche({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Rechercher...',
    this.onClear,
  });

  @override
  State<ChampRecherche> createState() => _ChampRechercheState();
}

class _ChampRechercheState extends State<ChampRecherche> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? Theme.of(context).colorScheme.surface.withOpacity( 0.3)
        : AppTheme.lightGrey;
    final iconColor = isDark 
        ? Theme.of(context).colorScheme.onSurface.withOpacity( 0.7)
        : AppTheme.darkGrey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        enableInteractiveSelection: true,
        onTap: () {
          // Ne rien faire, laisser le comportement par défaut
        },
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.5),
          ),
          prefixIcon: Icon(Icons.search, color: iconColor),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: iconColor),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged('');
                    if (widget.onClear != null) widget.onClear!();
                    _focusNode.unfocus(); // Fermer le clavier après clear
                  },
                )
              : null,
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
