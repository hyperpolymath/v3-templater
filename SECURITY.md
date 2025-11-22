# Security Policy

## Supported Versions

We release patches for security vulnerabilities according to the following schedule:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

### Preferred: Security Advisory

Create a private security advisory on GitHub:
https://github.com/Hyperpolymath/v3-templater/security/advisories/new

### Email

Send an email to: security@hyperpolymath.dev

Include the following information:
- Type of vulnerability (XSS, code injection, etc.)
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact assessment (what an attacker could do)

## Response Timeline

- **Initial Response**: Within 48 hours
- **Severity Assessment**: Within 7 days
- **Fix Timeline**:
  - Critical: 7-14 days
  - High: 14-30 days
  - Medium: 30-60 days
  - Low: 60-90 days

## Disclosure Policy

- Security advisories will be published after a fix is available
- We follow coordinated disclosure practices
- Credit will be given to security researchers who report responsibly

## Security Considerations in v3-templater

### Built-in Protections

1. **XSS Prevention**: Auto-escaping enabled by default
2. **Code Injection**: No eval() or Function() usage
3. **Template Injection**: Sandboxed expression evaluation
4. **Dependency Security**: Minimal dependencies (only 1 production dep)

### Security Best Practices

When using v3-templater:

✅ **DO:**
- Keep auto-escaping enabled (default)
- Use strict mode in development
- Validate all user input before templating
- Use the `safe` filter only for trusted content
- Keep dependencies updated (`npm audit`)

❌ **DON'T:**
- Disable auto-escaping globally
- Pass unsanitized user input directly to templates
- Use `safe` filter on user-provided content
- Trust template strings from untrusted sources

## Known Security Limitations

### Current Version (1.0.0)

1. **Filter Sandboxing**: Filters run in the same process context
   - Mitigation: Only use trusted filters
   - Future: Worker thread isolation (v1.2.0)

2. **Template Complexity**: No limits on template complexity
   - Mitigation: Set timeouts at application level
   - Future: Configurable execution limits (v1.1.0)

3. **Memory Usage**: Large templates can consume significant memory
   - Mitigation: Implement size limits in your application
   - Future: Streaming rendering (v1.3.0)

## Security Audit History

- **v1.0.0** (2024-01-15): Initial release, no external audits yet
- Planned: Third-party security audit in Q2 2025

## Bug Bounty

Currently, we do not have a formal bug bounty program. However:
- Security researchers will be credited in release notes
- Significant findings may receive acknowledgment in SECURITY.md
- We appreciate responsible disclosure

## Security Contacts

- **Security Lead**: See MAINTAINERS.md
- **Email**: security@hyperpolymath.dev
- **PGP Key**: Available at .well-known/security.txt

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Template Security Best Practices](docs/SECURITY-GUIDE.md) *(planned)*
- [Security.txt Specification (RFC 9116)](https://securitytxt.org/)
