# CleanUserProfileFolders
## A PowerShell script to bulk-clean temp folders across every Windows user profile

---

## 🇫🇷 Français

### Présentation

**CleanUserProfileFolders** est un script PowerShell qui parcourt automatiquement tous les profils utilisateurs d'une machine Windows et vide les dossiers ciblés de chacun d'eux — par défaut `AppData\Local\Temp`. Il calcule l'espace disque libéré par utilisateur, affiche un résumé avant/après, et peut exporter un rapport CSV. C'est l'outil idéal pour les administrateurs système qui doivent régulièrement libérer de l'espace disque sur des serveurs multi-utilisateurs sans avoir à nettoyer chaque profil manuellement.

### Fonctionnement

Le script :
1. Liste tous les profils utilisateurs présents dans un dossier (par défaut `C:\Users`)
2. Ignore les profils système (`Default`, `Public`, etc.) et ceux explicitement exclus
3. Vide les sous-dossiers ciblés dans chaque profil
4. Mesure l'espace libéré et affiche un rapport détaillé

```
C:\Users
 ├── alice     → AppData\Local\Temp  → nettoyé
 ├── bob       → AppData\Local\Temp  → nettoyé
 ├── Default   → ignoré
 └── Public    → ignoré
```

### Installation et utilisation (pour les utilisateurs)

**Prérequis** : Windows PowerShell 5.1+, exécution en tant qu'**administrateur**.

```powershell
git clone https://github.com/ecamescasse/Random-Stuff.git
cd Random-Stuff/UserProfileFoldersCleaner
```

Nettoyage simple (dossier Temp de chaque utilisateur sous `C:\Users`) :

```powershell
.\CleanUserProfileFolders.ps1
```

Mode simulation, pour voir ce qui serait supprimé sans rien effacer :

```powershell
.\CleanUserProfileFolders.ps1 -WhatIf
```

Exemple complet avec tous les paramètres :

```powershell
.\CleanUserProfileFolders.ps1 `
    -ProfileLocation "D:\Users" `
    -TargetPaths @('\AppData\Local\Temp', '\AppData\Local\Microsoft\Windows\INetCache') `
    -ExcludeUsers @('admin.local', 'svc_backup') `
    -ExportCsv "C:\Logs\rapport_nettoyage.csv"
```

| Paramètre          | Type       | Par défaut                                              | Description                                              |
|---------------------|------------|-----------------------------------------------------------|--------------------------------------------------------------|
| `-ProfileLocation`  | `string`   | Dossier parent de `%USERPROFILE%` (souvent `C:\Users`)   | Chemin racine contenant les profils utilisateurs         |
| `-TargetPaths`      | `string[]` | `\AppData\Local\Temp`                                    | Sous-dossier(s) relatif(s) à vider dans chaque profil     |
| `-ExcludeUsers`     | `string[]` | `@()`                                                      | Profils à ignorer, en plus des profils système par défaut |
| `-ExportCsv`        | `string`   | *(aucun)*                                                  | Chemin d'export du rapport CSV                            |

> ⚠️ **Ce script supprime définitivement** le contenu des dossiers ciblés (pas de corbeille). Testez toujours avec `-WhatIf` avant une exécution en production.

### Installation et utilisation (pour les contributeurs)

Pour contribuer au projet :

```powershell
git clone https://github.com/ecamescasse/Random-Stuff.git
cd Random-Stuff/UserProfileFoldersCleaner

# Créez une branche dédiée à votre changement
git checkout -b feature/ma-nouvelle-fonctionnalite

# Testez vos modifications localement en mode simulation
.\CleanUserProfileFolders.ps1 -WhatIf -Verbose
```

Il n'y a pas de dépendances externes ni de build à effectuer : le script est autonome (PowerShell natif). Pensez à tester sur un dossier de profils factice avant de proposer votre modification, et vérifiez que le script passe toujours `Set-StrictMode -Version Latest` sans erreur si vous l'ajoutez à votre environnement de test.

### Attentes envers les contributeurs

- Ouvrez une **issue** avant de commencer un développement conséquent, pour discuter de l'approche.
- Toute contribution se fait via **pull request**, référencée à l'issue correspondante.
- Merci de garder des commits clairs et si possible **squashés** avant la fusion.
- Le code doit rester compatible **PowerShell 5.1** (pas de syntaxe propre à PowerShell 7+ sans fallback).
- Documentez tout nouveau paramètre dans ce README.

### Problèmes connus

