function Invoke-TFGet
{
    Param(
    [Parameter(Mandatory=$true)]
    [string]$PathToGet,
    [Parameter(Mandatory=$false)]
    [int]$ChangesetNo = 0
    )

    $TFPath = Get-TFPath
    $PathToGet = '"{0}"' -f $PathToGet.Replace('\','/')
    if ($ChangesetNo -eq 1)
    {
        Start-Process -FilePath $TFPath -ArgumentList ('vc','get',$PathToGet,('/version:C{0}' -f $ChangesetNo),'/recursive') -WindowStyle Hidden -Wait
    }
    elseif ($ChangesetNo -gt 0)
    {
        Start-Process -FilePath $TFPath -ArgumentList ('vc','get',$PathToGet,('/version:C{0}' -f $ChangesetNo)) -WindowStyle Hidden -Wait
    }
    else
    {
        Start-Process -FilePath $TFPath -ArgumentList ('vc','get',$PathToGet) -WindowStyle Hidden -Wait
    }
}

Export-ModuleMember -Function Invoke-TFGet