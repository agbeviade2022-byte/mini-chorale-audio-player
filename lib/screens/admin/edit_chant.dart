import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/services/supabase_storage_service.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/models/category.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mini_chorale_audio_player/utils/snackbar_utils.dart';

class EditChantScreen extends ConsumerStatefulWidget {
  final Chant chant;

  const EditChantScreen({super.key, required this.chant});

  @override
  ConsumerState<EditChantScreen> createState() => _EditChantScreenState();
}

class _EditChantScreenState extends ConsumerState<EditChantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _auteurController;
  late TextEditingController _lyricsController;

  String? _selectedCategory;
  PlatformFile? _selectedAudioFile;
  PlatformFile? _selectedPartitionFile;
  bool _isUploading = false;
  final _storageService = SupabaseStorageService();

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.chant.titre);
    _auteurController = TextEditingController(text: widget.chant.auteur);
    _lyricsController = TextEditingController(text: widget.chant.lyrics ?? '');
    _selectedCategory = widget.chant.categorie;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _auteurController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (_storageService.isValidAudioFile(file)) {
          setState(() {
            _selectedAudioFile = file;
          });
        } else {
          if (mounted) {
            SnackBarUtils.showError(context, 'Fichier trop volumineux (max 50MB)');
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erreur lors de la sélection du fichier audio', details: e.toString());
      }
    }
  }

  Future<void> _pickPartitionFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedPartitionFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erreur lors de la sélection de la partition', details: e.toString());
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String audioUrl = widget.chant.urlAudio;
      String? partitionUrl = widget.chant.partitionUrl;

      // Upload nouveau fichier audio si sélectionné
      if (_selectedAudioFile != null) {
        final extension = _selectedAudioFile!.extension != null
            ? '.${_selectedAudioFile!.extension}'
            : '.mp3';

        audioUrl = await _storageService.uploadAudioFile(
          file: kIsWeb ? null : File(_selectedAudioFile!.path!),
          bytes: kIsWeb ? _selectedAudioFile!.bytes : null,
          fileName: _titreController.text.trim(),
          fileExtension: extension,
        );
      }

      // Upload nouvelle partition si sélectionnée
      if (_selectedPartitionFile != null) {
        final extension = _selectedPartitionFile!.extension != null
            ? '.${_selectedPartitionFile!.extension}'
            : '.jpg';

        partitionUrl = await _storageService.uploadAudioFile(
          file: kIsWeb ? null : File(_selectedPartitionFile!.path!),
          bytes: kIsWeb ? _selectedPartitionFile!.bytes : null,
          fileName: '${_titreController.text.trim()}_partition',
          fileExtension: extension,
        );
      }

      // Mettre à jour le chant
      await ref.read(chantsNotifierProvider.notifier).updateChant(
            id: widget.chant.id,
            titre: _titreController.text.trim(),
            categorie: _selectedCategory!,
            auteur: _auteurController.text.trim(),
            urlAudio: audioUrl,
            lyrics: _lyricsController.text.trim().isEmpty
                ? null
                : _lyricsController.text.trim(),
            partitionUrl: partitionUrl,
          );

      if (mounted) {
        SnackBarUtils.showChantUpdated(context, _titreController.text.trim());
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showChantUpdateError(context, e.toString());
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le chant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre du chant',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Auteur
              TextFormField(
                controller: _auteurController,
                decoration: const InputDecoration(
                  labelText: 'Auteur',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: Category.defaultCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Paroles
              TextFormField(
                controller: _lyricsController,
                decoration: const InputDecoration(
                  labelText: 'Paroles (optionnel)',
                  prefixIcon: Icon(Icons.lyrics),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // Changer le fichier audio
              Text(
                'Fichier audio',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: _selectedAudioFile == null
                    ? 'Changer le fichier audio'
                    : 'Nouveau: ${_selectedAudioFile!.name}',
                onPressed: () => _pickAudioFile(),
                icon: Icons.audio_file,
                isOutlined: true,
              ),
              const SizedBox(height: 24),

              // Partition
              Text(
                'Partition',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: _selectedPartitionFile == null
                    ? (widget.chant.partitionUrl != null
                        ? 'Changer la partition'
                        : 'Ajouter une partition')
                    : 'Nouveau: ${_selectedPartitionFile!.name}',
                onPressed: () => _pickPartitionFile(),
                icon: Icons.music_note,
                isOutlined: true,
              ),
              const SizedBox(height: 32),

              // Bouton soumettre
              CustomButton(
                text: _isUploading ? 'Modification en cours...' : 'Enregistrer',
                onPressed: _isUploading ? null : () => _submitForm(),
                icon: Icons.save,
                backgroundColor: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
