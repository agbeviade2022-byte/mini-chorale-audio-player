# 📦 Installer Node.js

## ❌ Le problème

Node.js n'est pas installé sur votre système Windows.

**Erreur:** `npm : Le terme «npm» n'est pas reconnu`

## ✅ Solution: Installer Node.js

### Méthode 1: Installation officielle (RECOMMANDÉ)

#### Étape 1: Télécharger Node.js

**Lien:** https://nodejs.org/

**Choisir:** **LTS (Long Term Support)** - Version 20.x

**Fichier:** `node-v20.x.x-x64.msi` (environ 30 MB)

#### Étape 2: Installer

1. **Double-cliquer** sur le fichier téléchargé
2. **Suivre l'assistant d'installation:**
   - ✅ Accepter la licence
   - ✅ Choisir le dossier d'installation (par défaut: `C:\Program Files\nodejs`)
   - ✅ **IMPORTANT:** Cocher "Automatically install the necessary tools"
   - ✅ Cliquer sur "Install"

**Durée:** 2-3 minutes

#### Étape 3: Vérifier l'installation

**Ouvrir un NOUVEAU PowerShell** (important !) et taper:

```powershell
node --version
npm --version
```

**Résultat attendu:**
```
v20.11.0
10.2.4
```

---

### Méthode 2: Installation avec Chocolatey (ALTERNATIVE)

Si vous avez Chocolatey installé:

```powershell
# En tant qu'administrateur
choco install nodejs-lts
```

---

## 🚀 Après l'installation

### 1. Fermer et rouvrir PowerShell

**IMPORTANT:** Fermez TOUS les terminaux PowerShell et rouvrez-en un nouveau.

### 2. Vérifier que npm fonctionne

```powershell
npm --version
```

**Résultat attendu:** `10.2.4` (ou similaire)

### 3. Installer les dépendances du dashboard

```powershell
cd "d:\Projet Flutter\admin-chorale-dashboard"
npm install
```

**Durée:** 2-3 minutes

**Résultat attendu:**
```
added 345 packages in 2m

23 packages are looking for funding
  run `npm fund` for details
```

### 4. Lancer le dashboard

```powershell
npm run dev
```

**Résultat attendu:**
```
▲ Next.js 14.2.0
- Local:        http://localhost:3000

✓ Ready in 2.5s
```

### 5. Ouvrir dans le navigateur

**URL:** http://localhost:3000/login

---

## 🆘 Problèmes courants

### Problème 1: "npm" toujours pas reconnu après installation

**Solution:**
1. Fermer TOUS les PowerShell
2. Rouvrir un NOUVEAU PowerShell
3. Vérifier: `npm --version`

### Problème 2: Erreur de permissions

**Solution:** Exécuter PowerShell en tant qu'administrateur

### Problème 3: Installation bloquée

**Solution:**
1. Désactiver temporairement l'antivirus
2. Réessayer l'installation
3. Réactiver l'antivirus

---

## 📋 Checklist d'installation

- [ ] Télécharger Node.js LTS depuis nodejs.org
- [ ] Installer Node.js (cocher "Automatically install tools")
- [ ] Fermer et rouvrir PowerShell
- [ ] Vérifier: `node --version`
- [ ] Vérifier: `npm --version`
- [ ] Aller dans le dossier dashboard
- [ ] Exécuter: `npm install`
- [ ] Exécuter: `npm run dev`
- [ ] Ouvrir: http://localhost:3000/login

---

## 🎯 Résumé

**Actions à faire:**

1. **Télécharger Node.js LTS:** https://nodejs.org/
2. **Installer** (2-3 minutes)
3. **Fermer et rouvrir PowerShell**
4. **Vérifier:** `npm --version`
5. **Installer le dashboard:**
   ```powershell
   cd "d:\Projet Flutter\admin-chorale-dashboard"
   npm install
   npm run dev
   ```

**Après ça, le dashboard fonctionnera !** 🚀
