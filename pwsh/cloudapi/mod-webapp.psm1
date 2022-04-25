##################################################################
#
# module to get, set (add), remove, entry in webapp.origin  by cloud api 
# to use it , is require to connect-cloudapi -server <fqdn>
# # Created by: Karol Zieliński
# Created on: 22.04.2022
# 
#
##################################################################

function get-cloud-webapp (
         [Parameter(Mandatory=$true,HelpMessage="Enter vcloud serwer fqdn")]$Server )
    {
$token = $global:DefaultCIServers_cloudapi.token[0]
$type = $global:DefaultCIServers_cloudapi.type
$server = $global:DefaultCIServers_cloudapi.server 
$Header = @{Authorization = 'Bearer '+ $token
              Accept =  $type[0]}
$url = 'https://' +$server+ '/cloudapi/1.0.0/site/settings/cors?filter=&sortAsc=origin&pageSize=100'
$req = Invoke-WebRequest -Headers $Header -uri $url -Method GET
$pages =  ($req.Content | ConvertFrom-Json ).pageCount 
$origins =  $req.Content | ConvertFrom-Json
$origins.values
}

function set-cloud-webapp (
    [Parameter(Mandatory=$true,HelpMessage="Enter vcloud serwer fqdn")]$Server,
    [Parameter(Mandatory=$true,HelpMessage='Enter new origin in format "https://fqdn1/","https://fqdn2/" ')]$webapp_origins 
    )
{
    $token = $global:DefaultCIServers_cloudapi.token[0]
    $type = $global:DefaultCIServers_cloudapi.type
    $server = $global:DefaultCIServers_cloudapi.server 
    $Header = @{Authorization = 'Bearer '+ $token
                Accept =  $type[0]}
$url = 'https://' +$server+ '/cloudapi/1.0.0/site/settings/cors'
    $origins =  get-cloud-webapp -Server $server
$body_head = '
{
        "resultTotal": 0,
        "pageCount": 0,
        "page": 0,
        "pageSize": 0,
        "associations": [
          {
            "entityId": "string",
            "associationId": "string"
          }
        ],
        "values": '
            
foreach  ($webapp_origin in  $webapp_origins ) { 
$origins  = $origins  + [PSCustomObject]@{origin = $webapp_origin }
        }
$body_main =  $origins | ConvertTo-Json

$body_end = '
}'
$body = $body_head + $body_main + $body_end
$put = Invoke-WebRequest -Headers $Header -uri $url -Method put -Body $body 
}  
function remove-cloud-webapp (
    [Parameter(Mandatory=$true,HelpMessage="Enter vcloud serwer fqdn")]$Server,
    [Parameter(Mandatory=$true,HelpMessage='Enter new origin in format "https://fqdn1/","https://fqdn2/" ')]$webapp_origins
      )
{
    $token = $global:DefaultCIServers_cloudapi.token[0]
    $type = $global:DefaultCIServers_cloudapi.type
    $server = $global:DefaultCIServers_cloudapi.server 
    $Header = @{Authorization = 'Bearer '+ $token
                Accept =  $type[0]}
$url = 'https://' +$server+ '/cloudapi/1.0.0/site/settings/cors'
    $origins =  get-cloud-webapp -Server $server
$body_head = '
    {
        "resultTotal": 0,
        "pageCount": 0,
        "page": 0,
        "pageSize": 0,
        "associations": [
          {
            "entityId": "string",
            "associationId": "string"
          }
        ],
        "values": '
foreach  ($webapp_origin in  $webapp_origins ) { 
$origins  = $origins   | ? origin -ne $webapp_origin 
        }
$body_main =  $origins | ConvertTo-Json
$body_end = '
}'
$body = $body_head + $body_main + $body_end
$put = Invoke-WebRequest -Headers $Header -uri $url -Method put -Body $body 

}  