const http = require('http');

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.end('Le serveur fonctionne !');
});

server.listen(3000, () => {
  console.log('Serveur en écoute sur http://localhost:3000');
});