function Get-ALDependencies {
<#
.SYNOPSIS
    Downloads all AL dependencies for a Business Central project into .alpackages.
.DESCRIPTION
    Reads app.json from the project at SourcePath, resolves every non-Microsoft, non-test
    dependency recursively, and copies the .app files into .alpackages. Dependencies are
    downloaded from the last successful Azure DevOps build for each project.

    Each dependency is only downloaded once per invocation (deduplication cache). All
    temporary directories created during the run are cleaned up automatically.
.PARAMETER SourcePath
    Root folder of the AL project (must contain app.json). Defaults to the current directory.
.PARAMETER ContainerName
    Name of the BC Docker container used to check which apps are already installed.
    Defaults to the container defined in .vscode/launch.json.
.PARAMETER Install
    Publish and install each downloaded app into the BC container.
.PARAMETER WriteDepenciesToCSVFile
    Append each resolved dependency to .alpackages\dep.csv.
.PARAMETER Inspect
    Dry-run mode. Resolves and validates the full dependency graph (verifying that a
    successful build exists for every dependency) without downloading, copying, or
    touching the container.
.EXAMPLE
    Get-ALDependencies
.EXAMPLE
    Get-ALDependencies -Install
.EXAMPLE
    Get-ALDependencies -Inspect
#>
    Param(
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location),
        [Parameter(Mandatory=$false)]
        [string]$ContainerName = (Get-ContainerFromLaunchJson),
        [Parameter(Mandatory=$false)]
        [switch]$Install,
        [Parameter(Mandatory=$false)]
        [switch]$WriteDepenciesToCSVFile,
        [Parameter(Mandatory=$false)]
        [switch]$Inspect
    )

    $RepositoryName = (Get-EnvironmentKeyValue -SourcePath $SourcePath -KeyName 'repo')

    if ($null -eq $RepositoryName) {

        if(($SourcePath -eq (Get-Location)) -and (Get-IsGitRepo ($SourcePath)))
        {
            $RepositoryUrl = Get-GitRepoFetchUrl
            if (($RepositoryUrl.EndsWith('-AL')) -or ($RepositoryUrl.EndsWith('-BC'))) {
                $RepositoryName = $RepositoryUrl.Substring($RepositoryUrl.Length - 3)
            }
        }
    }

    if ($null -ne $RepositoryName)	{
        Write-Host "Repository Name: $RepositoryName."
    }

    $script:ALDependencyCache = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $script:ALTempDirectories = [System.Collections.Generic.List[string]]::new()
    $script:ALLastExtractPath = $null

    if (-not $Inspect.IsPresent) {
        if (!([IO.Directory]::Exists((Join-Path $SourcePath '.alpackages')))) {
            New-EmptyDirectory (Join-Path $SourcePath '.alpackages')
        }
    }

    $AppJson = Get-Content (Join-Path $SourcePath 'app.json') -Raw -Encoding UTF8 | ConvertFrom-Json

    try {
        Get-ALDependenciesFromAppJson -AppJson $AppJson -SourcePath $SourcePath -SavePath $SourcePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install -WriteDepenciesToCSVFile:$WriteDepenciesToCSVFile -Inspect:$Inspect
    } finally {
        foreach ($dir in $script:ALTempDirectories) {
            if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        }
    }
}

