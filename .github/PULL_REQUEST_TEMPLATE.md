<!--
Thanks for contributing! Please fill out every checkbox honestly.
Maintainers will not merge anything that fails CI or skips items here.
The rules are documented in CONTRIBUTING.md.
-->

## Summary

<!-- One or two sentences. What does this PR do, and why? -->

## Type of change

- [ ] New prank payload
- [ ] Improvement to an existing prank
- [ ] Documentation
- [ ] CI / tooling
- [ ] Bug fix

## Contribution rules checklist

- [ ] **Harmless and fully reversible.** Includes a one-step uninstall path that fully restores prior state.
- [ ] **No exfiltration.** Network calls hit only allowlisted hosts (`catfact.ninja`, `raw.githubusercontent.com/TX-RX/...`). New endpoints are justified and added to the validator allowlist in this PR.
- [ ] **No privilege escalation.** Runs end-to-end in a standard user context. No UAC, no `SYSTEM`, no service installs.
- [ ] **No detection evasion** beyond `-WindowStyle Hidden`. No encoded commands, no AV/EDR tampering, no remote code execution outside the documented installer pattern.
- [ ] **Paired install/uninstall.** New `<Name>.ps1` ships with `Install-<Name>.ps1` and `Uninstall-<Name>.ps1`. Persistence is a single Scheduled Task named `OfficePranks-<Name>`.
- [ ] **README updated.** New payloads have a Contents row and a one-liner install snippet.

## Validator results

- [ ] I ran `.\.github\scripts\Validate-Pranks.ps1` locally and it passed.
- [ ] CI on this PR is green.

## Test plan

<!-- Bulleted checklist of how you verified the change on a real machine.
     For a new prank: install, observe the behavior, uninstall, confirm
     %LOCALAPPDATA%\OfficePranks and the scheduled task are gone.
     For a bug fix: the steps that previously reproduced the bug,
     and confirmation they no longer do. -->

- [ ] 
- [ ] 

## Notes for reviewers

<!-- Anything tricky, anything you want extra eyes on, anything intentionally
     left for a follow-up PR. -->
