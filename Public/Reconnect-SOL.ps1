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