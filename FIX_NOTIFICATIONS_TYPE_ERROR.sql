-- =====================================================
-- FIX : Erreur de type dans get_admin_notifications
-- =====================================================

SELECT '🔧 FIX : Fonction get_admin_notifications' as info;

-- ============================================
-- ÉTAPE 1 : Supprimer l'ancienne fonction
-- ============================================

SELECT '📋 ÉTAPE 1 : Suppression de l''ancienne fonction' as etape;

-- Supprimer la fonction existante
DROP FUNCTION IF EXISTS get_admin_notifications(INTEGER, BOOLEAN);

-- ============================================
-- ÉTAPE 2 : Recréer la fonction avec les bons types
-- ============================================

SELECT '📋 ÉTAPE 2 : Création de la nouvelle fonction' as etape;

-- Fonction pour récupérer les notifications non lues
CREATE OR REPLACE FUNCTION get_admin_notifications(
    p_limit INTEGER DEFAULT 50,
    p_only_unread BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id INTEGER,
    type TEXT,          -- ✅ TEXT au lieu de VARCHAR(50)
    titre TEXT,         -- ✅ TEXT au lieu de VARCHAR(255)
    message TEXT,
    user_id UUID,
    user_email TEXT,
    user_full_name TEXT,
    lu BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        an.id,
        an.type::text,              -- ✅ Cast explicite
        an.titre::text,             -- ✅ Cast explicite
        an.message,
        an.user_id,
        au.email::text as user_email,
        p.full_name::text as user_full_name,
        an.lu,
        an.created_at
    FROM admin_notifications an
    LEFT JOIN auth.users au ON an.user_id = au.id
    LEFT JOIN profiles p ON au.id = p.user_id
    WHERE (p_only_unread = FALSE OR an.lu = FALSE)
    ORDER BY an.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 3 : Tester la fonction
-- ============================================

SELECT '📋 ÉTAPE 3 : Test de la fonction' as etape;

-- Tester avec une limite de 5
SELECT 
    id,
    type,
    titre,
    CASE 
        WHEN lu = FALSE THEN '🔔 Non lu'
        ELSE '✅ Lu'
    END as statut,
    created_at
FROM get_admin_notifications(5, FALSE);

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ FONCTION CORRIGÉE ✅✅✅' as resultat;
SELECT 'La cloche de notification devrait maintenant fonctionner' as note;
SELECT 'Rafraîchissez le dashboard pour voir les notifications' as action;
