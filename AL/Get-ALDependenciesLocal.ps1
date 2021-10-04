function Get-ALDependenciesLocal {
    Param(
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location),
        [Parameter(Mandatory=$false)]
        [string]$ContainerName = (Get-ContainerFromLaunchJson),
        [Parameter(Mandatory=$false)]
        [switch]$Install
    )

    if ($null -eq $RepositoryName) {

        if(($SourcePath -eq (Get-Location)) -and (Get-IsGitRepo ($SourcePath)))
        {
            $RepositoryUrl = Get-GitRepoFetchUrl
            if (($RepositoryUrl.EndsWith('-AL')) -or ($RepositoryUrl.EndsWith('-BC'))) {
                $RepositoryName = $RepositoryUrl.Substring($RepositoryUrl.Length - 3)
            }
        }
        
    }

    Write-Host "Repository Name: $RepositoryName"

    if (!([IO.Directory]::Exists((Join-Path $SourcePath '.alpackages')))) {
        Create-EmptyDirectory (Join-Path $SourcePath '.alpackages')            
    }

    $AppJson = ConvertFrom-Json (Get-Content (Join-Path $SourcePath 'app.json') -Raw)

    Get-ALDependenciesFromAppJsonLocal -AppJson $AppJson -SourcePath $SourcePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install
}

function Get-ALDependenciesFromAppJsonLocal {
    Param(
        [Parameter(Mandatory=$true)]
        $AppJson,
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location),
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$false)]
        [string]$ContainerName,
        [Parameter(Mandatory=$false)]
        [switch]$Install
    )

    if ($RepositoryName -eq '') {
        $RepositoryName = 'BC'
    }
    
    foreach ($Dependency in $AppJson.dependencies | Where-Object Name -NotLike '*Tests*' | Where-Object publisher -NotLike 'Microsoft') {
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
                Write-Host "Could not get dependency: $($Dependency.name) from environment.json file"
                if ($Dependency.publisher -eq 'Microsoft') {
                    $Apps = @()
                    $DependencyAppJson = ConvertFrom-Json '{}'
                }
                else {
                    Write-Host "Check if dependency: $($Dependency.name) is published already"
                    try {
                        $InstalledApps = Get-NavContainerAppInfo -containerName $ContainerName -tenantSpecificProperties
                        foreach ($InstalledApp in $InstalledApps | Where-Object Name -eq $Dependency.name) {
                            if ($InstalledApp.IsInstalled) {
                                Write-Host "$($Dependency.name) is installed"
                            } 
                            else {
                                throw "$($Dependency.name) is not installed"        
                            }
                        }
                    }
                        catch {
                            if (!($_.Exception.Message.Contains('already published'))) {
                                throw $_.Exception.Message

                        }
                    }
                }
            }

            if ($DependencyProject -ne '') {
                if ($null -ne $DependencyVersion) {
                    Write-Host "Getting $($AppJson.name) dependency: $($Dependency.name) version: $($DependencyVersion)"
                }
                else {
                    Write-Host "Getting $($AppJson.name) dependency: $($Dependency.name)"
                }

                $Apps = Get-AppFromLastSuccessfulBuild -ProjectName $DependencyProject -RepositoryName $DependencyRepo -BuildNumber $DependencyVersion
                $DependencyAppJson = Get-AppJsonForProjectAndRepo -ProjectName $DependencyProject -RepositoryName $DependencyRepo

                if ($null -eq $Apps) {
                    throw "$($Dependency.name) could not be downloaded"
                }
            }

            # fetch any dependencies for this app
            Get-ALDependenciesFromAppJsonLocal -AppJson $DependencyAppJson -SourcePath $SourcePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install
            
            # copy (and optionally install) the apps that have been collected
            foreach ($App in $Apps | Where-Object Name -NotLike '*Tests*') {  
                Copy-Item $App.FullName (Join-Path (Join-Path $SourcePath '.alpackages') $App.Name)
                if ($Install.IsPresent) {
                    #try {
                        Publish-NavContainerApp -containerName $ContainerName -appFile $App.FullName -sync -skipVerification -ErrorAction SilentlyContinue
                        Install-NavContainerApp -containerName $ContainerName -appName $App.Name -ErrorAction SilentlyContinue
                        #Start-NavContainerAppDataUpgrade -containerName $ContainerName -appName $App.Name
                    #}
                    #catch {
                    #    if (!($_.Exception.Message.Contains('already published'))) {
                    #        throw $_.Exception.Message
                    #    }
                    #}
                }
            } 
            
            # optionally install the test apps that have been collected as well
            if ($IncludeTest) {
                foreach ($App in $Apps | Where-Object Name -Like '*Tests*') {  
                    Copy-Item $App.FullName (Join-Path (Join-Path $SourcePath '.alpackages') $App.Name)
                    if ($Install.IsPresent) {
                        try {
                            Publish-NavContainerApp -containerName $ContainerName -appFile $App.FullName -sync -install
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

function Get-AppJsonForProjectAndRepo {
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

function Get-DependencyFromEnvironment {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Get-EnvironmentKeyValue -SourcePath $SourcePath -KeyName 'dependencies' | Where-Object name -eq $Name
}

#Export-ModuleMember -Function Get-ALDependenciesLocal
