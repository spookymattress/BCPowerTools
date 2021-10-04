Function Get-ChangesetFiles
{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [string]$changeSetNos    
    )

    $changeSetNoCollection = $changeSetNos.Split(',')
    [bool]$changeIncludesDeletions = $false

    foreach ($changeSetNo in $changeSetNoCollection)
    {
        $changeContent = "";
        $deletedContent = "";

        #call the service to return details about the changeset
        $url = '_apis/tfvc/changesets/{0}' -f $changeSetNo

        $changeSet = Invoke-TFSAPI -Url $url

        [string]$changeSetComment = [Regex]::Replace($changeSet.comment,"[\/?:*""><|]+","")

        $changeSetComment = $changeSetComment.substring(0, [System.Math]::Min(100, $changeSetComment.Length))

        [string]$progressName = "Retrieving changeset {0} ({1})..." -f $changeSetNo, $changeSet.comment

        #call the service to retrieve the changes included in the changeset
        [string]$url = '_apis/tfvc/changesets/{0}/changes?api-version=1.0&$top=8000' -f $changeSetNo

        $changeSet = Invoke-TFSAPI -Url $url

        Write-Progress $progressName
        [int]$changeNo = 0

        #iterate through the changes calling the service for each to retrieve the content of each file as at that changeset
        foreach ($changes in $changeSet.Value)
        {    
            $changeNo++
            [string]$status = "Change {0} of {1}" -f $changeNo, $changeSet.count

            Write-Progress $progressName -Status $status -PercentComplete (($changeNo / $changeSet.count) * 100)

            foreach ($change in $changes)
            {                
                if (!$change.item.isFolder)
                {   
                    if ($change.changeType -NotLike "delete*")
                    {
                        $url = $change.item.url
                        $changeContent += Invoke-TFSAPI -Url $url -GetContents
                    }
                    else
                    {
                        #find the first changeset that the deleted object appeared in                
                        $url = '_apis/tfvc/changesets?searchCriteria.itemPath={0}&$top=1&$orderby=id%20asc' -f $change.item.path
                        $changeSets = Invoke-TFSAPI -Url $url
                
                        #get the content of the object as at that changeset
                        $url = '_apis/tfvc/items/{0}?versionType=Changeset&version={1}' -f $change.item.path, $changeSets.value[0].changesetId
                        $objectContent = Invoke-TFSAPI -Url $url -GetContents
                
                        #replace the existing Version List with "DELETEME"
                        $objectContent = [Regex]::Replace($objectContent,"Version List.*;","Version List=DELETEME;")
                        $deletedContent += $objectContent

                        $changeIncludesDeletions = $true
                    }
                }
            }    
        }

        if (!$changeContent -eq '')
        {
            #build the filename on the desktop to save the changes to, delete the file if it exists
            $filename = "{0}\CS{1} ~ {2}.TXT" -f [Environment]::GetFolderPath("Desktop"), $changeSetNo, $changeSetComment

            if ([System.IO.File]::Exists($filename))
            {
                [System.IO.File]::Delete($filename)
            }

            #write the content to the filename defined above
            Add-Content -Path $filename -Value $changeContent
        }

        if (!$deletedContent -eq '')
        {
            $deletedContentfilename = "{0}\CS{1}~{2} ~ {3}.TXT" -f [Environment]::GetFolderPath("Desktop"), $changeSetNo, 'DELETED', $changeSetComment

            if ([System.IO.File]::Exists($deletedContentfilename))
            {
                [System.IO.File]::Delete($deletedContentfilename)
            }

            #write the deleted content
            Add-Content -Path $deletedContentfilename -Value $deletedContent
        }

        Write-Progress $progressName -Completed
    }

    #if this changeset includes deletions, pop a message box to say so
    if ($changeIncludesDeletions)
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [System.Windows.Forms.MessageBox]::Show("This changeset includes some deletions. Objects for deletion are marked with 'DELETEME' in the version list.", "Deletions")
    }
}

Export-ModuleMember -Function Get-ChangesetFiles