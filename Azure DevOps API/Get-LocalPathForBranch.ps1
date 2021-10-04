function Get-LocalPathForBranch()
{
    Param(
    [Parameter(Mandatory=$true)]
    $BranchPath
    )

    $ResultFile = Join-Path (Create-TempDirectory) -ChildPath 'Result.txt'
    $BatchFile = (Join-Path (Split-Path $ResultFile -Parent) -ChildPath 'GetLocalPathForBranch.bat')    
    Add-Content -Path $BatchFile -Value ('"{0}" vc resolvepath "{1}" >> "{2}"' -f (Get-TFPath),$BranchPath,$ResultFile)
    Start-Process -FilePath $BatchFile -WindowStyle Hidden -Wait
    
    Get-Content $ResultFile

    Remove-Item (Split-Path $ResultFile -Parent) -Force -Recurse
}

Export-ModuleMember -Function Get-LocalPathForBranch