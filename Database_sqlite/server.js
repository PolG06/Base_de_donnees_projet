const http = require('http');

const sqlite3 = require('sqlite3').verbose();

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.end('Le serveur fonctionne !');
});

server.listen(3000, () => {
  console.log('Serveur en écoute sur http://localhost:3000');
});

//création du fichier de la base de données
const db = new sqlite3.Database('./database.db');
//Création de la table Resultats
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
});

//pour lancer le serveur: à la racine du fichier Database_sqlite, exécuter la commande node server.js

function show_database (){
  db.each("SELECT * FROM Resultats", (err, row) => {
    if (err) {
        console.error(err.message);
    } else {
        // Affiche la ligne entière formatée
        console.log("Ligne trouvée :", JSON.stringify(row, null, 2));
    }
  });
};

function delete_datas_from_database (){
  db.run("DELETE FROM Resultats", (err) => {
    if (err) {
        console.error("Erreur lors de la suppression :", err.message);
    } else {
        console.log("Toutes les données de la table 'Resultats' ont été supprimées.");
    }
  });
};

//pour supprimer le contenu de la table: 
//delete_datas_from_database()

//Pour afficher les données
//show_database()