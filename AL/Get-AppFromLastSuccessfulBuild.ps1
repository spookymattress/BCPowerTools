function Get-AppFromLastSuccessfulBuild {
    Param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectName,
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName = '',
        [Parameter(Mandatory=$false)]
        [switch]$OpenExplorer,
        [Parameter(Mandatory=$false)]
        [switch]$IncludeTests,
        [Parameter(Mandatory=$false)]
        [string]$BranchName = ''
    )

    $VSTSProjectName = Get-ProjectName $ProjectName

    if ($RepositoryName -ne '') {
        $APIUrl = ('{0}{1}/_apis/build/builds?queryOrder=finishTimeDescending&resultFilter=succeeded&$top=1&repositoryId={2}&repositoryType=TfsGit' -f (Get-TFSCollectionURL), $VSTSProjectName, (Get-RepositoryId -ProjectName $VSTSProjectName -RepositoryName $RepositoryName))
    }
    else {
        $APIUrl = ('{0}{1}/_apis/build/builds?queryOrder=finishTimeDescending&resultFilter=succeeded&$top=1' -f (Get-TFSCollectionURL), $VSTSProjectName)
    }
    if ($BranchName -ne ''){
        $APIUrl += '&branchName=refs/heads/{0}' -f $BranchName
    }
    
    $Build = Invoke-TFSAPI $APIUrl -SuppressError
    if($null -eq $Build){
        return $null
    } 
    else {
        if($Build.count -eq 0){
            return $null
        }
    }

    $Artifacts = Invoke-TFSAPI ('{0}{1}/_apis/build/builds/{2}/artifacts' -f (Get-TFSCollectionURL), $VSTSProjectName, $Build.value.id)
    $ArtifactPath = Join-Path (Create-TempDirectory) ('{0}.zip' -f (Get-URLParameterValue -Url $Artifacts.value.resource.downloadUrl -ParameterName 'artifactName'))
    Invoke-TFSAPI ($Artifacts.value.resource.downloadUrl) -OutFile -OutFilePath $ArtifactPath
    $ExpandPath = (Create-TempDirectory)
    Expand-Archive -Path $ArtifactPath -DestinationPath $ExpandPath

    if ($IncludeTests.IsPresent) {
        Get-ChildItem -Path $ExpandPath -Filter '*.app' -Recurse
    }
    else {
        Get-ChildItem -Path $ExpandPath -Filter '*.app' -Recurse | ? FullName -NotLike '*Tests*'
    }

    if ($OpenExplorer.IsPresent) {
        explorer (Split-Path (Get-ChildItem -Path $ExpandPath -Filter '*app' -Recurse).Item(0).FullName -Parent)
    }
    Remove-Item $ArtifactPath -Recurse
}

function Get-URLParameterValue {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$ParameterName
    )

    $ParameterString = $Url.Substring($Url.IndexOf('?') + 1)
    $Parameters = $ParameterString.Split('&')
    $Parameter = $Parameters | where {$_ -like ('{0}*' -f $ParameterName)}
    $Parameter.Substring($Parameter.IndexOf('=') + 1)
}

Export-ModuleMember -Function Get-AppFromLastSuccessfulBuild