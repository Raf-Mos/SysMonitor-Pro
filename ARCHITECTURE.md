# 🏗️ SysMonitor Pro — Architecture

![Architecture](https://img.shields.io/badge/Architecture-Modular-blue?style=flat-square)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash)

> **Document technique décrivant l'architecture modulaire de SysMonitor Pro.**

---

## 📋 Table des matières

- [🎯 Vue d'ensemble](#-vue-densemble)
- [📁 Structure du projet](#-structure-du-projet)
- [🔄 Flux de données](#-flux-de-données)
- [⚙️ Choix de conception](#️-choix-de-conception)
- [🔒 Considérations de sécurité](#-considérations-de-sécurité)
- [🔧 Extensibilité](#-extensibilité)
- [📝 Notes opérationnelles](#-notes-opérationnelles)

---

## 🎯 Vue d'ensemble

SysMonitor Pro adopte une **architecture modulaire** basée sur des scripts Bash spécialisés, favorisant la maintenabilité et l'extensibilité.

### 🏛️ Composants principaux

| Composant | Rôle | Description |
|---|---|---|
| 🎭 **`main.sh`** | Orchestrateur | Coordination et génération de rapports |
| ⚙️ **`config/`** | Configuration | Paramètres runtime et seuils |
| 📚 **`lib/`** | Modules métier | Vérifications spécialisées |
| 📊 **`reports/`** | Sortie | Rapports HTML générés |
| 📝 **`logs/`** | Logs | Journalisation des événements |

---

## 📁 Structure du projet

```
SysMonitor-Pro/
├── 🎭 main.sh                    # Point d'entrée principal
├── 📁 config/
│   ├── ⚙️ settings.conf          # Configuration générale
│   └── 🎚️ thresholds.conf       # Seuils d'alerte
├── 📁 lib/                       # Modules métier
│   ├── 📝 logger.sh             # Système de logs
│   ├── 💻 system_monitor.sh     # Surveillance système
│   ├── 🔄 process_manager.sh    # Gestion processus
│   ├── 🔧 service_checker.sh    # Vérification services
│   └── 🌐 network_utils.sh      # Utilitaires réseau
├── 📁 reports/                   # Rapports générés
│   └── 📊 system_report_YYYYMMDD.html
└── 📁 logs/                      # Journalisation
    └── 📝 sysmonitor.log
```

### 📚 Détail des modules `lib/`

| Module | Fonctions principales | Dépendances |
|---|---|---|
| 📝 **logger.sh** | `log_info()`, `log_warning()`, `log_error()`, `log_critical()` | `logger` (optionnel) |
| 💻 **system_monitor.sh** | `monitor_cpu_usage()`, `monitor_memory_usage()`, `monitor_disk_space()` | `top`, `free`, `df` |
| 🔄 **process_manager.sh** | `list_top_processes()`, `find_zombie_processes()`, `kill_problematic_process()` | `ps`, `pgrep`, `kill` |
| 🔧 **service_checker.sh** | `check_critical_services()`, `restart_failed_service()` | `systemctl`, `journalctl` |
| 🌐 **network_utils.sh** | `check_network_connectivity()`, `monitor_network_traffic()` | `ping`, `ss`/`netstat`, `ip` |

---

## 🔄 Flux de données

### 📊 Étapes du processus

1. **🚀 Initialisation**
   - Normalisation des fins de ligne (CRLF → LF)
   - Chargement des configurations
   - Sourcing des modules

2. **🔍 Validation**
   - Vérification des prérequis système
   - Validation des paramètres d'entrée
   - Configuration du piège de nettoyage

3. **⚡ Exécution**
   - Lancement séquentiel des modules
   - Capture des sorties texte
   - Gestion des erreurs

4. **📊 Génération**
   - Échappement HTML des sorties
   - Construction du rapport structuré
   - Sauvegarde quotidienne

---

## ⚙️ Choix de conception

### 🎯 Philosophie

| Principe | Justification | Implémentation |
|---|---|---|
| **🔧 Modularité** | Maintenabilité, testabilité | Scripts `lib/` indépendants |
| **📦 Portabilité** | Compatibilité multi-distributions | Commandes POSIX standard |
| **🚀 Simplicité** | Débogage facilité | Pas de dépendances externes |
| **📊 Lisibilité** | Rapports accessibles | HTML standard |

### 🛠️ Outils natifs privilégiés

| Besoin | Outil principal | Alternative | Raison |
|---|---|---|---|
| **💻 Processus** | `ps` | `/proc/*` | Universalité |
| **🗄️ Stockage** | `df -P` | `du` | Format portable |
| **🌐 Réseau** | `ss` | `netstat` | Performance |
| **🔧 Services** | `systemctl` | `service` | Standard moderne |

---

## 🔒 Considérations de sécurité

### 🛡️ Principes de sécurité

| Aspect | Mesure | Implémentation |
|---|---|---|
| **👤 Privilèges** | Principe du moindre privilège | Exécution en utilisateur standard |
| **📊 Données sensibles** | Filtrage | Évitement des mots de passe dans les rapports |
| **📝 Logs** | Rotation | Logs limités en taille |
| **🔐 Accès** | Permissions restrictives | `chmod 750` sur les scripts |

### ⚠️ Points d'attention

```bash
# ❌ À éviter : exposition de données sensibles
echo "Database password: $DB_PASS" >> report.html

# ✅ Recommandé : informations génériques
echo "Database connection: [CONFIGURED]" >> report.html
```

---

## 🔧 Extensibilité

### 🆕 Ajouter un nouveau module

1. **📝 Créer le module**
   ```bash
   # lib/mon_module.sh
   #!/bin/bash
   
   run_mon_monitoring() {
       echo "=== Mon Module ==="
       # Votre logique ici
   }
   ```

2. **🔗 Intégrer dans main.sh**
   ```bash
   # Dans main.sh
   source "${SCRIPT_DIR}/lib/mon_module.sh"
   
   # Dans main()
   run_mon_monitoring
   ```

3. **📊 Ajouter au rapport**
   ```bash
   # Dans generate_system_report()
   MON_OUTPUT=$(run_mon_monitoring 2>&1)
   append_section "Mon Module" "$MON_OUTPUT"
   ```

### 🎨 Personnaliser les rapports

```bash
# Remplacer html_escape et append_section pour :
# - Templates avancés (Mustache, Jinja2)
# - Graphiques (Chart.js, D3.js)
# - Thèmes CSS personnalisés
```

---

## 📝 Notes opérationnelles

### 🪟 Spécificités WSL

| Fonctionnalité | Comportement | Configuration |
|---|---|---|
| **💾 Disques Windows** | Détection automatique `/mnt/<lettre>` | `monitor_disk_space()` |
| **📄 Fins de ligne** | Normalisation CRLF → LF au démarrage | `fix_line_endings()` |
| **🔧 Outils système** | Fallback vers alternatives | Détection conditionnelle |

### 🚀 Performance

```bash
# Optimisations implémentées :
# - Sourcing conditionnel des modules
# - Cache des résultats coûteux (df, ps)
# - Parallélisation possible (background jobs)
```

### 🔍 Débogage

```bash
# Variables de débogage disponibles :
export DEBUG=1          # Mode verbeux
export DRY_RUN=1        # Simulation sans écriture
export LOG_LEVEL=DEBUG  # Logs détaillés
```

---

<div align="center">

**🏗️ Architecture conçue pour la robustesse et l'évolutivité**

![Modular Design](https://img.shields.io/badge/Design-Modular-success?style=flat-square)

</div>

*** End of file
