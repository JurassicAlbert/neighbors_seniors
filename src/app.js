const express = require('express');
const neighborRoutes = require('./routes/neighbors');
const seniorRoutes = require('./routes/seniors');

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.json({
    name: 'Neighbors & Seniors',
    description: 'A community platform connecting neighbors with seniors',
    version: '1.0.0',
    endpoints: {
      neighbors: '/api/neighbors',
      seniors: '/api/seniors',
      health: '/health',
    },
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.use('/api/neighbors', neighborRoutes);
app.use('/api/seniors', seniorRoutes);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong' });
});

module.exports = app;
