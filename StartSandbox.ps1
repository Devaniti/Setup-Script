(Get-Content -path "Sandbox.wsb") -Replace '<HostFolder>.*<\/HostFolder>', "<HostFolder>${PSScriptRoot}</HostFolder>" | Out-File "${$env:TEMP}\Sandbox.wsb"
& "${$env:TEMP}\Sandbox.wsb"