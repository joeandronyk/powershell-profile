# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") { 
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        Invoke-RestMethod https://github.com/joeandronyk/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Invoke-RestMethod https://github.com/joeandronyk/powershell-profile/raw/main/ja-powershell-theme.omp.json -OutFile $profilePath\ja-powershell-theme.omp.json
        Write-Host "The profile @ [$PROFILE] has been created and the oh-my-posh ja-powershell-theme.omp.json theme has been added."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://github.com/joeandronyk/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Invoke-RestMethod https://github.com/joeandronyk/powershell-profile/raw/main/ja-powershell-theme.omp.json -OutFile $profilePath\ja-powershell-theme.omp.json
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
        Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

# OMP Install
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains "CaskaydiaCove NF") {
        oh-my-posh font install CascadiaCode
        }
}
catch {
    Write-Error "Failed to download or install the Cascadia Code font. Error: $_"
}

# Final check and message to the user
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e)) {
    Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes."
} 
else {
    Write-Warning "Setup completed with errors. Please check the error messages above."
}