- Le résumé d'espace disque n'est disponible que si `-ProfileLocation` pointe vers un lecteur local (lettre de lecteur). Les chemins réseau (`\\serveur\partage`) ne permettent pas ce calcul.
- Les fichiers verrouillés ou en cours d'utilisation sont ignorés silencieusement (comptés dans "Skipped items"), le script ne les force pas.

### Soutenir le projet

Si cet outil vous fait gagner du temps, n'hésitez pas :
[Buy Me a Coffee](https://www.buymeacoffee.com/ecamescasse)

---

## 🇬🇧 English

### Overview

**CleanUserProfileFolders** is a PowerShell script that automatically walks through every user profile on a Windows machine (RDS server, Citrix, shared workstation...) and clears the temporary folders inside each one — by default `AppData\Local\Temp`. It calculates the disk space freed per user, shows a before/after summary, and can export a CSV report. It's the ideal tool for system administrators who regularly need to free up disk space on multi-user servers without manually cleaning each profile.

### How it works

The script:
1. Lists every user profile in a given folder (default: `C:\Users`)
2. Skips system profiles (`Default`, `Public`, etc.) and any explicitly excluded ones
3. Clears the targeted subfolders in each profile
4. Measures the space freed and prints a detailed report

```
C:\Users
 ├── alice     → AppData\Local\Temp  → cleaned
 ├── bob       → AppData\Local\Temp  → cleane
 ├── Default   → skipped
 └── Public    → skipped
```

### Installation and usage (for end-users)

**Requirements**: Windows PowerShell 5.1+, must be run as **Administrator**.

```powershell
git clone https://github.com/ecamescasse/Random-Stuff.git
cd Random-Stuff/UserProfileFoldersCleaner
```

Basic cleanup (Temp folder of every user under `C:\Users`):

```powershell
.\CleanUserProfileFolders.ps1
```

Dry-run mode, to preview what would be deleted without removing anything:

```powershell
.\CleanUserProfileFolders.ps1 -WhatIf
```

Full example using every parameter:

```powershell
.\CleanUserProfileFolders.ps1 `
    -ProfileLocation "D:\Users" `
    -TargetPaths @('\AppData\Local\Temp', '\AppData\Local\Microsoft\Windows\INetCache') `
    -ExcludeUsers @('admin.local', 'svc_backup') `
    -ExportCsv "C:\Logs\cleanup_report.csv"
```

| Parameter           | Type       | Default                                                  | Description                                                       |
|-----------------------|------------|-------------------------------------------------------------|-------------------------------------------------------------------------|
| `-ProfileLocation`   | `string`   | Parent folder of `%USERPROFILE%` (usually `C:\Users`)    | Root path containing user profiles                                |
| `-TargetPaths`       | `string[]` | `\AppData\Local\Temp`                                      | Relative subfolder(s) to clear inside each profile                 |
| `-ExcludeUsers`      | `string[]` | `@()`                                                        | Profiles to skip, in addition to the default system profiles     |
| `-ExportCsv`         | `string`   | *(none)*                                                     | Path to export the CSV report                                     |

> ⚠️ **This script permanently deletes** the contents of the targeted folders (no recycle bin). Always test with `-WhatIf` before running in production.

### Installation and usage (for contributors)

To contribute to the project:

```powershell
git clone https://github.com/ecamescasse/Random-Stuff.git
cd Random-Stuff/UserProfileFoldersCleaner

# Create a dedicated branch for your change
git checkout -b feature/my-new-feature

# Test your changes locally in dry-run mode
.\CleanUserProfileFolders.ps1 -WhatIf -Verbose
```

There are no external dependencies or build steps: the script is self-contained (native PowerShell). Make sure to test against a dummy profiles folder before submitting your change, and verify the script still passes `Set-StrictMode -Version Latest` cleanly if you add it to your test setup.

### Contributor expectations

- Open an **issue** before starting any significant work, to discuss the approach first.
- All contributions go through a **pull request**, referencing the related issue.
- Please keep commits clean and, where possible, **squashed** before merging.
- Code must remain **PowerShell 5.1** compatible (no PowerShell 7+-only syntax without a fallback).
- Document any new parameter in this README.

### Known issues

- The disk space summary is only available when `-ProfileLocation` points to a local drive (drive letter). Network paths (`\\server\share`) don't support this calculation.
- Locked or in-use files are silently skipped (counted under "Skipped items") — the script does not force-delete them.

### Support this project

If this tool saves you time, feel free :
[Buy Me a Coffee](https://www.buymeacoffee.com/ecamescasse)
