function Update-TFSConfigFile {
    Param(
        # JSON string containing configuration keys and values to use
        [Parameter(Mandatory=$false)]
        [string]
        $Config
    )
    if (!(Test-Path (Get-TFSConfigPath))) {
        New-TFSConfigFile
    }

    if ($null -eq (Get-TFSConfigKeyValue 'collectionUrl')) {
        Set-TFSConfigKeyValue -KeyName 'collectionUrl' -KeyValue 'Azure DevOps collection URL'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'user')) {
        Set-TFSConfigKeyValue -KeyName 'user' -KeyValue 'username'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'password')) {
        Set-TFSConfigKeyValue -KeyName 'password' -KeyValue 'password'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'translationKey')) {
        Set-TFSConfigKeyValue -KeyName 'translationKey' -KeyValue 'translation secret key'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'codeSigningCertThumbprint')) {
        Set-TFSConfigKeyValue -KeyName 'codeSigningCertThumbprint' -KeyValue 'code signing certificate thumbprint'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'businessCentralLicenceFile')) {
        Set-TFSConfigKeyValue -KeyName 'businessCentralLicenceFile' -KeyValue 'licence file for Business Central Containers'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'navLicenceFile')) {
        Set-TFSConfigKeyValue -KeyName 'navLicenceFile' -KeyValue 'licence file for NAV containers'
    }

    if ($null -eq (Get-TFSConfigKeyValue 'translationDictionaryPath')) {
        Set-TFSConfigKeyValue -KeyName 'translationDictionaryPath' -KeyValue (Join-Path (Split-Path (Get-TFSConfigPath) -Parent) 'dictionary.xml')
    }

    if ($Config -ne $null) {
        $ConfigJson = ConvertFrom-Json $Config
        foreach ($Key in $ConfigJson.PSObject.Properties) {
            if ($null -ne (Get-TFSConfigKeyValue $Key.Name)) {
                Set-TFSConfigKeyValue -KeyName $Key.Name -KeyValue $Key.Value
            }
        }
    }
}

Export-ModuleMember -Function Update-TFSConfigFile