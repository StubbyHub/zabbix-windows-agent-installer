# Install-ZabbixAgent.ps1 by StubbyHub
# -------------------------
# Configuration
# -------------------------
$zipUrl       = "https://cdn.zabbix.com/zabbix/binaries/stable/7.4/latest/zabbix_agent-7.4-latest-windows-amd64-openssl.zip"
$zipPath      = "$env:TEMP\zabbix_agent.zip"
$extractPath  = "$env:TEMP\zabbix_extracted"
$installPath  = "C:\Program Files\Zabbix Agent"
$serverIP     = "Your Zabbix Server IP"  # <-- Replace this
$hostname     = $env:COMPUTERNAME
$configFile   = "$installPath\conf\zabbix_agentd.conf"
$agentExe     = "$installPath\bin\zabbix_agentd.exe"

# Ensure TLS 1.2 support (for older Windows versions)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -------------------------
# Uninstall Existing Agent
# -------------------------
Write-Host "[*] Checking for existing Zabbix Agent service..."

$existingService = Get-Service -Name "Zabbix Agent" -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "[*] Stopping existing service..."
    Stop-Service "Zabbix Agent" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

if (Test-Path "$installPath\bin\zabbix_agentd.exe") {
    Write-Host "[*] Uninstalling existing ZIP-based agent..."
    & "$installPath\bin\zabbix_agentd.exe" --uninstall 2>$null
    Start-Sleep -Seconds 2
}

$app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Zabbix Agent*" }
if ($app) {
    Write-Host "[*] Uninstalling MSI-based agent..."
    $app.Uninstall()
    Start-Sleep -Seconds 5
}

# -------------------------
# Cleanup Old Files
# -------------------------
if (Test-Path $installPath) {
    Write-Host "[*] Removing old installation files..."
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue
}

# -------------------------
# Download & Install New Agent
# -------------------------
Write-Host "[*] Downloading Zabbix Agent package..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

Write-Host "[*] Extracting package..."
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

Write-Host "[*] Copying files to install directory..."
New-Item -ItemType Directory -Force -Path $installPath | Out-Null
Copy-Item "$extractPath\*" "$installPath\" -Recurse -Force

# -------------------------
# Update Configuration File
# -------------------------
Write-Host "[*] Updating agent configuration..."
(Get-Content $configFile) |
    ForEach-Object {
        $_ -replace '^Server=.*', "Server=$serverIP" `
           -replace '^ServerActive=.*', "ServerActive=$serverIP" `
           -replace '^Hostname=.*', "Hostname=$hostname"
    } | Set-Content $configFile

if (-not (Select-String -Path $configFile -Pattern '^Hostname=')) {
    Add-Content -Path $configFile -Value "`nHostname=$hostname"
}

# -------------------------
# Register and Start Service
# -------------------------
Write-Host "[*] Registering Zabbix Agent service..."
& "$agentExe" --config "$configFile" --install

Write-Host "[*] Starting Zabbix Agent..."
Start-Service "Zabbix Agent"

# -------------------------
# Final Cleanup
# -------------------------
Write-Host "[*] Cleaning up temporary files..."
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

# -------------------------
# Done
# -------------------------
Write-Host ""
Write-Host "Zabbix Agent installed and configured successfully."
Write-Host "  Server: $serverIP"
Write-Host "  Hostname: $hostname"
