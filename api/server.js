require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');
const postRoutes = require('./routes/posts');
const feedRoutes = require('./routes/feed');
const userRoutes = require('./routes/users');
const dmRoutes = require('./routes/dms');
const notificationRoutes = require('./routes/notifications');
const searchRoutes = require('./routes/search');
const setupSocket = require('./socket');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.CLIENT_URL || '*',
    methods: ['GET', 'POST'],
  },
});

app.set('io', io);
setupSocket(io);

// Middleware
app.use(cors({ origin: process.env.CLIENT_URL || '*' }));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

const strictLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
});

// Routes
app.use('/auth', strictLimiter, authRoutes);
app.use('/posts', postRoutes);
app.use('/feed', feedRoutes);
app.use('/users', userRoutes);
app.use('/dms', dmRoutes);
app.use('/notifications', notificationRoutes);
app.use('/search', searchRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok', app: 'June API' }));

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`June API running on port ${PORT}`);
});
