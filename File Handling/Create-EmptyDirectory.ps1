Function Create-EmptyDirectory
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath
    )

    if([IO.Directory]::Exists($DirectoryPath))
    {
        Remove-Item $DirectoryPath -Recurse -Force
    }
    
    [IO.Directory]::CreateDirectory($DirectoryPath) | Out-Null
}

Export-ModuleMember -Function Create-EmptyDirectory