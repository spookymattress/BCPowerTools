Param(
    [string] $serviceTier = 'BC170',
    [string] $RoleTailoredPath = "C:\Program Files\Microsoft Dynamics 365 Business Central\170\Service\",
    [string] $environment,
    [string] $tenantId,
    [string] $ClientID,
    [string] $ClientSecret,
    [ValidateSet('OnPrem','Cloud')]
    [string] $deploymentType = 'OnPrem'
)

$Folder = Get-ChildItem -Path "$env:System_ArtifactsDirectory\*app*" -Recurse -Directory 
$appPath = Get-ChildItem -Path ($Folder.FullName +"\*app") -Recurse

if($deploymentType -eq 'OnPrem'){
    Import-Module $RoleTailoredPath"Microsoft.Dynamics.Nav.Apps.Management.psd1"
    Import-Module $RoleTailoredPath"Microsoft.Dynamics.Nav.Management.dll"
    #Import-NAVServerLicense $serviceTier -LicenseData ([Byte[]]$(Get-Content -Path $DeveloperLicensePath -Encoding Byte))
    
    $Instance = Get-NAVServerInstance $serviceTier -Force
    if($Instance.State -eq 'Stopped'){
        Start-NAVServerInstance -ServerInstance $serviceTier -Force
    }
    
    $appPath | ForEach-Object {
        $version = (Get-NAVAppInfo -Path $_).Version
        $appName = (Get-NAVAppInfo -Path $_).Name
    
        $oldappName = (Get-NAVAppInfo -ServerInstance $serviceTier -Name "$appName").Name
        if ($oldappName){
            $oldVersion = (Get-NAVAppInfo -ServerInstance $serviceTier -Name "$appName").Version
            $oldVersion = $oldVersion[0].ToString()
        }
    
    
    
        Publish-NAVApp -ServerInstance $serviceTier -Path $_ -SkipVerification
        Sync-NAVTenant $serviceTier -Mode Sync -Force
        Sync-NAVApp -ServerInstance $serviceTier -Name $appName -Version $version -Force
    
        if (!$oldappName){
            Install-NAVApp -ServerInstance $serviceTier -Name $appName -Version $version 
        }else{
            Start-NAVAppDataUpgrade -ServerInstance $serviceTier -Name $appName -Version $version
            Unpublish-NAVApp -ServerInstance $serviceTier -Name $appName -Version $oldVersion
        }
    }
}
if($deploymentType -eq 'Cloud')
{

    $scopes       = "https://api.businesscentral.dynamics.com/.default"
    $baseUrl      = "https://api.businesscentral.dynamics.com/v2.0/$tenantId/$environment/api/microsoft/automation/v1.0"
    
    # Get access token 
    $token = Get-MsalToken `
             -ClientId $ClientID `
             -TenantId $tenantId `
             -Scopes $scopes `
             -ClientSecret (ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force)
    
    # Get companies
    $companies = Invoke-RestMethod `
                 -Method Get `
                 -Uri $("$baseurl/companies") `
                 -Headers @{Authorization='Bearer ' + $token.AccessToken}
    
    $companyId = $companies.value[0].id
    
    # Upload and install app
    Invoke-RestMethod `
    -Method Patch `
    -Uri $("$baseurl/companies($companyId)/extensionUpload(0)/content") `
    -Headers @{Authorization='Bearer ' + $token.AccessToken;'If-Match'='*'} `
    -ContentType "application/octet-stream" `
    -InFile $appPath 

    # Monitor publishing progress
    $inprogress = $true
    $completed = $false
    $errCount = 0

    Import-Module $RoleTailoredPath"Microsoft.Dynamics.Nav.Management.dll"
    Import-Module $RoleTailoredPath"Microsoft.Dynamics.Nav.Apps.Management.psd1"

    
    $version = (Get-NAVAppInfo -Path $appPath).Version
    $appName = (Get-NAVAppInfo -Path $appPath).Name

    Write-Host "Waiting for publish $version $appName"
    
    while ($inprogress)
    {
        Start-Sleep -Seconds 10
        try {
            $extensionDeploymentStatusResponse = Invoke-WebRequest `
                -Method Get `
                -Uri "$baseUrl/companies($companyId)/extensionDeploymentStatus" `
                -Headers @{Authorization='Bearer ' + $token.AccessToken}

            $extensionDeploymentStatuses = (ConvertFrom-Json $extensionDeploymentStatusResponse.Content).value
            $inprogress = $false
            $completed = $true
            
            $extensionDeploymentStatuses | Where-Object { $_.name -eq "$appName" -and $_.appVersion -eq "$version" } | % {
                Write-Host "$($_.name) $($_.appVersion) $($_.operationType) $($_.status)"
                if ($_.status -eq "InProgress") { $inProgress = $true }
                if ($_.status -ne "Completed") { $completed = $false }
            }
            $errCount = 0
        }
        catch {
            if ($errCount++ -gt 3) {
                $inprogress = $false
            }
        }
    }
    if (!$completed) {
        throw "Unable to publish app"
    }
}