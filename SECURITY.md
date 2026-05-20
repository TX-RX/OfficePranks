# Security Policy

These scripts execute on the machines of people who trust this repo. We take that seriously even though the payloads are jokes.

## What we consider a security issue

- A script does something the README does not document — anything beyond the stated prank behavior.
- A script establishes persistence outside the documented Scheduled Task / `%LOCALAPPDATA%\OfficePranks` footprint (e.g. registry Run keys, services, WMI subscriptions, startup folder, scheduled tasks under a different name).
- A script makes network calls to anything outside the published allowlist (currently `catfact.ninja` for the cat-fact API and `raw.githubusercontent.com` for installer downloads).
- A script reads, transmits, or persists data that is not strictly required for the prank — credentials, browser data, files, keystrokes, screen contents, clipboard contents, etc.
- A script attempts to disable, exclude, or evade endpoint protection (AV, Defender, EDR).
- A script requires or escalates to administrator privileges.
- A script obfuscates its payload (base64-encoded commands, downloaded-and-eval'd remote code outside the documented installer pattern, char-code reassembly, etc.).
- The CI validation workflow can be bypassed in a way that lets the above pass review.

## What is **not** a security issue

- Pranks that are louder, more annoying, or more frequent than you personally enjoy. Tune the parameters or use the uninstaller.
- The fact that the installer registers a hidden Scheduled Task. That is documented behavior and the whole point.
- The fact that the payload momentarily overrides system volume. That is also documented.

## How to report

**Do not open a public issue for security problems.** Instead:

- Open a private vulnerability report at [github.com/TX-RX/OfficePranks/security/advisories/new](https://github.com/TX-RX/OfficePranks/security/advisories/new), **or**
- Email the repository owner directly via the address on the [TX-RX GitHub profile](https://github.com/TX-RX).

Please include:

1. Which file and line(s) you're reporting.
2. What the script does that violates the policy above.
3. The minimum reproduction steps (PowerShell version, OS, command run).
4. Suggested fix if you have one.

## Response

We aim to:

- Acknowledge the report within **7 days**.
- Triage and respond with a remediation plan or rejection within **30 days**.
- Credit the reporter in the fix commit unless they ask to remain anonymous.

## Disclosure

We prefer coordinated disclosure: hold off on publishing details until a fix has shipped to `main`. If we go silent for more than 60 days after acknowledgment, you may publish.
