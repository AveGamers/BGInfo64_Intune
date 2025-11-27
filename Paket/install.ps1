# Zuerst werden die alten Dateien versucht zu entfernen. Somit kann einfach über das alte Verzeichnis installiert werden.
$PackageName = "Intune_BGInfo64"
$PackageVersion = "4.33"  # Erhöhe diese Version, wenn Desktop-Icons neu erstellt werden sollen
Start-Transcript -Path "C:\source\IntunePackage\$PackageName\Action.log" -NoClobber -Append

# Clean up before Installing. This is to able to just change the intunewin file for the updates (And the detection script).
try {
    Remove-Item -Path "C:\Program Files\BgInfo" -Recurse -Confirm:$false -Force
    Write-Host "Removed C:\Program Files\BgInfo"
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk" -Confirm:$false -Force
    Write-Host "Removed C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk"
    
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hintergrund aktualisieren.lnk" -Confirm:$false -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\BGInfo aktualisieren.lnk" -Confirm:$false -Force -ErrorAction SilentlyContinue
    Write-Host "Removed Start Menu shortcut"
    
    # Entferne Desktop-Verknüpfung aus allen User-Profilen (lokal und OneDrive) - neue und alte Benennung
    Get-ChildItem "C:\Users\*\Desktop\Hintergrund aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\*\OneDrive*\Desktop\Hintergrund aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\*\Desktop\BGInfo aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\*\OneDrive*\Desktop\BGInfo aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "Removed Desktop shortcuts from all user profiles (local and OneDrive)"
} catch {
    Write-Output "Error during cleanup: $($_.Exception.Message)"
    Write-Host "No previous installation found, continuing with installation."
}

try {
    New-Item -ItemType Directory -Path "c:\Program Files\BgInfo" -Force | Out-Null
    Write-Host "Created directory C:\Program Files\BgInfo"
    Copy-Item -Path "$PSScriptRoot\Bginfo64.exe" -Destination "C:\Program Files\BGInfo\Bginfo64.exe"
    Write-Host "Copied Bginfo64.exe to C:\Program Files\BGInfo\Bginfo64.exe"
    Copy-Item -Path "$PSScriptRoot\Config.bgi" -Destination "C:\Program Files\BGInfo\Config.bgi"
    Write-Host "Copied Config.bgi to C:\Program Files\BGInfo\Config.bgi"
    Copy-Item -Path "$PSScriptRoot\ActiveIP.vbs" -Destination "C:\Program Files\BGInfo\ActiveIP.vbs"
    Write-Host "Copied ActiveIP.vbs to C:\Program Files\BGInfo\ActiveIP.vbs"
    Copy-Item -Path "$PSScriptRoot\ActiveMAC.vbs" -Destination "C:\Program Files\BGInfo\ActiveMAC.vbs"
    Write-Host "Copied ActiveMAC.vbs to C:\Program Files\BGInfo\ActiveMAC.vbs"
    Copy-Item -Path "$PSScriptRoot\img0.jpg" -Destination "C:\Program Files\BGInfo\img0.jpg"
    Write-Host "Copied img0.jpg to C:\Program Files\BGInfo\img0.jpg"
    Write-Host "File Copy completed successfully."
} catch {
    Write-Output "Error during installation: $($_.Exception.Message)"
    exit 1 # Exit code 1 indicates failure (installation not successful)
 }
 try {
$Shell = New-Object -ComObject ("WScript.Shell")
$ShortCut = $Shell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk")
$ShortCut.TargetPath="`"C:\Program Files\BgInfo\Bginfo64.exe`""
$ShortCut.Arguments="`"C:\Program Files\BgInfo\Config.bgi`" /timer:0 /silent /nolicprompt"
$ShortCut.IconLocation = "Bginfo64.exe, 0";
$ShortCut.Save()
Write-Host "Shortcut created successfully at C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk"
Write-Host "BGInfo should now run at startup."
 } catch {
    Write-Output "Error creating shortcut: $($_.Exception.Message)"
    exit 1 # Exit code 1 indicates failure (shortcut creation not successful)
 }

# Verknüpfung auf dem User-Desktop erstellen für manuelles Neuladen (optional, kann vom User gelöscht werden)
# Da die Installation als SYSTEM läuft, erstellen wir die Verknüpfung für alle User-Profile
# Prüfe zuerst die installierte Version
# Hinweis: Bei 32-Bit PowerShell wird automatisch zu WOW6432Node umgeleitet
$RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\BGInfo64"
$InstalledVersion = $null

try {
    if (Test-Path $RegistryPath) {
        $InstalledVersion = (Get-ItemProperty -Path $RegistryPath -Name "Version" -ErrorAction SilentlyContinue).Version
    }
} catch {
    Write-Host "No previous version found in registry"
}

Write-Host "Current package version: $PackageVersion"
Write-Host "Installed version: $InstalledVersion"

