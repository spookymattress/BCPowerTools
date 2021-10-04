function Get-BranchNameForDependencies {
    param (
        # path that contains the source code of the dependent app
        [Parameter(Mandatory=$false)]
        [string]
        $Path = (Get-Location)
    )
    
    if ($null -ne (Get-EnvironmentKeyValue -SourcePath $Path -KeyName 'dependencyBranch')) {
        return (Get-EnvironmentKeyValue -SourcePath $Path -KeyName 'dependencyBranch')
    }

    if ($null -ne (Get-TFSConfigKeyValue -KeyName 'dependencyBranches')) {
        [Version]$PlatformVersion = [Version]::new()
        if (!([Version]::TryParse((Get-AppKeyValue -SourcePath $Path -KeyName 'platform'), [ref]$PlatformVersion))) {
            return ''
        }

        $DependencyBranches = Get-TFSConfigKeyValue -KeyName 'dependencyBranches'
        foreach ($DependencyBranch in $DependencyBranches) {
            [Version]$FromVersion = [Version]::new()
            [Version]$ToVersion = [Version]::new()
            if ([Version]::TryParse($DependencyBranch.from, [ref]$FromVersion)) {
                if ([Version]::TryParse($DependencyBranch.to, [ref]$ToVersion)) {
                    if (($PlatformVersion -ge $FromVersion) -and ($PlatformVersion -le $ToVersion)) {
                        return $DependencyBranch.branch
                    }
                }
            }
        }
    }

    return ''
}

Export-ModuleMember -Function Get-BranchNameForDependencies