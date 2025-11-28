-- =====================================================
-- ACTIVATION REALTIME POUR LA TABLE CHANTS
-- =====================================================
-- Exécutez ce script dans l'éditeur SQL de Supabase
-- =====================================================

-- 1. Ajouter les colonnes manquantes si elles n'existent pas
-- =====================================================

-- Colonne type (normal ou pupitre)
ALTER TABLE chants 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'normal' CHECK (type IN ('normal', 'pupitre'));

-- Colonne lyrics (paroles du chant)
ALTER TABLE chants 
ADD COLUMN IF NOT EXISTS lyrics TEXT;

-- Colonne partition_url (URL de la partition)
ALTER TABLE chants 
ADD COLUMN IF NOT EXISTS partition_url TEXT;

-- 2. Activer REALTIME sur la table chants
-- =====================================================

-- Activer la publication Realtime pour la table chants
ALTER PUBLICATION supabase_realtime ADD TABLE chants;

-- Alternative si la publication n'existe pas encore :
-- CREATE PUBLICATION supabase_realtime FOR TABLE chants;

-- 3. Vérifier que RLS est activé
-- =====================================================

-- RLS devrait déjà être activé, mais on vérifie
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;

-- 4. Créer des index pour améliorer les performances
-- =====================================================

-- Index sur le type pour filtrer rapidement
CREATE INDEX IF NOT EXISTS idx_chants_type ON chants(type);

-- Index composite pour les chants par pupitre
CREATE INDEX IF NOT EXISTS idx_chants_type_categorie ON chants(type, categorie);

-- 5. VÉRIFICATION
-- =====================================================

-- Vérifier la structure de la table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'chants'
ORDER BY ordinal_position;

-- Vérifier que Realtime est activé
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'chants';

-- =====================================================
-- NOTES IMPORTANTES
-- =====================================================

-- Si vous voyez une erreur "publication supabase_realtime does not exist",
-- cela signifie que Realtime n'est pas encore configuré dans votre projet.
-- 
-- Dans ce cas, allez dans le Dashboard Supabase :
-- 1. Database > Replication
-- 2. Activez Realtime pour la table "chants"
-- 
-- Ou créez manuellement la publication :
-- CREATE PUBLICATION supabase_realtime;
-- ALTER PUBLICATION supabase_realtime ADD TABLE chants;

-- =====================================================
-- REDÉMARRAGE DU CLIENT (si nécessaire)
-- =====================================================

-- Après avoir exécuté ce script, vous devrez peut-être :
-- 1. Redémarrer votre application Flutter
-- 2. Ou attendre quelques secondes pour que Supabase propage les changements
