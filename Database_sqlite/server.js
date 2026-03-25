const http = require('http');
const path = require('path');
const fs = require('fs');
const os = require('os');
const sqlite3 = require('sqlite3').verbose();

// Chemin user:// utilisé par Godot (voir config/name dans project.godot).
const APP_USER_PATH = path.join(
  process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming'),
  'Godot',
  'app_userdata',
  'Pointe ton Bagay',
  'database.db'
);

// Copie packagée dans le projet Godot (exportée avec l'exe).
const PACKAGED_PATH = path.resolve(__dirname, '..', 'Godot', 'Database_sqlite', 'database.db');

// Prépare un fichier R/W pour le serveur, identique à celui du jeu.
if (!fs.existsSync(APP_USER_PATH)) {
  fs.mkdirSync(path.dirname(APP_USER_PATH), { recursive: true });
  if (fs.existsSync(PACKAGED_PATH)) {
    fs.copyFileSync(PACKAGED_PATH, APP_USER_PATH);
  }
}

const dbPath = fs.existsSync(APP_USER_PATH) ? APP_USER_PATH : PACKAGED_PATH;
console.log(`Base utilisée : ${dbPath}`);

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.end('Le serveur fonctionne !');
});

server.listen(3000, () => {
  console.log('Serveur en écoute sur http://localhost:3000');
});

const db = new sqlite3.Database(dbPath);
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS Resultats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    position INT,
    skin VARCHAR(30),
    difficulty_selected TEXT CHECK (difficulty_selected IN ('easy', 'normal', 'hard')),
    mode_selected TEXT CHECK (mode_selected IN ('solo', 'multiplayer', 'difficile')),
    number_of_bots INT
  )`);
  show_database();
});

//pour lancer le serveur: à la racine du fichier Database_sqlite, exécuter la commande node server.js

function show_database() {
  db.all('SELECT * FROM Resultats', (err, rows) => {
    if (err) {
      console.error('Erreur SELECT :', err.message);
      return;
    }
    if (!rows || rows.length === 0) {
      console.log('Table Resultats vide.');
      return;
    }
    console.log('Contenu de Resultats :');
    rows.forEach((row, idx) => {
      console.log(`#${idx + 1}:`, JSON.stringify(row, null, 2));
    });
  });
}

function delete_datas_from_database() {
  db.run('DELETE FROM Resultats', (err) => {
    if (err) {
      console.error('Erreur lors de la suppression :', err.message);
    } else {
      console.log("Toutes les données de la table 'Resultats' ont été supprimées.");
    }
  });
}

//pour supprimer le contenu de la table: décomenter la ligne du dessous
//delete_datas_from_database()
