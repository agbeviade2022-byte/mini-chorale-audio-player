-- =====================================================
-- TEST : Profils sans user_id
-- =====================================================

-- Compter les profils orphelins
SELECT 
    COUNT(*) as nombre_profils_sans_user_id
FROM profiles
WHERE user_id IS NULL;

-- Lister les profils orphelins
SELECT 
    id,
    full_name,
    role,
    statut_validation,
    created_at
FROM profiles
WHERE user_id IS NULL
ORDER BY created_at DESC;
