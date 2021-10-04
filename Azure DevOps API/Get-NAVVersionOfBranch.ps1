function Get-NAVVersionOfBranch
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ServerPath
    )

    $AppMgt = Join-Path (Create-TempDirectory) 'COD1.TXT'
    Get-ObjectsFromTFSBranch -BranchPath (Join-Path $ServerPath 'COD1.TXT') -DestinationPath $AppMgt -Type File
    Get-VersionList $AppMgt
    Remove-Item $AppMgt
}

Get-NAVVersionOfBranch '$/NAV - Ultimo/Ultimo_Live'