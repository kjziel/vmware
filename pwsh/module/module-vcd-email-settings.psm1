Function get-email-settings ()
        { 
            $vcd_uri =  $Global:DefaultCIServers[0].href
            $session_key  =  $Global:DefaultCIServers[0].SessionSecret
            $api_version  = $Global:DefaultCIServers[0].ExtensionData.Client.Version
            $accept = 'application/*+xml;version=' + $api_version
            $headers = @{
                "x-vcloud-authorization" = $session_key 
                "Accept" = $accept
            }
            #$headers
            $vcd_href = '' + $vcd_uri + 'admin/extension/settings/email'  
            $request =   Invoke-WebRequest  -Uri  $vcd_href -Headers $headers
            #$request.Content  
            $settings =  [xml]$request.Content
            $settings.EmailSettings | select SenderEmailAddress,
            EmailSubjectPrefix , 
            AlertEmailToAllAdmins ,
            AlertEmailTo , 
            @{n="UseAuthentication";e={$_.SmtpSettings.UseAuthentication}},
            @{n="SmtpServerName";e={$_.SmtpSettings.SmtpServerName}},
            @{n="SmtpServerPort";e={$_.SmtpSettings.SmtpServerPort}},
            @{n="SmtpSecureMode";e={$_.SmtpSettings.SmtpSecureMode}},
            @{n="UserName";e={$_.SmtpSettings.UserName}}
        }


Function set-email-settings (
            #[Parameter(Mandatory)]$SmtpSecureMode,

            [Parameter(Mandatory=$true,HelpMessage="Enter one START_TLS , SSL, null ")][ArgumentCompletions('START_TLS', 'SSL', 'null' )]$SmtpSecureMode,
            [Parameter(Mandatory=$true,HelpMessage="password to email account")]$Password)
    {
        $vcd_uri =  $Global:DefaultCIServers[0].href
        $session_key  =  $Global:DefaultCIServers[0].SessionSecret
        $api_version  = $Global:DefaultCIServers[0].ExtensionData.Client.Version
        #### get setting section 
        $get_accept = 'application/*+xml;version=' + $api_version
    $get_headers = @{
            "x-vcloud-authorization" = $session_key 
            "Accept" = $get_accept
        }    
        #$headers
        $vcd_href = '' + $vcd_uri + 'admin/extension/settings/email'  
        $get_request =   Invoke-WebRequest  -Uri  $vcd_href -Headers $get_headers
        $settings =  [xml]$get_request.Content
        $get_request_href = $settings.EmailSettings.href
        $SenderEmailAddress = $settings.EmailSettings.SenderEmailAddress
        $EmailSubjectPrefix  = $settings.EmailSettings.EmailSubjectPrefix
        $AlertEmailToAllAdmins =  $settings.EmailSettings.AlertEmailToAllAdmins
        $AlertEmailTo = $settings.EmailSettings.AlertEmailTo
        $UseAuthentication =   $settings.EmailSettings.SmtpSettings.UseAuthentication
        $SmtpServerName =   $settings.EmailSettings.SmtpSettings.SmtpServerName
        $SmtpServerPort =   $settings.EmailSettings.SmtpSettings.SmtpServerPort
        #$SmtpSecureMode =   $settings.EmailSettings.SmtpSettings.SmtpSecureMode
        $UserName =     $settings.EmailSettings.SmtpSettings.UserName

        #### set setting 
        #$SmtpSecureMode =  "START_TLS"   ## START_TLS , SSL, null 
        #$Password = "xxxxx"

$bodyjson ='{
    "href" : "'+$get_request_href+'",
    "type" : "application/vnd.vmware.admin.emailSettings+json",
    "senderEmailAddress" :  "'+$SenderEmailAddress+'",
    "emailSubjectPrefix" : "'+$EmailSubjectPrefix+'",
    "alertEmailToAllAdmins" : '+$AlertEmailToAllAdmins+',
    "alertEmailTo" : "'+$AlertEmailTo+'",
    "smtpSettings" : {
      "useAuthentication" : '+$UseAuthentication+',
      "smtpServerName" : "'+$SmtpServerName+'",
      "smtpServerPort" : '+$SmtpServerPort+',
      "smtpSecureMode" : "'+$SmtpSecureMode+'",
      "userName" : "'+$UserName+'",
      "password" : "'+$Password+'",
      "vCloudExtension" : [ ]
    },
    "vCloudExtension" : [ ]
  }'


$set_headers = @{
    "Content-Type" = "application/vnd.vmware.admin.emailSettings+json"
    "x-vcloud-authorization" = $session_key
    "Accept" = "application/*+json;version=" + $api_version
}
#$headers
$vcd_href = '' + $vcd_uri + 'admin/extension/settings/email'  
$set_request =   Invoke-WebRequest  -Method PUT -Uri  $vcd_href -Headers $set_headers -Body $bodyjson
}

# 'example user   set-email-settings -SmtpSecureMode START_TLS -Password "pppp"'