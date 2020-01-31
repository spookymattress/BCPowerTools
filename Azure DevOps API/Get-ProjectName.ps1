function Get-ProjectName {
    param(
        # project name (or part of project name) to find match for
        [Parameter(Mandatory=$false)]
        [string]
        $ProjectName = ''
    )

    if ($ProjectName -eq '') {
        return
    }

    $VSTSProjectName = (Get-VSTSProjects | Where-Object name -like ('*{0}' -f $ProjectName)).name
    if (($null -eq $VSTSProjectName) -and ($ProjectName.StartsWith('Clever'))) {
        $VSTSProjectName = (Get-VSTSProjects | Where-Object name -like ('*{0}' -f $ProjectName.Substring(7))).name
    }

    $VSTSProjectName
}

Export-ModuleMember -Function Get-ProjectName