-- =====================================================
-- AJOUTER LA COLONNE 'actif' À LA TABLE CHORALES
-- =====================================================
-- Ce script ajoute la colonne 'actif' si elle n'existe pas
-- =====================================================

-- Vérifier et ajouter la colonne 'actif'
DO $$ 
BEGIN
    -- Vérifier si la colonne existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chorales' 
        AND column_name = 'actif'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne
        ALTER TABLE chorales 
        ADD COLUMN actif BOOLEAN DEFAULT true;
        
        RAISE NOTICE '✅ Colonne actif ajoutée à la table chorales';
    ELSE
        RAISE NOTICE '⚠️ La colonne actif existe déjà';
    END IF;
END $$;

-- Mettre à jour les chorales existantes (toutes actives par défaut)
UPDATE chorales 
SET actif = true 
WHERE actif IS NULL;

-- Vérifier le résultat
SELECT 
    '✅ VÉRIFICATION' as info,
    COUNT(*) as total_chorales,
    COUNT(*) FILTER (WHERE actif = true) as chorales_actives,
    COUNT(*) FILTER (WHERE actif = false) as chorales_inactives
FROM chorales;

-- Afficher quelques exemples
SELECT 
    '📋 EXEMPLES' as info,
    id,
    nom,
    actif,
    created_at
FROM chorales
ORDER BY created_at DESC
LIMIT 5;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Colonne actif ajoutée à la table chorales
--
-- ✅ VÉRIFICATION
-- total_chorales | chorales_actives | chorales_inactives
-- ---------------|------------------|-------------------
-- 5              | 5                | 0
--
-- 📋 EXEMPLES
-- id           | nom              | ville  | actif | created_at
-- -------------|------------------|--------|-------|------------
-- xxx-xxx-xxx  | Chorale Paris    | Paris  | true  | 2024-11-18
-- xxx-xxx-xxx  | Chorale Lyon     | Lyon   | true  | 2024-11-17
-- =====================================================
