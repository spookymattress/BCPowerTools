function New-TFSConfigFile {
    if (!(Test-Path (Get-TFSConfigPath))) {
        if (!(Test-Path (Split-Path (Get-TFSConfigPath) -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path (Get-TFSConfigPath) -Parent)
        }
        
        Set-Content -Value '{}' -Path (Get-TFSConfigPath)
    }

    Update-TFSConfigFile
}

Export-ModuleMember -Function New-TFSConfigFile