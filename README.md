# 🖥️ SysMonitor Pro

![Bash](https://img.shields.io/badge/Bash-4%2B-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL-0078D4?style=flat-square&logo=linux&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

> **Un ensemble de scripts Bash modulaires pour surveiller un serveur Linux et générer des rapports HTML quotidiens.**

---

## 📋 Table des matières

- [🚀 Aperçu rapide](#-aperçu-rapide)
- [📦 Prérequis](#-prérequis)
- [⚡ Installation](#-installation)
- [🎯 Utilisation](#-utilisation)
- [📊 Rapports](#-rapports)
- [📚 Documentation](#-documentation)
- [🤝 Contribuer](#-contribuer)

---

## 🚀 Aperçu rapide

SysMonitor Pro surveille automatiquement :
- **💻 Système** : CPU, mémoire, stockage, charge système
- **🔄 Processus** : Top processus, zombies, gestion avancée
- **🔧 Services** : Services critiques, redémarrages automatiques
- **🌐 Réseau** : Connectivité, interfaces, ports, trafic
- **📝 Logs** : Centralisation et analyse des logs

### ✨ Fonctionnalités clés

| Fonctionnalité | Description |
|---|---|
| 📅 **Rapports quotidiens** | `reports/system_report_YYYYMMDD.html` |
| 📂 **Sections groupées** | Interface HTML avec sections collapsibles |
| 🪟 **Support WSL** | Détection automatique des disques Windows (`C:/`, `D:/`) |
| ⚙️ **Modulaire** | Architecture extensible avec modules `lib/` |
| 🚨 **Alertes** | Seuils configurables (OK/WARNING/CRITICAL) |

---

## 📦 Prérequis

### Obligatoires
- **Bash 4+**
- **Coreutils** : `df`, `ps`, `awk`, `grep`

### Recommandés
| Outil | Usage | Alternative |
|---|---|---|
| `ss` | Ports réseau | `netstat` |
| `journalctl` | Logs systemd | `/var/log/*` |
| `logger` | Envoi syslog | - |

---

## ⚡ Installation
### 🔧 Étapes d'installation

1. **📥 Cloner le dépôt**
   ```bash
   git clone <repository-url>
   cd SysMonitor-Pro
   ```

2. **🔧 Configuration WSL (Windows uniquement)**
   ```bash
   # Normaliser les fins de ligne si nécessaire
   sed -i 's/\r$//' config/*.conf main.sh lib/*.sh
   ```

3. **✅ Permissions d'exécution**
   ```bash
   chmod +x main.sh lib/*.sh
   ```

4. **🚀 Test d'installation**
   ```bash
   ./main.sh --help
   ```

---

## 🎯 Utilisation

### 🏃 Démarrage rapide

```bash
# Monitoring complet + rapport HTML
./main.sh

# Aide complète
./main.sh --help
```

### 🎛️ Modules individuels

| Commande | Description |
|---|---|
| `./main.sh --system-only` | 💻 Système uniquement |
| `./main.sh --process-only` | 🔄 Processus uniquement |
| `./main.sh --service-only` | 🔧 Services uniquement |
| `./main.sh --network-only` | 🌐 Réseau uniquement |

---

## 📊 Rapports

### 📍 Emplacement
```
reports/system_report_$(date +%Y%m%d).html
```
**Exemple** : `reports/system_report_20251005.html`

### 🎨 Structure du rapport

Le rapport HTML est organisé en **sections collapsibles** :

| Section | Contenu |
|---|---|
| 💻 **Système** | CPU, RAM, Swap, Disques, Charge |
| 🔄 **Processus** | Top 10, Zombies, Surveillance |
| 🔧 **Services** | État services critiques |
| 🌐 **Réseau** | Connectivité, Interfaces, Ports |
| 📝 **Logs** | Extraits récents |

### 🚨 Niveaux d'alerte

| Niveau | Badge | Description |
|---|---|---|
| ✅ **OK** | `🟢` | Fonctionnement normal |
| ⚠️ **WARNING** | `🟡` | Seuil d'attention atteint |
| 🚨 **CRITICAL** | `🔴` | Intervention requise |

> **Note** : Les seuils sont configurables dans `config/thresholds.conf`

### 🪟 Support WSL
- Détection automatique des disques Windows
- Rapport inclut : `C:/`, `D:/`, etc. sous `/mnt/<lettre>`

---

## 📚 Documentation

| Document | Description |
|---|---|
| 📋 [`ARCHITECTURE.md`](ARCHITECTURE.md) | Architecture et flux de données |
| ⚙️ [`CONFIGURATION.md`](CONFIGURATION.md) | Configuration et personnalisation |

---

## 🤝 Contribuer

### 🔧 Développement

1. **Nouveau module** : Créer `lib/your_module.sh`
2. **Intégration** : Modifier `main.sh` pour inclure le module
3. **Standards** : Respecter `set -euo pipefail`

### 🧪 Tests

```bash
# Test rapide système
./main.sh --system-only

# Vérifier la génération de rapport
ls -la reports/
```

### 📝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit (`git commit -am 'Ajouter nouvelle fonctionnalité'`)
4. Push (`git push origin feature/nouvelle-fonctionnalite`)
5. Créer une Pull Request

---

## 📄 Licence

```
MIT License - Voir LICENSE pour plus de détails
```

---

<div align="center">

**🛠️ Développé avec ❤️ pour la surveillance système Linux**

![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg?style=flat-square)

</div>
