-- =====================================================
-- TEST : Statistiques générales
-- =====================================================

-- Statistiques des utilisateurs et profils
SELECT 
    'Total users (auth.users)' as element,
    COUNT(*)::text as valeur
FROM auth.users

UNION ALL

SELECT 
    'Total profiles' as element,
    COUNT(*)::text as valeur
FROM profiles

UNION ALL

SELECT 
    'Profiles avec user_id' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE user_id IS NOT NULL

UNION ALL

SELECT 
    'Profiles sans user_id' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE user_id IS NULL

UNION ALL

SELECT 
    'Total chorales' as element,
    COUNT(*)::text as valeur
FROM chorales

UNION ALL

SELECT 
    'Chorales actives' as element,
    COUNT(*)::text as valeur
FROM chorales
WHERE statut = 'actif'

UNION ALL

SELECT 
    'Total chants' as element,
    COUNT(*)::text as valeur
FROM chants;
