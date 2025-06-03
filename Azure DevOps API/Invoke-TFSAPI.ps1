function Invoke-TFSAPI
{
    Param(
    [Parameter(Mandatory=$true)]
    [string]$Url,    
    [Parameter(Mandatory=$false)]
    [string]$HttpMethod = 'Get',
    [Parameter(Mandatory=$false)]
    [string]$HttpContent,
    [Parameter(Mandatory=$false)]
    [switch]$GetContents,
    [Parameter(Mandatory=$false)]
    [switch]$OutFile,
    [Parameter(Mandatory=$false)]
    [string]$OutFilePath,
    [Parameter(Mandatory=$false)]
    [switch]$SuppressError
    )

    $Headers = Create-HttpHeaders

    if ($Url.Substring(0,1) -eq '/')
    {
        $Url = $Url.Substring(1)
    }
    
    if ($Url.Substring(0,4) -ne 'http')
    {
        $TFSUrl = '{0}{1}' -f (Get-TFSConfigKeyValue 'collectionUrl'), $Url
    }
    else
    {
        $TFSUrl = $Url
    }

    try
    {
        switch ($HttpMethod)
        {
            'Get'
            {
                if ($GetContents)
                {
                    $TempPath = (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString() + ".TXT"))
                    Invoke-RestMethod -Method Get -Headers $Headers -Uri $TFSUrl -OutFile $TempPath
                    $Result = Get-Content $TempPath -Raw -Encoding UTF8
                    [IO.File]::Delete($TempPath)
                    $Result
                }
                else
                {
                    if ($OutFile.IsPresent) {
                        Invoke-RestMethod -Method Get -Headers $Headers -Uri $TFSUrl -OutFile $OutFilePath
                    }
                    else {
                        Invoke-RestMethod -Method Get -Headers $Headers -Uri $TFSUrl
                    }
                }
            }
            'Put'
            {
                Invoke-RestMethod -Method Put -Headers $Headers -Uri $TFSUrl -Body $HttpContent
            }
        }
    }
    catch
    {
        if($SuppressError.IsPresent) {
            return $null
        }
        else {
            Write-Error $_.Exception.Message
        }           
    }
}

function Create-HttpHeaders
{
    $ba = ("{0}:{1}" -f (Get-TFSConfigKeyValue 'user'),(Get-TFSConfigKeyValue 'password'))
    $ba = [System.Text.Encoding]::UTF8.GetBytes($ba)
    $ba = [System.Convert]::ToBase64String($ba)
    $h = @{Authorization=("Basic {0}" -f $ba);'Accept-Encoding'='gzip,deflate'}   
    $h
}

function Get-TFSCollectionURL
{
    Get-TFSConfigKeyValue 'collectionUrl'
}

Export-ModuleMember -Function Invoke-TFSAPI
Export-ModuleMember -Function Get-TFSCollectionURL
Export-ModuleMember -Function Read-ConfigFile