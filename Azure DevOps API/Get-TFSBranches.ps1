function Get-TFSBranches
{
    Param(        
        [Parameter(Mandatory=$false)]
        [switch]$AdditionBranches,
        [Parameter(Mandatory=$false)]
        [int]$NAVVersion = 0
    )  
 
    $BranchesCollection = New-Object System.Collections.Generic.List[System.String]  

    $Branches = Invoke-TFSAPI -Url '_apis/tfvc/branches?includeChildren=true'
    foreach ($Branch in $Branches.value)
    {        
        Add-BranchToCollection -Branch $Branch -BranchesCollection ([ref]$BranchesCollection) -AdditionBranches $AdditionBranches -NAVVersion $NAVVersion
    }

    $BranchesCollection.Sort()
    $BranchesCollection
}

function Add-BranchToCollection
{
    Param(
        $Branch,        
        [System.Collections.Generic.List[System.String]][ref]$BranchesCollection,
        [bool]$AdditionBranches,
        [int]$NAVVersion
    )

    if (($AdditionBranches -and ($AdditionBranches -eq (Get-BranchPathIsAddition $Branch.path))) -or !$AdditionBranches)
    {
        if (($AdditionBranches) -and ($NAVVersion -gt 0))
        {
            if ((Get-AdditionBasePath -AdditionPath $Branch.path).IndexOf(('NAV - Base Versions/{0}' -f $NAVVersion)) -gt 0)
            {
                $BranchesCollection.Add($Branch.path)
            }
        }
        else
        {
            $BranchesCollection.Add($Branch.path)
        }
    }

    foreach ($ChildBranch in $Branch.children)
    {
        Add-BranchToCollection -Branch $ChildBranch -BranchesCollection ([ref]$BranchesCollection) -AdditionBranches $AdditionBranches
    }
}

function Get-BranchPathIsAddition
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$BranchPath
    )

    $AdditionPrefixes = @()
    $AdditionPrefixes = '$/Addition','$/Document Delivery','$/Mobile Apps 6 NAV', '$/AppSource'

    foreach ($AdditionPrefix in $AdditionPrefixes)
    {
        if ($BranchPath.Length -gt $AdditionPrefix.Length)
        {
            if ($BranchPath.Substring(0,$AdditionPrefix.Length) -eq $AdditionPrefix)
            {            
                $true
                return
            }
        }
    }

    $false
}

Export-ModuleMember -Function Get-TFSBranches
Export-ModuleMember -Function Get-BranchPathIsAddition