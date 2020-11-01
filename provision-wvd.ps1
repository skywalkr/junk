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

# Create temp folder
New-Item -ItemType Directory "C:\Temp"

# Install FSLogix
$FSLogix = Invoke-WebRequest "https://aka.ms/fslogix_download" -Method Head -UseBasicParsing
$FSLogixArchive = $FSLogix.BaseResponse.ResponseUri.Segments[$FSLogix.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest "https://aka.ms/fslogix_download" -outfile "C:\Temp\$FSLogixArchive" -UseBasicParsing
Expand-Archive -Path "C:\Temp\$FSLogixArchive" -DestinationPath "C:\Temp\$($FSLogixArchive.Replace('.zip',''))"
Start-Process "C:\Temp\$($FSLogixArchive.Replace('.zip',''))\x64\Release\FSLogixAppsSetup.exe" -ArgumentList '/quiet' -Wait

# Install OneDrive
$OneDrive = Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2083517" -Method Head -UseBasicParsing
$OneDriveInstaller = $OneDrive.BaseResponse.ResponseUri.Segments[$OneDrive.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2083517" -outfile "C:\Temp\$OneDriveInstaller" -UseBasicParsing
Start-Process "C:\Temp\$OneDriveInstaller" -ArgumentList '/allusers /quiet' -Wait

# Install WebRTC
$WebRTC = Invoke-WebRequest "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt" -Method Head -UseBasicParsing
$WebRTCInstaller = $WebRTC.Headers.'Content-Disposition'.Split("=")[1]
Invoke-WebRequest "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt" -outfile "C:\Temp\$WebRTCInstaller" -UseBasicParsing
Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList ('/i "C:\Temp\{0}" /l*v "C:\Temp\{0}.log" /quiet' -f $WebRTCInstaller) -Wait

# Install Teams
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force | New-ItemProperty -Name "IsWVDEnvironment" -Value 1 -PropertyType DWORD

$Teams = Invoke-WebRequest "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi" -Method Head -UseBasicParsing
$TeamsInstaller = $Teams.BaseResponse.ResponseUri.Segments[$Teams.BaseResponse.ResponseUri.Segments.Length - 1]
Invoke-WebRequest "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi" -outfile "C:\Temp\$TeamsInstaller" -UseBasicParsing
Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList ('/i "C:\Temp\{0}" /l*v "C:\Temp\{0}.log" ALLUSER=1 ALLUSERS=1 /quiet' -f $TeamsInstaller) -Wait

# Install WVD Agent
$WVDAgent = Invoke-WebRequest "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -Method Head -UseBasicParsing
$WVDAgentInstaller = $WVDAgent.Headers.'Content-Disposition'.Split("=")[1]
Invoke-WebRequest "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -outfile "C:\Temp\$WVDAgentInstaller" -UseBasicParsing
Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList ('/i "C:\Temp\{0}" /l*v "C:\Temp\{0}.log" REGISTRATIONTOKEN={1} /quiet' -f $WVDAgentInstaller,$RegistrationToken) -Wait

# Install WVD Bootloader
$WVDBootloader = Invoke-WebRequest "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -Method Head -UseBasicParsing
$WVDBootloaderInstaller = $WVDBootloader.Headers.'Content-Disposition'.Split("=")[1]
Invoke-WebRequest "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -outfile "C:\Temp\$WVDBootloaderInstaller" -UseBasicParsing
Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList ('/i "C:\Temp\{0}" /l*v "C:\Temp\{0}.log" /quiet' -f $WVDBootloaderInstaller) -Wait