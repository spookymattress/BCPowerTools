function Get-TFSFilesPresentInFolder
{
    Param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath,
    [Parameter(Mandatory=$true)]
    [string]$BranchPath
    )

    #if the $BranchPath is actually a local folder convert it to a TFS branch path
    if ($BranchPath.Substring(0,1) -ne '$')
    {
        for ($i = 1;$i -le 2;$i++)
        {
            $TempBranchPath = $BranchPath.Substring($BranchPath.LastIndexOf('\')) + $TempBranchPath
            $BranchPath = $BranchPath.Substring(0,$BranchPath.LastIndexOf('\'))
        }

        $TempBranchPath = '$' + $TempBranchPath
        $TempBranchPath.Replace('\','/')
        $BranchPath = $TempBranchPath
    }

    $FolderItems = Get-ChildItem -Path $FolderPath
    Write-Progress -Activity 'Getting files...'
    [int]$i = 0
    foreach ($FolderItem in $FolderItems)
    {
        $i++
        Write-Progress -Activity 'Getting files...' -PercentComplete (($i / $FolderItems.Count) * 100)

        Invoke-TFGet (Join-Path $BranchPath (Split-Path $FolderItem -Leaf))
    }

    Write-Progress -Activity 'Getting files...' -Completed
}

Export-ModuleMember -Function Get-TFSFilesPresentInFolder