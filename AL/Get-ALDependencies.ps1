function Get-ALDependencies {
    Param(
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location),
        [Parameter(Mandatory=$false)]
        [string]$ContainerName = (Get-ContainerFromLaunchJson),
        [Parameter(Mandatory=$false)]
        [switch]$Install
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

    Write-Host "Repository Name: $RepositoryName"

    if (!([IO.Directory]::Exists((Join-Path $SourcePath '.alpackages')))) {
        Create-EmptyDirectory (Join-Path $SourcePath '.alpackages')            
    }

    $AppJson = ConvertFrom-Json (Get-Content (Join-Path $SourcePath 'app.json') -Raw)

    Get-ALDependenciesFromAppJson -AppJson $AppJson -SourcePath $SourcePath -SavePath $SourcePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install
}

function Get-ALDependenciesFromAppJson {
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
        [switch]$Install
    )
    
    foreach ($Dependency in $AppJson.dependencies) {
        $EnvDependency = Get-DependencyFromEnvironment -SourcePath $SourcePath -Name $Dependency.name
        Write-Host "Getting $($AppJson.name) dependency: $($Dependency.name)"
        $Apps = Get-AppFromLastSuccessfulBuild -ProjectName $EnvDependency.project -RepositoryName $EnvDependency.repo
        $DependencyAppJson = Get-AppJsonForProjectAndRepo -ProjectName $EnvDependency.project -RepositoryName $EnvDependency.repo
        if ($DependencyAppJson.dependencies.length -gt 0) {
            $DepSourcePath = Get-EnvironmentJsonForProjectAndRepo -ProjectName $EnvDependency.project -RepositoryName $EnvDependency.repo
            Get-ALDependenciesFromAppJson -AppJson $DependencyAppJson -SourcePath $DepSourcePath -SavePath $SavePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install    
        } else {
            Get-ALDependenciesFromAppJson -AppJson $DependencyAppJson -SourcePath $SourcePath -SavePath $SavePath -RepositoryName $RepositoryName -ContainerName $ContainerName -Install:$Install    
        }
        
        
        foreach ($App in $Apps) {
            if (!$App.FullName.Contains('Tests')) {
                Copy-Item $App.FullName (Join-Path (Join-Path $SavePath '.alpackages') $App.Name)
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

function Get-EnvironmentJsonForProjectAndRepo {
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

    $AppContent = Invoke-TFSAPI ('{0}{1}/_apis/git/repositories/{2}/items?path=app/environment.json' -f (Get-TFSCollectionURL), $VSTSProjectName, (Get-RepositoryId -ProjectName $VSTSProjectName -RepositoryName $RepositoryName)) -GetContents
    $FilePath = Join-Path (Create-TempDirectory) ('environment.json' -f (New-Guid))
    Out-File -FilePath $FilePath -InputObject $AppContent
    $FilePath = Split-Path -Path $FilePath -resolve
    $FilePath
}

Export-ModuleMember -Function Get-ALDependencies
Export-ModuleMember -Function Get-ALDependenciesFromAppJson
Export-ModuleMember -Function Get-AppJsonForProjectAndRepo
Export-ModuleMember -Function Get-EnvironmentJsonForProjectAndRep