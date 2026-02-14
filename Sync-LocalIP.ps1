# Sync-LocalIP.ps1
# Automatically updates the API_BASE_URL in fraudshield/.env with the current machine's LAN IP.

$ErrorActionPreference = "Stop"

function Get-LocalIP {
    # Prefer physical Wi-Fi or Ethernet interfaces, excluding virtual ones
    $ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        ($_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*") -and 
        $_.IPAddress -notlike "169.254.*" -and
        $_.InterfaceAlias -notlike "vEthernet*"
    } | Select-Object -ExpandProperty IPAddress

    # Fallback to any if no physical one found (though less likely to be what we want)
    if (-not $ips) {
        $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.IPAddress -notlike "127.0.0.1" -and $_.IPAddress -notlike "169.254.*" 
        } | Select-Object -First 1 -ExpandProperty IPAddress
    }
    else {
        $ip = $ips | Select-Object -First 1
    }

    if (-not $ip) {
        throw "Could not determine local IP address. Please check your network connection."
    }
    return $ip
}

try {
    $newIp = Get-LocalIP
    Write-Host "Detected Local IP: $newIp" -ForegroundColor Cyan

    $envPath = Join-Path $PSScriptRoot "fraudshield\.env"
    if (-not (Test-Path $envPath)) {
        throw "Could not find .env file at $envPath"
    }

    $content = Get-Content $envPath
    $updated = $false
    
    $newContent = foreach ($line in $content) {
        if ($line -match "^API_BASE_URL=http://([^:]+):(\d+)(.*)") {
            $oldIp = $Matches[1]
            $port = $Matches[2]
            $path = $Matches[3]
            
            if ($oldIp -ne $newIp) {
                Write-Host "Updating IP from $oldIp to $newIp" -ForegroundColor Yellow
                "API_BASE_URL=http://${newIp}:${port}${path}"
                $updated = $true
            }
            else {
                Write-Host "IP is already up to date: $newIp" -ForegroundColor Green
                $line
            }
        }
        else {
            $line
        }
    }

    if ($updated) {
        $newContent | Set-Content $envPath
        Write-Host "Successfully updated $envPath" -ForegroundColor Green
    }
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
