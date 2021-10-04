function Get-CommentForChangeset
{
    Param(
    [Parameter(Mandatory=$true)]
    [int]$ChangesetNumber
    )

    (Invoke-TFSAPI -Url ('_apis/tfvc/changesets/{0}' -f $ChangesetNumber)).comment  
}

Export-ModuleMember -Function Get-CommentForChangeset