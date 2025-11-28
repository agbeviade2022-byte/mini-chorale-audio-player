-- =====================================================
-- FIX : Ajouter foreign key chants → chorales
-- =====================================================

SELECT '🔧 AJOUT FOREIGN KEY' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier les données existantes
-- ============================================

SELECT '📋 ÉTAPE 1 : Vérification données' as etape;

-- Vérifier s'il y a des chants avec chorale_id invalide
SELECT 
    COUNT(*) as nombre_chants_invalides,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Toutes les chorales existent'
        ELSE '⚠️ Certains chants ont des chorale_id invalides'
    END as statut
FROM chants ch
LEFT JOIN chorales c ON ch.chorale_id = c.id
WHERE ch.chorale_id IS NOT NULL
AND c.id IS NULL;

-- Lister les chants avec chorale_id invalide
SELECT 
    ch.id,
    ch.titre,
    ch.chorale_id,
    '❌ Chorale inexistante' as probleme
FROM chants ch
LEFT JOIN chorales c ON ch.chorale_id = c.id
WHERE ch.chorale_id IS NOT NULL
AND c.id IS NULL;

-- ============================================
-- ÉTAPE 2 : Nettoyer les données invalides (optionnel)
-- ============================================

SELECT '📋 ÉTAPE 2 : Nettoyage (optionnel)' as etape;

-- Option 1: Mettre à NULL les chorale_id invalides
UPDATE chants
SET chorale_id = NULL
WHERE chorale_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM chorales WHERE id = chants.chorale_id
);

SELECT '✅ Données nettoyées' as status;

-- ============================================
-- ÉTAPE 3 : Ajouter la foreign key
-- ============================================

SELECT '📋 ÉTAPE 3 : Ajout foreign key' as etape;

-- Ajouter la contrainte de foreign key
ALTER TABLE chants
ADD CONSTRAINT fk_chants_chorale
FOREIGN KEY (chorale_id)
REFERENCES chorales(id)
ON DELETE SET NULL;

SELECT '✅ Foreign key ajoutée' as status;

-- ============================================
-- ÉTAPE 4 : Vérification
-- ============================================

SELECT '📋 ÉTAPE 4 : Vérification' as etape;

-- Vérifier que la foreign key existe
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name,
    '✅ Foreign key créée' as statut
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'chants'
AND tc.table_schema = 'public';

-- Compter les foreign keys
SELECT 
    COUNT(*) as nombre_foreign_keys,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Foreign key existe'
        ELSE '❌ Foreign key manquante'
    END as statut
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_name = 'chants'
AND table_schema = 'public';

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ FOREIGN KEY AJOUTÉE ✅✅✅' as resultat;
SELECT 'La jointure Supabase devrait maintenant fonctionner' as note;
SELECT 'Rafraîchissez le cache Supabase si nécessaire' as action;
