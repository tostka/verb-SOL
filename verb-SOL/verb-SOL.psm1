﻿# verb-sol.psm1


<#
.SYNOPSIS
verb-SOL - Skype-Online-related functions
.NOTES
Version     : 1.0.15.0
Author      : Todd Kadrie
Website     :	https://www.toddomation.com
Twitter     :	@tostka
CreatedDate : 4/8/2020
FileName    : verb-SOL.psm1
License     : MIT
Copyright   : (c) 4/8/2020 Todd Kadrie
Github      : https://github.com/tostka
AddedCredit : REFERENCE
AddedWebsite:	REFERENCEURL
AddedTwitter:	@HANDLE / http://twitter.com/HANDLE
REVISIONS
* 4/8/2020 - 1.0.0.0
# 11:38 AM 12/30/2019 ran vsc alias-expan
* 10:55 AM 12/6/2019 Connect-SOL: added suffix to TitleBar tag for non-TOR tenants, also config'd a central tab vari
* 5:14 PM 11/27/2019 repl $MFA code with get-TenantMFARequirement
* 1:07 PM 11/25/2019 added *tol/*tor/*cmw alias variants for connect & reconnect
* 10:00 AM 11/20/2019 added  doc for credential param. rsol already had credential support
* 10:21 AM 6/20/2019 finally got up to full function, added showdebug to rsol & csol
* 3:10 PM 6/19/2019 fixed?
* 1:02 PM 11/7/2018 added Disconnect-PssBroken
.DESCRIPTION
verb-SOL - Skype-Online-related functions
.LINK
https://github.com/tostka/verb-SOL
#>


$script:ModuleRoot = $PSScriptRoot ;
$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem $script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======



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
    * 2:58 PM 7/27/2021 pstitlebar updates
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
    [CmdletBinding()]
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

    $sTitleBarTag=@("SOL") ;
    $TentantTag=get-TenantTag -Credential $Credential ; 
    $sTitleBarTag += $TentantTag ;
    
    
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
    <#
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
    #>
    # direct pull
    if((Get-Variable  -name "$($TenOrg)Meta").value.SOLOverrideAdminDomain){
        $OverrideAdminDomain = (Get-Variable  -name "$($TenOrg)Meta").value.SOLOverrideAdminDomain
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
            
            Add-PSTitleBar $sTitleBarTag -verbose:$($VerbosePreference -eq "Continue")  ;
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

#*------v csolcmw.ps1 v------
function csolcmw {Connect-SOL -cred $credO365CMWCSID}

#*------^ csolcmw.ps1 ^------

#*------v csoltol.ps1 v------
function csoltol {Connect-SOL -cred $credO365TOLSID}

#*------^ csoltol.ps1 ^------

#*------v csoltor.ps1 v------
function csoltor {Connect-SOL -cred $credO365TORSID}

#*------^ csoltor.ps1 ^------

#*------v csolVEN.ps1 v------
function csolVEN {Connect-SOL -cred $credO365VENCSID}

#*------^ csolVEN.ps1 ^------

#*------v Disconnect-SOL.ps1 v------
Function Disconnect-SOL {
    <#
    .SYNOPSIS
    Disconnect-SOL - Disconnects any PSS to https://ps.outlook.com/powershell/ (cleans up session after a batch or other temp work is done)
    .NOTES
    Updated By: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    Based on original function Author:  ExactMike Perficient, Global Knowl... (Partner)
    Website:	https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    REVISIONS   :
    * 2:56 PM 7/27/2021 updated pstitletag, rem'd console color reset
    * 2:44 PM 3/2/2021 added console TenOrg color support
    # 10:25 AM 6/20/2019 switched to common $rgxSOLPsHostName
    # 8:47 AM 6/2/2017 cleaned up deadwood, simplified pshelp
    * 8:49 AM 3/15/2017 Disconnect-SOL: add Remove-PSTitleBar 'SOL' to clean up on disconnect
    * 7:58 AM 3/15/2017 ren Disconnect/Connect/Reconnect-SOL => Disconnect/Connect/Reconnect-SOL
    * 7:48 AM 3/15/2017 added pss, doing tweaks to put into prod use
    * 2/10/14 posted version
    .DESCRIPTION
    I use this to smoothly cleanup connections.
    Mike's original notes:
    The function Disconnect-SOL gets used within batches.  Below is one
    example of how I batch items for processing and use the
    Disconnect-SOL function.
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    Disconnect-SOL;
    .LINK
    https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    #>
    [CmdletBinding()]
    [Alias('dxo')]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
    if($Global:SOLModule){$Global:SOLModule | Remove-Module -Force ; } ;
    if($Global:SOLSession){$Global:SOLSession | Remove-PSSession ; } ;
    Get-PSSession|Where-Object{$_.ComputerName -match $rgxSOLPsHostName} | Remove-PSSession ;
    Remove-PSTitlebar 'SOL' -verbose:$($VerbosePreference -eq "Continue");;
    #[console]::ResetColor()  # reset console colorscheme
}

#*------^ Disconnect-SOL.ps1 ^------

#*------v Reconnect-SOL.ps1 v------
Function Reconnect-SOL {
    <#
    .SYNOPSIS
    Reconnect-SOL - Test and reestablish connection to SkypeForBusinessOnline @ admin0a.online.lync.com
    .NOTES
    Updated By: : Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	@tostka http://twitter.com/tostka
    Based on original function Author: ExactMike Perficient, Global Knowl... (Partner)
    Website:	https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    REVISIONS   :
    * 1:07 PM 11/25/2019 added *tol/*tor/*cmw alias variants for connect & reconnect
    * 10:00 AM 11/20/2019 added  doc for credential param
    * 9:51 AM 6/20/2019 init
    .DESCRIPTION
    I use this for routine test/reconnect of SOL. His orig use was within batches, to break up and requeue chunks of commands.
    Mike's original comment: Below is one
    example of how I batch items for processing and use the
    Reconnect-SOL function.  I'm still experimenting with how to best
    batch items and you can see here I'm using a combination of larger batches for
    Write-Progress and actually handling each individual item within the
    foreach-object script block.  I was driven to this because disconnections
    happen so often/so unpredictably in my current customer's environment:

    #-=-=Batch sample-=-=-=-=-=-=
    $batchsize = 10 ;
    $RecordCount=$mr.count  ;
    $b=0  ;
    $mrs = @() ;
    do {
        Write-Progress -Activity "Getting move request statistics for all $wave move requests." -Status "Processing Records $b through $($b+$batchsize) of $RecordCount." -PercentComplete ($b/$RecordCount*100) ;
        $mrs += $mr | Select-Object -skip $b -first $batchsize | foreach-object {Reconnect-SOL; $_ | Get-SOMETHING} ;
        $b=$b+$batchsize ;
        } ;
    until ($b -gt $RecordCount) ;
    #-=-=-=-=-=-=-=-=
    .PARAMETER  Credential
    Credential to use for this connection [-credential 'ADMINUPN@DOMAIN.COM']
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    Reconnect-SOL;
    .LINK
    https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    #>

    Param(
        [Parameter(HelpMessage="Credential to use for this connection [-credential [credential obj variable]")]
        [System.Management.Automation.PSCredential]$Credential
    ) ;
    $verbose = ($VerbosePreference -eq "Continue") ; 
    # fault tolerant looping SOL connect, don't let it exit until a connection is present, and stable, or return error for hard time out
    $tryNo=0 ;
    Do {
        $tryNo++ ;
        write-host "." -NoNewLine; if($tryNo -gt 1){Start-Sleep -m (1000 * 5)} ;
        <# 9:57 AM 6/20/2019 +[XXXX]::[PS]:C:\u\w\e\scripts$ $SOLSession | format-list *
            State                  : Opened
            ComputerType           : RemoteMachine
            ComputerName           : admin0a.online.lync.com
            ConfigurationName      : Microsoft.PowerShell
            Name                   : Session1
            Availability           : Available
            ApplicationPrivateData : {SessionInfo, PSVersionTable}
            Runspace               : System.Management.Automation.RemoteRunspace
        #>
        if (($SOLSession.state -ne 'Opened' -AND $SOLSession.Availability -ne 'Available') -or !$SOLSession) {
            write-verbose "$((get-date).ToString('HH:mm:ss')):Connecting:`$SOLSession invalid state:$(($SOLSession| Format-Table -a State,Availability |out-string).trim())"  ;
            Disconnect-SOL; Disconnect-PssBroken ;Start-Sleep -Seconds 3;
            if(!$Credential){
                Connect-SOL ;
            } else {
                Connect-SOL -Credential $Credential ;
            } ;
        } ;
        if( !(Get-PSSession|Where-Object{($_.ComputerName -match $rgxSOLPsHostName) -AND ($_.State -eq 'Opened') -AND ($_.Availability -eq 'Available')}) ){
            write-verbose "$((get-date).ToString('HH:mm:ss')):Reconnecting:No existing PSSESSION matching $($rgxSOLPsHostName) with valid Open/Availability:$((Get-PSSession|Where-Object{$_.ComputerName -match $rgxSOLPsHostName}| Format-Table -a State,Availability |out-string).trim())" ;
            if(!$Credential){
                Reconnect-SOL ;
            } else {
                Reconnect-SOL -credential $Credential ;
            } ;
        }  ;
        if($tryNo -gt $DoRetries ){throw "RETRIED SOL CONNECT $($tryNo) TIMES, ABORTING!" } ;
    } Until ((Get-PSSession |Where-Object{$_.ComputerName -match $rgxSOLPsHostName -AND $_.State -eq "Opened" -AND $_.Availability -eq "Available"}))
}

#*------^ Reconnect-SOL.ps1 ^------

#*------v rsolcmw.ps1 v------
function rsolcmw {Reconnect-SOL -cred $credO365CMWCSID}

#*------^ rsolcmw.ps1 ^------

#*------v rsoltol.ps1 v------
function rsoltol {Reconnect-SOL -cred $credO365TOLSID}

#*------^ rsoltol.ps1 ^------

#*------v rsoltor.ps1 v------
function rsoltor {Reconnect-SOL -cred $credO365TORSID}

#*------^ rsoltor.ps1 ^------

#*------v rsolVEN.ps1 v------
function rsolVEN {Reconnect-SOL -cred $credO365VENCSID}

#*------^ rsolVEN.ps1 ^------

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function Connect-SOL,csolcmw,csoltol,csoltor,csolVEN,Disconnect-SOL,Reconnect-SOL,rsolcmw,rsoltol,rsoltor,rsolVEN -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbHFKGir+RRuCxf8Fm0wVfN/d
# BL6gggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBT3/cK4
# s+KN7dBhBaDqQ9LSYXv0IDANBgkqhkiG9w0BAQEFAASBgFejZ4wLE965jxJdgicy
# zbWy2p28KiI7kI46zDrptIqUOGk1SVLwmu/vHBE1wXm4bNA6OarwGRpL8kk6bbTq
# Nw6rji8h/7CSCcHOmRp9WD7gJQsmY+OhbMRo6scyai2spDLfQUhJEQsJMXYt6wTL
# 3hXIbIc2omMhN7D1N8Lsdo46
# SIG # End signature block
