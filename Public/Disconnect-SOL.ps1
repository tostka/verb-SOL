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
    *---^ END Comment-based Help  ^--- #>
    # 9:25 AM 3/21/2017 getting undefined on the below, pretest them
    if($Global:SOLModule){$Global:SOLModule | Remove-Module -Force ; } ;
    if($Global:SOLSession){$Global:SOLSession | Remove-PSSession ; } ;
    Get-PSSession|Where-Object{$_.ComputerName -match $rgxSOLPsHostName} | Remove-PSSession ;
    Remove-PSTitlebar 'SOL' ;
}
