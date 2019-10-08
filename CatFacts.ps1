#Run this every 1/2 hour and in an 8 hour work day there will be approximately 3 times per day that your victim hears a cat fact
if ((Get-Random -Maximum 10000) -lt 1875) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Function Set-Speaker($Volume){$wshShell = new-object -com wscript.shell;1..50 | % {$wshShell.SendKeys([char]174)};1..$Volume | % {$wshShell.SendKeys([char]175)}}
#
    Set-Speaker -Volume 10
    Add-Type -AssemblyName System.Speech
    $SpeechSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $CatFact = Invoke-RestMethod  -Uri 'https://catfact.ninja/fact'
    $SpeechSynth.Speak("Waddup here is what you need to impress clients in the next meeting")
    $SpeechSynth.Speak($CatFact.fact)
}    
