# Montre multimode sur FPGA (Horloge / Chronomètre / Alarme)

Projet personnel de montre « multimode » implémentée sur FPGA (carte DE1 Cyclone II) avec un processeur **Nios II**
et deux **composants personnalisés Avalon-MM** :

- `CHRONO`     : chronomètre matériel,
- `ALARM_BELL` : gestion de la sonnerie d'alarme sous forme de chenillard de LEDs.

L’application affiche l’heure, un chronomètre ou un mode alarme sur les 4 afficheurs 7 segments de la carte,
et utilise un chenillard de LEDs lorsque l’alarme se déclenche.

> ℹ️ Dans le code et certains noms de signaux, le terme *minuterie* reste utilisé, mais le comportement
> est celui d’une **alarme à heure programmée** (comparaison avec l’horloge) plutôt qu’un simple compte à rebours.

---

## 🎯 Objectifs du projet

- Concevoir une **architecture complète FPGA + Nios II** pour une montre à trois modes :
  - Horloge (HH:MM),
  - Chronomètre,
  - Alarme (heure de réveil / de déclenchement).
- Mettre en œuvre un **co-design matériel / logiciel** :
  - partie temps réel déportée dans des IP VHDL (`CHRONO`, `ALARM_BELL`),
  - logique de haut niveau en C embarqué (HAL Nios II).
- Utiliser un **interval timer** avec interruption comme base de temps à 1 Hz.
- Gérer l’interface utilisateur via les **KEY (sur interruptions)** et les **SW** de la carte
  (changement de mode, réglage, démarrage/arrêt, programmation de l’alarme).

---

## 🧱 Architecture globale

### Matériel (FPGA)

- Carte : **DE1 Cyclone II**.
- Processeur : **Nios II** (système construit avec Platform Designer / Qsys).
- Périphériques principaux :
  - `timer_0`  : Interval Timer configuré pour générer une interruption toutes les 1 s,
  - `KEYS`     : entrée des boutons poussoirs (KEY0..KEY3) reliés à un PIO avec interruptions,
  - `switches` : entrée des interrupteurs SW (programmation de l’heure / de l’alarme),
  - `LEDG`     : LEDs vertes (indication du mode courant : horloge / chrono / alarme),
  - `LEDR`     : LEDs rouges (chenillard géré par `ALARM_BELL`),
  - `HEXS`     : sortie vers les 4 afficheurs 7 segments (affichage HH:MM).

Les KEYs sont configurées pour lever des interruptions, avec une priorité inférieure à celle du timer,
de façon à garantir la stabilité de la base de temps (le timer reste prioritaire).

### IP personnalisés Avalon-MM

- **CHRONO (Custom Component)**  
  - Compteur matériel de type chronomètre (secondes / minutes),
  - Contrôle via registres mémoire-mappés :
    - démarrage / arrêt,
    - remise à zéro,
  - Synchronisation sur un tick à 1 Hz (piloté par le logiciel).

- **ALARM_BELL (Custom Component)**  
  - Gestion de l’**alarme** via un **chenillard** de LEDs lorsque l’heure programmée est atteinte,
  - Entrées/sorties :
    - registre d’activation / désactivation depuis le Nios II,
    - sorties vers les LEDs rouges `LEDR`,
  - Le chenillard reste actif jusqu’à appui sur KEY3.

Les fichiers VHDL se trouvent dans le dossier `src/` :

- `FDIV.vhd`  
- `CHRONO.vhd`  
- `SEVEN_SEG.vhd`  
- `TOP_LEVEL.vhd`  
- `ALARM_BELL.vhd`  
- `bcd_counter.vhd`  
- `CHRONO_avalon_interface.vhd`  
- `ALARM_BELL_avalon_interface.vhd`  

---

## 🧠 Architecture logicielle (Nios II)

Code C embarqué : voir `software/watch.c` et `software/watch.h`.

### Principes généraux

- **Initialisation** :
  - configuration de l’**interval timer** (période = 1 s),
  - enregistrement du handler d’interruption du timer via `alt_irq_register`,
  - enregistrement du handler d’interruption des KEYs,
  - initialisation de la structure d’horloge et du mode courant (horloge par défaut),
  - mise à zéro des IP `CHRONO` et `ALARM_BELL`.

