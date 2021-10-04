function Get-VSTSProjects {
    (Invoke-TFSAPI -Url ('{0}_apis/projects?$top=1000' -f (Get-TFSCollectionURL))).value
}

Export-ModuleMember -Function Get-VSTSProjects