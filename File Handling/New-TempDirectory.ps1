function New-TempDirectory
{
    $TempDirectoryPath = (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
    New-EmptyDirectory $TempDirectoryPath
    $TempDirectoryPath
}
Export-ModuleMember -Function New-TempDirectory