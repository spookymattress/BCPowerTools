function Get-TFSConfigPath {
    Join-Path (Join-Path ([System.Environment]::GetFolderPath('ApplicationData')) 'Technology Management') 'TFS Tools Config.json'
}

Export-ModuleMember -Function Get-TFSConfigPath