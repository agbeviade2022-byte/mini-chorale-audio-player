-- =====================================================
-- MIGRATION: RATTACHER CHAQUE CHANT À UNE CHORALE
-- =====================================================

-- =====================================================
-- 1. AJOUTER LA COLONNE chorale_id À LA TABLE chants
-- =====================================================

-- Vérifier si la colonne existe déjà
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chants' AND column_name = 'chorale_id'
  ) THEN
    -- Ajouter la colonne chorale_id
    ALTER TABLE chants 
    ADD COLUMN chorale_id UUID REFERENCES chorales(id) ON DELETE CASCADE;
    
    RAISE NOTICE '✅ Colonne chorale_id ajoutée à la table chants';
  ELSE
    RAISE NOTICE '⚠️ La colonne chorale_id existe déjà';
  END IF;
END $$;

-- =====================================================
-- 2. ASSIGNER LES CHANTS EXISTANTS À UNE CHORALE PAR DÉFAUT
-- =====================================================

-- Option A: Assigner tous les chants à la première chorale
DO $$
DECLARE
  v_first_chorale_id UUID;
  v_chants_count INTEGER;
BEGIN
  -- Récupérer l'ID de la première chorale
  SELECT id INTO v_first_chorale_id
  FROM chorales
  ORDER BY created_at
  LIMIT 1;
  
  IF v_first_chorale_id IS NOT NULL THEN
    -- Compter les chants sans chorale
    SELECT COUNT(*) INTO v_chants_count
    FROM chants
    WHERE chorale_id IS NULL;
    
    IF v_chants_count > 0 THEN
      -- Assigner tous les chants sans chorale à la première chorale
      UPDATE chants
      SET chorale_id = v_first_chorale_id
      WHERE chorale_id IS NULL;
      
      RAISE NOTICE '✅ % chant(s) assigné(s) à la chorale par défaut', v_chants_count;
    ELSE
      RAISE NOTICE '✅ Tous les chants ont déjà une chorale assignée';
    END IF;
  ELSE
    RAISE NOTICE '⚠️ Aucune chorale trouvée. Créez une chorale d''abord.';
  END IF;
END $$;

-- =====================================================
-- 3. RENDRE LA COLONNE chorale_id OBLIGATOIRE (OPTIONNEL)
-- =====================================================

-- Décommenter cette section si vous voulez rendre chorale_id obligatoire
/*
ALTER TABLE chants 
ALTER COLUMN chorale_id SET NOT NULL;

RAISE NOTICE '✅ La colonne chorale_id est maintenant obligatoire';
*/

-- =====================================================
-- 4. METTRE À JOUR LES RLS POLICIES
-- =====================================================

-- Supprimer l'ancienne policy
DROP POLICY IF EXISTS "chants_read_validated_users_only" ON chants;

-- Créer une nouvelle policy qui vérifie:
-- 1. L'utilisateur est validé
-- 2. L'utilisateur appartient à la même chorale que le chant
CREATE POLICY "chants_read_by_chorale_and_validated"
ON chants
FOR SELECT
TO authenticated
USING (
  -- L'utilisateur doit être validé
  is_user_validated()
  AND
  -- L'utilisateur doit appartenir à la même chorale que le chant
  chorale_id = (
    SELECT chorale_id 
    FROM profiles 
    WHERE id = auth.uid()
  )
);

COMMENT ON POLICY "chants_read_by_chorale_and_validated" ON chants IS 
'Les utilisateurs validés peuvent voir uniquement les chants de leur chorale';

-- =====================================================
-- 5. POLICY POUR LES ADMINS (VOIR TOUS LES CHANTS)
-- =====================================================

-- Les admins et super_admins peuvent voir tous les chants
CREATE POLICY "chants_read_by_admins"
ON chants
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
  )
);

COMMENT ON POLICY "chants_read_by_admins" ON chants IS 
'Les admins peuvent voir tous les chants de toutes les chorales';

-- =====================================================
-- 6. POLICY POUR L'INSERTION (ADMINS SEULEMENT)
-- =====================================================

-- Supprimer l'ancienne policy si elle existe
DROP POLICY IF EXISTS "chants_insert_by_admins" ON chants;

-- Créer la policy pour l'insertion
CREATE POLICY "chants_insert_by_admins"
ON chants
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
  )
);

COMMENT ON POLICY "chants_insert_by_admins" ON chants IS 
'Seuls les admins peuvent ajouter des chants';

-- =====================================================
-- 7. POLICY POUR LA MODIFICATION (ADMINS SEULEMENT)
-- =====================================================

DROP POLICY IF EXISTS "chants_update_by_admins" ON chants;

CREATE POLICY "chants_update_by_admins"
ON chants
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
  )
);

-- =====================================================
-- 8. POLICY POUR LA SUPPRESSION (ADMINS SEULEMENT)
-- =====================================================

DROP POLICY IF EXISTS "chants_delete_by_admins" ON chants;

CREATE POLICY "chants_delete_by_admins"
ON chants
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
  )
);

-- =====================================================
-- 9. CRÉER UN INDEX POUR OPTIMISER LES REQUÊTES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_chants_chorale_id ON chants(chorale_id);

-- Index créé (le message sera affiché dans la section suivante)

-- =====================================================
-- 10. VÉRIFICATION FINALE
-- =====================================================

-- Afficher les statistiques
DO $$
DECLARE
  v_total_chants INTEGER;
  v_chants_avec_chorale INTEGER;
  v_chants_sans_chorale INTEGER;
  v_total_chorales INTEGER;
BEGIN
  -- Compter les chants
  SELECT COUNT(*) INTO v_total_chants FROM chants;
  SELECT COUNT(*) INTO v_chants_avec_chorale FROM chants WHERE chorale_id IS NOT NULL;
  SELECT COUNT(*) INTO v_chants_sans_chorale FROM chants WHERE chorale_id IS NULL;
  SELECT COUNT(*) INTO v_total_chorales FROM chorales;
  
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ MIGRATION TERMINÉE';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '📊 STATISTIQUES:';
  RAISE NOTICE '  - Total chorales: %', v_total_chorales;
  RAISE NOTICE '  - Total chants: %', v_total_chants;
  RAISE NOTICE '  - Chants avec chorale: %', v_chants_avec_chorale;
  RAISE NOTICE '  - Chants sans chorale: %', v_chants_sans_chorale;
  RAISE NOTICE '';
  RAISE NOTICE '🔒 POLICIES CRÉÉES:';
  RAISE NOTICE '  ✅ chants_read_by_chorale_and_validated';
  RAISE NOTICE '  ✅ chants_read_by_admins';
  RAISE NOTICE '  ✅ chants_insert_by_admins';
  RAISE NOTICE '  ✅ chants_update_by_admins';
  RAISE NOTICE '  ✅ chants_delete_by_admins';
  RAISE NOTICE '';
  RAISE NOTICE '📋 RÈGLES:';
  RAISE NOTICE '  - Les membres voient uniquement les chants de leur chorale';
  RAISE NOTICE '  - Les admins voient tous les chants';
  RAISE NOTICE '  - Seuls les admins peuvent ajouter/modifier/supprimer';
  RAISE NOTICE '==============================================';
END $$;

-- Afficher la répartition des chants par chorale
SELECT 
  c.nom as chorale,
  COUNT(ch.id) as nombre_chants
FROM chorales c
LEFT JOIN chants ch ON c.id = ch.chorale_id
GROUP BY c.id, c.nom
ORDER BY nombre_chants DESC;
