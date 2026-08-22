require('dotenv').config();

const app = require('./app');
const http = require('http');
const { Server } = require('socket.io');
const socketHandler = require('./sockets');
const { socketCors } = require('./config/cors');

const PORT = process.env.PORT || 5001;

const server = http.createServer(app);

// Socket.IO setup
const io = new Server(server, {
  cors: socketCors,
});

// Initialize socket handlers
socketHandler(io);

// Handle port already in use error
server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use.`);
    console.log(`💡 Try using a different port or kill the process using: lsof -i :${PORT}`);
    process.exit(1);
  } else {
    console.error('Server error:', error);
    process.exit(1);
  }
});

server.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 API URL: http://localhost:${PORT}/api`);
  console.log(`🔌 Socket URL: ws://localhost:${PORT}`);
});