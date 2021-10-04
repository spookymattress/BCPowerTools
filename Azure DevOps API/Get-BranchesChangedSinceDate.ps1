function Get-BranchesChangedSinceDate
{
    Param(
        [Parameter(Mandatory=$false)]
        [DateTime]$ChangedSinceDate = [DateTime]::Today,
        [Parameter(Mandatory=$false)]
        [switch]$AdditionBranches
    )

    $ChangedBranches = @()

    if ($AdditionBranches)
    {
        $Branches = Get-TFSBranches -AdditionBranches
    }
    else
    {
        $Branches = Get-TFSBranches
    }

    foreach($Branch in $Branches)
    {
        [DateTime]$DateOfLastChange = [DateTime]::Parse((Get-DateOfLastChangesetInBranch -BranchPath $Branch))
        if ($DateOfLastChange -gt $ChangedSinceDate)
        {
            $ChangedBranches += $Branch
        }
    }

    $ChangedBranches
}

function Get-DateOfLastChangesetInBranch
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$BranchPath
    )

    $Changeset = Get-ChangesetsInBranch -BranchPath $BranchPath -ChangeSetOption Newest
    (Invoke-TFSAPI -Url ('_apis/tfvc/changesets/{0}' -f $Changeset)).createdDate
}

Export-ModuleMember -Function Get-BranchesChangedSinceDate
Export-ModuleMember -Function Get-DateOfLastChangesetInBranch