-- =====================================================
-- FIX : Ajouter la chorale dans la liste des utilisateurs
-- =====================================================

SELECT '🔧 FIX : Fonction get_all_users_with_emails_debug avec chorale' as info;

-- ============================================
-- ÉTAPE 1 : Supprimer l'ancienne fonction
-- ============================================

SELECT '📋 ÉTAPE 1 : Suppression de l''ancienne fonction' as etape;

DROP FUNCTION IF EXISTS get_all_users_with_emails_debug();

-- ============================================
-- ÉTAPE 2 : Créer la nouvelle fonction avec chorale
-- ============================================

SELECT '📋 ÉTAPE 2 : Création avec colonne chorale' as etape;

CREATE OR REPLACE FUNCTION get_all_users_with_emails_debug()
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    email TEXT,
    role TEXT,
    telephone TEXT,
    statut_validation TEXT,
    chorale_id UUID,
    chorale_nom TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        p.full_name::text,
        au.email::text,
        p.role::text,
        p.telephone::text,
        p.statut_validation::text,
        p.chorale_id,
        c.nom::text as chorale_nom,
        p.created_at::timestamptz  -- ✅ Cast explicite
    FROM profiles p
    INNER JOIN auth.users au ON p.user_id = au.id
    LEFT JOIN chorales c ON p.chorale_id = c.id
    WHERE p.user_id IS NOT NULL
    ORDER BY 
        CASE 
            WHEN p.role = 'super_admin' THEN 1
            WHEN p.role = 'admin' THEN 2
            WHEN p.role = 'membre' THEN 3
            ELSE 4
        END,
        p.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 3 : Permissions
-- ============================================

SELECT '📋 ÉTAPE 3 : Permissions' as etape;

GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO authenticated;

-- ============================================
-- ÉTAPE 4 : Tester
-- ============================================

SELECT '📋 ÉTAPE 4 : Test de la fonction' as etape;

SELECT 
    full_name,
    email,
    role,
    COALESCE(chorale_nom, '❌ Aucune chorale') as chorale,
    CASE 
        WHEN role = 'super_admin' THEN '🔴 Super Admin'
        WHEN role = 'admin' THEN '🟠 Admin'
        WHEN role = 'membre' THEN '🟢 Membre'
        ELSE '⚪ Autre'
    END as badge
FROM get_all_users_with_emails_debug()
LIMIT 10;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ FONCTION MISE À JOUR ✅✅✅' as resultat;
SELECT 'La page Utilisateurs affichera maintenant les chorales' as note;
SELECT 'Rafraîchissez le dashboard pour voir les changements' as action;
