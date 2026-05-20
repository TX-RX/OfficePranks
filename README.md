# OfficePranks

Harmless PowerShell pranks for coworkers and friends who leave their computers unattended. Everything here is a joke — please keep contributions in that spirit. No malware, no data theft, no persistence beyond what a normal user can clean up in seconds.

## Contents

| File | What it does |
| --- | --- |
| [`CatFacts.ps1`](CatFacts.ps1) | Payload: ~18.75% of the time it raises the system volume and speaks a random fact from [catfact.ninja](https://catfact.ninja) via Windows speech synthesis. |
| [`Install-CatFacts.ps1`](Install-CatFacts.ps1) | One-shot installer. Stages the payload, registers a Scheduled Task on a weekday work-hours schedule, and fires it once to verify. |
| [`Uninstall-CatFacts.ps1`](Uninstall-CatFacts.ps1) | Removes the task and the staged payload. Leaves git clones alone. |

## Quick install (one-liner)

Open PowerShell on the target machine and paste:

```powershell
iex (irm https://raw.githubusercontent.com/TX-RX/OfficePranks/main/Install-CatFacts.ps1)
```

That downloads `Install-CatFacts.ps1`, which then downloads `CatFacts.ps1` into `%LOCALAPPDATA%\OfficePranks\`, registers a Scheduled Task running every 30 minutes on weekdays 9 AM – 5 PM, and speaks one fact immediately so you know it worked. No administrator privileges required — everything runs in the current user's context.

## Manual install

If you'd rather see what you're running before you run it:

```powershell
git clone https://github.com/TX-RX/OfficePranks.git
cd OfficePranks
.\Install-CatFacts.ps1
```

When `Install-CatFacts.ps1` finds a `CatFacts.ps1` next to itself (i.e. you're running it from a clone), it uses that file in place instead of downloading. Edit `CatFacts.ps1` first if you want to customize the speech, the volume, or the random gate.

## Customizing the schedule

`Install-CatFacts.ps1` exposes parameters for tweaking the cadence:

```powershell
# Every 15 minutes from 8 AM to 6 PM
.\Install-CatFacts.ps1 -StartTime 08:00 -EndTime 18:00 -IntervalMinutes 15

# Use a fork instead of TX-RX/OfficePranks
.\Install-CatFacts.ps1 -SourceUrl 'https://raw.githubusercontent.com/<you>/OfficePranks/main/CatFacts.ps1'

# Skip the verification run at the end (silent install)
.\Install-CatFacts.ps1 -SkipVerifyRun
```

Full parameter list:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `-TaskName` | `OfficePranks-CatFacts` | Scheduled Task name. Change it if you're stacking multiple pranks. |
| `-SourceUrl` | `…/TX-RX/OfficePranks/main/CatFacts.ps1` | Where to download `CatFacts.ps1` when not running from a clone. |
| `-StartTime` | `09:00` | First fire of the day. |
| `-EndTime` | `17:00` | Last fire of the day. |
| `-IntervalMinutes` | `30` | Gap between fires. |
| `-SkipVerifyRun` | (off) | Don't speak a fact at the end of install. |

## Testing the payload

`CatFacts.ps1` accepts a `-Force` switch that bypasses the random gate, useful for verifying audio works:

```powershell
.\CatFacts.ps1 -Force
```

## Uninstall

If you installed via clone:

```powershell
.\Uninstall-CatFacts.ps1
```

If you used the one-liner (no clone), paste:

```powershell
Unregister-ScheduledTask -TaskName 'OfficePranks-CatFacts' -Confirm:$false
Remove-Item "$env:LOCALAPPDATA\OfficePranks" -Recurse -Force
```

The uninstaller is safe to run on a machine that was never installed — it just reports "not found" and exits. It also detects when `%LOCALAPPDATA%\OfficePranks` is actually a git clone (`.git` folder present) and leaves the directory intact in that case.

## How it works

1. **Random gate.** On each run, `CatFacts.ps1` rolls `Get-Random -Maximum 10000` and only proceeds if the result is under `1875` (~18.75%). With a 30-minute trigger over an 8-hour day that's 16 chances per day, yielding ~3 expected fact deliveries.
2. **Volume.** Before speaking, the script sends the volume-down key 50 times to floor the system volume, then volume-up `N` times to set a known level (default `10`, i.e. ~20% on a 50-step scale). This guarantees the fact is audible regardless of what the victim had set, including a muted machine.
3. **Speech.** Uses `System.Speech.Synthesis.SpeechSynthesizer` — built into Windows, no extra packages required.
4. **Scheduled Task.** Registered under the current user with `LogonType Interactive` and `RunLevel Limited`, weekly trigger on Mon–Fri with sub-trigger repetition every `IntervalMinutes` minutes for the duration `EndTime - StartTime`. No admin elevation, no system-wide changes.
5. **Failure modes.** If `catfact.ninja` is unreachable, the payload silently returns (try/catch around the API call) and waits for the next tick. If the speech subsystem isn't available, the script errors silently inside the hidden PowerShell window.

## Safety notes

- This is intended for **personal machines or shared dev boxes among friends**. Don't deploy on company-managed devices without checking your acceptable-use policy — a hidden scheduled task that downloads and executes code is the kind of thing modern EDR products will flag, and rightly so.
- The volume override is the rudest part. If you want a kinder version, replace `Set-Speaker -Volume 10` in `CatFacts.ps1` with code that snapshots and restores the prior volume.
- All persistence is contained in one Scheduled Task and one folder. Nothing is written to the registry, no services are installed, no startup entries are created.

## Contributing

Pull requests welcome for new pranks in the same spirit. The rules are summarized here and enforced by CI:

- Harmless and reversible — your prank must come with a one-step uninstall.
- No exfiltration. No data leaves the victim's machine except for benign public-API calls like catfact.ninja.
- No privilege escalation. Anything that needs admin is out of scope.
- No detection evasion beyond `-WindowStyle Hidden` on the scheduled action.
- Include `Install-*.ps1` and `Uninstall-*.ps1` scripts for each new payload, and update the README.

Full details and the local validator command in [CONTRIBUTING.md](CONTRIBUTING.md). Vulnerability reports go through [SECURITY.md](SECURITY.md), and project conduct is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Every PR runs the [Validate workflow](.github/workflows/validate.yml).

## License

[MIT](LICENSE).
