Function Get-ObjectsFromTFSBranch
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$BranchPath,
        [Parameter(Mandatory=$false)]
        [string]$DestinationPath,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Folder','File')]
        [string]$Type = 'File',
        [Parameter(Mandatory=$false)]
        [int]$ChangesetNo,
        [Parameter(Mandatory=$false)]
        [boolean]$UseTF = $false
    )

    if($UseTF)
    {
        Write-Progress 'Downloading objects...'

        Invoke-TFGet -PathToGet $BranchPath -ChangesetNo $ChangesetNo

        Write-Progress 'Downloading objects...' -Completed
    }
    else
    {
        if($Type -eq 'File')
        {
            if ($ChangesetNo -gt 0)
            {
                $FileContent = Invoke-TFSAPI -Url ('_apis/tfvc/items/{0}?versionType=Changeset&version={1}' -f $BranchPath, $ChangesetNo) -GetContents
            }
            else
            {
                $FileContent = Invoke-TFSAPI -Url ('_apis/tfvc/items/{0}' -f $BranchPath) -GetContents
            }

            if ($FileContent -ne 'WebServiceError')
            {
                Add-Content -Path $DestinationPath -Value $FileContent
            }
        }
        else
        {
            Create-EmptyDirectory -DirectoryPath $DestinationPath

            if ($ChangesetNo -gt 0)
            {
                $BranchFiles = Invoke-TFSAPI -Url ('_apis/tfvc/items?scopePath={0}&recusionLevel=OneLevel&versionType=Changeset&version={1}' -f $BranchPath, $ChangesetNo)
            }
            else
            {
                $BranchFiles = Invoke-TFSAPI -Url ('_apis/tfvc/items?scopePath={0}&recusionLevel=OneLevel' -f $BranchPath)
            }

            Write-Progress 'Downloading objects...'

            [int]$FileNo = 0

            foreach($BranchFile in $BranchFiles.Value)
            {
                $FileNo++
                Write-Progress 'Downloading objects...' -PercentComplete (($FileNo / $BranchFiles.count) * 100)

                if (!$BranchFile.isFolder)
                {
                    Add-Content -Path (Join-Path -Path $DestinationPath -ChildPath (Split-Path $BranchFile.path -Leaf)) -Value (Invoke-TFSAPI -Url $BranchFile.url -GetContents)
                }
            }

            Write-Progress 'Downloading objects...' -Completed
        }
    }
}

Export-ModuleMember -Function Get-ObjectsFromTFSBranch