const express = require('express');
const router = express.Router();

const seniors = [];
let nextId = 1;

router.get('/', (req, res) => {
  res.json(seniors);
});

router.get('/:id', (req, res) => {
  const senior = seniors.find((s) => s.id === parseInt(req.params.id));
  if (!senior) {
    return res.status(404).json({ error: 'Senior not found' });
  }
  res.json(senior);
});

router.post('/', (req, res) => {
  const { name, email, address, needs } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }
  const senior = { id: nextId++, name, email, address, needs: needs || [], createdAt: new Date().toISOString() };
  seniors.push(senior);
  res.status(201).json(senior);
});

router.delete('/:id', (req, res) => {
  const index = seniors.findIndex((s) => s.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ error: 'Senior not found' });
  }
  seniors.splice(index, 1);
  res.status(204).send();
});

module.exports = router;
