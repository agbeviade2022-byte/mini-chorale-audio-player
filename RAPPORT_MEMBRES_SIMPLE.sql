-- =====================================================
-- RAPPORT : Membres par chorale (VERSION SIMPLE)
-- =====================================================

-- ============================================
-- RAPPORT 1 : Vue d'ensemble par chorale
-- ============================================

SELECT 
    COALESCE(c.nom, 'Aucune chorale') as chorale,
    COUNT(*) as nb_membres,
    COUNT(CASE WHEN p.statut_validation = 'valide' THEN 1 END) as nb_valides,
    COUNT(CASE WHEN p.statut_validation = 'en_attente' THEN 1 END) as nb_en_attente,
    COUNT(CASE WHEN p.statut_validation = 'refuse' THEN 1 END) as nb_refuses
FROM profiles p
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.role IN ('membre', 'admin')
GROUP BY c.nom, c.id
ORDER BY nb_membres DESC, c.nom;

-- ============================================
-- RAPPORT 2 : Liste complète des membres
-- ============================================

SELECT 
    COALESCE(c.nom, 'Aucune chorale') as chorale,
    p.full_name as nom_complet,
    au.email,
    p.role,
    p.statut_validation,
    TO_CHAR(p.created_at, 'DD/MM/YYYY') as date_inscription
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
LEFT JOIN chorales c ON p.chorale_id = c.id
ORDER BY 
    CASE WHEN c.nom IS NULL THEN 1 ELSE 0 END,
    c.nom,
    p.full_name;

-- ============================================
-- RAPPORT 3 : Membres SANS chorale
-- ============================================

SELECT 
    p.full_name as nom_complet,
    au.email,
    p.role,
    p.statut_validation,
    TO_CHAR(p.created_at, 'DD/MM/YYYY') as date_inscription,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_depuis_inscription
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
WHERE p.chorale_id IS NULL
ORDER BY p.created_at DESC;

-- ============================================
-- RAPPORT 4 : Statistiques globales
-- ============================================

SELECT 
    (SELECT COUNT(*) FROM chorales) as total_chorales,
    (SELECT COUNT(*) FROM profiles) as total_utilisateurs,
    (SELECT COUNT(*) FROM profiles WHERE chorale_id IS NOT NULL) as membres_avec_chorale,
    (SELECT COUNT(*) FROM profiles WHERE chorale_id IS NULL) as membres_sans_chorale,
    (SELECT COUNT(*) FROM profiles WHERE statut_validation = 'valide') as membres_valides,
    (SELECT COUNT(*) FROM profiles WHERE statut_validation = 'en_attente') as membres_en_attente,
    (SELECT COUNT(*) FROM chants) as total_chants;
