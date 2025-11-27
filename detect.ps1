# Let This script figure out, if we have the current version of the Paket installed using a hashsum
$PackageName = "Intune_BGInfo64"
$PackageVersion = "4.33"  # Muss mit der Version in install.ps1 übereinstimmen
Start-Transcript -Path "C:\source\IntunePackage\$PackageName\Detection.log" -NoClobber -Append

# Define the installation path
$installPath = "C:\Program Files\BgInfo"
$startupShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk"
$startMenuShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hintergrund aktualisieren.lnk"

# Define required files and their expected SHA256 hashes
$requiredFiles = @(
    @{
        Path = "$installPath\ActiveIP.vbs"
        Hash = "C881490AF60BD1C14EB43A9C1B4AA0FB0E82A5102E87C4AA2CD21CFE0727B3F1"  # Set to $null if hash check is not required for this file
    },
    @{
        Path = "$installPath\ActiveMAC.vbs"
        Hash = "5E7661BAB9DD67D540973DF49DEDAD766408D93C183130B4534BA01685DDE018"  # Set to $null if hash check is not required for this file
    },
    @{
        Path = "$installPath\BGInfo64.exe"
        Hash = "EE2C4850E62277E5EFDED460AFD708AF22007EF5F2C2C9DAE7A699FC3DE346D0"  # Set to $null if hash check is not required for this file
    },
    @{
        Path = "$installPath\Config.bgi"
        Hash = "791FC45D7D6481476DEEFEF64EADF7F9E68F11E9261123E365206D16EBE48E70"  # Set to $null if hash check is not required for this file
    },
    @{
        Path = "$installPath\img0.jpg"
        Hash = "7AFAD70F5CC627EF544B3717E5F1FE413B4E54A6FCE53FAE2D6B1F2D44BE4A01"  # Set to $null if hash check is not required for this file
    },
    @{
        Path = $startupShortcutPath
        Hash = $null  # Shortcuts cannot be hashed reliably
    },
    @{
        Path = $startMenuShortcutPath
        Hash = $null  # Shortcuts cannot be hashed reliably
    }
)

# Check if all required files exist
$allFilesExist = $true
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path -Path $file.Path -PathType Leaf)) {
        $allFilesExist = $false
        $missingFiles += $file.Path
        Write-Host "Missing file: $($file.Path)"
    }
}

if (-not $allFilesExist) {
    Stop-Transcript
    Write-Output "Detection failed: Missing files: $($missingFiles -join ', ')"
    exit 1
}

# All files exist, now validate hashes where specified
try {
    foreach ($file in $requiredFiles) {
        if ($null -ne $file.Hash) {
            $fileHash = (Get-FileHash -Path $file.Path -Algorithm SHA256).Hash
            Write-Host "Hash for $($file.Path): $fileHash"
            
            if ($fileHash -ne $file.Hash) {
                Stop-Transcript
                Write-Output "Detection failed: File hash mismatch for '$($file.Path)'. Expected: '$($file.Hash)', Actual: '$fileHash'."
                exit 1
            }
        } else {
            Write-Host "File exists (no hash validation): $($file.Path)"
        }
    }
    
    # All validations passed
    # Check if desktop shortcuts need to be recreated based on version
    # Hinweis: Bei 32-Bit PowerShell wird automatisch zu WOW6432Node umgeleitet
    $RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\BGInfo64"
    $InstalledVersion = $null
    
    try {
        if (Test-Path $RegistryPath) {
            $InstalledVersion = (Get-ItemProperty -Path $RegistryPath -Name "Version" -ErrorAction SilentlyContinue).Version
        }
    } catch {
        Write-Host "No version found in registry"
    }
    
    Write-Host "Package version: $PackageVersion"
    Write-Host "Installed version: $InstalledVersion"
    
    if ($InstalledVersion -ne $PackageVersion) {
        Stop-Transcript
        Write-Output "Detection failed: Version mismatch. Package version: $PackageVersion, Installed version: $InstalledVersion. Desktop shortcuts need to be recreated."
        exit 1
    }
    
    Stop-Transcript
    Write-Output "Detection successful: All required files present, validated, and version matches."
    exit 0
}
catch {
    Stop-Transcript
    Write-Output "Detection failed: An error occurred during validation: $($_.Exception.Message)"
    exit 1
}