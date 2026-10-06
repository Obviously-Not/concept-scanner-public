# Security policy

## Reporting a vulnerability

Please report security issues privately. Do not open a public GitHub issue.

Use GitHub's **private vulnerability reporting**: navigate to the Security tab of this repository and click **Report a vulnerability**. This routes the report directly to the maintainers without making it public.
Direct link: [Security tab](https://github.com/Obviously-Not/concept-scanner-public/security).

## Scope

concept-scanner is a local-first command-line tool, with a window over the same commands, that reads source code on your machine and sends it to a locally running Ollama instance by default, or to a remote OpenAI-compatible provider only when you choose one. Reports in scope include:

- Vulnerabilities in the scan pipeline that could leak source code to a non-local destination
- Path traversal, symlink escape, or zip-bomb vulnerabilities in repository validation
- Vulnerabilities in the audit-log or output-sanitization code paths
- Vulnerabilities in `concept-scanner update`, which replaces the running binary or the Mac app: any way to make it install a file that is not a signed release, to install without the user's confirmation, or to leave a copy half-replaced; and any way to make a scan check for a release without the person's yes (that check is off unless they turn it on, and the setting lives in their home folder, out of reach of a repository being scanned)
- Vulnerabilities in the window (`concept-scanner ui`, the Mac app, and the Windows install), a server on `127.0.0.1` that runs this program's own commands: any way for a web page, another program, or another account on the same computer to make it run a command without the secret it gives the page it opens; any way to make it run something other than one of this program's own commands; any way to reach it from another computer; and any request that changes something on a GET
- Vulnerabilities in the saved keys (`~/.concept-scanner/credentials.json`, readable by its owner only): any way for a repository being scanned to read a saved key, choose which key is used or where it is sent, or make a key appear in output, a log, a command line, or another process's environment
- Vulnerabilities in the install scripts (`install.sh`, `install.ps1`): any way to make them install a file that does not match the release's checksums, write outside the user's home folder (beyond a temporary download folder they remove), ask for administrator rights, or change a shell startup file or the user's PATH in a way `--uninstall` does not undo
- Dependency vulnerabilities that materially affect the above

Out of scope:

- Issues in third-party services this tool can be configured to talk to (Ollama itself, or a remote provider you choose)
- Social-engineering or physical-access attacks
- Theoretical issues without a reproducer

## What to expect

We will acknowledge a valid report within 5 business days and provide a remediation plan within 14 days for in-scope issues. Disclosure timing is coordinated with the reporter.
