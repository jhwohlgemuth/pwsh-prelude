# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

## Reporting a Vulnerability

We take the security of pwsh-prelude seriously. If you believe you have found a security vulnerability, please report it to us as described below.

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to the repository maintainer or through GitHub's private vulnerability reporting feature.

Please include the following information in your report:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

This information will help us triage your report more quickly.

## Security Considerations

When using pwsh-prelude, please be aware of the following security considerations:

### Credential Handling

- Functions that accept credentials or tokens (e.g., `Invoke-WebRequestBasicAuth`, `New-GitlabRunner`) handle sensitive data
- Never hardcode credentials in scripts
- Use secure credential storage mechanisms (Windows Credential Manager, Secret Management modules, etc.)
- Be cautious when using `-Verbose` or logging, as sensitive data may be exposed

### Web Requests

- Always validate SSL/TLS certificates when making web requests
- Be cautious when using `-SkipCertificateChecks` parameter
- Sanitize and validate all user input before including it in web requests

### File Operations

- Functions that modify system files (e.g., `Update-HostsFile`) require elevated privileges
- Always validate file paths to prevent path traversal attacks
- Be cautious when executing downloaded content

### Code Execution

- Functions that use `Invoke-Expression` have been marked with appropriate suppressions
- Be extremely cautious when executing code from untrusted sources
- Always validate and sanitize input before using with `Invoke-Expression`

### GitLab Runner Registration

- `Register-GitlabRunner` creates Docker containers with elevated permissions
- Only register runners on trusted infrastructure
- Regularly rotate runner tokens
- Monitor runner activity for suspicious behavior

## Preferred Languages

We prefer all communications to be in English.

## Policy Updates

This security policy may be updated from time to time. Please check back regularly for any changes.
