function Get-BuildVersion {
    Param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectName = 'BuildTemplates',
        [Parameter(Mandatory=$false)]
        [string]$RepositoryName = 'BuildTemplates.ERP',
        [Parameter(Mandatory=$false)]
        [string]$VariableGroupName = 'BuildVersion',
        [Parameter(Mandatory=$false)]
        [string]$CustomerProjectName
    )

    if ($RepositoryName -ne '') {
        $APIUrl = '{0}/{1}/_apis/distributedtask/variablegroups?groupName={2}' -f (Get-TFSCollectionURL), $ProjectName, $VariableGroupName
    }
    
    $response = Invoke-TFSAPI $APIUrl -SuppressError
    if($null -eq $response){
        return $null
    } 
    else {
        if($response.count -eq 0){
            return $null
        }
    }

    $variableGroup = $response.value[0]
    $variables = $variableGroup.variables

    $searchResult = Search-VariableName -Variables $variables -SearchName $CustomerProjectName
    return $searchResult
}

function Search-VariableName {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Variables,
        [Parameter(Mandatory=$true)]
        [string]$SearchName
    )

    foreach ($varName in $Variables.PSObject.Properties.Name) {
        if ($varName -like "*$SearchName*") {
            $result = $Variables.$varName.value
        }
    }

    return $result
}

Export-ModuleMember -Function Get-BuildVersion