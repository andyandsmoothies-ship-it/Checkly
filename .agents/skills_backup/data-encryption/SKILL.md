---
name: data-encryption
description: >
  Implement strong encryption using AES, RSA, TLS, and proper key management.
  Use when securing data at rest, in transit, or implementing end-to-end
  encryption.
---

# Data Encryption

## When to Use

- Sensitive data storage
- Database encryption
- File encryption
- Communication security
- Compliance requirements (GDPR, HIPAA, PCI-DSS)
- Password storage
- End-to-end encryption

## Quick Start

Minimal working example:

```javascript
// encryption-service.js
const crypto = require("crypto");
const fs = require("fs").promises;

class EncryptionService {
  constructor() {
    // AES-256-GCM for symmetric encryption
    this.algorithm = "aes-256-gcm";
    this.keyLength = 32; // 256 bits
    this.ivLength = 16; // 128 bits
    this.saltLength = 64;
    this.tagLength = 16;
  }

  /**
   * Generate a cryptographically secure random key
   */
  generateKey() {
    return crypto.randomBytes(this.keyLength);
  }

  /**
   * Derive a key from a password using PBKDF2
   */
  async deriveKey(password, salt = null) {
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Node.js Encryption Library](references/nodejs-encryption-library.md) | Node.js Encryption Library |
| [Python Cryptography Implementation](references/python-cryptography-implementation.md) | Python Cryptography Implementation |
| [Database Encryption (PostgreSQL)](references/database-encryption-postgresql.md) | Database Encryption (PostgreSQL) |
| [TLS/SSL Configuration](references/tlsssl-configuration.md) | TLS/SSL Configuration |
