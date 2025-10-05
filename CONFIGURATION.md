# ⚙️ SysMonitor Pro — Guide de Configuration

![Configuration](https://img.shields.io/badge/Configuration-Customizable-orange?style=flat-square)
![Format](https://img.shields.io/badge/Format-Bash_Config-blue?style=flat-square)

> **Guide complet pour personnaliser les paramètres et seuils de SysMonitor Pro.**

---

## 📋 Table des matières

- [📁 Fichiers de configuration](#-fichiers-de-configuration)
- [⚙️ Configuration générale](#️-configuration-générale)
- [🎚️ Seuils d'alerte](#️-seuils-dalerte)
- [🎯 Exemples de personnalisation](#-exemples-de-personnalisation)
- [🪟 Spécificités WSL](#-spécificités-wsl)
- [🔄 Rechargement](#-rechargement)
- [🛠️ Dépannage](#️-dépannage)

---

## 📁 Fichiers de configuration

| Fichier | Purpose | Format |
|---|---|---|
| 📋 **`config/settings.conf`** | Paramètres généraux | Variables Bash |
| 🎚️ **`config/thresholds.conf`** | Seuils numériques | Variables Bash |

### 📂 Emplacement
```
SysMonitor-Pro/
└── config/
    ├── settings.conf      # Configuration principale
    └── thresholds.conf    # Seuils d'alerte
```

---

## ⚙️ Configuration générale

### 📋 `config/settings.conf`

```bash
#!/bin/bash
# Configuration générale de SysMonitor Pro

# 📁 Chemins des répertoires
LOG_DIR="./logs"                    # Répertoire des logs
REPORT_DIR="./reports"              # Répertoire des rapports

# 🔧 Services critiques à surveiller
CRITICAL_SERVICES=(
    "ssh"                           # Accès distant
    "cron"                          # Planificateur de tâches
    "rsyslog"                       # Système de logs
    "systemd-networkd"              # Gestion réseau
)

# 🌐 Interfaces réseau à monitorer
NETWORK_INTERFACES=(
    "eth0"                          # Interface principale
    "lo"                            # Interface de bouclage
)

# 🎯 Cibles de test de connectivité
PING_TARGETS=(
    "8.8.8.8"                       # Google DNS
    "1.1.1.1"                       # Cloudflare DNS
    "google.com"                    # Test de résolution DNS
)

# 📝 Configuration des logs
LOG_LEVEL="INFO"                    # Niveau de log (DEBUG|INFO|WARNING|ERROR|CRITICAL)
SYSLOG_ENABLED=false               # Envoi vers syslog système
```

### 🎛️ Paramètres détaillés

| Paramètre | Type | Description | Valeurs possibles |
|---|---|---|---|
| `LOG_DIR` | String | Répertoire des fichiers de log | Chemin relatif ou absolu |
| `REPORT_DIR` | String | Répertoire des rapports HTML | Chemin relatif ou absolu |
| `CRITICAL_SERVICES` | Array | Services système à surveiller | Noms de services systemd |
| `NETWORK_INTERFACES` | Array | Interfaces réseau à monitorer | `eth0`, `wlan0`, `enp0s3`, etc. |
| `PING_TARGETS` | Array | Cibles pour tests de connectivité | IPs ou noms de domaine |
| `LOG_LEVEL` | String | Niveau de verbosité des logs | `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` |
| `SYSLOG_ENABLED` | Boolean | Envoi des logs critiques vers syslog | `true`, `false` |

---

## 🎚️ Seuils d'alerte

### 📊 `config/thresholds.conf`

```bash
#!/bin/bash
# Seuils d'alerte pour SysMonitor Pro

# 💻 Seuils CPU (en pourcentage)
CPU_WARNING_THRESHOLD=70            # ⚠️  Seuil d'avertissement
CPU_CRITICAL_THRESHOLD=90           # 🚨 Seuil critique

# 🧠 Seuils mémoire (en pourcentage)
MEMORY_WARNING_THRESHOLD=80         # ⚠️  RAM : seuil d'avertissement
MEMORY_CRITICAL_THRESHOLD=95        # 🚨 RAM : seuil critique

# 💾 Seuils disque (en pourcentage)
DISK_WARNING_THRESHOLD=85           # ⚠️  Espace disque : avertissement
DISK_CRITICAL_THRESHOLD=95          # 🚨 Espace disque : critique

# ⚡ Seuils de charge système
LOAD_WARNING_MULTIPLIER=1.5         # ⚠️  Multiplicateur vs nb de CPU
LOAD_CRITICAL_MULTIPLIER=2.0        # 🚨 Multiplicateur vs nb de CPU

# 🌐 Paramètres réseau
NETWORK_TIMEOUT=5                   # Timeout ping (secondes)
NETWORK_RETRY_COUNT=3               # Nombre de tentatives

# 🔧 Paramètres services
SERVICE_RESTART_MAX_ATTEMPTS=3      # Tentatives de redémarrage max
SERVICE_CHECK_INTERVAL=60           # Intervalle entre vérifications (sec)
```

### 📈 Niveaux d'alerte

| Niveau | Badge | Couleur | Critère |
|---|---|---|---|
| ✅ **OK** | 🟢 | Vert | < Seuil WARNING |
| ⚠️ **WARNING** | 🟡 | Orange | ≥ WARNING et < CRITICAL |
| 🚨 **CRITICAL** | 🔴 | Rouge | ≥ CRITICAL |

### 🎯 Calcul des seuils

#### 💻 CPU et 🧠 Mémoire
```bash
# Exemples avec les seuils par défaut :
# CPU : 0-69% = OK, 70-89% = WARNING, 90%+ = CRITICAL
# RAM : 0-79% = OK, 80-94% = WARNING, 95%+ = CRITICAL
```

#### ⚡ Charge système
```bash
# Calcul basé sur le nombre de CPU
# Exemple avec 4 CPU :
# Load < 6.0 (4×1.5) = OK
# Load 6.0-7.9 (4×2.0) = WARNING  
# Load ≥ 8.0 = CRITICAL
```

---

## 🎯 Exemples de personnalisation

### 🏢 Environnement de production

```bash
# config/thresholds.conf - Production
CPU_WARNING_THRESHOLD=60            # Plus strict
CPU_CRITICAL_THRESHOLD=80
MEMORY_WARNING_THRESHOLD=75
MEMORY_CRITICAL_THRESHOLD=90
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
```

### 🧪 Environnement de développement

```bash
# config/thresholds.conf - Développement
CPU_WARNING_THRESHOLD=85            # Plus permissif
CPU_CRITICAL_THRESHOLD=95
MEMORY_WARNING_THRESHOLD=90
MEMORY_CRITICAL_THRESHOLD=98
DISK_WARNING_THRESHOLD=90
DISK_CRITICAL_THRESHOLD=98
```

### 🏠 Serveur domestique

```bash
# config/settings.conf - Homelab
CRITICAL_SERVICES=(
    "ssh"
    "docker"                        # Conteneurs
    "nginx"                         # Serveur web
    "samba"                         # Partage de fichiers
)

PING_TARGETS=(
    "192.168.1.1"                   # Passerelle locale
    "8.8.8.8"                       # Google DNS
)
```

---

## 🪟 Spécificités WSL

### 💾 Surveillance des disques Windows

```bash
# La détection des disques Windows est automatique
# Pour exclure certains disques, modifier monitor_disk_space() :

monitor_disk_space() {
    # Exclure le disque D: par exemple
    df -P -h | grep -v "/mnt/d" | while read filesystem size used avail percent mount; do
        # ... logique de surveillance
    done
}
```

### 🔧 Services WSL-spécifiques

```bash
# config/settings.conf - WSL
CRITICAL_SERVICES=(
    "ssh"
    # Pas de systemd-networkd sous WSL1
    # "systemd-networkd"
)

# Adapter selon la version WSL
if grep -qi "microsoft" /proc/version; then
    # Configuration spécifique WSL
    NETWORK_INTERFACES=("eth0")
fi
```

---

## 🔄 Rechargement

### 🔄 Application des modifications

```bash
# Les fichiers de configuration sont rechargés à chaque exécution
./main.sh                          # Recharge automatique

# Pour tester une configuration :
./main.sh --dry-run                # Mode simulation (si implémenté)
```

### ✅ Validation de la configuration

```bash
# Vérifier la syntaxe bash
bash -n config/settings.conf
bash -n config/thresholds.conf

# Tester le sourcing
source config/settings.conf && echo "✅ settings.conf OK"
source config/thresholds.conf && echo "✅ thresholds.conf OK"
```

---

## 🛠️ Dépannage

### ❗ Erreurs courantes

| Erreur | Cause | Solution |
|---|---|---|
| `unbound variable` | Variable non définie | Vérifier la syntaxe des arrays : `VAR=("item1" "item2")` |
| `permission denied` | Droits insuffisants | `chmod +r config/*.conf` |
| `command not found` | Service inexistant | Adapter `CRITICAL_SERVICES` à votre distribution |

### 🔍 Débogage de la configuration

```bash
# Afficher les variables chargées
source config/settings.conf
echo "Services surveillés : ${CRITICAL_SERVICES[*]}"
echo "Interfaces réseau : ${NETWORK_INTERFACES[*]}"
echo "Cibles ping : ${PING_TARGETS[*]}"

# Vérifier les seuils
source config/thresholds.conf
echo "Seuil CPU critique : $CPU_CRITICAL_THRESHOLD%"
echo "Seuil mémoire : $MEMORY_WARNING_THRESHOLD%"
```

### 📝 Logs de configuration

```bash
# Les erreurs de configuration apparaissent dans :
tail -f logs/sysmonitor.log

# Rechercher les erreurs de configuration :
grep -i "config\|threshold\|setting" logs/sysmonitor.log
```

---

## 🎨 Configuration avancée

### 🎭 Profils multiples

```bash
# Créer des profils spécifiques
config/
├── settings.conf               # Défaut
├── settings-prod.conf          # Production
├── settings-dev.conf           # Développement
└── settings-homelab.conf       # Homelab

# Utilisation :
CONFIG_PROFILE="prod" ./main.sh
```

### 🔗 Configuration dynamique

```bash
# Dans settings.conf - détection automatique
if systemctl --version >/dev/null 2>&1; then
    CRITICAL_SERVICES+=("systemd-networkd")
fi

if command -v docker >/dev/null 2>&1; then
    CRITICAL_SERVICES+=("docker")
fi
```

---

<div align="center">

**⚙️ Configuration flexible pour tous les environnements**

![Configurable](https://img.shields.io/badge/Highly-Configurable-success?style=flat-square)

</div>

*** End of file
