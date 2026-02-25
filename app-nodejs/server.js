const http = require('http');

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('App 3: Node.js Backend is Live!\n');
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});