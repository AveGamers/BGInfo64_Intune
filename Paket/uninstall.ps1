$PackageName = "Intune_BGInfo64"
Start-Transcript -Path "C:\source\IntunePackage\$PackageName\Action.log" -NoClobber -Append

try {
    Remove-Item -Path "C:\Program Files\BgInfo" -Recurse -Confirm:$false -Force
    Write-Host "Removed C:\Program Files\BgInfo"
    
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk" -Confirm:$false -Force
    Write-Host "Removed Startup shortcut"
    
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hintergrund aktualisieren.lnk" -Confirm:$false -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\BGInfo aktualisieren.lnk" -Confirm:$false -Force -ErrorAction SilentlyContinue
    Write-Host "Removed Start Menu shortcut"
    
    # Entferne Desktop-Verknüpfung aus allen User-Profilen (lokal und OneDrive) - neue und alte Benennung
    Get-ChildItem "C:\Users\*\Desktop\Hintergrund aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\*\OneDrive*\Desktop\Hintergrund aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\*\Desktop\BGInfo aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\*\OneDrive*\Desktop\BGInfo aktualisieren.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "Removed Desktop shortcuts from all user profiles (local and OneDrive)"
    Write-Host "Removed Start Menu shortcut"
    
    # Entferne Registry-Einträge
    # Hinweis: Bei 32-Bit PowerShell wird automatisch zu WOW6432Node umgeleitet
    $RegistryPath = "HKLM:\SOFTWARE\WOW6432Node\BGInfo64"
    if (Test-Path $RegistryPath) {
        Remove-Item -Path $RegistryPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed registry key: $RegistryPath"
    }
} catch {
    Write-Output "Error during cleanup: $($_.Exception.Message)"
    Write-Host "No previous installation found, continuing with uninstallation."
}

Stop-Transcript
Write-Host "Uninstallation completed successfully."
exit 0 # Exit code 0 indicates success (uninstallation successful)