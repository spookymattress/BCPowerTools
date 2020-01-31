function Set-TFSConfigKeyValue {
    Param(
        # Key name to set in config file
        [Parameter(Mandatory=$true)]
        [string]
        $KeyName,
        # Key value to set in config file
        [Parameter(Mandatory=$true)]
        [string]
        $KeyValue
    )

    $ConfigJson = ConvertFrom-Json (Get-Content (Get-TFSConfigPath) -Raw)
    $ConfigJson.PSObject.Properties.Remove($KeyName)

        $ConfigJson.PSObject.Properties.Add((New-Object System.Management.Automation.PSNoteProperty($KeyName,$KeyValue)))
            
        Set-Content -Path (Get-TFSConfigPath) -Value (ConvertTo-Json $ConfigJson)
}

Export-ModuleMember -Function Set-TFSConfigKeyValue