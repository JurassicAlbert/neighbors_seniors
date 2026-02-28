const express = require('express');
const router = express.Router();

const neighbors = [];
let nextId = 1;

router.get('/', (req, res) => {
  res.json(neighbors);
});

router.get('/:id', (req, res) => {
  const neighbor = neighbors.find((n) => n.id === parseInt(req.params.id));
  if (!neighbor) {
    return res.status(404).json({ error: 'Neighbor not found' });
  }
  res.json(neighbor);
});

router.post('/', (req, res) => {
  const { name, email, address, skills } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }
  const neighbor = { id: nextId++, name, email, address, skills: skills || [], createdAt: new Date().toISOString() };
  neighbors.push(neighbor);
  res.status(201).json(neighbor);
});

router.delete('/:id', (req, res) => {
  const index = neighbors.findIndex((n) => n.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ error: 'Neighbor not found' });
  }
  neighbors.splice(index, 1);
  res.status(204).send();
});

module.exports = router;
