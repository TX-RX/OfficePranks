# CatFacts.ps1
#
# When run, has ~18.75% chance of cranking the system volume and having
# Windows speech synthesis read a random cat fact from catfact.ninja.
# Designed to be scheduled every 30 minutes during work hours, yielding
# roughly 3 facts in an 8-hour day. Pass -Force to bypass the random
# gate (useful for testing).
#
# To install:   .\Install-CatFacts.ps1
# To uninstall: .\Uninstall-CatFacts.ps1
# Manual cleanup if the uninstaller is missing:
#   Unregister-ScheduledTask -TaskName 'OfficePranks-CatFacts' -Confirm:$false
#   Remove-Item "$env:LOCALAPPDATA\OfficePranks" -Recurse -Force

param([switch]$Force)

if ($Force -or ((Get-Random -Maximum 10000) -lt 1875)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Set-Speaker($Volume) {
        $wshShell = New-Object -ComObject wscript.shell
        1..50      | ForEach-Object { $wshShell.SendKeys([char]174) }  # volume down x50
        1..$Volume | ForEach-Object { $wshShell.SendKeys([char]175) }  # volume up x N
    }

    try {
        $CatFact = Invoke-RestMethod -Uri 'https://catfact.ninja/fact' -TimeoutSec 10
    } catch {
        return  # network failure: stay silent, try again next tick
    }

    Set-Speaker -Volume 10
    Add-Type -AssemblyName System.Speech
    $SpeechSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $SpeechSynth.Speak("Did you know? ")
    $SpeechSynth.Speak($CatFact.fact)
}
