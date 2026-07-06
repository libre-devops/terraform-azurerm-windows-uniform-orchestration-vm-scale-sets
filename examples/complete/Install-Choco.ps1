# Runs on every instance at first boot via the CustomScriptExtension (encoded into
# commandToExecute with textencodebase64, PowerShell's -EncodedCommand wants UTF-16LE).
# Kept useful but basic: bootstrap Chocolatey and a couple of everyday tools.
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

& "$env:ProgramData\chocolatey\bin\choco.exe" install --yes --no-progress curl 7zip
