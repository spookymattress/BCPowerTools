function Get-EnvironmentKeyValue {
    Param(
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location),
        [Parameter(Mandatory=$true)]
        [string]$KeyName
    )

    if (!(Test-Path (Join-Path $SourcePath 'environment.json'))) {
        return ''
    }

    $JsonContent = Get-Content (Join-Path $SourcePath 'environment.json') -Raw -Encoding UTF8
    $Json = ConvertFrom-Json $JsonContent

    $Json.PSObject.Properties.Item($KeyName).Value
}

Export-ModuleMember -Function Get-EnvironmentKeyValue