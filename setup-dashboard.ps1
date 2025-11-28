# =====================================================
# SCRIPT D'INSTALLATION DU DASHBOARD ADMIN (Windows)
# =====================================================

Write-Host "🚀 Installation du Dashboard Admin..." -ForegroundColor Green
Write-Host ""

# Aller dans le dossier parent
Set-Location "d:\Projet Flutter\"

# Créer le projet Next.js
Write-Host "📦 Création du projet Next.js..." -ForegroundColor Cyan
npx create-next-app@latest admin-chorale-dashboard --typescript --tailwind --app --no-src-dir --import-alias "@/*"

# Aller dans le dossier
Set-Location admin-chorale-dashboard

# Installer les dépendances
Write-Host ""
Write-Host "📦 Installation des dépendances..." -ForegroundColor Cyan
npm install @supabase/supabase-js
npm install @supabase/auth-helpers-nextjs
npm install recharts
npm install lucide-react

# Créer les dossiers
Write-Host ""
Write-Host "📁 Création de la structure..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "app\login"
New-Item -ItemType Directory -Force -Path "app\dashboard\chorales"
New-Item -ItemType Directory -Force -Path "app\dashboard\users"
New-Item -ItemType Directory -Force -Path "app\dashboard\chants"
New-Item -ItemType Directory -Force -Path "app\dashboard\stats"
New-Item -ItemType Directory -Force -Path "app\dashboard\logs"
New-Item -ItemType Directory -Force -Path "components"
New-Item -ItemType Directory -Force -Path "lib"

# Créer .env.local
Write-Host ""
Write-Host "🔧 Configuration..." -ForegroundColor Cyan
@"
NEXT_PUBLIC_SUPABASE_URL=https://milzcdtfblwhblstwuzh.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=VOTRE_ANON_KEY_ICI
"@ | Out-File -FilePath ".env.local" -Encoding UTF8

Write-Host ""
Write-Host "Installation terminee!" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Yellow
Write-Host "1. Modifier .env.local avec votre ANON_KEY"
Write-Host "2. Copier les fichiers depuis DASHBOARD_WEB_GUIDE.md"
Write-Host "3. Lancer: npm run dev"
Write-Host "4. Ouvrir: http://localhost:3000"
Write-Host ""
