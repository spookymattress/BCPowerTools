function Get-TFSConfigPath {
    Join-Path (Join-Path ([System.Environment]::GetFolderPath('ApplicationData')) 'NORRIQ') 'BCPowerToolsConfig.json'
}

Export-ModuleMember -Function Get-TFSConfigPath