-- =====================================================
-- FIX RAPIDE : Corriger l'accès à la vue membres_en_attente
-- =====================================================
-- Exécutez ce script pour corriger l'erreur 42703
-- =====================================================

-- Donner les permissions sur les vues
GRANT SELECT ON membres_en_attente TO authenticated;
GRANT SELECT ON stats_validations TO authenticated;

-- Vérifier que la vue fonctionne
SELECT 'Test de la vue membres_en_attente' as test;
SELECT * FROM membres_en_attente LIMIT 5;

SELECT 'Fix appliqué avec succès !' as status;