function Get-ALDependenciesFromAppJson {
<#
.SYNOPSIS
    Recursively resolves and downloads AL dependencies described in an app.json object.
.DESCRIPTION
    For each non-Microsoft, non-test dependency in AppJson:
      1. Looks up project/repo/version from environment.json (if present) or derives them
         from the dependency name and RepositoryName.
      2. Skips dependencies already installed in the container or already processed this run.
      3. Downloads the artifact from the last successful Azure DevOps build. app.json and
         environment.json are read from the artifact if available, otherwise fetched from
         the repository default branch via the API.
      4. Recurses into transitive dependencies before copying .app files to SavePath\.alpackages.
.PARAMETER AppJson
    Parsed app.json object whose dependencies are to be resolved.
.PARAMETER SourcePath
    Folder containing environment.json for the current app. Used to look up per-project
    dependency overrides.
.PARAMETER SavePath
    Root folder where .alpackages lives. Defaults to the current directory.
.PARAMETER RepositoryName
    Azure DevOps repository name used as the default when a dependency has no explicit repo.
.PARAMETER ContainerName
    BC Docker container used to check which apps are already installed.
.PARAMETER Install
    Publish and install each downloaded app into the container.
.PARAMETER WriteDepenciesToCSVFile
    Append each resolved dependency to SavePath\.alpackages\dep.csv.
.PARAMETER Inspect
    Dry-run mode — validates dependency availability without downloading or installing.
#>
    Param(
        [Parameter(Mandatory=$true)]
        $AppJson,
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location),
        [Parameter(Mandatory=$false)]
        [string]$SavePath = (Get-Location),
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$false)]
        [string]$ContainerName,
        [Parameter(Mandatory=$false)]
        [switch]$Install,
        [Parameter(Mandatory=$false)]
        [switch]$WriteDepenciesToCSVFile,
        [Parameter(Mandatory=$false)]
        [switch]$Inspect
    )

    if ($WriteDepenciesToCSVFile -and -not $Inspect.IsPresent) {
        $dependencyFile = Join-Path (Join-Path $SavePath '.alpackages') dep.csv
        if (Test-Path $dependencyFile)  {
            Remove-Item $dependencyFile -Force
        }
    }

    if ($RepositoryName -eq '') {
        $RepositoryName = 'BC'
    }

    foreach ($Dependency in $AppJson.dependencies | Where-Object Name -NotLike '*Test*') {
		if ($null -ne $Dependency) {
            # is the source for this app defined in the environment file?
            $EnvDependency = Get-DependencyFromEnvironment -SourcePath $SourcePath -Name $Dependency.name
            if ($null -ne $EnvDependency) {
                if ($null -ne $EnvDependency.includetest) {
                    $IncludeTest = $EnvDependency.includetest
                }

                $DependencyProject = $EnvDependency.project
                $DependencyRepo = $EnvDependency.repo
                $DependencyVersion = $EnvDependency.version

            }
            # otherwise aquire the app from the last successful build
            else {
                if ($Dependency.publisher -eq 'Microsoft') {
                    $Apps = @()
                    $DependencyAppJson = ConvertFrom-Json '{}'

                    $DependencyProject = ''
                    $DependencyRepo = ''
                }
                else {
                    $DependencyProject = $Dependency.name
                    $DependencyRepo = $RepositoryName
                }
            }
			
            $InstalledDependency = Get-BCContainerAppInfo -ContainerName $ContainerName -InstalledOnly -UseNewFormat | Where-Object {$_.Name -eq $Dependency.Name} 
            if ($InstalledDependency -ne $null){
                Write-Host "Skipping installed dependency: $($InstalledDependency.Name)" -ForegroundColor Yellow
                continue				
            }			
			

            if (-not $script:ALDependencyCache.Add($Dependency.name)) {
                Write-Host "Skipping already downloaded dependency: $($Dependency.name)" -ForegroundColor Yellow
                continue
            }
            if ($DependencyProject -ne '') {
                $appNamePrefix = if ($AppJson.Name) { "$($AppJson.Name) " } else { "" }
                if ($null -ne $DependencyVersion) {
                    Write-Host "Getting ${appNamePrefix}dependency: $($Dependency.name) version: $($DependencyVersion)" -NoNewline
                }
                else {
                    Write-Host "Getting ${appNamePrefix}dependency: $($Dependency.name)" -NoNewline
                }

                $Apps = Get-AppFromLastSuccessfulBuild -ProjectName $DependencyProject -RepositoryName $DependencyRepo -BuildNumber $DependencyVersion -Inspect:$Inspect
                if ($null -eq $Apps) {
                    throw "$($Dependency.name) could not be downloaded"
                }
                $appJsonInArtifact = $null
                if ($null -ne $script:ALLastExtractPath) {
                    $appJsonInArtifact = Get-ChildItem -Path $script:ALLastExtractPath -Filter 'app.json' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                }
                if ($null -ne $appJsonInArtifact) {
                    $DependencyAppJson = Get-Content $appJsonInArtifact.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                } else {
                    $DependencyAppJson = Get-AppJsonForProjectAndRepo -ProjectName $DependencyProject -RepositoryName $DependencyRepo
                }
            }

            # fetch any dependencies for this app
            if ($DependencyAppJson.dependencies.length -gt 0) {
                $envJsonInArtifact = $null
                if ($null -ne $script:ALLastExtractPath) {
                    $envJsonInArtifact = Get-ChildItem -Path $script:ALLastExtractPath -Filter 'environment.json' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                }
                if ($null -ne $envJsonInArtifact) {
                    $DepSourcePath = Split-Path $envJsonInArtifact.FullName -Parent
                } else {
                    $DepSourcePath = Get-EnvironmentJsonForProjectAndRepo -ProjectName $EnvDependency.project -RepositoryName $EnvDependency.repo
                }
                Get-ALDependenciesFromAppJson -AppJson $DependencyAppJson -SourcePath $DepSourcePath -SavePath $SavePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install -WriteDepenciesToCSVFile:$WriteDepenciesToCSVFile -Inspect:$Inspect
            } else {
                Get-ALDependenciesFromAppJson -AppJson $DependencyAppJson -SourcePath $SourcePath -SavePath $SavePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install -WriteDepenciesToCSVFile:$WriteDepenciesToCSVFile -Inspect:$Inspect
            }
            
            # copy (and optionally install) the apps that have been collected
            foreach ($App in $Apps | Where-Object Name -NotLike '*Test*') {
                if ($Inspect.IsPresent) {
                    Write-Host "INSPECT: Would copy $($App.Name) to .alpackages" -ForegroundColor Cyan
                } else {
                    Copy-Item $App.FullName (Join-Path (Join-Path $SavePath '.alpackages') $App.Name)
                    if ($Install.IsPresent) {
                        try {
                            Publish-BcContainerApp -containerName $ContainerName -appFile $App.FullName -sync -install -skipVerification -checkAlreadyInstalled -IgnoreIfAppExists
                        }
                        catch {
                            if (!($_.Exception.Message.Contains('already published'))) {
                                throw $_.Exception.Message
                            }
                        }
                    }
                }
                Write-Host $App.Name
                if ($WriteDepenciesToCSVFile.IsPresent -and -not $Inspect.IsPresent) {
                    try {
                        Write-Host "Writing dependency: $($App.name) to file"
                        New-Object -TypeName PSCustomObject -Property @{ID=$App.Name } | Export-Csv -Path $dependencyFile -NoTypeInformation -Append
                    }
                    catch {
                        if (!($_.Exception.Message.Contains('error writing to csv file'))) {
                            throw $_.Exception.Message
                        }
                    }
                }
            }
            
            # optionally install the test apps that have been collected as well
            if ($IncludeTest) {
                foreach ($App in $Apps | Where-Object Name -Like '*Test*') {
                    if ($Inspect.IsPresent) {
                        Write-Host "INSPECT: Would copy $($App.Name) to .alpackages" -ForegroundColor Cyan
                    } else {
                        Copy-Item $App.FullName (Join-Path (Join-Path $SavePath '.alpackages') $App.Name)
                        if ($Install.IsPresent) {
                            try {
                                Publish-BcContainerApp -containerName $ContainerName -appFile $App.FullName -sync -skipVerification -install -checkAlreadyInstalled -IgnoreIfAppExists
                            }
                            catch {
                                if (!($_.Exception.Message.Contains('already published'))) {
                                    throw $_.Exception.Message
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

function Get-AppJsonForProjectAndRepo {
<#
.SYNOPSIS
    Fetches app.json for a given Azure DevOps project and repository from the default branch.
.PARAMETER ProjectName
    Short project name (resolved to a VSTS project via Get-ProjectName).
.PARAMETER RepositoryName
    Repository name within the project. Defaults to 'BC'.
.PARAMETER Publisher
    Pass 'Microsoft' to short-circuit and return an empty object.
#>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$false)]
        [string]$Publisher
    )
    if ($Publisher -eq 'Microsoft') {
        return '{}'
    }
    
    $VSTSProjectName = Get-ProjectName $ProjectName

    if ($RepositoryName -eq '') {
        $RepositoryName = 'BC'
    }

    $AppContent = Invoke-TFSAPI ('{0}{1}/_apis/git/repositories/{2}/items?path=app/app.json' -f (Get-TFSCollectionURL), $VSTSProjectName, (Get-RepositoryId -ProjectName $VSTSProjectName -RepositoryName $RepositoryName)) -GetContents
    $AppJson = ConvertFrom-Json $AppContent
    $AppJson
}

function Get-EnvironmentJsonForProjectAndRepo {
<#
.SYNOPSIS
    Fetches environment.json for a given Azure DevOps project and repository and writes it
    to a temporary file, returning the directory path.
.DESCRIPTION
    Used to obtain per-project dependency overrides when resolving transitive dependencies.
    Returns the parent directory of the written file so it can be passed as SourcePath to
    Get-ALDependenciesFromAppJson. Returns an empty JSON object if the file does not exist.
.PARAMETER ProjectName
    Short project name (resolved to a VSTS project via Get-ProjectName).
.PARAMETER RepositoryName
    Repository name within the project. Defaults to 'BC'.
.PARAMETER Publisher
    Pass 'Microsoft' to short-circuit and return an empty object.
#>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$false)]
        [string]$Publisher
    )
    if ($Publisher -eq 'Microsoft') {
        return '{}'
    }
    
    $VSTSProjectName = Get-ProjectName $ProjectName

    if ($RepositoryName -eq '') {
        $RepositoryName = 'BC'
    }

    $AppContent = Invoke-TFSAPI ('{0}{1}/_apis/git/repositories/{2}/items?path=app/environment.json' -f (Get-TFSCollectionURL), $VSTSProjectName, (Get-RepositoryId -ProjectName $VSTSProjectName -RepositoryName $RepositoryName)) -GetContents -SuppressError
    $FilePath = Join-Path (New-TempDirectory) ('environment.json' -f (New-Guid))
    if ($null -ne $AppContent) {
        Out-File -FilePath $FilePath -InputObject $AppContent
    }
    else {
        Out-File -FilePath $FilePath -InputObject '{}'
    }
    
    $FilePath = Split-Path -Path $FilePath -resolve
    $FilePath
}

function Get-DependencyFromEnvironment {
<#
.SYNOPSIS
    Returns the dependency override entry for a named app from the local environment.json.
.PARAMETER SourcePath
    Folder containing environment.json.
.PARAMETER Name
    App name to look up in the dependencies array.
#>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Get-EnvironmentKeyValue -SourcePath $SourcePath -KeyName 'dependencies' | Where-Object name -eq $Name
}

Export-ModuleMember -Function Get-ALDependencies
Export-ModuleMember -Function Get-ALDependenciesFromAppJson
Export-ModuleMember -Function Get-AppJsonForProjectAndRepo
Export-ModuleMember -Function Get-EnvironmentJsonForProjectAndRepo
