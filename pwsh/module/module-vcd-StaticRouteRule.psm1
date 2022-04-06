script based on Markus Kraus  vMarkusK/NatRules.ps1   https://gist.github.com/vMarkusK 

Function New-EdgeStaticRouteRul (
		$EdgeGateway,
		$EdgeInterface,
		$Network,
		$NextHop,
		$descraption) {
	$Edgeview = Search-Cloud -QueryType EdgeGateway -name $EdgeGateway | Get-CIView
	if (!$Edgeview) {
		Write-Warning "Edge Gateway with name $Edgeview not found"
		break
	}
##name convert 
	if ($edgeinterface.InterfaceType -eq "internal" ){ 
		$edgeinterface.InterfaceType = $edgeinterface.InterfaceType.substring(0,1).toupper()+$edgeinterface.InterfaceType.substring(1).tolower()
	}
	elseif ($edgeinterface.InterfaceType -eq "Uplink")
	{
		$edgeinterface.InterfaceType = "External" 
	}
	$URI = ($edgeview.Href + "/action/configureServices")
	$wc = New-Object System.Net.WebClient
	$wc.Headers.Add("x-vcloud-authorization", $Edgeview.Client.SessionKey)
	$wc.Headers.Add("Content-Type", "application/vnd.vmware.admin.edgeGatewayServiceConfiguration+xml")
	$wc.Headers.Add("Accept", "application/*+xml;version=34.0")
	$webclient = New-Object system.net.webclient
    $webclient.Headers.Add("x-vcloud-authorization",$Edgeview.Client.SessionKey)
    $webclient.Headers.Add("accept",$EdgeView.Type + ";version=34.0")
    [xml]$EGWConfXML = $webclient.DownloadString($EdgeView.href)
	[xml]$OriginalXML = $EGWConfXML.EdgeGateway.Configuration.EdgegatewayServiceConfiguration.StaticRoutingService.outerxml
	$strXML = '<StaticRoute>
	<Name>' + $descraption + '</Name>
	<Network>' + $Network + '</Network>
	<NextHopIp>' + $NextHop + '</NextHopIp>
	<Interface>' + $EdgeInterface.InterfaceType + '</Interface>
	<GatewayInterface href="' + $EdgeInterface.href + '" name="' + $EdgeInterface.name + '" type="application/vnd.vmware.vcloud.orgVdcNetwork+xml"/>
	</StaticRoute>'
	$GoXML = '<?xml version="1.0" encoding="UTF-8"?><EdgeGatewayServiceConfiguration xmlns="http://www.vmware.com/vcloud/v1.5"><StaticRoutingService><IsEnabled>true</IsEnabled>'
	$OriginalXML.StaticRoutingService.StaticRoute | ForEach-Object {
		$GoXML += $_.OuterXML
	}
	$GoXML += $StrXML
	$GoXML += '</StaticRoutingService></EdgeGatewayServiceConfiguration>'
	$headers = @{
		"Content-Type" = "application/vnd.vmware.admin.edgeGatewayServiceConfiguration+xml"
		"x-vcloud-authorization" = $Edgeview.Client.SessionKey
		"Accept" = "application/*+xml;version=34.0"
	}
	$request = Invoke-RestMethod -Method POST  -Uri $URI -SkipCertificateCheck  -Headers $headers -Body $GoXML -SkipHttpErrorCheck
	if($request.Error.message) {$request.Error.message}
}	

Function Get-EdgeStaticRouteRule ($EdgeGateway)  {  
    $Edgeview = Search-Cloud -QueryType EdgeGateway -name $EdgeGateway | Get-CIView
	if (!$Edgeview) {
		Write-Warning "Edge Gateway with name $Edgeview not found"
		break
	}
    $webclient = New-Object system.net.webclient
    $webclient.Headers.Add("x-vcloud-authorization",$Edgeview.Client.SessionKey)
    $webclient.Headers.Add("accept",$EdgeView.Type + ";version=34.0")
    [xml]$EGWConfXML = $webclient.DownloadString($EdgeView.href)
    $StaticRouteRules = $EGWConfXML.EdgeGateway.Configuration.EdgegatewayServiceConfiguration.StaticRoutingService.StaticRoute
    $Rules = @()
    if ($StaticRouteRules){
		$StaticRouteRules | ForEach-Object {
	        $NewRule = new-object PSObject -Property @{
	        name = $_.name
			network = $_.network
			NextHopIp = $_.NextHopIp
			Interfacetype  = $_.Interface
			Interface = $_.GatewayInterface.name 
	    }
	        $Rules += $NewRule
	    }
	}
    $Rules
}

Function Get-EdgeInterface ($EdgeGateway)  {  
    $Edgeview = Search-Cloud -QueryType EdgeGateway -name $EdgeGateway | Get-CIView
	if (!$Edgeview) {
		Write-Warning "Edge Gateway with name $Edgeview not found"
		break
	}
    $webclient = New-Object system.net.webclient
    $webclient.Headers.Add("x-vcloud-authorization",$Edgeview.Client.SessionKey)
    $webclient.Headers.Add("accept",$EdgeView.Type + ";version=34.0")
    [xml]$EGWConfXML = $webclient.DownloadString($EdgeView.href)
    $EdgeInterfaces  = $EGWConfXML.EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface
    $Rules = @()
    if ($EdgeInterfaces){
		$EdgeInterfaces | ForEach-Object {
	        $NewRule = new-object PSObject -Property @{
	        Name = $_.name
			DisplayName = $_.DisplayName
			Network_name= $_.Network.name 
			InterfaceType= $_.InterfaceType
			Subnet_Gateway= $_.SubnetParticipation.Gateway
			Subnet_Netmask= $_.SubnetParticipation.Netmask
			Subnet_SubnetPrefixLength= $_.SubnetParticipation.SubnetPrefixLength
			Subnet_IpAddress= $_.SubnetParticipation.IpAddress
			Subnet_UseForDefaultRoute= $_.SubnetParticipation.UseForDefaultRoute
			Subnet_TotalIpCount= $_.SubnetParticipation.TotalIpCount
			ApplyRateLimit= $_.ApplyRateLimit
			UseForDefaultRoute= $_.UseForDefaultRoute
			Connected= $_.Connected
			href= $_.Network.href
	    }
	        $Rules += $NewRule
	    }
	}
    $Rules
}
