-- =====================================================
-- FIX : Permissions pour la vue membres_en_attente
-- =====================================================
-- Exécutez ce script si vous avez l'erreur 42703
-- =====================================================

-- Donner les permissions sur la vue aux admins
GRANT SELECT ON membres_en_attente TO authenticated;

-- Créer une policy pour la vue (si nécessaire)
-- Note: Les vues héritent généralement des policies des tables sous-jacentes
-- mais on peut forcer l'accès pour les admins

-- Vérifier que la vue existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'membres_en_attente') 
        THEN '✅ Vue membres_en_attente existe'
        ELSE '❌ Vue membres_en_attente n''existe pas'
    END as vue_check;

-- Vérifier les permissions
SELECT 
    grantee, 
    privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'membres_en_attente';

-- Tester la vue
SELECT * FROM membres_en_attente LIMIT 5;
