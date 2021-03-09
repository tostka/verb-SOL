#*------v Connect-SOL.ps1 v------
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
    * 2:44 PM 3/2/2021 added console TenOrg color support
    * 8:09 AM 10/16/2020 updated $Cred to Meta lookup to cover Down-Level Logon Name's
    * 7:13 AM 7/22/2020 replaced codeblock w get-TenantTag(); rewrote SOL OverrideAdminDomain support, to dyn pull from infra settings ; fixed $MFA handling issues (flipped detect) ; replaced debug echos with verbose
    * 5:17 PM 7/21/2020 add ven supp
    * 10:03 AM 5/12/2020 updated cred to $credO365TORSID
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
        [string]$OverrideAdminDomain,
        [Parameter(HelpMessage="[noun]-PREFIX[command] PREFIX string for clearly marking cmdlets sourced in this connection [-CommandPrefix SOLlab]")]
        [string]$CommandPrefix = 'SOL',
        [Parameter(HelpMessage="Credential to use for this connection [-credential 'ADMINUPN@DOMAIN.COM']")]
        [System.Management.Automation.PSCredential]$Credential = $credO365TORSID
    ) ;
    $verbose = ($VerbosePreference -eq "Continue") ; 
    # disable prefix spec, unless actually blanked (e.g. centrally spec'd in profile).
    if(!$CommandPrefix){ $CommandPrefix='SOL' ; } ;
    
    # pulling the $MFA auto by splitting the credential and checking the o365_*_OPDomain & o365_$($credVariTag)_MFA global varis
    $MFA = get-TenantMFARequirement -Credential $Credential ;

    $sTitleBarTag="SOL" ;
    $TentantTag=get-TenantTag -Credential $Credential ; 
    if($TentantTag -ne 'TOR'){
        # explicitly leave this tenant (default) untagged
        $sTitleBarTag += $TentantTag ;
    } ; 
    
    $spltSOLsess=@{ } ;
    if(!$MFA){
        $spltSOLsess.Add("Credential",$Credential);
    } else {
        $spltSOLsess.Add("UserName",$Credential.username);
    } ;
    write-verbose "(using cred:$($credential.username))" ; 
    # set color scheme to White text on Black
    #$HOST.UI.RawUI.BackgroundColor = "Black" ; $HOST.UI.RawUI.ForegroundColor = "White" ;
    # $OverrideAdminDomain = $TORMeta['o365_TenantDomain'] ; 

    $credDom = ($Credential.username.split("@"))[1] ;
    if($credential.username){
        if($credential.username.contains('\')){$credDom = ($Credential.username.split("\"))[0] }
        elseif($credential.username.contains('@')){$credDom = ($Credential.username.split("@"))[1] }
        else { throw "Unrecognized or credential.username format (neither '\' or '@' present):$($Credential.username)!. EXITING" ; } ;
    }elseif($env:userdomain){$credDom = $env:userdomain} 
    else { throw "Unrecognized credential.username and *NO* `$env:UserName found. EXITING" ; } ;
    $Metas=(gv *meta|?{$_.name -match '^\w{3}Meta$'}) ; 
    foreach ($Meta in $Metas){
        if( ($credDom -eq $Meta.value.legacyDomain) -OR ($credDom -eq $Meta.value.o365_TenantDomain) -OR ($credDom -eq $Meta.value.o365_OPDomain)){
            $OverrideAdminDomain = $Meta.value.SOLOverrideAdminDomain ; 
            break ; 
        } ; 
    } ; 

    If ($OverrideAdminDomain) {
        $spltSOLsess.Add("OverrideAdminDomain",$OverrideAdminDomain);
    	Write-Host "Connecting to SOL w Hybrid OverrideAdminDomain:$($OverrideAdminDomain)"  ;
    } Else {
    	Write-Host "Connecting to SOL"  ;
    } ;

    if(!(get-command -Name New-CsOnlineSession -ea 0)){
        if(!(Get-Module SkypeOnlineConnector -ListAvailable -ErrorAction Stop | out-null)){ 
            <#dyn install missing module - but SOL mod *isn't avail* in psg must be BINARY dl'd & installed (facepalm)
            if(get-module PowerShellGet){ 
                Install-Module SkypeOnlineConnector -scope CurrentUser 

            }else { throw "REQUIRES WIN10, PSV5+ OR installed PowerShellGet module" } ;
            #>
            #https://docs.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-the-skype-for-business-online-connector
            $SOLModRefUrl = "https://docs.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-the-skype-for-business-online-connector" ; 
            $SOLModDlUrl = "https://www.microsoft.com/download/details.aspx?id=39366" ; 
            throw "MISSING REQUIRED SkypeOnlineConnector *binary* module`n -*NOT* available from PSGallery or other automatable sources`nSee support Site:`n$($SOLModRefURL)`nor MS DL:`n$($SOLModDlUrl)`n`nDL & Install, and restart PS before attempting to connect to SOL"
        }  ;
        <#Try {Get-Module SkypeOnlineConnector -ErrorAction Stop | out-null } Catch {Import-Module -Name SkypeOnlineConnector -ErrorAction Stop  } ;
        if(!$MFA){ $Teamssplat.Add("Credential",$Credential) }
        else { $Teamssplat.Add("AccountId",$Credential.username) }
        #>
    } else {  write-verbose "(SkypeOnlineConnector module installed)" } ;
    
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
            write-verbose "$((get-date).ToString('HH:mm:ss')):Import-Module w`n$(($pltModule|out-string).trim())" ;


            $Global:SOLModule = Import-Module @pltModule ;
            write-verbose "$((get-date).ToString('HH:mm:ss')):New-CsOnlineSession w`n$(($spltSOLsess|out-string).trim())" ;
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
            write-verbose "`n$((get-date).ToString('HH:mm:ss')):Import-PSSession w`n$(($pltPSS|out-string).trim())" ;
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
            <# borked by psreadline v1/v2 breaking changes
            if(($PSFgColor = (Get-Variable  -name "$($TenOrg)Meta").value.PSFgColor) -AND ($PSBgColor = (Get-Variable  -name "$($TenOrg)Meta").value.PSBgColor)){
                write-verbose "(setting console colors:$($TenOrg)Meta.PSFgColor:$($PSFgColor),PSBgColor:$($PSBgColor))" ; 
                $Host.UI.RawUI.BackgroundColor = $PSBgColor
                $Host.UI.RawUI.ForegroundColor = $PSFgColor ; 
            } ;
            #>
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

#*------^ Connect-SOL.ps1 ^------