# 🔧 Résoudre le problème "npm n'est pas reconnu"

## ❌ Le problème

Node.js est installé mais PowerShell ne le trouve pas car il n'est pas dans le PATH.

**Erreur:** `npm : Le terme «npm» n'est pas reconnu`

## ✅ Solution 1: Redémarrer l'ordinateur (LE PLUS SIMPLE)

**C'est la solution la plus simple et la plus efficace !**

1. **Enregistrer votre travail**
2. **Redémarrer l'ordinateur**
3. **Ouvrir un nouveau PowerShell**
4. **Tester:**
   ```powershell
   npm --version
   ```

**Si ça fonctionne, passez directement à l'installation du dashboard !**

---

## ✅ Solution 2: Ajouter Node.js au PATH manuellement

Si vous ne voulez pas redémarrer:

### Étape 1: Ouvrir les variables d'environnement

1. **Appuyer sur** `Windows + R`
2. **Taper:** `sysdm.cpl`
3. **Appuyer sur** Entrée
4. **Onglet** "Avancé"
5. **Cliquer sur** "Variables d'environnement"

### Étape 2: Modifier la variable PATH

1. **Section "Variables utilisateur"**
2. **Sélectionner** la ligne `Path`
3. **Cliquer sur** "Modifier"
4. **Cliquer sur** "Nouveau"
5. **Ajouter:** `C:\Program Files\nodejs`
6. **Cliquer sur** "OK" (3 fois)

### Étape 3: Fermer et rouvrir PowerShell

**IMPORTANT:** Fermer TOUS les PowerShell et en ouvrir un NOUVEAU

### Étape 4: Vérifier

```powershell
npm --version
```

**Résultat attendu:** `10.2.4` (ou similaire)

---

## ✅ Solution 3: Utiliser le chemin complet (TEMPORAIRE)

Si les solutions ci-dessus ne marchent pas, utilisez le chemin complet:

```powershell
cd "d:\Projet Flutter\admin-chorale-dashboard"

# Utiliser le chemin complet
& "C:\Program Files\nodejs\npm.cmd" install
& "C:\Program Files\nodejs\npm.cmd" run dev
```

---

## ✅ Solution 4: Réinstaller Node.js

Si rien ne fonctionne:

1. **Désinstaller Node.js:**
   - Panneau de configuration
   - Programmes et fonctionnalités
   - Désinstaller "Node.js"

2. **Redémarrer l'ordinateur**

3. **Réinstaller Node.js:**
   - Télécharger depuis https://nodejs.org/
   - Installer (cocher "Automatically install tools")
   - **IMPORTANT:** Cocher "Add to PATH" pendant l'installation

4. **Redémarrer l'ordinateur**

5. **Vérifier:**
   ```powershell
   npm --version
   ```

---

## 🚀 Après avoir résolu le problème

### 1. Vérifier que npm fonctionne

```powershell
npm --version
```

**Résultat attendu:** `10.2.4`

### 2. Installer les dépendances du dashboard

```powershell
cd "d:\Projet Flutter\admin-chorale-dashboard"
npm install
```

**Durée:** 2-3 minutes

### 3. Lancer le dashboard

```powershell
npm run dev
```

**Résultat attendu:**
```
▲ Next.js 14.2.0
- Local:        http://localhost:3000

✓ Ready in 2.5s
```

### 4. Ouvrir dans le navigateur

**URL:** http://localhost:3000/login

**Se connecter avec:**
- Email: kodjodavid2025@gmail.com
- Mot de passe: votre_mot_de_passe

---

## 📋 Checklist de dépannage

- [ ] Node.js est installé (vérifier dans Panneau de configuration)
- [ ] Redémarrer l'ordinateur
- [ ] Ouvrir un NOUVEAU PowerShell
- [ ] Tester: `npm --version`
- [ ] Si ça ne marche pas: Ajouter au PATH manuellement
- [ ] Si ça ne marche toujours pas: Réinstaller Node.js
- [ ] Une fois que npm fonctionne: `npm install`
- [ ] Lancer: `npm run dev`

---

## 🆘 Aide supplémentaire

### Vérifier si Node.js est installé

```powershell
Get-Command node
```

**Si installé, vous verrez:**
```
CommandType     Name        Version    Source
-----------     ----        -------    ------
Application     node.exe    20.11.0    C:\Program Files\nodejs\node.exe
```

### Vérifier le dossier d'installation

```powershell
Test-Path "C:\Program Files\nodejs\npm.cmd"
```

**Résultat attendu:** `True`

---

## 🎯 Résumé

**Solution la plus simple:**

1. **Redémarrer l'ordinateur** 🔄
2. **Ouvrir un nouveau PowerShell**
3. **Tester:** `npm --version`
4. **Installer le dashboard:**
   ```powershell
   cd "d:\Projet Flutter\admin-chorale-dashboard"
   npm install
   npm run dev
   ```

**Dans 99% des cas, le redémarrage résout le problème !** 🚀
