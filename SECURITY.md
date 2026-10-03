# Security policy

## Reporting a vulnerability

Please report security issues privately. Do not open a public GitHub issue.

Use GitHub's **private vulnerability reporting**: navigate to the Security tab of this repository and click **Report a vulnerability**. This routes the report directly to the maintainers without making it public.
Direct link: [Security tab](https://github.com/Obviously-Not/concept-scanner-public/security).

## Scope

concept-scanner is a local-first command-line tool that reads source code on your machine and sends it to a locally running Ollama instance. Reports in scope include:

- Vulnerabilities in the scan pipeline that could leak source code to a non-local destination
- Path traversal, symlink escape, or zip-bomb vulnerabilities in repository validation
- Vulnerabilities in the audit-log or output-sanitization code paths
- Vulnerabilities in `concept-scanner update`, which replaces the running binary: any way to make it install a file that is not a signed release, to install without the user's confirmation, or to leave a copy half-replaced; and any way to make a scan check for a release without the person's yes (that check is off unless they turn it on, and the setting lives in their home folder, out of reach of a repository being scanned)
- Vulnerabilities in the install scripts (`install.sh`, `install.ps1`): any way to make them install a file that does not match the release's checksums, write outside the user's home folder (beyond a temporary download folder they remove), ask for administrator rights, or change a shell startup file or the user's PATH in a way `--uninstall` does not undo
- Dependency vulnerabilities that materially affect the above

Out of scope:

- Issues in third-party services this tool can be configured to talk to (Ollama itself; cloud providers — not supported in the public build)
- Social-engineering or physical-access attacks
- Theoretical issues without a reproducer

## What to expect

We will acknowledge a valid report within 5 business days and provide a remediation plan within 14 days for in-scope issues. Disclosure timing is coordinated with the reporter.
