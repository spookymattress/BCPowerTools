function Get-TFPath
{
    $TestPaths = 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\TF.exe','C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\TF.exe','C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe','C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe'
    foreach ($TestPath in $TestPaths)
    {
        if (Test-Path $TestPath)
        {
            return $TestPath       
        }
    }

    $TestPath = 'C:\Program Files (x86)\Microsoft Visual Studio\*\*\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe'
    if (Test-Path $TestPath)
    {
        return Resolve-Path $TestPath | Select-Object -ExpandProperty Path
    }
    
    Write-Error -Message 'Could not locate tf.exe'
}

Export-ModuleMember -Function Get-TFPath