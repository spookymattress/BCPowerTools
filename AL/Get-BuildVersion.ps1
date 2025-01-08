function Get-BuildVersion {
    Param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectName,
        [Parameter(Mandatory=$false)]
        [string]$VariableGroupName = 'Build',
        [Parameter(Mandatory=$false)]
        [string]$CustomerProjectName,
        [Parameter(Mandatory=$false)]
        [string]$SearchName = 'version'
    )

    if ($ProjectName -ne '') {
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

    $searchResult = Search-VariableName -Variables $variables -SearchName $SearchName
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
        if ($varName -clike "*$SearchName*") {
            $result = $Variables.$varName.value
        }
    }

    return $result
}

Export-ModuleMember -Function Get-BuildVersion