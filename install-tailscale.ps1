# Tailscale Installation and Connection Script for Windows
# This script installs Tailscale (if not present) and connects using an auth key
# Usage: irm https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-tailscale.ps1 | iex

$ErrorActionPreference = "Stop"

# Auth key placeholder - replace with your actual auth key
$AUTH_KEY = "YOUR_AUTH_KEY_HERE"

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check PowerShell version
function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.1 or higher is required. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
    Write-Info "PowerShell version: $($PSVersionTable.PSVersion)"
}

# Check if running as Administrator
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator"
        exit 1
    }
    Write-Info "Running with Administrator privileges"
}

# Check if Tailscale is already installed
function Test-TailscaleInstalled {
    # Check if tailscale command exists
    if (Get-Command tailscale -ErrorAction SilentlyContinue) {
        return $true
    }
    
    # Check if Tailscale service exists
    $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
    if ($service) {
        return $true
    }
    
    # Check registry for installation
    $regPath = "HKLM:\SOFTWARE\Tailscale"
    if (Test-Path $regPath) {
        return $true
    }
    
    return $false
}

# Install Tailscale using winget
function Install-TailscaleWithWinget {
    Write-Info "Attempting to install Tailscale using winget..."
    
    try {
        # Check if winget is available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id Tailscale.Tailscale --silent --accept-package-agreements --accept-source-agreements
            Write-Info "Tailscale installed successfully using winget"
            return $true
        } else {
            Write-Warn "winget is not available"
            return $false
        }
    } catch {
        Write-Warn "Failed to install using winget: $_"
        return $false
    }
}

# Install Tailscale by downloading installer
function Install-TailscaleWithInstaller {
    Write-Info "Downloading Tailscale installer..."
    
    $installerUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe"
    $installerPath = "$env:TEMP\tailscale-setup.exe"
    
    try {
        # Download installer
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "Installer downloaded to $installerPath"
        
        # Run silent install
        Write-Info "Installing Tailscale (this may take a moment)..."
        $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Info "Tailscale installed successfully"
            
            # Clean up installer
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Error "Installer exited with code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Failed to download or install Tailscale: $_"
        return $false
    }
}

# Install Tailscale
function Install-Tailscale {
    Write-Info "Installing Tailscale..."
    
    # Try winget first
    if (Install-TailscaleWithWinget) {
        return
    }
    
    # Fallback to direct download
    if (Install-TailscaleWithInstaller) {
        return
    }
    
    Write-Error "Failed to install Tailscale using both methods"
    exit 1
}

# Wait for Tailscale service to be ready
function Wait-ForTailscaleService {
    Write-Info "Waiting for Tailscale service to be ready..."
    
    $maxAttempts = 30
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            Write-Info "Tailscale service is running"
            return
        }
        
        Start-Sleep -Seconds 2
        $attempt++
    }
    
    Write-Warn "Tailscale service may not be ready yet, but continuing..."
}

# Ensure Tailscale service is enabled
function Enable-TailscaleService {
    Write-Info "Ensuring Tailscale service is enabled..."
    
    $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.StartType -ne "Automatic") {
            Set-Service -Name "Tailscale" -StartupType Automatic
            Write-Info "Tailscale service set to start automatically"
        } else {
            Write-Info "Tailscale service is already set to start automatically"
        }
        
        if ($service.Status -ne "Running") {
            Start-Service -Name "Tailscale"
            Write-Info "Tailscale service started"
        }
    } else {
        Write-Warn "Tailscale service not found. It may start after installation."
    }
}

# Connect to Tailscale with auth key
function Connect-Tailscale {
    Write-Info "Connecting to Tailscale..."
    
    if ($AUTH_KEY -eq "YOUR_AUTH_KEY_HERE") {
        Write-Error "Auth key not configured. Please replace YOUR_AUTH_KEY_HERE with your actual Tailscale auth key."
        exit 1
    }
    
    # Wait a bit for tailscale command to be available in PATH
    $maxAttempts = 10
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        if (Get-Command tailscale -ErrorAction SilentlyContinue) {
            break
        }
        Start-Sleep -Seconds 1
        $attempt++
    }
    
    if (-not (Get-Command tailscale -ErrorAction SilentlyContinue)) {
        Write-Error "tailscale command not found. Please restart your PowerShell session or add Tailscale to PATH."
        exit 1
    }
    
    # Connect using auth key
    try {
        & tailscale up --authkey=$AUTH_KEY --accept-routes --accept-dns
        
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Successfully connected to Tailscale!"
            
            # Display Tailscale status
            Write-Info "Tailscale status:"
            & tailscale status
        } else {
            Write-Error "Failed to connect to Tailscale. Exit code: $LASTEXITCODE"
            exit 1
        }
    } catch {
        Write-Error "Error connecting to Tailscale: $_"
        exit 1
    }
}

# Main execution
function Main {
    Write-Info "Starting Tailscale installation and connection script..."
    
    Test-PowerShellVersion
    Test-Administrator
    
    if (Test-TailscaleInstalled) {
        Write-Info "Tailscale is already installed"
    } else {
        Install-Tailscale
    }
    
    Enable-TailscaleService
    Wait-ForTailscaleService
    Connect-Tailscale
    
    Write-Info "Script completed successfully!"
}

# Run main function
Main
