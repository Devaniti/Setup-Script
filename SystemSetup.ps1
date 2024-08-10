# Script for setting up new Windows 11 PC for graphic development
# You need need to run it with administator rights
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList @("-ExecutionPolicy Bypass", "-File `"$($MyInvocation.MyCommand.Path)`"")
    Exit
}

Push-Location $env:TEMP

function ShowFileExtensions {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0
}
function ShowHiddenFiles {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1
}
function ShowFullFilePathInExplorer {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -ErrorAction 'SilentlyContinue'
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name FullPath -Value 1
}
function UseFullRightClickMenu {
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -ErrorAction 'SilentlyContinue'
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -ErrorAction 'SilentlyContinue'
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -ErrorAction 'Continue'
}
function EnableWindowsDeveloperMode {
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -Value 1
}
function InstallGraphicTools {
    Add-WindowsCapability -Online -Name "Tools.Graphics.DirectX~~~~0.0.1.0" -ErrorAction 'Continue'
}
function InstallWinget {
    Write-Output "Downloading WinGet and its dependencies..." | Out-Host
    Write-Output "No progress output during download, this may take a while..." | Out-Host
    $PrevProgressPreference = $ProgressPreference
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
    Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile Microsoft.UI.Xaml.2.8.x64.appx
    $ProgressPreference = $PrevProgressPreference
    Write-Output "Download finished, installing WinGet" | Out-Host
    Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx -ErrorAction 'SilentlyContinue'
    Add-AppxPackage Microsoft.UI.Xaml.2.8.x64.appx -ErrorAction 'SilentlyContinue'
    Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ErrorAction 'SilentlyContinue'
    Remove-Item -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Remove-Item -Path Microsoft.VCLibs.x64.14.00.Desktop.appx
    Remove-Item -Path Microsoft.UI.Xaml.2.8.x64.appx 
}

function SetPowershellExecutionPolicyToUnrestricted {
    # Run on built-in powershell
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Bypass -Force
    # Refresh path to see new powershell
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    # Run again, but on new powershell
    pwsh -command "Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Bypass -Force"
}

function AllowLongPathsInGit {
    # Refresh path to include git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    git config --system core.longpaths true
}

function DisableWindowsAppExecutionAliasForPython {
    Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe
    Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe
}

function RestartComputer {
    Restart-Computer
}

# Window management to ask user about settings to set
function PromptUser() {    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Enables modern controls
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # List of options
    $Options = @()
    $Options += @{Name = "Show file extensions."; Enabled = $true; Callback = $function:ShowFileExtensions }
    $Options += @{Name = "Show hidden files."; Enabled = $true; Callback = $function:ShowHiddenFiles }
    $Options += @{Name = "Show full file path in explorer."; Enabled = $true; Callback = $function:ShowFullFilePathInExplorer }
    $Options += @{Name = "Always use full right click menu in explorer."; Enabled = $false; Callback = $function:UseFullRightClickMenu }
    $Options += @{Name = "Enable Windows Developer Mode."; Enabled = $true; Callback = $function:EnableWindowsDeveloperMode }
    $Options += @{Name = "Install Graphic Tools component (required for d3d12 debug layer)."; Enabled = $true; Callback = $function:InstallGraphicTools }
    $Options += @{Name = "Install Winget (required to install software below)."; Enabled = $true; Callback = $function:InstallWinget }
    $Options += @{Name = "Install Google Chrome."; Enabled = $true; Package = "Google.Chrome" }
    $Options += @{Name = "Install Mozilla Firefox."; Enabled = $false; Package = "Mozilla.Firefox" }
    $Options += @{Name = "Install Opera."; Enabled = $false; Package = "Opera.Opera" }
    $Options += @{Name = "Install Latest Powershell."; Enabled = $true; Package = "Microsoft.PowerShell" }
    $Options += @{Name = "Set Powershell execution policy to unrestricted."; Enabled = $true; Callback = $function:SetPowershellExecutionPolicyToUnrestricted }
    $Options += @{Name = "Install Git."; Enabled = $true; Package = "Git.Git" }
    $Options += @{Name = "Allow long paths in Git."; Enabled = $true; Callback = $function:AllowLongPathsInGit }
    $Options += @{Name = "Install P4V."; Enabled = $false; Package = "Perforce.P4V" }
    $Options += @{Name = "Install Cmake."; Enabled = $true; Package = "Kitware.CMake" }
    $Options += @{Name = "Install Visual Studio Code."; Enabled = $true; Package = "Microsoft.VisualStudioCode" }
    $Options += @{Name = "Install CLion."; Enabled = $false; Package = "JetBrains.CLion" }
    $Options += @{Name = "Install Visual Studio 2022 Community."; Enabled = $true; Package = "Microsoft.VisualStudio.2022.Community" }
    $Options += @{Name = "Install Visual Studio 2022 Professional."; Enabled = $false; Package = "Microsoft.VisualStudio.2022.Professional" }
    $Options += @{Name = "Install Visual Studio 2022 Enterprise."; Enabled = $false; Package = "Microsoft.VisualStudio.2022.Enterprise" }
    $Options += @{Name = "Add .NET desktop development components to all Visual Studio instances ."; Enabled = $true; VSComponent = "Microsoft.VisualStudio.Workload.ManagedDesktop" }
    $Options += @{Name = "Add C++ desktop development components to all Visual Studio instances ."; Enabled = $true; VSComponent = "Microsoft.VisualStudio.Workload.NativeDesktop" }
    $Options += @{Name = "Add UWP development components to all Visual Studio instances ."; Enabled = $true; VSComponent = "Microsoft.VisualStudio.Workload.Universal" }
    $Options += @{Name = "Add Game development with C++ components to all Visual Studio instances ."; Enabled = $true; VSComponent = "Microsoft.VisualStudio.Workload.NativeGame" }
    $Options += @{Name = "Install Microsoft PIX on Windows."; Enabled = $true; Package = "Microsoft.PIX" }
    $Options += @{Name = "Install RenderDoc."; Enabled = $true; Package = "BaldurKarlsson.RenderDoc" }
    $Options += @{Name = "Install Vulkan SDK."; Enabled = $true; Package = "KhronosGroup.VulkanSDK" }
    $Options += @{Name = "Install 7zip."; Enabled = $true; Package = "7zip.7zip" }
    $Options += @{Name = "Install Python 3.12."; Enabled = $true; Package = "Python.Python.3.12" }
    $Options += @{Name = "Disable Windows App Execution Alias for Python."; Enabled = $true; Callback = $function:DisableWindowsAppExecutionAliasForPython }
    $Options += @{Name = "Install OBS Studio."; Enabled = $false; Package = "OBSProject.OBSStudio" }
    $Options += @{Name = "Install VLC."; Enabled = $false; Package = "OBSProject.OBSStudio" }
    $Options += @{Name = "Install Slack."; Enabled = $false; Package = "SlackTechnologies.Slack" }
    $Options += @{Name = "Install Zoom."; Enabled = $false; Package = "Zoom.Zoom" }
    $Options += @{Name = "Install Discord."; Enabled = $false; Package = "Discord.Discord" }
    $Options += @{Name = "Install Microsoft Office."; Enabled = $false; Package = "Microsoft.Office" }
    $Options += @{Name = "Install PowerToys."; Enabled = $false; Package = "Microsoft.PowerToys" }
    $Options += @{Name = "Install Steam."; Enabled = $false; Package = "Valve.Steam" }
    $Options += @{Name = "Install Epic Games Launcher."; Enabled = $false; Package = "EpicGames.EpicGamesLauncher" }
    $Options += @{Name = "Restart Computer after completion."; Enabled = $true; LateCallback = $function:RestartComputer }

    #Enable DPI awareness
    $code = @"
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
"@
    $Win32Helpers = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru
    $null = $Win32Helpers::SetProcessDPIAware()
    $DPI = (Get-ItemProperty -path "HKCU:\Control Panel\Desktop\WindowMetrics").AppliedDPI
    $Font = New-Object System.Drawing.Font("Segoe UI", (0.065 * $DPI), [System.Drawing.FontStyle]::Regular)
    $Width = (5.5 * $DPI)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Graphics Dev Machine Setup by Devaniti'
    $form.StartPosition = 'CenterScreen'

    $CurrentOffset = (0.05 * $DPI)

    $Rows = @()
    Foreach ($i in $Options) {
        $CheckboxObj = New-Object System.Windows.Forms.CheckBox
        $CheckboxObj.Location = New-Object System.Drawing.Point((0.15 * $DPI), $CurrentOffset)
        $CheckboxObj.Size = New-Object System.Drawing.Size(($Width - (0.4 * $DPI)), (0.2 * $DPI))
        $CheckboxObj.Checked = $i.Enabled
        $CheckboxObj.Font = $Font
        $CheckboxObj.Text = $i.Name
        $form.Controls.Add($CheckboxObj)
        $Rows += @{Checkbox = $CheckboxObj; Option = $i }
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

    $form.AutoScroll = $true
    $Width = $Width + (0.1 * $DPI)

    $FormHeight = [math]::min($CurrentOffset, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height - (0.8 * $DPI))

    $form.Size = New-Object System.Drawing.Size($Width, $FormHeight)
    $form.Topmost = $true
    $result = $form.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return
    }

    $Result = @()
    Foreach ($i in $Rows) {
        $temp = $i.Option;
        $temp.Enabled = $i.Checkbox.Checked;
        $Result += $temp
    }
    return $Result
}

$Settings = PromptUser

if ($null -eq $Settings) {
    Pop-Location
    return
}

$VSModulesToInstall = @()

Foreach ($i in $Settings) {
    if ($i.Enabled -and ($null -ne $i.Callback)) {
        Write-Output "Running callback for $($i.Name)"
        $i.Callback.Invoke()
    }
    if ($i.Enabled -and ($null -ne $i.Package)) {
        Write-Output "Installing $($i.Name)"
        winget install -e --accept-source-agreements --accept-package-agreements --scope machine $i.Package
    }
    if ($i.Enabled -and ($null -ne $i.VSComponent)) {
        Write-Output "Added $($i.Name) to list of Visual Studio components"
        $VSModulesToInstall += "--add $($i.VSComponent);includeRecommended"
    }
}

if (0 -ne $VSModulesToInstall.Length) {
    Write-Output "Installing Visual Studio components"
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
    $commandLineArgs += $VSModulesToInstall;
        
    Foreach ($i in Get-VSSetupInstance) {
        $installPath = $i.InstallationPath
        $currentcommandLineArgs = ($commandLineArgs + "--installPath `"$installPath`"")
        Start-Process -FilePath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installershell.exe" -Wait -ArgumentList $currentcommandLineArgs | Out-Null
    }

    # vs_installershell seem to create broken Nuget.config with no entries
    # first we check if it is indeed broken
    # default config will be larger than 150 bytes
    $file = Get-Item -LiteralPath "$env:APPDATA\nuget\nuget.config" -ErrorAction 'SilentlyContinue'
    if ($file.Length -lt 150) {
        # If it is broken, we can just remove broken config, 
        # it will be recreated by nuget on first use with correct defaults
        Remove-Item $file -ErrorAction 'SilentlyContinue'
    }
}

Foreach ($i in $Settings) {
    if ($i.Enabled -and ($null -ne $i.LateCallback)) {
        Write-Output "Running late callback for $($i.Name)"
        $i.LateCallback.Invoke()
    }
}

Pop-Location
