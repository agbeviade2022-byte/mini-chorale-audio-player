-- =====================================================
-- MIGRATION : Ajout du système de chants par pupitre
-- =====================================================
-- Exécutez ce script dans l'éditeur SQL de Supabase
-- =====================================================

-- 1. Ajouter la colonne 'type' à la table chants
-- =====================================================

ALTER TABLE chants 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'normal' CHECK (type IN ('normal', 'pupitre'));

-- Mettre à jour les chants existants pour qu'ils soient de type 'normal'
UPDATE chants SET type = 'normal' WHERE type IS NULL;

-- 2. Créer un index pour améliorer les performances
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_chants_type ON chants(type);
CREATE INDEX IF NOT EXISTS idx_chants_type_categorie ON chants(type, categorie);

-- 3. Vérification
-- =====================================================

-- Vérifier que la colonne a été ajoutée
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'chants' 
  AND column_name = 'type';

-- Vérifier les chants existants
SELECT type, COUNT(*) as count
FROM chants
GROUP BY type;

-- =====================================================
-- NOTES
-- =====================================================
-- Type 'normal' : Chants avec catégories classiques (Répétition, Messe, etc.)
-- Type 'pupitre' : Chants par pupitre (Ténor, Basse, Soprano, Alto)
--                  Le champ 'categorie' contiendra le nom du pupitre
-- =====================================================
