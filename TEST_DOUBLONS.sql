-- =====================================================
-- TEST : Doublons user_id
-- =====================================================

-- Lister les user_id en double
SELECT 
    user_id,
    COUNT(*) as nombre_profils,
    STRING_AGG(id::text, ', ') as profile_ids,
    STRING_AGG(full_name, ', ') as noms
FROM profiles
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
