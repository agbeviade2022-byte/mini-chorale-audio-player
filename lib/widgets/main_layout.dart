import 'package:flutter/material.dart';
import 'package:mini_chorale_audio_player/screens/player/mini_player.dart';

/// Layout principal qui affiche le MiniPlayer en bas de toutes les pages
class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Contenu principal
        Expanded(child: child),
        
        // Mini player en bas (se cache automatiquement quand le modal est ouvert)
        const MiniPlayer(),
      ],
    );
  }
}
