# Define suspicious directories (Windows equivalent)
$dirs = @(
    "C:\Windows\Temp",
    "C:\Users\$env:USERNAME\AppData\Local\Temp",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs",
    "C:\Users\$env:USERNAME\AppData\Roaming",
    "C:\Users\$env:USERNAME\AppData\Local"
)

# Define file types to look for (potentially malicious types)
$fileTypes = @("*.exe", "*.bat", "*.js", "*.vbs", "*.cmd", "*.ps1", "*.scr", "*.dll")

# Function to check and install ClamAV for Windows
Function Install-ClamAV {
    $clamavPath = "C:\Program Files\ClamAV"
    
    # Check if ClamAV is installed
    if (Test-Path $clamavPath) {
        Write-Host "[✔] ClamAV is already installed." -ForegroundColor Green
    } else {
        Write-Host "[!] ClamAV is not installed. Attempting to install..." -ForegroundColor Yellow
        $clamavInstaller = "https://github.com/mkovatsc/clamav-windows/releases/download/0.103.3/clamav-0.103.3-x64.msi"
        $installerPath = "$env:TEMP\clamav-installer.msi"
        
        # Download and install ClamAV
        Invoke-WebRequest -Uri $clamavInstaller -OutFile $installerPath
        Start-Process msiexec.exe -ArgumentList "/i", $installerPath, "/quiet", "/norestart" -Wait
        Remove-Item -Path $installerPath
        
        # Verify installation
        if (Test-Path $clamavPath) {
            Write-Host "[✔] ClamAV installed successfully." -ForegroundColor Green
        } else {
            Write-Host "[✖] ClamAV installation failed." -ForegroundColor Red
        }
    }
}

# Run ClamAV scan if installed
Function Run-ClamAVScan {
    $clamavPath = "C:\Program Files\ClamAV\clamscan.exe"
    
    if (Test-Path $clamavPath) {
        Write-Host "Running ClamAV scan..." -ForegroundColor Yellow
        & $clamavPath --scan -r --bell --infected --remove C:\Users\$env:USERNAME\AppData\Local\Temp
    } else {
        Write-Host "[✖] ClamAV not found. Skipping virus scan." -ForegroundColor Red
    }
}

# Function to scan suspicious directories
Function Scan-Directories {
    foreach ($dir in $dirs) {
        Write-Host "Checking directory: $dir" -ForegroundColor Green
        
        # Look for suspicious file types
        foreach ($type in $fileTypes) {
            $files = Get-ChildItem -Path $dir -Recurse -Filter $type -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                Write-Host "[!] Suspicious File Found: $file" -ForegroundColor Red
            }
        }

        # Look for hidden files (potential backdoors)
        $hiddenFiles = Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -match "Hidden" }
        foreach ($file in $hiddenFiles) {
            Write-Host "[!] Hidden File: $file" -ForegroundColor Red
        }
    }
}

# Main Execution
Write-Host "Starting system scan for suspicious files and viruses..." -ForegroundColor Yellow

# Install ClamAV if missing
Install-ClamAV

# Scan directories for suspicious files
Scan-Directories

# Run ClamAV scan if installed
Run-ClamAVScan

Write-Host "System scan completed." -ForegroundColor Yellow
