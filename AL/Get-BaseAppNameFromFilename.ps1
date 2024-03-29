function Get-BaseAppNameFromFilename {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Filename
    )
    
    if ($Filename -match  '^(.*_)(.*)(_\d.\d.\d.\d.app)') {
        return $Matches[2]
    }
    else
    { return ''}
}

Export-ModuleMember -Function Get-BaseAppNameFromFilename
