# Script for setting up new Windows 11 PC for graphic development
# You need need to run it with administator rights
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList @("-ExecutionPolicy Bypass", "-File `"$($MyInvocation.MyCommand.Path)`"")
    Exit
}

Push-Location $env:TEMP

# Window management to ask user about settings to set
function PromptUser() {    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # List of options
    $Options = @()
    $Options += @{Name = "Show file extensions."; Enabled = $true }
    $Options += @{Name = "Show hidden files."; Enabled = $true }
    $Options += @{Name = "Show full file path in explorer."; Enabled = $true }
    $Options += @{Name = "Always use full right click menu in explorer."; Enabled = $false }
    $Options += @{Name = "Enable Windows Developer Mode."; Enabled = $true }
    $Options += @{Name = "Install Graphic Tools component (required for d3d12 debug layer)."; Enabled = $true }
    $Options += @{Name = "Install Winget (required to install software below)."; Enabled = $true }
    $Options += @{Name = "Install Google Chrome."; Enabled = $true; Package = "Google.Chrome" }
    $Options += @{Name = "Install Mozilla Firefox."; Enabled = $false; Package = "Mozilla.Firefox" }
    $Options += @{Name = "Install Opera."; Enabled = $false; Package = "Opera.Opera" }
    $Options += @{Name = "Install Git."; Enabled = $true; Package = "Git.Git" }
    $Options += @{Name = "Install P4V."; Enabled = $false; Package = "Perforce.P4V" }
    $Options += @{Name = "Install Visual Studio Code."; Enabled = $true; Package = "Microsoft.VisualStudioCode" }
    $Options += @{Name = "Install CLion."; Enabled = $false; Package = "JetBrains.CLion" }
    $Options += @{Name = "Install Visual Studio 2022 Community."; Enabled = $true; Package = "Microsoft.VisualStudio.2022.Community" }
    $Options += @{Name = "Install Visual Studio 2022 Professional."; Enabled = $false; Package = "Microsoft.VisualStudio.2022.Professional" }
    $Options += @{Name = "Install Visual Studio 2022 Enterprise."; Enabled = $false; Package = "Microsoft.VisualStudio.2022.Enterprise" }
    $Options += @{Name = "Add .NET desktop development components to all Visual Studio instances ."; Enabled = $true }
    $Options += @{Name = "Add C++ desktop development components to all Visual Studio instances ."; Enabled = $true }
    $Options += @{Name = "Add UWP development components to all Visual Studio instances ."; Enabled = $true }
    $Options += @{Name = "Add Game development with C++ components to all Visual Studio instances ."; Enabled = $true }
    $Options += @{Name = "Install Microsoft PIX on Windows."; Enabled = $true; Package = "Microsoft.PIX" }
    $Options += @{Name = "Install RenderDoc."; Enabled = $true; Package = "BaldurKarlsson.RenderDoc" }
    $Options += @{Name = "Install Vulkan SDK."; Enabled = $true; Package = "KhronosGroup.VulkanSDK" }
    $Options += @{Name = "Install 7zip."; Enabled = $true; Package = "7zip.7zip" }
    $Options += @{Name = "Install Java Runtime Environment."; Enabled = $true; Package = "Oracle.JavaRuntimeEnvironment" }
    $Options += @{Name = "Install Python 3.11."; Enabled = $true; Package = "Python.Python.3.11" }
    $Options += @{Name = "Install OBS Studio."; Enabled = $false; Package = "OBSProject.OBSStudio" }
    $Options += @{Name = "Install VLC."; Enabled = $false; Package = "OBSProject.OBSStudio" }
    $Options += @{Name = "Install Slack."; Enabled = $false; Package = "SlackTechnologies.Slack" }
    $Options += @{Name = "Install Zoom."; Enabled = $false; Package = "Zoom.Zoom" }
    $Options += @{Name = "Install Discord."; Enabled = $false; Package = "Discord.Discord" }
    $Options += @{Name = "Install Microsoft Office."; Enabled = $false; Package = "Microsoft.Office" }
    $Options += @{Name = "Install PowerToys."; Enabled = $false; Package = "Microsoft.PowerToys" }
    $Options += @{Name = "Install Steam."; Enabled = $false; Package = "Valve.Steam" }
    $Options += @{Name = "Install Epic Games Launcher."; Enabled = $false; Package = "EpicGames.EpicGamesLauncher" }
    $Options += @{Name = "Restart Computer after completion."; Enabled = $true }

    #Enable DPI awareness
    $code = @"
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
"@
    $Win32Helpers = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru
    $null = $Win32Helpers::SetProcessDPIAware()
    $DPI = (Get-ItemProperty -path "HKCU:\Control Panel\Desktop\WindowMetrics").AppliedDPI
    $Font = New-Object System.Drawing.Font("Segoe UI", (0.065 * $DPI), [System.Drawing.FontStyle]::Regular)
    $Width = (6 * $DPI)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Graphics Dev Machine Setup'
    $form.StartPosition = 'CenterScreen'

    $CurrentOffset = (0.1 * $DPI)

    $Rows = @()
    Foreach ($i in $Options) {
        $LabelObj = New-Object System.Windows.Forms.Label
        $LabelObj.Location = New-Object System.Drawing.Point((0.3 * $DPI), $CurrentOffset)
        $LabelObj.Size = New-Object System.Drawing.Size(($Width - 1), (0.2 * $DPI))
        $LabelObj.Font = $Font
        $LabelObj.Text = $i.Name
        $form.Controls.Add($LabelObj)
        $CheckboxObj = New-Object System.Windows.Forms.CheckBox
        $CheckboxObj.Location = New-Object System.Drawing.Point((0.15 * $DPI), $CurrentOffset)
        $CheckboxObj.Size = New-Object System.Drawing.Size((0.2 * $DPI), (0.2 * $DPI))
        $CheckboxObj.Checked = $i.Enabled
        $form.Controls.Add($CheckboxObj)
        $Rows += @{Label = $LabelObj; Checkbox = $CheckboxObj; Package = $i.Package }
        $CurrentOffset += (0.25 * $DPI)
    }

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point((($Width / 2) - (0.8 * $DPI)), $CurrentOffset)
    $okButton.Size = New-Object System.Drawing.Size((0.7 * $DPI), (0.3 * $DPI))
    $okButton.Text = 'OK'
    $okButton.Font = $Font
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point((($Width / 2) + (0.1 * $DPI)), $CurrentOffset)
    $cancelButton.Size = New-Object System.Drawing.Size((0.7 * $DPI), (0.3 * $DPI))
    $cancelButton.Text = 'Cancel'
    $cancelButton.Font = $Font
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $CurrentOffset += (0.8 * $DPI)

    $form.Size = New-Object System.Drawing.Size($Width, $CurrentOffset)
    $form.Topmost = $true
    $result = $form.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        exit
    }

    $Result = @()
    Foreach ($i in $Rows) {
        $Result += @{Selected = $i.Checkbox.Checked; Package = $i.Package }
    }
    return $Result
}

$Settings = PromptUser

# Windows explorer settings
if ($Settings[0].Selected -eq $true) {
    # Sets option to always show file extensions
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0
}

if ($Settings[1].Selected -eq $true) {
    # Sets option to show hidden files (but not OS protected files)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1
}

if ($Settings[2].Selected -eq $true) {
    # Sets option to show full path instead of just folder name in file explorer window title
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -ErrorAction 'SilentlyContinue'
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name FullPath -Value 1
}

if ($Settings[3].Selected -eq $true) {
    # Reverts Windows 11's right mouse click menu back to full Windows 10 like menu
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -ErrorAction 'SilentlyContinue'
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -ErrorAction 'SilentlyContinue'
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -ErrorAction 'SilentlyContinue'
}

if ($Settings[4].Selected -eq $true) {
    # Enables Windows developer mode, which is required for some features (e.g. DXR debugging in PIX)
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -Value 1
}

if ($Settings[5].Selected -eq $true) {
    # Adds Graphic Tools package required for d3d12 debug layer
    Add-WindowsCapability -Online -Name "Tools.Graphics.DirectX~~~~0.0.1.0"
}

if ($Settings[10].Selected -eq $true) {
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
    Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile Microsoft.UI.Xaml.2.7.x64.appx
    Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx -ErrorAction 'SilentlyContinue'
    Add-AppxPackage Microsoft.UI.Xaml.2.7.x64.appx -ErrorAction 'SilentlyContinue'
    Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ErrorAction 'SilentlyContinue'
}

Foreach ($i in $Settings) {
    if ($i.Selected -and ($null -ne $i.Package)) {
        winget install -e --accept-source-agreements --accept-package-agreements $i.Package
    }
}

if (($Settings[17].Selected -eq $true) -or ($Settings[18].Selected -eq $true) -or ($Settings[19].Selected -eq $true) -or ($Settings[20].Selected -eq $true)) {
    Set-ExecutionPolicy unrestricted -Scope Process -Force

    if (-not (Get-Module -ListAvailable -Name VSSetup)) {
        Install-PackageProvider NuGet -Force
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        Install-Module VSSetup -Scope CurrentUser -Repository PSGallery
    }

    $commandLineArgs = @("modify")
    $commandLineArgs += "--installWhileDownloading"
    $commandLineArgs += "--passive"
    $commandLineArgs += "--norestart"

    if ($Settings[17].Selected -eq $true) {
        $commandLineArgs += "--add Microsoft.VisualStudio.Workload.ManagedDesktop"
    }
    
    if ($Settings[18].Selected -eq $true) {
        $commandLineArgs += " --add Microsoft.VisualStudio.Workload.NativeDesktop"
    }
    
    if ($Settings[19].Selected -eq $true) {
        $commandLineArgs += " --add Microsoft.VisualStudio.Workload.Universal"
    }
    
    if ($Settings[20].Selected -eq $true) {
        $commandLineArgs += " --add Microsoft.VisualStudio.Workload.NativeGame"
    }
    
    Foreach ($i in Get-VSSetupInstance) {
        $installPath = $i.InstallationPath
        $currentcommandLineArgs = ($commandLineArgs + "--installPath `"$installPath`"")
        Start-Process -FilePath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installershell.exe" -Wait -ArgumentList $currentcommandLineArgs
    }
}

if ($Settings[5].Selected -eq $true) {
    # Adds Graphic Tools package required for d3d12 debug layer
    Add-WindowsCapability -Online -Name "Tools.Graphics.DirectX~~~~0.0.1.0"
}

if ($Settings[36].Selected -eq $true) {
    Restart-Computer
}