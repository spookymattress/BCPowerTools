Function Get-ChangesetNumberForVersionList
{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [string]$BranchPath,
        [Parameter(Mandatory=$true,Position=2)]        
        [string]$VersionList,
        [Parameter(Mandatory=$false)]
        [switch]$NoError
    )

    $url = '_apis/tfvc/changesets/?searchCriteria.itemPath={0}&$top=200' -f $BranchPath
    $changeSets = Invoke-TFSAPI -Url $url
    [int]$changeSetNo = 0
    
    foreach ($changeSet in $changeSets.value)
    {        
        if ($VersionList.Length -le $changeSet.comment.Length)
        {
            if ($changeSet.comment.Substring(0,$VersionList.Length) -eq $VersionList)
            {         
                if ($changeSet.comment.Length -eq $VersionList.Length)
                {
                    $changeSetNo = $changeSet.changesetId
                    $changeSetNo
                    return
                }
                elseif ($changeSet.comment.Substring($VersionList.Length,1) -eq ' ')
                {
                    $changeSetNo = $changeSet.changesetId
                    $changeSetNo
                    return
                }
            }
        }
    }

    if ($NoError.IsPresent) {
        0
    }
    else {
        throw ('Could not find changeset Id for {0} in {1}' -f $VersionList, $BranchPath)
    }
}

Export-ModuleMember -Function Get-ChangesetNumberForVersionList