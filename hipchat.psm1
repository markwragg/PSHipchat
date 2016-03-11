﻿#Requires -Version 3.0

<#
    .PARAMETER  message
     Required. The message body. 10,000 characters max.

    .PARAMETER  color
     The background colour of the HipChat message. One of "yellow", "green", "red", "purple", "gray", or "random". (default: gray)

    .PARAMETER  notify
     Set whether or not this message should trigger a notification for people in the room. (default: false)

    .PARAMETER  apitoken
     Required. This must be a HipChat API token created by a Room Admin for the room you are sending notifications to (default: API key for Test room).

    .PARAMETER  room
     Required. The id or URL encoded name of the HipChat room you want to send the message to (default: Test).

    .PARAMETER  retry
     The number of times to retry sending the message (default: 0)

    .PARAMETER  retrysecs
     The number of seconds to wait between tries (default: 30)
#>

function Send-Hipchat {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)][string]$message,
        [ValidateSet('yellow', 'green', 'red', 'purple', 'gray','random')][string]$color = 'gray',
        [switch]$notify,
        [Parameter(Mandatory = $True)][string]$apitoken,   
        [Parameter(Mandatory = $True)][string]$room,
        [int]$retry = 0,
        [int]$retrysecs = 30
    )

    $authObj = @{
	    "Authorization" = "Bearer $($apitoken)";
	    "Content-type" = "application/json"
    }

    $messageObj = @{
        "message" = $message;
        "color" = $color;
        "notify" = [string]$notify
    }
                
    $uri = "https://api.hipchat.com/v2/room/$room/notification"    
    $body = ConvertTo-Json $messageObj

    $Retrycount = 0
    $Result = $null
 
    
    While(!$Result -and $RetryCount -le $retry){
	    $Retrycount++
        try {
		    $Result = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $authObj -ErrorAction SilentlyContinue
		    Write-Verbose "'$message' sent"
		    Return $true
		    }
	    catch {
            $errormessage = $_
            Write-Verbose "Could not send message. $($_.Exception.message)"
		    
            If ($retrycount -lt $retry){
                Write-Verbose "retrying in $retrysecs seconds..."
                Start-Sleep -Seconds $retrysecs
            }
	    }
    }
    
    #Report any errors
    If ($errormessage.ErrorDetails.Message -ne $null){
        Write-Error ($errormessage.ErrorDetails.Message | convertfrom-json).error.message
    }Else{
        Write-Verbose "Could not send after $Retrycount tries. I quit."
		Write-Error $errormessage.Exception.message
    } 

    Return $false
}