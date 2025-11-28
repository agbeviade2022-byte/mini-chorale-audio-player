#!/bin/bash

# =====================================================
# SCRIPT D'INSTALLATION DU DASHBOARD ADMIN
# =====================================================

echo "🚀 Installation du Dashboard Admin..."
echo ""

# Créer le projet Next.js
echo "📦 Création du projet Next.js..."
cd "d:/Projet Flutter/"
npx create-next-app@latest admin-chorale-dashboard --typescript --tailwind --app --no-src-dir --import-alias "@/*"

# Aller dans le dossier
cd admin-chorale-dashboard

# Installer les dépendances
echo ""
echo "📦 Installation des dépendances..."
npm install @supabase/supabase-js
npm install @supabase/auth-helpers-nextjs
npm install recharts
npm install lucide-react

# Créer les dossiers
echo ""
echo "📁 Création de la structure..."
mkdir -p app/login
mkdir -p app/dashboard/chorales
mkdir -p app/dashboard/users
mkdir -p app/dashboard/chants
mkdir -p app/dashboard/stats
mkdir -p app/dashboard/logs
mkdir -p components
mkdir -p lib

# Créer .env.local
echo ""
echo "🔧 Configuration..."
cat > .env.local << EOF
NEXT_PUBLIC_SUPABASE_URL=https://milzcdtfblwhblstwuzh.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=VOTRE_ANON_KEY_ICI
EOF

echo ""
echo "✅ Installation terminée!"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Modifier .env.local avec votre ANON_KEY"
echo "2. Copier les fichiers depuis DASHBOARD_WEB_GUIDE.md"
echo "3. Lancer: npm run dev"
echo "4. Ouvrir: http://localhost:3000"
echo ""
