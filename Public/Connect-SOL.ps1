Function Connect-SOL {
    <#
    .SYNOPSIS
    Connect-SOL - Establish PSS to https://ps.outlook.com/powershell/
    .NOTES
    Author: : Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    Based on 'overlapping functions' concept by: ExactMike Perficient, Global Knowl... (Partner)
    Website:	https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    REVISIONS   :
    * 10:55 AM 12/6/2019 Connect-SOL: added suffix to TitleBar tag for non-TOR tenants, also config'd a central tab vari
    * 5:14 PM 11/27/2019 repl $MFA code with get-TenantMFARequirement
    * 1:07 PM 11/25/2019 added *tol/*tor/*cmw alias variants for connect & reconnect
    * 2:45 PM 4/18/2018 port cxo to cSOL
    .DESCRIPTION
    .PARAMETER  ProxyEnabled
    Use Proxy-Aware SessionOption settings [-ProxyEnabled]
    .PARAMETER  CommandPrefix
    [noun]-PREFIX[command] PREFIX string for clearly marking cmdlets sourced in this connection [-CommandPrefix SOLlab ]
    .PARAMETER  Credential
    Credential to use for this connection [-credential 'ADMINUPN@DOMAIN.COM']
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    connect-SOL
    Connect using defaults, and leverage any pre-set $global:o365cred variable
    .EXAMPLE
    connect-SOL -CommandPrefix SOL -credential (Get-Credential -credential s-todd.kadrie@torolab.com)  ;
    Connect an explicit credential, and use 'SOLlab' as the cmdlet prefix
    .LINK
    https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    *---^ END Comment-based Help  ^--- #>

    Param(
        [Parameter(HelpMessage="Force domain autodiscovery to connect to SOL (necessary with Skype Hybrid on-prem)[-OverrideAdminDomain TENANT.onmicrosoft.com]")]
        [string]$OverrideAdminDomain = $TORMeta['o365_TenantDomain'],
        [Parameter(HelpMessage="[noun]-PREFIX[command] PREFIX string for clearly marking cmdlets sourced in this connection [-CommandPrefix SOLlab]")]
        [string]$CommandPrefix = 'SOL',
        [Parameter(HelpMessage="Credential to use for this connection [-credential 'ADMINUPN@DOMAIN.COM']")]
        [System.Management.Automation.PSCredential]$Credential = $credTORSID,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug
    ) ;
    # disable prefix spec, unless actually blanked (e.g. centrally spec'd in profile).
    if(!$CommandPrefix){ $CommandPrefix='SOL' ; } ;

    # pulling the $MFA auto by splitting the credential and checking the o365_*_OPDomain & o365_$($credVariTag)_MFA global varis
    $MFA = get-TenantMFARequirement -Credential $Credential ;

    $sTitleBarTag="SOL" ;
    
    # use credential domain to determine target org
    $rgxLegacyLogon = '\w*\\\w*' ; 
    if($Credential.username -match $rgxLegacyLogon){
        $credDom =$Credential.username.split('\')[0] ; 
        switch ($credDom){
            "$($TORMeta['legacyDomain'])" {
                # leave untagged
            }
            "$($TOLMeta['legacyDomain'])" {
                $sTitleBarTag = $sTitleBarTag + "TOL"
            }
            "$CMWMeta['legacyDomain'])" {
                $sTitleBarTag = $sTitleBarTag + "CMW"
            }
        } ; 
    } elseif ($Credential.username.contains('@')){
        $credDom = ($Credential.username.split("@"))[1] ;
        switch ($credDom){
            "$($TORMeta['o365_OPDomain'])" {
                # leave untagged
            }
            "$($TOLMeta['o365_OPDomain'])" {
                $sTitleBarTag = $sTitleBarTag + "TOL"
            }
            "$CMWMeta['o365_OPDomain'])" {
                $sTitleBarTag = $sTitleBarTag + "CMW"
            }
        } ; 
    } else {
        write-warning "$((get-date).ToString('HH:mm:ss')):UNRECOGNIZED CREDENTIAL!:$($Credential.Username)`nUNABLE TO RESOLVE DEFAULT EX10SERVER FOR CONNECTION!" ;
    }  ;  
    
    $spltSOLsess=@{ } ;
    if($MFA){
        $spltSOLsess.Add("Credential",$Credential);
    } else {
        $spltSOLsess.Add("UserName",$Credential.username);
    } ;

    # set color scheme to White text on Black
    #$HOST.UI.RawUI.BackgroundColor = "Black" ; $HOST.UI.RawUI.ForegroundColor = "White" ;
    If ($OverrideAdminDomain) {
        $spltSOLsess.Add("OverrideAdminDomain",$OverrideAdminDomain);
    	Write-Host "Connecting to SOL w Hybrid OverrideAdminDomain:$($OverrideAdminDomain)"  ;
    } Else {
    	Write-Host "Connecting to SOL"  ;
    } ;
    $Exit = 0 ; # zero out $exit each new cmd try/retried
    Do {
        $error.clear() ;# 11:42 AM 9/11/2017 add preclear, we're going to post-test the $error
        Try {
            $pltModule=[ordered]@{
                Name="SkypeOnlineConnector" ;
                Global=$true;
                Prefix=$CommandPrefix ;
                PassThru=$true;
                DisableNameChecking=$true ;
            } ;
            if($showDebug){
                write-host -foregroundcolor green "`n$((get-date).ToString('HH:mm:ss')):Import-Module w`n$(($pltModule|out-string).trim())" ;
            } ;
            $Global:SOLModule = Import-Module @pltModule ;
            if($showDebug){
                write-host -foregroundcolor green "`n$((get-date).ToString('HH:mm:ss')):New-CsOnlineSession w`n$(($spltSOLsess|out-string).trim())" ;
            } ;

            $Global:SOLSession = New-CsOnlineSession @spltSOLsess ;
            <# PSSession object: 8:51 AM 6/20/2019
            State                  : Opened
            IdleTimeout            : 900000
            OutputBufferingMode    : None
            DisconnectedOn         :
            ExpiresOn              :
            ComputerType           : RemoteMachine
            ComputerName           : admin0a.online.lync.com
            ContainerId            :
            VMName                 :
            VMId                   :
            ConfigurationName      : Microsoft.PowerShell
            InstanceId             : efa81a32-caaf-4e67-8c2a-015ba96e3d1a
            Id                     : 2
            Name                   : Session2
            Availability           : Available
            ApplicationPrivateData : {SessionInfo, PSVersionTable}
            Runspace               : System.Management.Automation.RemoteRunspace
            #>
            #Import-PSSession -Session $CSSession
            #Import-PSSession $Global:SOLSession -Prefix $CommandPrefix -DisableNameChecking -AllowClobber
            $pltPSS=[ordered]@{
                Session=$Global:SOLSession ;
                Prefix=$CommandPrefix ;
                DisableNameChecking=$true  ;
                AllowClobber=$true ;
            } ;
            if($showDebug){
                write-host -foregroundcolor green "`n$((get-date).ToString('HH:mm:ss')):Import-PSSession w`n$(($pltPSS|out-string).trim())" ;
            } ;
            Import-PSSession @pltPSS ;
            #$SOLSession = New-SOLCsOnlineSession -Credential $o365cred ;
            # with hybrid above throws up: The remote name could not be resolved: 'lyncdiscover.DOMAIN.com'

            <# 3:10 PM 4/18/2018 live connect pssession
            #-=-=-=-=-=-=-=-=
            Name              : Session3
            ComputerName      : admin0a.online.lync.com
            ConfigurationName : Microsoft.PowerShell
            #-=-=-=-=-=-=-=-=
            #>
            if($error.count -ne 0) {
                if($error[0].FullyQualifiedErrorId -eq '-2144108477,PSSessionOpenFailed'){
                    write-warning "$((get-date).ToString('HH:mm:ss')):AUTH FAIL BAD PASSWORD? ABORTING TO AVOID LOCKOUT!" ;
                    throw "$((get-date).ToString('HH:mm:ss')):AUTH FAIL BAD PASSWORD? ABORTING TO AVOID LOCKOUT!" ;
                    EXIT ;
                } ;
            } ;
            
            Add-PSTitleBar $sTitleBarTag ;
            $Exit = $Retries ;
        } Catch {
            # capture auth errors - nope, they never get here, if use throw, it doesn't pass in the auth $error, gens a new one.
            # pause to give it time to reset
            Start-Sleep -Seconds $RetrySleep ;
            $Exit ++ ;
            Write-Verbose "Failed to exec cmd because: $($Error[0])" ;
            Write-Verbose "Try #: $Exit" ;
            If ($Exit -eq $Retries) {Write-Warning "Unable to exec cmd!"} ;
        } # try-E
    } Until ((Get-PSSession |Where-Object{$_.ComputerName -match $rgxSOLPsHostName -AND $_.State -eq "Opened" -AND $_.Availability -eq "Available"}) -or ($Exit -eq $Retries) ) # loop-E
}
