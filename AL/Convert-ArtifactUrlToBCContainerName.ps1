function Convert-ArtifactUrlToBCContainerName {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ArtifactUrl
    )

    $segments = "$ArtifactUrl/////".Split('/')

    $type = $segments[1] 
    $version = $segments[2]
    $country = $segments[3]

    if ($type -eq 'sandbox') {
        $containerName = 'CLOUD'
    }
    else {
        $containerName = 'ONPREM'
    }
    
    if ($version -ne '') {
        $containerName += $version -replace '[^a-zA-Z0-9]', ''
    }

    if ($country -ne '') {
        $containerName += '-' + $country.ToUpper()
    }

    return $containerName
}


Export-ModuleMember -Function Convert-ArtifactUrlToBCContainerName