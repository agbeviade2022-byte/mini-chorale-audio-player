-- =====================================================
-- SCRIPT DE CRÉATION DU BUCKET STORAGE
-- =====================================================
-- Copiez et exécutez ce script dans l'éditeur SQL de Supabase
-- Dashboard → SQL Editor → New Query
-- =====================================================

-- 1. Créer le bucket audio_files
-- =====================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio_files',
  'audio_files',
  true,
  52428800,  -- 50 MB en bytes
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a', 'audio/mp4', 'audio/aac', 'audio/flac', 'audio/x-m4a']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a', 'audio/mp4', 'audio/aac', 'audio/flac', 'audio/x-m4a'];

-- 2. Créer les politiques d'accès (RLS)
-- =====================================================

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Anyone can view audio files" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload audio files" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update audio files" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete audio files" ON storage.objects;

-- Permettre à tout le monde de voir/télécharger les fichiers audio
CREATE POLICY "Anyone can view audio files"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audio_files');

-- Permettre aux admins d'uploader des fichiers
CREATE POLICY "Admins can upload audio files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Permettre aux admins de mettre à jour des fichiers
CREATE POLICY "Admins can update audio files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Permettre aux admins de supprimer des fichiers
CREATE POLICY "Admins can delete audio files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 3. Vérification
-- =====================================================

-- Vérifier que le bucket a été créé
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE id = 'audio_files';

-- Vérifier les politiques
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE '%audio%';

-- =====================================================
-- SCRIPT TERMINÉ
-- =====================================================
-- Si tout s'est bien passé, vous devriez voir :
-- 1. Le bucket "audio_files" créé avec les bonnes options
-- 2. 4 politiques RLS créées pour le bucket
-- =====================================================
