# Pointe ton Bagay – blind shot 3D (Godot 4)

## À propos
Projet Godot 4 réalisé en 2e année d’informatique : un arena-shooter tour par tour mêlant phase de déplacement dans l’obscurité et phase de tir révélée. Le joueur affronte d'autres joueurs sur une plateforme qui rétrécit. 

## Fonctionnalités principales
- Possiblité de changer la langue du jeu (Français/Anglais)
- Mode solo configurable : 1 à 6 bots (`solo_setup.tscn`) avec trois niveaux de difficulté.
- Sélection du pseudo du personnage et de son skin (`character_select.tscn`).
- Jouable au clavier/souris ou à la manette
- Sauvegarde des scores automatique dans une base de données SQLite (`user://database.db`).
- Implémentation de musiques pour toujours plus de suspense.

## Structure du projet
- `Godot/` : cœur du jeu Godot 4.
  - `.godot/` : données d’éditeur (import/cache).
  - `scenes/` : toutes les scènes du jeu et des menus.
  - `scripts/` : logique GDScript (gameplay, UI, état global).
  - `assets/` : ressources visuelles/sons utilisées par les scènes.
  - `addons/` : plugins Godot, dont `godot-sqlite`.
  - `Database_sqlite/` : copie embarquée de la base SQLite distribuée avec le jeu.
  - `Exports/` : compilations du projet vers des exécutables pour chaque OS.
- `Database_sqlite/` : scripts et utilitaires Node pour préparer ou réinitialiser la base de données en dehors de Godot.

## OS prérequis afin de permettre l'exécution simple du jeu
- un des OS suivants: Windows, Linux

## Prérequis à la manipulation du code
- Godot 4.6 afin de visualiser la structure du code godot, les noeuds et scènes du jeu.
- VScode afin de visualiser le reste de la structure du projet, et de configurer la base de données
- Node.js afin de lancer la base de données en cas de tests

## Mise en route du jeu sur windows
C'est très simple: Ouvrir le bon exécutable correspondant à l'OS Windows depuis la racine du projet.

## Mise en route du jeu sur windows
Exécuter la commande ./Pointe-Ton-Bagay.x86_64 depuis le répertoire "Pointe-Ton-Bagay\Godot\Exports\For_Linux"

## Déroulement d’une partie
1. Menu d'accueil avec possibilité de consulter le score, changer les parametre, fermer le jeu, changer la langue ou continuer
2. Sélectionner le mode : le solo est prêt, le multijoueur n'est pas encore disponible
3. Régler le nombre et la difficulté des bots, puis choisir un personnage/couleur.
4. Pendant la manche :
   - **Phase sombre** (12 s) : déplacement, visée et placement sans visibilité ennemie.
   - **Phase lumière** : révélations, ordre de tir affiché, projectiles déclenchés après un court délai (0,8 s).
   - La plateforme et le temps pour se déplacer durant les phases sombres se réduisent à chaque manche.
5. En cas de mort, passage en mode spectateur avec suivi d’un survivant et option de quitter.
6. Fin de partie : écran récapitulatif de la game et enregistrement du score dans la base de données SQLite.

## Contrôles par défaut (modifiables depuis les paramètres)
- Déplacements : flèches directionnelles (gauche/droite/haut/bas) ou joystick gauche pour manette
- Se coucher : `C` ou bouton B manette xbox (`toggle_prone`).
- Pause : `Échap` ou bouton Start manette (`toggle_pause`).
- Souris / stick droit : visée et caméra, molette pour zoom caméra (dans `game.gd`).

## Concernant la base de données

- Table `Resultats` : `name`, `position`, `skin`, `difficulty_selected` (easy/normal/hard), `mode_selected`, `number_of_bots`.
- Les scores sont insérés via `enregistrer_score_bdd()` dans `scripts/game.gd` après chaque partie.
- Les données sont persistantes: lorsque vous rallumerez le jeu, les données de vos dernières parties seront conservées
- Réinitialiser la base de données : Depuis `Projet_pointe_ton_bagay\Base_de_donnees_projet`, lancer la commande node server.js dans un terminal, tout en ayant décommenté l'appel à la fonction delete_datas_from_database(), puis faire Ctrl+C

## Technologies utilisées
- Godot 4.6
- VsCode
- SQLite (avec l'addon Godot 4 de 2shady4u)
