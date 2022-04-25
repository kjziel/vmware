##################################################################
#
# module to create session with token to cloud director, using cloudapi endpoint 
# # Created by: Karol Zieliński
# Created on: 21.04.2022
# Created for: Exea Data Center
#
##################################################################


Function connect-cloudapi (
    [Parameter(Mandatory=$true,HelpMessage="Enter vcloud serwer fqdn")]$Server,
    [Parameter(Mandatory=$false,HelpMessage="tenant org ")]$Org,
    [Parameter(Mandatory=$true,HelpMessage="session type  provider or tenant")][ArgumentCompletions('provider', 'tenant' )]$accesstype )
{
    
<#
.Description
module to connect to vmware cloud director cloudapi endpoint
connect-cloudapi -server <vcdfqdn> -org <orgname> -accesstype <provider or tenant>
command login to api vcloud, generate token and save value to $global:DefaultCIServers_cloudapi 
#> 


$cred = Get-Credential
if ($accesstype -eq  "provider") { $org = "system" }
[xml]$vcd_version = (Invoke-WebRequest  -Uri  https://$server/api/versions ).Content
$latest_api = ($vcd_version.SupportedVersions.VersionInfo | sort Version -Descending  | ? version -ge 36 | select -First 1)
$api_version = $latest_api.Version 
$href_provider  = $latest_api.ProviderLoginUrl
$href_tenant  = '' +$latest_api.LoginUrl
$user = $cred.GetNetworkCredential().UserName + "@" + $org
$pass = $cred.GetNetworkCredential().Password
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Header_login = @{
    Authorization = $basicAuthValue
    Accept =  'application/*;version=' + $api_version 
}
$req =  Invoke-WebRequest -Uri $href_provider -Headers $Header_login  -Method POST
$session_token =  ($req.Headers  | ConvertTo-Json  | ConvertFrom-Json )."X-VMWARE-VCLOUD-ACCESS-TOKEN" 
$session_create_token_date  = ($req.Headers  | ConvertTo-Json  | ConvertFrom-Json ).date
$session_type  = ($req.Headers  | ConvertTo-Json  | ConvertFrom-Json )."Content-Type"
$session_location = ($req.Headers  | ConvertTo-Json  | ConvertFrom-Json )."Content-Location"
$session_id = ($req.Content   | ConvertFrom-Json  ).id 
$session_user = ($req.Content   | ConvertFrom-Json  ).user
$session_user_role = ($req.Content   | ConvertFrom-Json  ).roles
$session_org = ($req.Content   | ConvertFrom-Json  ).org
$sessionIdleTimeoutMinutes = ($req.Content   | ConvertFrom-Json  ).sessionIdleTimeoutMinutes
$session_global =   [PSCustomObject]@{
    Server     = $Server
    Token     = $session_token
    Createtime      = $session_create_token_date 
    Type     = $session_type
    Location = $session_location
    ID       = $session_id
    User     = $session_user
    Userrole = $session_user_role
    Org      = $session_org
    SessionIdleTimeoutMinutes    = $sessionIdleTimeoutMinutes
}
if ($global:DefaultCIServers_cloudapi)  
{
    Set-Variable -Scope global -Name DefaultCIServers_cloudapi -Value $session_global
}
else  {
    New-Variable -Scope global -Name DefaultCIServers_cloudapi -Value $session_global
}
if ($global:DefaultCIServers_cloudapi.server ) 
    {
        Write-Host  $global:DefaultCIServers_cloudapi.user.name "you are connected to" $global:DefaultCIServers_cloudapi.server 
    }
}


Function disconnect-cloudapi (
    [Parameter(Mandatory=$true,HelpMessage="Enter vcloud serwer fqdn")]$Server )
{
<#
.Description
module to disconnect from  cloud director cloudapi endpoint
disconnect-cloudapi -server <vcdfqdn> 
#> 
    if ($global:DefaultCIServers_cloudapi)  
{
    Remove-Variable -Scope global -Name DefaultCIServers_cloudapi
    Write-Host "session disconnected"
}
else  {
    Write-Host "no session" }
}
