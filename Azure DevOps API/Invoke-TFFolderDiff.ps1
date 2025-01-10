function Invoke-TFFolderDiff
{
    Param(
    [Parameter(Mandatory=$true)]
    [string]$SourceFolder,
    [Parameter(Mandatory=$true)]
    [string]$TargetFolder,
    [Parameter(Mandatory=$false)]
    [int]$SourceVersion,
    [Parameter(Mandatory=$false)]
    [int]$TargetVersion,
    [Parameter(Mandatory=$false)]
    [switch]$GetObjectsFromTarget
    )

    if($TargetVersion -gt 0)
    {
        $TargetFolder = '{0};C{1}' -f $TargetFolder, $TargetVersion
    }

    if($SourceVersion -gt 0)
    {
        $SourceFolder = '{0};C{1}' -f $SourceFolder, $SourceVersion
    }

    $ObjectDifferences = @()
    $TempFile = Join-Path (New-EmptyDirectory) -ChildPath 'FolderDiffResult.txt'
    $BatchFile = (Join-Path (Split-Path $TempFile -Parent) -ChildPath 'ExecuteFolderDiff.bat')
    [string]$Collection = '"/collection:{0}"' -f (Get-TFSCollectionURL)
    Add-Content -Path $BatchFile -Value ('"{0}" vc folderdiff "{1}" "{2}" {3} >> "{4}"'-f (Get-TFPath), $SourceFolder, $TargetFolder, $Collection, $TempFile)
         
    Start-Process -FilePath $BatchFile -WindowStyle Hidden -Wait

    $TempFileContent = Get-Content $TempFile
    $Matches = [Regex]::Matches($TempFileContent,'\D{3}\d{1,10}\.TXT')
    foreach ($Match in $Matches)
    {    
        if (!$ObjectDifferences.Contains($Match.Value))
        {
            $ObjectDifferences += $Match.Value

            if ($GetObjectsFromTarget.IsPresent) {
                Get-ObjectsFromTFSBranch -BranchPath (Join-Path $TargetFolder ($Match.Value)) -Type File -UseTF $true
            }
        }
    }

    $ObjectDifferences

    Remove-Item (Split-Path $TempFile -Parent) -Recurse -Force
}

Export-ModuleMember -Function Invoke-TFFolderDiff