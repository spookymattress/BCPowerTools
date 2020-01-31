function Get-Shelvesets
{
    Param(
        [Parameter(Mandatory=$false)]
        [string]$Owner
    )

    if ($Owner -ne '')
    {
        $Shelvesets = Invoke-TFSAPI ('_apis/tfvc/shelvesets?owner={0}' -f $Owner)
    }
    else
    {
        $Shelvesets = Invoke-TFSAPI '_apis/tfvc/shelvesets'
    }

    $Shelvesets.value
}

function Select-Shelveset
{
    $Owner = ('{0}' -f (whoami).Substring((whoami).LastIndexOf('\') + 1).Replace('.',' '))
    $Shelveset = Get-Shelvesets -Owner $Owner | Out-GridView -OutputMode Single
    $Shelveset
}

function Get-ShelvesetRollbackFiles
{
    $Shelveset = Select-Shelveset
    $ShelvesetChanges = Invoke-TFSAPI ('_apis/tfvc/shelvesets/{0}?maxChangeCount=100' -f $Shelveset.id)
    foreach ($ShelvesetChange in $ShelvesetChanges.changes)
    {
        $ObjectContent = Invoke-TFSAPI ('_apis/tfvc/items/{0}?versionType=Changeset&version={1}' -f $ShelvesetChange.item.path, $ShelvesetChange.item.version)
        if ($ObjectContent -eq 'WebServiceError')
        {
            $ObjectContent = Invoke-TFSAPI $ShelvesetChange.item.url
            $TempFile = New-TemporaryFile
            Add-Content -Value $ObjectContent -Path $TempFile.FullName
            Set-NAVApplicationObjectProperty -TargetPath $TempFile.FullName -VersionListProperty 'DELETEME'
            $ObjectContent = Get-Content $TempFile.FullName -Raw
        }

        $RollbackContent += $ObjectContent
    }

    $FilePath = Join-Path ([System.Environment]::GetFolderPath("Desktop")) ($Shelveset.name + '.TXT')
    if (Test-Path -Path $FilePath)
    {
        Remove-Item $FilePath -Force
    }

    Add-Content $FilePath -Value $RollbackContent
}

Export-ModuleMember -Function Get-ShelvesetRollbackFiles
Export-ModuleMember -Function Get-Shelvesets
Export-ModuleMember -Function Select-Shelveset