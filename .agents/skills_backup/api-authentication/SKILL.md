---
name: api-authentication
description: >
  Implement secure API authentication with JWT, OAuth 2.0, API keys, and session
  management. Use when securing APIs, managing tokens, or implementing user
  authentication flows.
---

# API Authentication

> [!NOTE]
> **Related skills:** For ASP.NET Core JWT/Identity/OIDC, see `aspnetcore-authentication`. This skill covers language-agnostic authentication patterns (Node.js, Python).

## When to Use

- Securing API endpoints
- Implementing user login/logout flows
- Managing access tokens and refresh tokens
- Integrating OAuth 2.0 providers
- Protecting sensitive data
- Implementing API key authentication

## Quick Start

Minimal working example:

```javascript
// Node.js JWT Implementation
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const app = express();
const SECRET_KEY = process.env.JWT_SECRET || 'your-secret-key';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'your-refresh-secret';

// User login endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user in database
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [JWT Authentication](references/jwt-authentication.md) | JWT Authentication |
| [OAuth 2.0 Implementation](references/oauth-20-implementation.md) | OAuth 2.0 Implementation |
| [API Key Authentication](references/api-key-authentication.md) | API Key Authentication |
| [Python Authentication Implementation](references/python-authentication-implementation.md) | Python Authentication Implementation |
