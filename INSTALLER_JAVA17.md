# ☕ Installation et Configuration de Java 17

## 🚨 Problème Actuel

```
JDK 17 or higher is required.
Please set a valid Java home path to 'java.jdt.ls.java.home' setting 
or JAVA_HOME environment variable.
```

**Cause :** Java 17 n'est pas installé ou pas configuré correctement.

---

## ✅ Solution Rapide : Télécharger et Installer Java 17

### Option 1 : Adoptium (Recommandé)

1. **Télécharger Java 17**
   - Aller sur : https://adoptium.net/temurin/releases/
   - Sélectionner :
     - Version : **17 - LTS**
     - Operating System : **Windows**
     - Architecture : **x64**
     - Package Type : **JDK**
   - Cliquer sur **Download**

2. **Installer**
   - Exécuter le fichier `.msi` téléchargé
   - ✅ Cocher "Set JAVA_HOME variable"
   - ✅ Cocher "Add to PATH"
   - Cliquer sur "Install"

3. **Vérifier l'installation**
   ```bash
   java -version
   ```
   
   Vous devriez voir :
   ```
   openjdk version "17.0.x"
   ```

---

### Option 2 : Oracle JDK

1. **Télécharger**
   - Aller sur : https://www.oracle.com/java/technologies/downloads/#java17
   - Télécharger **Windows x64 Installer**

2. **Installer**
   - Exécuter le fichier `.exe`
   - Suivre les instructions

3. **Configurer manuellement** (voir section suivante)

---

## 🔧 Configuration Manuelle de JAVA_HOME

### Méthode 1 : Via l'Interface Windows

1. **Ouvrir les Variables d'Environnement**
   - Appuyer sur `Windows + R`
   - Taper : `sysdm.cpl`
   - Cliquer sur l'onglet "Avancé"
   - Cliquer sur "Variables d'environnement"

2. **Créer JAVA_HOME**
   - Dans "Variables système", cliquer sur "Nouvelle"
   - Nom de la variable : `JAVA_HOME`
   - Valeur : `C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot`
     (Remplacer par votre chemin d'installation)
   - Cliquer sur "OK"

3. **Ajouter au PATH**
   - Sélectionner la variable "Path"
   - Cliquer sur "Modifier"
   - Cliquer sur "Nouveau"
   - Ajouter : `%JAVA_HOME%\bin`
   - Cliquer sur "OK" partout

4. **Redémarrer VS Code et le terminal**

---

### Méthode 2 : Via PowerShell (Temporaire)

```powershell
# Définir JAVA_HOME pour la session actuelle
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Vérifier
java -version
```

---

## 🎯 Configuration pour Flutter/Android

### Vérifier la Configuration Android Studio

1. **Ouvrir Android Studio**
2. **File > Project Structure > SDK Location**
3. **JDK location** : Vérifier qu'il pointe vers Java 17

---

### Configurer gradle.properties (Alternative)

Si vous ne voulez pas modifier JAVA_HOME globalement :

**Fichier : `android/gradle.properties`**

Ajouter :
```properties
org.gradle.java.home=C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.13.11-hotspot
```

---

## 🔍 Vérification Complète

### 1. Vérifier Java
```bash
java -version
```

**Attendu :**
```
openjdk version "17.0.x" 2024-xx-xx
OpenJDK Runtime Environment Temurin-17.0.x+x (build 17.0.x+x)
OpenJDK 64-Bit Server VM Temurin-17.0.x+x (build 17.0.x+x, mixed mode, sharing)
```

---

### 2. Vérifier JAVA_HOME
```bash
echo %JAVA_HOME%
```

**Attendu :**
```
C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot
```

---

### 3. Vérifier PATH
```bash
echo %PATH%
```

Doit contenir : `C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot\bin`

---

## 🚀 Après Installation

### 1. Redémarrer VS Code
- Fermer complètement VS Code
- Rouvrir le projet

### 2. Nettoyer le Projet Flutter
```bash
flutter clean
flutter pub get
```

### 3. Relancer la Compilation
```bash
flutter run --release -d emulator-5554
```

---

## ⚠️ Problèmes Courants

### Problème 1 : "java n'est pas reconnu"

**Solution :**
- Vérifier que `%JAVA_HOME%\bin` est dans PATH
- Redémarrer le terminal
- Redémarrer VS Code

---

### Problème 2 : "JAVA_HOME is set to an invalid directory"

**Solution :**
- Vérifier que le chemin existe
- Pas d'espace ou caractères spéciaux
- Utiliser des backslashes doubles dans gradle.properties : `\\`

---

### Problème 3 : Plusieurs versions de Java installées

**Solution :**
```bash
# Lister toutes les installations Java
where java

# S'assurer que Java 17 est en premier dans PATH
```

---

## 📋 Checklist

- [ ] Java 17 téléchargé
- [ ] Java 17 installé
- [ ] JAVA_HOME configuré
- [ ] PATH mis à jour
- [ ] Terminal redémarré
- [ ] VS Code redémarré
- [ ] `java -version` affiche 17.0.x
- [ ] `flutter clean` exécuté
- [ ] Compilation relancée

---

## 🎯 Liens Utiles

- **Adoptium (Recommandé)** : https://adoptium.net/
- **Oracle JDK** : https://www.oracle.com/java/technologies/downloads/#java17
- **Documentation Flutter** : https://docs.flutter.dev/get-started/install/windows

---

## ✅ Une Fois Java 17 Installé

Relancez la compilation :

```bash
# Nettoyer
flutter clean

# Récupérer les dépendances
flutter pub get

# Lancer sur l'émulateur
flutter run --release -d emulator-5554
```

---

**Date :** 17 novembre 2025  
**Priorité :** 🔴 CRITIQUE  
**Temps estimé :** 10-15 minutes
