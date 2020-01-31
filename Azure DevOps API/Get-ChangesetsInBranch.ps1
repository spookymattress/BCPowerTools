Function Get-ChangesetsInBranch
{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [string]$BranchPath,
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateSet('Oldest','Newest')]
        [string]$ChangeSetOption    
    )

    [string]$orderby = 'id desc'
    if ($ChangeSetOption -eq 'Oldest')
    {
        $orderby = 'id asc'
    }

    $url = '_apis/tfvc/changesets/?searchCriteria.itemPath={0}&$top=1&$orderby={1}' -f $BranchPath, $orderby
    $changeSets = Invoke-TFSAPI -Url $url
    
    foreach ($changeSet in $changeSets.value)
    {        
        $changeSet.changesetId
    }
}

Export-ModuleMember -Function Get-ChangesetsInBranch