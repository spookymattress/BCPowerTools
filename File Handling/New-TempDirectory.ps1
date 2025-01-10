function New-TempDirectory
{
    $TempDirectoryPath = (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
    Create-EmptyDirectory $TempDirectoryPath
    $TempDirectoryPath
}
Export-ModuleMember -Function New-EmptyDirectory