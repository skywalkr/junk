<#
    .SYNOPSIS
        Configures apps for Windows Virtual Desktop.
#>

$BoldChatUri = "https://download.boldchat.com/ext/bin/boldchat2024.msi"
$CiscoJabberUri = "https://binaries.webex.com/static-content-pipeline/jabber-upgrade/production/jabberdesktop/apps/windows/public/latest/CiscoJabberSetup.msi"

# Force use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install BoldChat
$BoldChat = Invoke-WebRequest $BoldChatUri -Method Head -UseBasicParsing
$BoldChatInstaller = $BoldChat.BaseResponse.ResponseUri.Segments[$BoldChat.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest $BoldChatUri -outfile "$PSScriptRoot\$BoldChatInstaller" -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList ('/i "{0}\{1}" /l*v "{0}\{1}.log" /quiet' -f $PSScriptRoot,$BoldChatInstaller) -Wait

# Install Cisco Jabber
$CiscoJabber = Invoke-WebRequest $CiscoJabberUri -Method Head -UseBasicParsing
$CiscoJabberInstaller = $CiscoJabber.BaseResponse.ResponseUri.Segments[$CiscoJabber.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest $CiscoJabberUri -outfile "$PSScriptRoot\$CiscoJabberInstaller" -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList ('/i "{0}\{1}" /l*v "{0}\{1}.log" /quiet' -f $PSScriptRoot,$CiscoJabberInstaller) -Wait