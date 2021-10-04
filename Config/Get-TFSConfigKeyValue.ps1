function Get-TFSConfigKeyValue {
    Param(
        # Name of config key to retrieve
        [Parameter(Mandatory=$true)]
        [string]
        $KeyName
    )

    if (!(Test-Path (Get-TFSConfigPath))) {
        throw "Could not find config file.
        
Please create it with New-TFSConfigFile then use ""notepad (Get-TFSConfigPath)"" to edit."
    }

    $ConfigJson = ConvertFrom-Json (Get-Content (Get-TFSConfigPath) -Raw)
    $ConfigJson.PSObject.Properties.Item($KeyName).Value
}

Export-ModuleMember -Function Get-TFSConfigKeyValue