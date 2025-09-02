const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const http = require('http');
const socketIO = require('socket.io');
require('dotenv').config();

const authRoutes = require('./src/routes/auth');
const vehicleRoutes = require('./src/routes/vehicles');
const adminRoutes = require('./src/routes/admin');
const userRoutes = require('./src/routes/users');
const settingsRoutes = require('./src/routes/settings');
const { initializeWebSocket } = require('./src/services/websocket');
const { errorHandler } = require('./src/middleware/errorHandler');
const { rateLimiter } = require('./src/middleware/rateLimiter');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: [
      'http://localhost:3000',
      'https://deepanshuvermaa.github.io',
      process.env.ADMIN_PANEL_URL || 'https://deepanshuvermaa.github.io/quickbill-admin'
    ],
    credentials: true
  }
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: [
    'http://localhost:3000',
    'https://deepanshuvermaa.github.io',
    process.env.ADMIN_PANEL_URL || 'https://deepanshuvermaa.github.io/quickbill-admin'
  ],
  credentials: true
}));
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

// Rate limiting
app.use('/api/', rateLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/settings', settingsRoutes);

// Initialize WebSocket
initializeWebSocket(io);

// Error handling middleware
app.use(errorHandler);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`🚀 ParkEase Backend running on port ${PORT}`);
  console.log(`📡 WebSocket server initialized`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});