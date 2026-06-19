function Get-AppFromLastSuccessfulBuild {
<#
.SYNOPSIS
    Downloads the .app files from the last successful Azure DevOps build for a project.
.DESCRIPTION
    Queries the Azure DevOps build API for the most recent successful build of the given
    project/repository, downloads the artifact ZIP, extracts it to a temporary directory,
    and returns FileInfo objects for each .app file (excluding test apps unless -IncludeTests
    is set). The ZIP is deleted after extraction; the extracted directory is registered in
    $script:ALTempDirectories so the caller can clean it up after copying the files.

    When -Inspect is set, the function returns an empty array immediately after confirming
    a successful build exists, without downloading anything.
.PARAMETER ProjectName
    Short project name (resolved to a VSTS project via Get-ProjectName).
.PARAMETER RepositoryName
    Repository name used to filter builds. When empty, the latest build across all
    repositories in the project is used.
.PARAMETER BranchName
    Limit the build search to a specific branch (e.g. 'main').
.PARAMETER BuildNumber
    Limit the build search to a specific build number.
.PARAMETER IncludeTests
    Include test apps (files whose path contains 'Tests') in the returned list.
.PARAMETER OpenExplorer
    Open Windows Explorer at the extracted artifact folder after downloading.
.PARAMETER Inspect
    Dry-run mode. Returns an empty array after confirming a successful build exists,
    without downloading or extracting the artifact.
.OUTPUTS
    System.IO.FileInfo — one entry per .app file found in the artifact.
.EXAMPLE
    Get-AppFromLastSuccessfulBuild -ProjectName 'MyApp' -RepositoryName 'BC'
.EXAMPLE
    Get-AppFromLastSuccessfulBuild -ProjectName 'MyApp' -RepositoryName 'BC' -Inspect
#>
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
        [string]$BranchName = '',
        [Parameter(Mandatory=$false)]
        [string]$BuildNumber = '',
        [Parameter(Mandatory=$false)]
        [switch]$Inspect
    )

    $VSTSProjectName = Get-ProjectName $ProjectName

    if ($RepositoryName -ne '') {
        $APIUrl = ('{0}{1}/_apis/build/builds?queryOrder=finishTimeDescending&resultFilter=succeeded&$top=1&repositoryId={2}&repositoryType=TfsGit' -f (Get-TFSCollectionURL), $VSTSProjectName, (Get-RepositoryId -ProjectName $VSTSProjectName -RepositoryName $RepositoryName))
    }
    else {
        $APIUrl = ('{0}{1}/_apis/build/builds?queryOrder=finishTimeDescending&resultFilter=succeeded&$top=1' -f (Get-TFSCollectionURL), $VSTSProjectName)
    }
    if ($BranchName -ne '') {
        $APIUrl += '&branchName=refs/heads/{0}' -f $BranchName
    }
    if ($BuildNo -ne '') {
        $APIUrl += '&buildNumber={0}' -f $BuildNumber
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

    Write-Host " (repo: $RepositoryName, build: $($Build.value.buildNumber))." -ForegroundColor Cyan

    if ($Inspect.IsPresent) {
        return ,@()
    }

    $Artifacts = Invoke-TFSAPI ('{0}{1}/_apis/build/builds/{2}/artifacts' -f (Get-TFSCollectionURL), $VSTSProjectName, $Build.value.id)

    $ArtifactPath = Join-Path (New-TempDirectory) ('{0}.zip' -f (Get-URLParameterValue -Url $Artifacts.value.resource.downloadUrl -ParameterName 'artifactName'))
    Invoke-TFSAPI ($Artifacts.value.resource.downloadUrl) -OutFile -OutFilePath $ArtifactPath
    $ExpandPath = (New-TempDirectory)
    Expand-Archive -Path $ArtifactPath -DestinationPath $ExpandPath
    $script:ALTempDirectories.Add($ExpandPath)
    $script:ALLastExtractPath = $ExpandPath

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