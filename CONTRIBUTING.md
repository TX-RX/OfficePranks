# Contributing to OfficePranks

Pull requests welcome. This document explains the rules that contributions must follow and how CI enforces them.

## The five rules

Every prank in this repo must satisfy all of the following. CI checks each rule mechanically where possible; reviewers check the rest.

### 1. Harmless and fully reversible

- A target user must be able to fully remove your prank with one command (or by running your `Uninstall-*.ps1` script).
- The prank must not modify any file the user owns, alter system settings beyond what is restored by the uninstaller, or leave behind state outside `%LOCALAPPDATA%\OfficePranks` and a single named Scheduled Task.
- Volume overrides, speech output, popup dialogs, mouse wiggles — fine. Wallpaper changes, browser homepage hijacks, file renames, registry edits — not fine without an uninstaller that restores the prior state byte-for-byte.

### 2. No exfiltration

- The prank may not transmit anything from the victim's machine to a network endpoint beyond:
  - The fact/joke/quote APIs already on the allowlist (`catfact.ninja`).
  - `raw.githubusercontent.com/TX-RX/OfficePranks/...` for installer downloads.
- If your prank needs a new public API, propose it in your PR and update the allowlist in `.github/scripts/Validate-Pranks.ps1`. Maintainers will weigh whether to extend the allowlist.
- No credentials, no browser data, no clipboard contents, no keystrokes, no files, no screenshots, no telemetry. Ever.

### 3. No privilege escalation

- The script must work end-to-end in a standard, non-administrator user context.
- No `Start-Process -Verb RunAs`, no UAC prompts, no scheduled tasks running as `SYSTEM`, no service installs.

### 4. No detection evasion beyond `-WindowStyle Hidden`

- A hidden PowerShell window for the scheduled action is fine.
- Disabling or excluding from Defender / AV / EDR is forbidden. Adding Defender exclusion paths is forbidden.
- Base64-encoded commands (`-EncodedCommand`, `FromBase64String`) are forbidden. If a reviewer cannot read the payload at a glance, it doesn't belong here.
- Downloading and evaluating remote code outside the documented `iex (irm .../Install-*.ps1)` installer pattern is forbidden.

### 5. Paired install/uninstall + README updates

- Every new payload `<Name>.ps1` must ship with `Install-<Name>.ps1` and `Uninstall-<Name>.ps1`.
- The installer must register a single Scheduled Task under a uniquely-named `OfficePranks-<Name>` key. No registry Run keys, no services, no startup-folder shortcuts.
- Update `README.md` with a row in the Contents table and a quick-install one-liner that points at the new installer URL.

## Local validation

Before opening a PR, run the validator locally:

```powershell
.\.github\scripts\Validate-Pranks.ps1
```

The same script runs in CI on every PR. It checks:

- PowerShell parse errors in every `.ps1` file.
- [PSScriptAnalyzer](https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/overview) findings at `Error` severity (warnings are advisory).
- Paired `Install-<X>.ps1` / `Uninstall-<X>.ps1` for any new payload.
- Denylist of malicious patterns — see the script for the full list, but in summary: AV tampering, encoded commands, process injection, persistence outside Scheduled Tasks, network calls to non-allowlisted hosts, and credential harvesting.
- That `README.md` was updated when a new top-level `.ps1` is added.

Validator failures must be resolved before a PR is mergeable.

## PR process

1. Fork or branch (`feat/<name>`, `fix/<thing>`, `docs/<topic>`, etc.).
2. Make your change and run the validator.
3. Open a PR using the [pull request template](.github/PULL_REQUEST_TEMPLATE.md) — fill in every checkbox honestly.
4. Address review feedback. Maintainers will not merge anything that fails CI or skips checklist items.

## Commit messages

Keep them descriptive. Imperative mood, first line under ~72 characters, body explains *why* when the change isn't self-evident. See the existing `git log` for the style.

## Code style

- Two-space indentation.
- One blank line between logical blocks.
- Comments explain *why*, not *what* — let identifiers carry the meaning.
- Cmdlet names spelled out (`Invoke-WebRequest`, not `iwr`) in committed scripts. Aliases are OK in README one-liners where compactness matters.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