if ($InstalledVersion -ne $PackageVersion) {
    Write-Host "Version mismatch or first installation - creating desktop shortcuts for all users"
    try {
        $UserProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }
        
        foreach ($UserProfile in $UserProfiles) {
            # Prüfe auf OneDrive-Desktop, sonst lokaler Desktop
            $OneDriveDesktop = "$($UserProfile.FullName)\OneDrive*\Desktop"
            $OneDriveDesktopPath = Get-Item $OneDriveDesktop -ErrorAction SilentlyContinue | Select-Object -First 1
            
            if ($OneDriveDesktopPath) {
                $DesktopPath = $OneDriveDesktopPath.FullName
            } else {
                $DesktopPath = "$($UserProfile.FullName)\Desktop"
            }
            
            if (Test-Path $DesktopPath) {
                $Shell = New-Object -ComObject ("WScript.Shell")
                $ShortCut = $Shell.CreateShortcut("$DesktopPath\Hintergrund aktualisieren.lnk")
                $ShortCut.TargetPath="`"C:\Program Files\BgInfo\Bginfo64.exe`""
                $ShortCut.Arguments="`"C:\Program Files\BgInfo\Config.bgi`" /timer:0 /silent /nolicprompt"
                $ShortCut.IconLocation = "C:\Program Files\BgInfo\Bginfo64.exe, 0"
                $ShortCut.Description = "BGInfo Hintergrund aktualisieren"
                $ShortCut.Save()
                Write-Host "Desktop shortcut created for user: $($UserProfile.Name) at $DesktopPath"
            }
        }
        
    } catch {
        Write-Output "Error creating desktop shortcuts: $($_.Exception.Message)"
    }
    
    # Schreibe die Version in die Registry (außerhalb des Try-Catch für Desktop-Shortcuts)
    Write-Host "=== Starting registry write process ==="
    Write-Host "Registry Path: $RegistryPath"
    Write-Host "Package Version: $PackageVersion"
    
    try {
        if (-not (Test-Path $RegistryPath)) {
            Write-Host "Registry path does not exist, creating..."
            $newKey = New-Item -Path $RegistryPath -Force
            Write-Host "Created registry path: $RegistryPath"
            Write-Host "New key object: $newKey"
        } else {
            Write-Host "Registry path already exists"
        }
        
        Write-Host "Setting Version property..."
        Set-ItemProperty -Path $RegistryPath -Name "Version" -Value $PackageVersion -Type String
        Write-Host "Version $PackageVersion written to registry at $RegistryPath"
        
        # Verifiziere
        Write-Host "Verifying registry write..."
        $WrittenVersion = (Get-ItemProperty -Path $RegistryPath -Name "Version" -ErrorAction Stop).Version
        Write-Host "Verified registry version: $WrittenVersion"
        
        if ($WrittenVersion -eq $PackageVersion) {
            Write-Host "SUCCESS: Registry version matches package version" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Registry version mismatch!" -ForegroundColor Yellow
        }
    } catch {
        Write-Output "ERROR writing to registry: $($_.Exception.Message)"
        Write-Host "Error details: $($_.Exception)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        Write-Host "Warning: Could not write version to registry. This may require administrator rights."
    }
    Write-Host "=== Registry write process completed ==="
    
} else {
    Write-Host "Version $PackageVersion already installed - skipping desktop shortcut creation"
}

# Verknüpfung im Startmenü erstellen für manuelles Neuladen
try {
    $StartMenuPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCut = $Shell.CreateShortcut("$StartMenuPath\Hintergrund aktualisieren.lnk")
    $ShortCut.TargetPath="`"C:\Program Files\BgInfo\Bginfo64.exe`""
    $ShortCut.Arguments="`"C:\Program Files\BgInfo\Config.bgi`" /timer:0 /silent /nolicprompt"
    $ShortCut.IconLocation = "C:\Program Files\BgInfo\Bginfo64.exe, 0"
    $ShortCut.Description = "BGInfo Hintergrund aktualisieren"
    $ShortCut.Save()
    Write-Host "Start Menu shortcut created successfully at $StartMenuPath\Hintergrund aktualisieren.lnk"
    
    # Hinweis: Automatisches Anheften im Startmenü ist per Script nicht zuverlässig möglich
    # Die Verknüpfung ist aber im Startmenü unter "Alle Apps" verfügbar
    Write-Host "Note: Shortcut is available in Start Menu under 'All Apps'. Users can pin it manually if desired."
} catch {
    Write-Output "Error creating start menu shortcut: $($_.Exception.Message)"
}

# BGInfo direkt nach der Installation ausführen
Start-Process -FilePath "C:\Program Files\BgInfo\Bginfo64.exe" -ArgumentList '"C:\Program Files\BgInfo\Config.bgi" /timer:0 /silent /nolicprompt'
Write-Host "BGInfo executed successfully after installation."
Stop-Transcript
Write-Host "Installation completed successfully."

exit 0 # Exit code 0 indicates success (installation successful)