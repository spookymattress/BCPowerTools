function Select-TFSBranch {
    $Branch = Get-TFSBranches | Out-GridView -Title 'Please select a branch' -OutputMode Single
    $Branch 
}

Export-ModuleMember -Function Select-TFSBranch