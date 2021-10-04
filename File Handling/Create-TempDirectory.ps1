function Create-TempDirectory
{
    $TempDirectoryPath = (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
    Create-EmptyDirectory $TempDirectoryPath
    $TempDirectoryPath
}

Export-ModuleMember -Function Create-TempDirectory