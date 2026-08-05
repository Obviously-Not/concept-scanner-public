# Security policy

## Reporting a vulnerability

Please report security issues privately. Do not open a public GitHub issue.

Use GitHub's **private vulnerability reporting**: navigate to the [Security tab](https://github.com/Obviously-Not/concept-scanner/security) of this repository and click **Report a vulnerability**. This routes the report directly to the maintainers without making it public.

## Scope

concept-scanner is a local-first command-line tool that reads source code on your machine and sends it to a locally running Ollama instance. Reports in scope include:

- Vulnerabilities in the scan pipeline that could leak source code to a non-local destination
- Path traversal, symlink escape, or zip-bomb vulnerabilities in repository validation
- Vulnerabilities in the audit-log or output-sanitization code paths
- Dependency vulnerabilities that materially affect the above

Out of scope:

- Issues in third-party services this tool can be configured to talk to (Ollama itself; cloud providers — not supported in the public build)
- Social-engineering or physical-access attacks
- Theoretical issues without a reproducer

## What to expect

We will acknowledge a valid report within 5 business days and provide a remediation plan within 14 days for in-scope issues. Disclosure timing is coordinated with the reporter.
