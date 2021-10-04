function Get-TFSFiles {
    param(
        [parameter (Mandatory=$False)]
        [string]$ProjectName,
        [parameter (Mandatory=$False)]
        [string]$BranchNames,
        [string]$ObjectNames,
        [string]$ObjectFolder,
        [string]$VersionToGet,
        [string]$TFSFolder,
        [string]$tempFileName,
        [string]$tfexeLocationFolder,
        [switch]$removeExistingFiles
    )

    if ($tempFileName -eq '') {$tempFileName = 'C:\temp\psoutput.txt'}
    if ($TFSFolder -eq '') {$TFSFolder = 'C:\TFS\'}
    if ($tfexeLocationFolder -eq '') {$tfexeLocationFolder = Get-TFPath}
    if ($ProjectName -eq '')
    {
        $ProjectPath = ''
        $ProjectPath = Get-TFSBranches | Out-GridView -Title 'Select the Project Path' -OutputMode Single
        if ($ProjectPath -eq '')
        {
            return
        }
        $ProjectPath = $ProjectPath.Split("/")
        $ProjectName = $ProjectPath[1]
        for($index = 2; $index -lt $ProjectPath.Length; $index++)
        {
            if($BranchNames -eq '') 
            {
                $BranchNames = $ProjectPath[$index]
            } else {
                $BranchNames += "\" + $ProjectPath[$index]     
            }
        }
    }
    
    #If the user has not supplied any object names or an object folder then select a folder
    #Otherwise don't show the dialog
    if (($ObjectFolder -eq '') -and ($ObjectNames -eq ''))
    {
        Add-Type -AssemblyName System.Windows.Forms
        $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            SelectedPath = "C:\"
        }
 
        if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::Cancel) {
            return
        }
        $ObjectFolder = $FolderBrowser.SelectedPath
    }

    foreach ($BranchName in $BranchNames.split(",")) { 
        $defCmd = "$/$ProjectName/$BranchName"

        if ($ObjectNames -eq "") {
            if ($ObjectFolder -ne "") {
                $ObjectNames = Get-FileListFromFolder($ObjectFolder)
            }
        }

        if ($ObjectNames -ne "") {
            #$cmd += $defCmd
            foreach ($ObjectName in $ObjectNames.split(",")) {
                    if ($ObjectName -ne ""){

                        if ($ObjectName.EndsWith(".TXT") -eq $False) {
                            $ObjectName += ".TXT"
                        } 
                        $cmd += '"' + $defCmd + "/$ObjectName"
                        #$cmd +=  " " + $ObjectName
                    }
                    if ($VersionToGet -ne "") {
                        $cmd += ";$VersionToGet"
                    }
                    $cmd += '" ';
            }
        } else {
          $cmd = $defCmd;
          if ($VersionToGet -ne "") {
            $cmd += ";$VersionToGet"
          }
        }

        if ($removeExistingFiles) {
          write-output "Cleaning up local $ProjectName\$BranchName folder..."
          Start-Process -FilePath $tfexeLocationFolder -ArgumentList $("get " + '"' + $defCmd + ';1"') -WorkingDirectory $TFSFolder -Wait -NoNewWindow
        }

        if ($ObjectNames -ne "") {
            write-output "Getting $ObjectNames from $ProjectName\$BranchName..."
        } else {
            write-output "Getting items from $ProjectName\$BranchName..."
        }

        Start-Process -FilePath $tfexeLocationFolder -ArgumentList "get $cmd" -WorkingDirectory $TFSFolder -Wait -RedirectStandardOutput $tempFileName -NoNewWindow
        write-output '---------------------------------'
        $c = Get-Content -Path $tempFileName
        foreach ($l in $c) {write-host $l}
        write-output '---------------------------------'
        write-output ''
    }
}

Export-ModuleMember -Function Get-TFSFiles