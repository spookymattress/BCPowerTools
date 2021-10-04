function Get-RepositoryId {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName
    )

    $Repos = Invoke-TFSAPI ('{0}{1}/_apis/git/repositories' -f (Get-TFSCollectionURL), $ProjectName)

    if ($RepositoryName -ne '') {
        $Id = ($Repos.value | where name -like ('*{0}*' -f $RepositoryName)).id
    }
    else {
        $Id = $Repos.value.item(0).id
    }

    if ($Id -eq '' -or $Id -eq $null) {
        $Id = Get-RepositoryId -ProjectName $ProjectName -RepositoryName ''
    }

    $Id
}

Export-ModuleMember -Function Get-RepositoryId