- **ISR du timer** (toutes les 1 s) :
  - incrément de la structure d’horloge (heures / minutes / secondes),
  - mise à jour du chronomètre si le mode chrono est actif (pilotage de l’IP `CHRONO`),
  - vérification de l’alarme : comparaison entre l’heure courante et l’heure programmée,
  - rafraîchissement des valeurs affichées sur les afficheurs 7 segments.

- **ISR des KEYs** :
  - changement de mode (horloge / chrono / alarme),
  - démarrage / arrêt du chronomètre,
  - reset du chronomètre,
  - validation de la programmation de l’alarme,
  - arrêt de l’alarme / du chenillard.

- **Boucle principale** :
  - lecture des **SW** pour la configuration (réglage de l’heure, heure d’alarme),
  - gestion de la machine d’états de la montre :
    - mode horloge,
    - mode chrono,
    - mode alarme (programmation + attente déclenchement),
  - écriture dans les registres de contrôle des IP personnalisées (`CHRONO`, `ALARM_BELL`),
  - mise à jour des LEDs vertes `LEDG` pour refléter le mode actif.

---

## 🕹 Modes de fonctionnement

### Horloge (mode par défaut)

- Affichage **HH:MM** basé sur le tick 1 Hz du timer,
- Possibilité de régler heures et minutes via les SWITCH (lecture en tâche de fond) + `KEY3` de validation,
- LED verte `LEDG0` allumée pour indiquer le mode horloge,
- L’horloge continue de tourner en permanence, même lorsqu’on bascule en mode chrono ou alarme.

### Chronomètre

- La `KEY1` de mode permet de basculer en mode chronomètre,
- LED verte `LEDG1` allumée pour indiquer ce mode,
- Démarrage / arrêt via la touche `KEY2`,
- Remise à zéro via la touche `KEY3`,
- Le comptage (secondes / minutes) est pris en charge par l’IP **CHRONO**, contrôlée via registres Avalon-MM.

### Alarme (ancienne “minuterie”)

- La touche `KEY1` de mode permet de basculer en mode alarme,
- LED verte `LEDG2` allumée pour indiquer ce mode,
- Dans ce mode, l’utilisateur programme une **heure de déclenchement** (HH:MM) via les SWITCH,
- La validation de l’alarme se fait via la touche `KEY2`,
- Quand l’horloge atteint l’instant programmé, le logiciel active l’IP **ALARM_BELL**,
- `ALARM_BELL` déclenche un **chenillard** sur les LEDs rouges `LEDR`,
- Le chenillard reste actif tant que l’utilisateur n’appuie pas sur la touche `KEY3`.

---

## 🛠 Outils & environnement

- **Intel Quartus Prime** (version 13.0sp1 dans ce projet),
- **Platform Designer / Qsys** pour la construction du système Nios II,
- **Nios II EDS** (SBT for Eclipse, ou Altera Monitor Program) pour la partie C/HAL,
- **ModelSim** pour la simulation VHDL,
- Carte **DE1 Cyclone II**.

---

## ⚙️ Mise en route

### 1. Synthèse FPGA

1. Ouvrir le projet Quartus dans le dossier `fit/`.
2. Vérifier que la carte cible est bien **DE1**.
3. Lancer :
   - `Analysis & Synthesis`,
   - puis `Fitter`,
   - puis `Program Device`,
   - puis `Assembler(Generate programming files)`,
   - enfin `TimeQuest Timing Analysis`,
   - ou cliquer simplement sur `Start Compilation`
4. Programmer la carte avec le fichier `.sof` généré.

### 2. Génération / build du logiciel Nios II

1. Ouvrir Nios II Software Build Tools (ou Eclipse Nios II EDS / Altera Monitor Program).
2. Créer une **BSP** à partir du fichier `nios_system.sopcinfo`.
3. Créer un projet d’application C et y ajouter :
   - `software/watch.c`,
   - `software/watch.h`.
4. Régénérer la BSP si nécessaire.
5. Compiler le projet, puis télécharger le `.elf` sur la carte DE1.

---

## 📂 Organisation du dépôt

```text
src/       # IP personnalisées et logique VHDL (CHRONO, ALARM_BELL, bcd, afficheurs…)
fit/       # Projet Quartus + Qsys (Nios II, timer, PIO…)
software/  # Code C embarqué (HAL Nios II) pour la montre
simu/      # (Optionnel) Testbenches & scripts ModelSim
