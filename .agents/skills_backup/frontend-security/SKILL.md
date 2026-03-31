---
name: frontend-security
description: >
  Comprehensive frontend security covering XSS prevention, DOM sanitization,
  Content Security Policy (CSP), input validation, clickjacking protection,
  secure redirects, authentication token management, and browser security features
  (SRI, Trusted Types, Feature Policy). Includes framework-specific patterns for
  React, Vue, Angular, and vanilla JS. Use for XSS scanning, CSP configuration,
  secure DOM manipulation, frontend security code reviews, or client-side
  vulnerability assessment. Use PROACTIVELY for any frontend security work.
---

# Frontend Security

Secure frontend code against client-side attacks through defense-in-depth: safe DOM manipulation, CSP, input validation, and modern browser security features.

## When to Use

- Implementing XSS prevention or sanitizing user-generated content
- Configuring Content Security Policy headers
- Building secure forms with client-side validation
- Reviewing frontend code for security vulnerabilities
- Implementing clickjacking protection or secure redirects
- Managing authentication tokens (JWT storage, session management)
- Integrating third-party scripts securely

## Do Not Use When

- Backend-only security (use `security-scan` instead)
- Compliance auditing (use `security-scan` with compliance mode)
- Architecture-level threat modeling (use `security-scan`)

## Core Patterns

### XSS Prevention

```typescript
// ❌ UNSAFE — user input in innerHTML
element.innerHTML = userInput;

// ✅ SAFE — textContent for plain text
element.textContent = userInput;

// ✅ SAFE — DOMPurify for HTML content
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

### Framework-Specific

| Framework | Dangerous Pattern | Safe Alternative |
|-----------|-------------------|-----------------|
| React | `dangerouslySetInnerHTML` | `DOMPurify.sanitize()` before use |
| Vue | `v-html` | `v-text` or sanitize input |
| Angular | `bypassSecurityTrust*` | Use built-in sanitization |
| Vanilla JS | `innerHTML`, `document.write` | `textContent`, `createElement` |

### URL Validation

```typescript
function sanitizeURL(url: string): string {
  try {
    const parsed = new URL(url);
    if (['http:', 'https:'].includes(parsed.protocol)) {
      return parsed.href;
    }
  } catch {}
  return '#'; // Safe fallback
}
```

### Content Security Policy

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'nonce-{random}';
  img-src 'self' data: https:;
  frame-ancestors 'self';
  report-uri /csp-report;
```

### Secure Token Storage

| Method | Security | Use Case |
|--------|----------|----------|
| HttpOnly cookie | ✅ Best | Server-rendered apps |
| `sessionStorage` | ⚠️ OK | SPA with short sessions |
| `localStorage` | ❌ Avoid | Vulnerable to XSS |
| In-memory variable | ✅ Good | SPA with refresh token flow |

## Prevention Checklist

- [ ] All dynamic content uses `textContent` or is sanitized with DOMPurify
- [ ] No `innerHTML` with user input without sanitization
- [ ] CSP headers configured (at minimum `script-src 'self'`)
- [ ] All URLs validated before navigation/redirect
- [ ] `rel="noopener noreferrer"` on external links
- [ ] Subresource Integrity (SRI) on CDN resources
- [ ] No `eval()`, `Function()`, or string-to-code patterns
- [ ] Event listeners use `addEventListener`, not inline handlers
- [ ] Authentication tokens stored securely (not in `localStorage`)
- [ ] Frame protection via `X-Frame-Options` or CSP `frame-ancestors`
