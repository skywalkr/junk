<#
    .SYNOPSIS
        Configures machine for Windows Virtual Desktop.
    .PARAMETER RegistrationToken
        Token used to register virtual machine with session host pool
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$RegistrationToken    
)

# Remove unwanted packages
$PackageNames = "Microsoft.549981C3F5F10",
"Microsoft.BingWeather",
"Microsoft.Microsoft3DViewer",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.MicrosoftSolitaireCollection",
"Microsoft.MicrosoftStickyNotes",
"Microsoft.MixedReality.Portal",
"Microsoft.MSPaint",
"Microsoft.Office.OneNote",
"Microsoft.People",
"Microsoft.ScreenSketch",
"Microsoft.SkypeApp",
"Microsoft.StorePurchaseApp",
"Microsoft.Wallet",
"Microsoft.Windows.Photos",
"Microsoft.WindowsAlarms",
"Microsoft.WindowsCalculator",
"Microsoft.WindowsCamera",
"Microsoft.WindowsCommunicationsApps",
"Microsoft.WindowsFeedbackHub",
"Microsoft.WindowsMaps",
"Microsoft.WindowsSoundRecorder",
"Microsoft.WindowsStore",
"Microsoft.YourPhone",
"Microsoft.Xbox.TCUI",
"Microsoft.XboxApp",
"Microsoft.XboxGameOverlay",
"Microsoft.XboxGamingOverlay",
"Microsoft.XboxIdentityProvider",
"Microsoft.XboxSpeechToTextOverlay",
"Microsoft.ZuneMusic",
"Microsoft.ZuneVideo"

$FSLogixUri = "https://aka.ms/fslogix_download"
$OneDriveUri = "https://go.microsoft.com/fwlink/?linkid=2083517"
$WebRTCUri = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt"
$TeamsUri = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi"
$WVDAgentUri = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$WVDBootLoaderUri = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"

$InstalledPackages = Get-AppxPackage -AllUsers
$ProvisionedPackages = Get-AppxProvisionedPackage -Online

ForEach ($Package In $ProvisionedPackages) {
    If ($PackageNames -match $Package.DisplayName) {
        Remove-AppxProvisionedPackage -Online -PackageName $Package.PackageName -ErrorAction Ignore
    }
}

ForEach ($Package In $InstalledPackages) {
    If ($PackageNames -match $Package.Name) {
        Remove-AppxPackage -Package $Package.PackageFullName -AllUsers -ErrorAction Ignore
    }
}

# Force use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install FSLogix
$FSLogix = Invoke-WebRequest $FSLogixUri -Method Head -UseBasicParsing
$FSLogixArchive = $FSLogix.BaseResponse.ResponseUri.Segments[$FSLogix.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest $FSLogixUri -outfile "$PSScriptRoot\$FSLogixArchive" -UseBasicParsing
Expand-Archive -Path "$PSScriptRoot\$FSLogixArchive" -DestinationPath "$PSScriptRoot\$($FSLogixArchive.Replace('.zip',''))"
Start-Process "$PSScriptRoot\$($FSLogixArchive.Replace('.zip',''))\x64\Release\FSLogixAppsSetup.exe" -ArgumentList '/quiet' -Wait

# Install OneDrive
$OneDrive = Invoke-WebRequest $OneDriveUri -Method Head -UseBasicParsing
$OneDriveInstaller = $OneDrive.BaseResponse.ResponseUri.Segments[$OneDrive.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest $OneDriveUri -outfile "$PSScriptRoot\$OneDriveInstaller" -UseBasicParsing
Start-Process "$PSScriptRoot\$OneDriveInstaller" -ArgumentList '/allusers /quiet' -Wait

# Install WebRTC
$WebRTC = Invoke-WebRequest $WebRTCUri -Method Head -UseBasicParsing
$WebRTCInstaller = $WebRTC.Headers.'Content-Disposition'.Split("=")[1]
Invoke-WebRequest $WebRTCUri -outfile "$PSScriptRoot\$WebRTCInstaller" -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList ('/i "{0}\{1}" /l*v "{0}\{1}.log" /quiet' -f $PSScriptRoot,$WebRTCInstaller) -Wait

# Install Teams
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force | New-ItemProperty -Name "IsWVDEnvironment" -Value 1 -PropertyType DWORD
$Teams = Invoke-WebRequest $TeamsUri -Method Head -UseBasicParsing
$TeamsInstaller = $Teams.BaseResponse.ResponseUri.Segments[$Teams.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest $TeamsUri -outfile "$PSScriptRoot\$TeamsInstaller" -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList ('/i "{0}\{1}" /l*v "{0}\{1}.log" ALLUSER=1 ALLUSERS=1 /quiet' -f $PSScriptRoot,$TeamsInstaller) -Wait

# Install WVD Agent
$WVDAgent = Invoke-WebRequest $WVDAgentUri -Method Head -UseBasicParsing
$WVDAgentInstaller = $WVDAgent.Headers.'Content-Disposition'.Split("=")[1]
Invoke-WebRequest $WVDAgentUri -outfile "$PSScriptRoot\$WVDAgentInstaller" -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList ('/i "{0}\{1}" /l*v "{0}\{1}.log" REGISTRATIONTOKEN={2} /quiet' -f $PSScriptRoot,$WVDAgentInstaller,$RegistrationToken) -Wait

# Install WVD Bootloader
$WVDBootloader = Invoke-WebRequest $WVDBootLoaderUri -Method Head -UseBasicParsing
$WVDBootloaderInstaller = $WVDBootloader.Headers.'Content-Disposition'.Split("=")[1]
Invoke-WebRequest $WVDBootLoaderUri -outfile "$PSScriptRoot\$WVDBootloaderInstaller" -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList ('/i "{0}\{1}" /l*v "{0}\{1}.log" /quiet' -f $PSScriptRoot,$WVDBootloaderInstaller) -Wait