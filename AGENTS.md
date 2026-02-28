# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Neighbors & Seniors is a Node.js/Express REST API that connects neighbors with seniors in their community. The server runs on port 3000 by default (configurable via `PORT` env var). Data is stored in-memory (no database required).

### Quick reference

| Task | Command |
|------|---------|
| Install deps | `npm install` |
| Dev server (with watch) | `npm run dev` |
| Start server | `npm start` |
| Run tests | `npm test` |
| Run tests (watch) | `npm run test:watch` |
| Lint | `npm run lint` |
| Lint + fix | `npm run lint:fix` |

### Notes

- The dev server uses Node's built-in `--watch` flag for automatic restarts on file changes.
- ESLint uses flat config format (`eslint.config.mjs`).
- Tests use Jest + supertest and run against the Express app directly (no server startup needed).
- No external services (databases, caches, etc.) are required — all data is in-memory.
