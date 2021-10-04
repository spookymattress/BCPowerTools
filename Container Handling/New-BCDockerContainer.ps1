<# 
 .Synopsis
  Create a NAV Docker Container
 .Description
 .Parameter containerName
  Name of the container you are creating
 .Parameter licenseFile
  Licensefile for the container
 .Parameter BCVersion
 The Business Central version you want to use for the container
#>

function New-BCDockerContainer {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $containerName, 
        [Parameter(Mandatory=$true)]
        [string] $licenseFile,
        [Parameter(Mandatory=$true)]
        [ValidateSet('BC13.0DK','BC13.1DK','BC13.2DK','BC13.3DK','BC13.4DK','BC13.5DK','BC13.6DK','BC13.7DK','BC13.8DK','BC14.0DK','BC14.0-W1','BC14.1DK','BC15.0DK','BC15.1DK','BC15.2DK','BC16.0DK')]
        [string]$BCVersion
        
    )

$userName = $env:UserName


    Switch ($BCVersion){

    
            'BC13.0DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.0.24630.0-dk-ltsc2019"        
            }
            'BC13.1DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.1.25940.0-dk-ltsc2019"
            }
            'BC13.2DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.2.26556.0-dk-ltsc2019"            
            }
            'BC13.3DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.3.27233.0-dk-ltsc2019"    
            }
            'BC13.4DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.4.28874.0-dk-ltsc2019"
            }
            'BC13.5DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.5.29483.0-dk-ltsc2019"  
            }
            'BC13.6DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.6.29777.0-dk-ltsc2019"  
            }
            'BC13.7DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.7.31809.0-dk-ltsc2019"  
            }
            'BC13.8DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:13.8.32990.0-dk-ltsc2019"  
            }
            'BC14.0DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:14.0.29537.0-dk-ltsc2019"
            }
            'BC14.0-W1'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:14.0.29537.0-ltsc2019"
            }
            'BC14.1DK' 
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:14.1.32615.0-dk-ltsc2019"
                New-NavContainer -accept_eula -containerName $containerName -licenseFile $licenseFile -updateHosts -imageName $imagename -auth navuserpassword `
                -accept_outdated -shortcuts Desktop -isolation hyperv -includeAL -includeCSide  -additionalParameters @("--publish 444:443")
            }
            'BC15.0DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:15.0.36560.0-dk-ltsc2019"
                New-NavContainer -accept_eula -containerName $containerName -licenseFile $licenseFile -updateHosts -imageName $imagename -auth navuserpassword `
                -accept_outdated -shortcuts Desktop -useBestContainerOS -includeAL
            }
            'BC15.1DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:15.1.37793.0-dk-ltsc2019"
                New-NavContainer -accept_eula -containerName $containerName -licenseFile $licenseFile -updateHosts -imageName $imagename -auth navuserpassword `
                -accept_outdated -shortcuts Desktop -useBestContainerOS -includeAL
            }
             'BC15.2DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:15.2.39040.0-dk-ltsc2019"
                New-NavContainer -accept_eula -containerName $containerName -licenseFile $licenseFile -updateHosts -imageName $imagename -auth navuserpassword `
                -accept_outdated -shortcuts Desktop -useBestContainerOS -includeAL
            }
             'BC16.0DK'
            {
                $imagename = "mcr.microsoft.com/businesscentral/onprem:16.0.11240.12076-dk-ltsc2019"
                New-NavContainer -accept_eula -containerName $containerName -licenseFile $licenseFile -updateHosts -imageName $imagename -auth navuserpassword `
                -accept_outdated -shortcuts Desktop -includeAL -isolation hyperv -useBestContainerOS
                
            }
    }

    
  
    Write-Host -ForegroundColor Green "Moving Shortcuts"   
    
    $ShortCutFolder = 'C:\Users\$userName\Desktop\'
                  
    if (!(Test-Path -Path "$ShortCutFolder$containername")) {
        New-Item -ItemType Directory -Path "C:\Users\$userName\Desktop\$ContainerName"
    }
    if (Test-Path -Path "C:\Users\$userName\Desktop\$ContainerName Web Client.lnk") {
        Move-Item -Path "C:\Users\$userName\Desktop\$ContainerName Web Client.lnk" -Destination "C:\Users\$userName\Desktop\$ContainerName\$ContainerName Web Client.lnk" -Force
    }
    if (Test-Path -Path "C:\Users\$userName\Desktop\$ContainerName CSIDE.lnk") {
        Move-Item -Path "C:\Users\$userName\Desktop\$ContainerName CSIDE.lnk" -Destination "C:\Users\$userName\Desktop\$ContainerName\$ContainerName CSIDE.lnk" -Force
    }
    if (Test-Path -Path "C:\Users\$userName\Desktop\$ContainerName Command Prompt.lnk") { 
        Move-Item -Path "C:\Users\$userName\Desktop\$ContainerName Command Prompt.lnk" -Destination "C:\Users\$userName\Desktop\$ContainerName\$ContainerName Command Prompt.lnk" -Force
    }
    if (Test-Path -Path "C:\Users\$userName\Desktop\$ContainerName PowerShell Prompt.lnk") { 
        Move-Item -Path "C:\Users\$userName\Desktop\$ContainerName PowerShell Prompt.lnk" -Destination "C:\Users\$userName\Desktop\$ContainerName\$ContainerName PowerShell Prompt.lnk" -Force
    }
    if (Test-Path -Path "C:\Users\$userName\Desktop\$ContainerName Windows Client.lnk") {
        Move-Item -Path "C:\Users\$userName\Desktop\$ContainerName Windows Client.lnk" -Destination "C:\Users\$userName\Desktop\$ContainerName\$ContainerName Windows Client.lnk"
    }
    if (Test-Path -Path "C:\Users\$userName\Desktop\$ContainerName WinClient Debugger.lnk") {
        Move-Item -Path "C:\Users\$userName\Desktop\$ContainerName WinClient Debugger.lnk" -Destination "C:\Users\$userName\Desktop\$ContainerName\$ContainerName WinClient Debugger.lnk"
    }


    Write-Host -ForegroundColor Green "Docker Container Created"
}