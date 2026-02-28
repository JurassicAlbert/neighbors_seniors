const request = require('supertest');
const app = require('../src/app');

describe('App', () => {
  describe('GET /', () => {
    it('should return application info', async () => {
      const res = await request(app).get('/');
      expect(res.status).toBe(200);
      expect(res.body.name).toBe('Neighbors & Seniors');
      expect(res.body.endpoints).toBeDefined();
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('ok');
      expect(res.body.uptime).toBeDefined();
    });
  });
});

describe('Neighbors API', () => {
  let createdId;

  it('GET /api/neighbors should return empty array initially', async () => {
    const res = await request(app).get('/api/neighbors');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/neighbors should create a neighbor', async () => {
    const res = await request(app)
      .post('/api/neighbors')
      .send({ name: 'Alice Johnson', email: 'alice@example.com', address: '123 Oak St', skills: ['cooking', 'gardening'] });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Alice Johnson');
    expect(res.body.id).toBeDefined();
    createdId = res.body.id;
  });

  it('POST /api/neighbors should reject missing fields', async () => {
    const res = await request(app).post('/api/neighbors').send({ name: 'Bob' });
    expect(res.status).toBe(400);
  });

  it('GET /api/neighbors/:id should return a specific neighbor', async () => {
    const res = await request(app).get(`/api/neighbors/${createdId}`);
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Alice Johnson');
  });

  it('GET /api/neighbors/:id should return 404 for unknown id', async () => {
    const res = await request(app).get('/api/neighbors/9999');
    expect(res.status).toBe(404);
  });

  it('DELETE /api/neighbors/:id should remove a neighbor', async () => {
    const res = await request(app).delete(`/api/neighbors/${createdId}`);
    expect(res.status).toBe(204);
  });
});

describe('Seniors API', () => {
  let createdId;

  it('GET /api/seniors should return empty array initially', async () => {
    const res = await request(app).get('/api/seniors');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/seniors should create a senior', async () => {
    const res = await request(app)
      .post('/api/seniors')
      .send({ name: 'Martha Williams', email: 'martha@example.com', address: '456 Elm St', needs: ['grocery shopping', 'lawn care'] });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Martha Williams');
    expect(res.body.id).toBeDefined();
    createdId = res.body.id;
  });

  it('POST /api/seniors should reject missing fields', async () => {
    const res = await request(app).post('/api/seniors').send({});
    expect(res.status).toBe(400);
  });

  it('GET /api/seniors/:id should return a specific senior', async () => {
    const res = await request(app).get(`/api/seniors/${createdId}`);
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Martha Williams');
  });

  it('DELETE /api/seniors/:id should remove a senior', async () => {
    const res = await request(app).delete(`/api/seniors/${createdId}`);
    expect(res.status).toBe(204);
  });
});
