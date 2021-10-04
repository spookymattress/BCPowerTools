function Get-BCVersionFromContainer {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    $BCContainerVersion = Get-BcContainerNavVersion $ContainerName
    Write-Host 'Container version: ' $BCContainerVersion

    $ContainerSplitArray = $BCContainerVersion.Split('.')
    $ContainerVersion = $ContainerSplitArray[0]+$ContainerSplitArray[1]
    [int]$ContainerVersion 
}

function Get-BCVersionFromArtifact {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ArtifactString
    )

    $Segments = "$ArtifactString/////".Split('/')
    $ArtifactUrl = Get-BCArtifactUrl -storageAccount $Segments[0] -type $Segments[1] -version $Segments[2] -country $Segments[3] -select $Segments[4] | Select-Object -First 1
    $Segments2 = "$ArtifactUrl/////".Split('/')

    $ContainerVersion = $Segments2[4]

    $ContSplitArray = $ContainerVersion.Split('.')
    $ContainerVersion = $ContSplitArray[0]+$ContSplitArray[1]
    [int]$ContainerVersion 
}

Export-ModuleMember -Function Get-BCVersionFromContainer
Export-ModuleMember -Function Get-BCVersionFromArtifact